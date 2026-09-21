import json
import os
import time
import random
import hashlib
import hmac
import base64
import urllib.parse
import logging
import string
import threading
import requests
from datetime import datetime

import pymysql

from flask import Flask, request, jsonify, g
from flask_cors import CORS

from config import Config

logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)
app.config['JSON_AS_ASCII'] = False


# ==================== 缓存层 (Redis + 内存回退) ====================

class MemoryCache:
    def __init__(self):
        self._store = {}

    def set(self, key, value, ttl=None):
        expire = time.time() + ttl if ttl else None
        self._store[key] = (value, expire)

    def get(self, key):
        if key not in self._store:
            return None
        value, expire = self._store[key]
        if expire and time.time() > expire:
            del self._store[key]
            return None
        return value

    def delete(self, key):
        self._store.pop(key, None)

    def exists(self, key):
        return self.get(key) is not None

    def incr(self, key, ttl=None):
        val = int(self.get(key) or 0) + 1
        self.set(key, str(val), ttl)
        return val

    def ttl(self, key):
        if key not in self._store:
            return -2
        _, expire = self._store[key]
        if expire is None:
            return -1
        return max(0, int(expire - time.time()))


class RedisCache:
    def __init__(self, host, port, password, db):
        import redis
        self.client = redis.Redis(host=host, port=port, password=password, db=db, decode_responses=True)
        self.client.ping()

    def set(self, key, value, ttl=None):
        if ttl:
            self.client.setex(key, ttl, value)
        else:
            self.client.set(key, value)

    def get(self, key):
        return self.client.get(key)

    def delete(self, key):
        self.client.delete(key)

    def exists(self, key):
        return self.client.exists(key) > 0

    def incr(self, key, ttl=None):
        pipe = self.client.pipeline()
        pipe.incr(key)
        if ttl:
            pipe.expire(key, ttl)
        result = pipe.execute()
        return result[0]

    def ttl(self, key):
        return self.client.ttl(key)


def init_cache():
    try:
        cache = RedisCache(Config.REDIS_HOST, Config.REDIS_PORT, Config.REDIS_PASSWORD, Config.REDIS_DB)
        logger.info("Redis连接成功")
        return cache
    except Exception as e:
        logger.warning(f"Redis连接失败，使用内存缓存: {e}")
        return MemoryCache()


cache = init_cache()


# ==================== 阿里云短信服务 (直接HTTP调用) ====================

class AliyunSmsService:
    def __init__(self):
        self._available = bool(Config.ALIYUN_ACCESS_KEY_ID and Config.ALIYUN_ACCESS_KEY_SECRET)
        if self._available:
            logger.info("阿里云短信服务初始化成功")
        else:
            logger.warning("阿里云AccessKey未配置，短信发送功能不可用")

    def _percent_encode(self, s):
        s = str(s)
        s = urllib.parse.quote(s, safe='')
        s = s.replace('+', '%20').replace('*', '%2A').replace('%7E', '~')
        return s

    def _sign(self, params, secret):
        sorted_keys = sorted(params.keys())
        canonicalized = "&".join(f"{self._percent_encode(k)}={self._percent_encode(params[k])}" for k in sorted_keys)
        string_to_sign = "GET&" + self._percent_encode("/") + "&" + self._percent_encode(canonicalized)
        hmac_obj = hmac.new((secret + "&").encode("utf-8"), string_to_sign.encode("utf-8"), hashlib.sha1)
        return base64.b64encode(hmac_obj.digest()).decode("utf-8")

    def send_verify_code(self, phone, code, country_code="86"):
        if not self._available:
            logger.warning("阿里云AccessKey不可用，跳过短信发送。验证码已存入缓存。")
            return True, "AccessKey不可用", ""

        if not Config.ALIYUN_SMS_SIGN_NAME:
            logger.warning("短信签名未配置，跳过短信发送。验证码已存入缓存。")
            return True, "签名未配置", ""

        params = {
            "AccessKeyId": Config.ALIYUN_ACCESS_KEY_ID,
            "Format": "JSON",
            "Version": "2017-05-25",
            "SignatureMethod": "HMAC-SHA1",
            "Timestamp": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
            "SignatureVersion": "1.0",
            "SignatureNonce": hashlib.md5(f"{phone}{time.time()}{random.random()}".encode()).hexdigest(),
            "Action": "SendSmsVerifyCode",
            "PhoneNumber": phone,
            "SignName": Config.ALIYUN_SMS_SIGN_NAME,
            "TemplateCode": Config.ALIYUN_SMS_TEMPLATE_CODE,
            "TemplateParam": json.dumps({
                Config.CODE_TEMPLATE_VAR: code,
                "min": Config.CODE_VALID_DISPLAY
            }),
            "ReturnVerifyCode": "false",
            "Interval": str(Config.SMS_SEND_INTERVAL),
            "DuplicatePolicy": "1",
            "CodeLength": str(Config.CODE_LENGTH),
            "ValidTime": str(Config.CODE_VALID_TIME),
            "CountryCode": country_code,
        }

        params["Signature"] = self._sign(params, Config.ALIYUN_ACCESS_KEY_SECRET)

        try:
            query = "&".join(f"{self._percent_encode(k)}={self._percent_encode(params[k])}" for k in sorted(params.keys()))
            full_url = f"https://{Config.ALIYUN_DYPNS_ENDPOINT}/?{query}"
            import urllib.request as _ur
            import urllib.error as _ure
            req = _ur.Request(full_url, method="GET", headers={"User-Agent": "xianleihuhu-backend/1.0"})
            resp_body = ""
            try:
                with _ur.urlopen(req, timeout=10) as resp_raw:
                    resp_body = resp_raw.read().decode("utf-8")
                    result = json.loads(resp_body)
            except _ure.HTTPError as e:
                err_body = e.read().decode("utf-8") if e.fp else ""
                resp_body = err_body
                logger.error(f"阿里云HTTP错误 {e.code}: {err_body}")
                try:
                    result = json.loads(err_body)
                except Exception:
                    result = {"Code": "UNKNOWN", "Message": f"HTTP {e.code}: {err_body[:200]}"}

            if result.get("Code") == "OK":
                logger.info(f"短信发送成功: phone={phone}, response={resp_body[:200]}")
                model = result.get("Model")
                biz_id = model.get("BizId", "") if isinstance(model, dict) else ""
                return True, "发送成功", biz_id
            else:
                resp_preview = json.dumps(result, ensure_ascii=False)[:300]
                logger.error(f"短信发送失败: phone={phone}, code={result.get('Code')}, msg={result.get('Message')}, full={resp_preview}")
                return False, result.get("Message") or "发送失败", ""
        except Exception as e:
            logger.error(f"短信发送异常: phone={phone}, error={e}")
            return False, str(e), ""


sms_service = AliyunSmsService()


# ==================== Resend邮箱服务 ====================

class ResendEmailService:
    def __init__(self):
        self._available = bool(Config.RESEND_API_KEY)
        if self._available:
            logger.info("Resend邮箱服务初始化成功")
        else:
            logger.warning("Resend API Key未配置，邮箱发送功能不可用")

    def send_verify_code(self, email, code):
        if not self._available:
            logger.warning("Resend API Key不可用，跳过邮件发送。验证码已存入缓存。")
            return True, "API Key不可用"

        subject = f"您的验证码：{code}"
        html_body = (
            f'<div style="font-family:sans-serif;max-width:400px;margin:0 auto;padding:32px;">'
            f'<h2 style="color:#2b313d;">雷虎虎验证码</h2>'
            f'<p style="color:#787a7e;font-size:15px;">您的验证码为：</p>'
            f'<p style="font-size:32px;font-weight:bold;color:#3f74fc;letter-spacing:6px;">{code}</p>'
            f'<p style="color:#999;font-size:13px;">验证码{Config.CODE_VALID_DISPLAY}分钟内有效，请勿告知他人。</p>'
            f'</div>'
        )

        payload = {
            "from": f"{Config.RESEND_FROM_NAME} <{Config.RESEND_FROM_EMAIL}>",
            "to": [email],
            "subject": subject,
            "html": html_body,
        }

        try:
            headers = {
                "Authorization": f"Bearer {Config.RESEND_API_KEY}",
                "Content-Type": "application/json",
            }
            resp = requests.post(
                Config.RESEND_API_URL,
                json=payload,
                headers=headers,
                timeout=10,
            )
            if resp.status_code == 200:
                result = resp.json()
                logger.info(f"邮件发送成功: email={email}, id={result.get('id', '')}")
                return True, "发送成功"
            else:
                try:
                    err_json = resp.json()
                    msg = err_json.get("message", "") or err_json.get("error", "") or f"发送失败({resp.status_code})"
                except Exception:
                    msg = f"发送失败({resp.status_code})"
                logger.error(f"邮件发送失败: email={email}, status={resp.status_code}, body={resp.text}")
                return False, msg
        except Exception as e:
            logger.error(f"邮件发送异常: email={email}, error={e}")
            return False, str(e)


email_service = ResendEmailService()


# ==================== 工具函数 ====================

def generate_code():
    return str(random.randint(10 ** (Config.CODE_LENGTH - 1), 10 ** Config.CODE_LENGTH - 1))


def generate_short_no():
    """生成10位短ID"""
    import string as s
    chars = s.ascii_uppercase + s.digits
    # 去掉易混淆字符
    chars = chars.replace('O', '').replace('0', '').replace('I', '').replace('1', '')
    code = ''.join(random.choices(chars, k=10))
    # 确保唯一
    try:
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute("SELECT id FROM user WHERE short_no=%s", (code,))
                while cursor.fetchone():
                    code = ''.join(random.choices(chars, k=10))
                    cursor.execute("SELECT id FROM user WHERE short_no=%s", (code,))
        finally:
            conn.close()
    except Exception as e:
        logging.error(f"generate_short_no error: {e}")
    return code


def is_valid_short_no(short_no):
    """验证short_no格式是否正确（10位大写字母+数字，不含易混淆字符）"""
    if not short_no or len(short_no) != 10:
        return False
    import string as s
    valid_chars = set(s.ascii_uppercase + s.digits)
    valid_chars -= {'O', '0', 'I', '1'}
    return all(c in valid_chars for c in short_no)


def hash_password(plain_pwd):
    """使用bcrypt对密码进行哈希，返回带盐值的哈希字符串"""
    import bcrypt
    return bcrypt.hashpw(plain_pwd.encode('utf-8'), bcrypt.gensalt(rounds=12)).decode('utf-8')


def verify_password(plain_pwd, stored_hash):
    """验证密码：兼容bcrypt和旧版双重MD5，验证成功后自动标记需迁移"""
    import bcrypt
    if not stored_hash:
        return False
    try:
        if stored_hash.startswith('$2b$') or stored_hash.startswith('$2a$'):
            return bcrypt.checkpw(plain_pwd.encode('utf-8'), stored_hash.encode('utf-8'))
    except Exception:
        pass
    old_hash = hashlib.md5(hashlib.md5(plain_pwd.encode()).hexdigest().encode()).hexdigest()
    return old_hash == stored_hash


def is_legacy_hash(stored_hash):
    """判断是否为旧版MD5哈希（需要迁移）"""
    return stored_hash is not None and not (stored_hash.startswith('$2b$') or stored_hash.startswith('$2a$'))


def get_client_ip():
    if request.headers.get('X-Forwarded-For'):
        return request.headers.get('X-Forwarded-For').split(',')[0].strip()
    if request.headers.get('X-Real-IP'):
        return request.headers.get('X-Real-IP')
    return request.remote_addr or '127.0.0.1'


def make_success(data=None):
    if data is None:
        return jsonify({})
    return jsonify(data)


def make_error(msg, status=400):
    return jsonify({"status": status, "msg": msg}), status


# ==================== 缓存Key生成 ====================

def code_key(biz, channel, account):
    prefix = Config.SMS_KEY_PREFIX if channel == "phone" else Config.EMAIL_KEY_PREFIX
    biz_prefix = biz
    return f"{prefix}{biz_prefix}{channel}:{account}"


def last_send_key(biz, channel, account):
    prefix = Config.SMS_KEY_PREFIX if channel == "phone" else Config.EMAIL_KEY_PREFIX
    return f"{prefix}{biz}last:{channel}:{account}"


def hourly_count_key(biz, channel, account):
    prefix = Config.SMS_KEY_PREFIX if channel == "phone" else Config.EMAIL_KEY_PREFIX
    return f"{prefix}{biz}hourly:{channel}:{account}"


def ip_register_key(ip):
    return f"register:ip:{ip}"


def user_info_key(uid):
    return f"user:info:{uid}"


def user_token_key(uid):
    return f"user:token:{uid}"


# ==================== 频控检查 ====================

def check_rate_limit(biz, channel, account):
    last_key = last_send_key(biz, channel, account)
    hourly_key = hourly_count_key(biz, channel, account)

    last_send = cache.get(last_key)
    if last_send:
        elapsed = time.time() - float(last_send)
        remaining = Config.SMS_SEND_INTERVAL - int(elapsed)
        if remaining > 0:
            return False, f"发送过于频繁，请{remaining}秒后重试"

    hourly_count = int(cache.get(hourly_key) or 0)
    if hourly_count >= Config.SMS_HOURLY_LIMIT:
        return False, "发送次数已达上限，请1小时后再试"

    return True, ""


def record_rate_limit(biz, channel, account):
    last_key = last_send_key(biz, channel, account)
    hourly_key = hourly_count_key(biz, channel, account)

    cache.set(last_key, str(time.time()), ttl=Config.SMS_SEND_INTERVAL)
    cache.incr(hourly_key, ttl=3600)


# ==================== IP限流 ====================

def check_ip_register_limit(ip):
    key = ip_register_key(ip)
    count = int(cache.get(key) or 0)
    if count >= Config.REGISTER_IP_HOURLY_LIMIT:
        return False, "注册请求过于频繁，请稍后重试"
    return True, ""


def record_ip_register(ip):
    key = ip_register_key(ip)
    cache.incr(key, ttl=3600)


# ==================== API 路由 ====================

@app.route('/v1/user/sms/registercode', methods=['POST'])
def send_register_code():
    data = request.get_json(silent=True) or {}
    zone = data.get('zone', '0086')
    phone = data.get('phone', '').strip()

    if not phone:
        return make_error("手机号不能为空")

    country_code = zone[2:] if len(zone) > 2 else "86"

    if country_code == "86" and len(phone) != 11:
        return make_error("手机号格式错误")

    # 先检查是否已注册
    exist = check_phone_registered(zone, phone)

    biz = Config.BIZ_REGISTER
    channel = "phone"

    ok, msg = check_rate_limit(biz, channel, phone)
    if not ok:
        return make_error(msg, 429)

    code = generate_code()
    key = code_key(biz, channel, phone)
    cache.set(key, code, ttl=Config.CODE_VALID_TIME)
    record_rate_limit(biz, channel, phone)

    logger.info(f"验证码已生成: phone={phone}, code={code}, biz=register, exist={exist}")

    # 异步发送短信，先返回成功，减少用户等待时间
    def send_sms_async():
        try:
            success, send_msg, biz_id = sms_service.send_verify_code(phone, code, country_code)
            if success:
                logger.info(f"验证码短信发送成功: phone={phone}, biz=register")
            else:
                logger.warning(f"验证码短信发送失败: phone={phone}, msg={send_msg}")
        except Exception as e:
            logger.error(f"异步发送短信异常: phone={phone}, error={e}")

    import threading
    threading.Thread(target=send_sms_async, daemon=True).start()

    return make_success({"exist": exist})


def check_phone_registered(zone, phone):
    """检查手机号是否已注册：优先缓存 → MySQL(主) → 8091登录接口(兜底)"""
    cache_key = f"registered:phone:{zone}:{phone}"
    if cache.get(cache_key):
        return 1

    username = f"{zone}{phone}"

    # MySQL主查询：user表中username字段存储格式为 zone+phone
    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST,
            port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER,
            password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE,
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "SELECT uid FROM user WHERE username = %s LIMIT 1",
                    (username,)
                )
                row = cursor.fetchone()
                if row:
                    cache.set(cache_key, "1")
                    return 1
                return 0
        finally:
            conn.close()
    except Exception as e:
        logger.warning(f"MySQL查询手机号注册状态失败，改用8091检测: {e}")

    # 8091登录接口兜底检测
    try:
        resp = requests.post(
            "http://127.0.0.1:8091/v1/user/login",
            json={
                "username": username,
                "password": os.getenv("CHECK_EXIST_TEST_PWD", "check_exist_pwd_dev_only"),
            },
            timeout=5,
        )
        resp_data = resp.json()
        if not isinstance(resp_data, dict):
            return 0
        msg = resp_data.get("msg", "") or resp_data.get("message", "")
        # 如果错误信息不包含"不存在"，说明用户存在（密码错误等其他原因）
        if "用户不存在" not in msg and "不存在" not in msg and "not found" not in msg.lower():
            cache.set(cache_key, "1")
            return 1
        return 0
    except Exception as e:
        logger.error(f"8091检测用户状态失败: {e}")
    return 0


def check_email_registered(email):
    """检查邮箱是否已注册：优先缓存 → MySQL(主) → 8091登录接口(兜底)"""
    cache_key = f"registered:email:{email}"
    if cache.get(cache_key):
        return 1

    # MySQL主查询
    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST,
            port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER,
            password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE,
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "SELECT uid FROM user WHERE email = %s LIMIT 1",
                    (email,)
                )
                row = cursor.fetchone()
                if row:
                    cache.set(cache_key, "1")
                    return 1
                return 0
        finally:
            conn.close()
    except Exception as e:
        logger.warning(f"MySQL查询邮箱注册状态失败，改用8091检测: {e}")

    # 8091登录接口兜底检测
    try:
        resp = requests.post(
            "http://127.0.0.1:8091/v1/user/login",
            json={
                "username": email,
                "password": os.getenv("CHECK_EXIST_TEST_PWD", "check_exist_pwd_dev_only"),
            },
            timeout=5,
        )
        resp_data = resp.json()
        if not isinstance(resp_data, dict):
            return 0
        msg = resp_data.get("msg", "") or resp_data.get("message", "")
        if "用户不存在" not in msg and "不存在" not in msg and "not found" not in msg.lower():
            cache.set(cache_key, "1")
            return 1
        return 0
    except Exception as e:
        logger.error(f"8091检测邮箱用户状态失败: {e}")
    return 0


@app.route('/v1/user/isregister', methods=['POST'])
def check_is_register():
    data = request.get_json(silent=True) or {}
    zone = data.get('zone', '0086')
    phone = data.get('phone', '').strip()
    email = data.get('email', '').strip()
    account = data.get('account', '').strip()

    # 优先使用明确的phone/email字段，否则根据account字段判断
    if not phone and not email and account:
        # 如果account包含@则认为是邮箱，否则是手机号
        if '@' in account:
            email = account
        else:
            phone = account

    exist = 0

    if phone:
        logger.info(f"检查手机号注册状态: zone={zone}, phone={phone}")
        exist = check_phone_registered(zone, phone)
    elif email:
        logger.info(f"检查邮箱注册状态: email={email}")
        exist = check_email_registered(email)

    return make_success({"exist": exist})


@app.route('/v1/user/register', methods=['POST'])
def register():
    data = request.get_json(silent=True) or {}
    zone = data.get('zone', '0086')
    phone = data.get('phone', '').strip()
    sms_code = data.get('code', '').strip()
    password = data.get('password', '').strip()
    invite_code = data.get('invite_code', '').strip()

    if not phone:
        return make_error("手机号不能为空")
    if not sms_code:
        return make_error("验证码不能为空")
    if not password:
        return make_error("密码不能为空")
    if len(password) < 6 or len(password) > 20:
        return make_error("密码长度必须是6~20位")

    ip = get_client_ip()
    ok, msg = check_ip_register_limit(ip)
    if not ok:
        return make_error(msg, 429)

    biz = Config.BIZ_REGISTER
    channel = "phone"
    key = code_key(biz, channel, phone)
    stored_code = cache.get(key)

    logger.info(f"注册验证码校验: phone={phone}, input_code={sms_code}, stored_code={stored_code}")

    if not stored_code:
        logger.warning(f"验证码已过期: phone={phone}")
        return make_error("验证码已过期，请重新获取")
    if stored_code != sms_code:
        logger.warning(f"验证码错误: phone={phone}, input={sms_code}, expected={stored_code}")
        return make_error("验证码错误")

    cache.delete(key)
    record_ip_register(ip)

    logger.info(f"用户注册成功: phone={phone}, ip={ip}")

    # 调用8090悟空IM服务创建用户（token由8090颁发，IM接口通用）
    # 8090不真正校验验证码（无短信服务），传固定值即可
    try:
        im_resp = requests.post(
            "http://127.0.0.1:8091/v1/user/register",
            json={
                "zone": zone,
                "phone": phone,
                "code": "123456",
                "password": password,
            },
            timeout=10,
        )
        im_data = im_resp.json()
        if im_resp.status_code == 200 and "uid" in im_data:
            logger.info(f"8090用户创建成功: uid={im_data.get('uid')}")
            im_uid = im_data.get("uid", "")
            # 生成short_no并存储到MySQL
            short_no = generate_short_no()
            try:
                conn = pymysql.connect(
                    host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
                    user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
                    database=Config.MYSQL_DATABASE, charset='utf8mb4',
                    cursorclass=pymysql.cursors.DictCursor
                )
                try:
                    with conn.cursor() as cursor:
                        cursor.execute(
                            "INSERT INTO user (uid, short_no, username, password_hash, phone, nickname, avatar, sign, status, created_at) "
                            "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 1, NOW()) "
                            "ON DUPLICATE KEY UPDATE short_no=%s",
                            (im_uid, short_no, f"{zone}{phone}", password, phone, phone[-4:], "", "", short_no)
                        )
                    conn.commit()
                    logger.info(f"用户信息已存储到MySQL: uid={im_uid}, short_no={short_no}")
                finally:
                    conn.close()
            except Exception as e:
                logger.error(f"存储用户信息失败: {e}")
            im_data["short_no"] = short_no
            # 补充手机号和区号（8090注册接口不返回phone字段）
            im_data["phone"] = phone
            im_data["zone"] = zone
            # 标记手机号已注册（用于isRegister检测）
            cache.set(f"registered:phone:{zone}:{phone}", "1")
            # 存储token->uid映射（用于头像上传等需要uid的接口）
            im_token = im_data.get("token", "")
            if im_token and im_uid:
                cache.set(f"im_token:uid:{im_token}", im_uid)
            return make_success(im_data)
        else:
            msg = im_data.get("msg", "注册失败")
            logger.error(f"8090用户创建失败: {msg}")
            # 如果用户已存在，尝试用密码登录（兼容老用户）
            if "已存在" in msg or "exist" in msg.lower():
                logger.info(f"用户已存在，尝试登录: phone={phone}")
                login_resp = requests.post(
                    "http://127.0.0.1:8091/v1/user/login",
                    json={
                        "username": f"{zone}{phone}",
                        "password": password,
                    },
                    timeout=10,
                )
                login_data = login_resp.json()
                if login_resp.status_code == 200 and "uid" in login_data:
                    logger.info(f"登录成功: uid={login_data.get('uid')}")
                    cache.set(f"registered:phone:{zone}:{phone}", "1")
                    im_token = login_data.get("token", "")
                    im_uid = login_data.get("uid", "")
                    if im_token and im_uid:
                        cache.set(f"im_token:uid:{im_token}", im_uid)
                    # 补充手机号和区号
                    login_data["phone"] = phone
                    login_data["zone"] = zone
                    # 查询short_no
                    try:
                        conn3 = pymysql.connect(
                            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
                            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
                            database=Config.MYSQL_DATABASE, charset='utf8mb4',
                            cursorclass=pymysql.cursors.DictCursor
                        )
                        try:
                            with conn3.cursor() as cursor3:
                                cursor3.execute("SELECT short_no FROM user WHERE uid=%s LIMIT 1", (im_uid,))
                                row3 = cursor3.fetchone()
                                if row3 and row3.get('short_no'):
                                    login_data["short_no"] = row3['short_no']
                        except Exception as e:
                            logger.error(f"查询short_no失败: {e}")
                        finally:
                            conn3.close()
                    except Exception as e:
                        logger.error(f"数据库连接失败: {e}")
                    return make_success(login_data)
                else:
                    login_msg = login_data.get("msg", "登录失败")
                    logger.warning(f"登录失败: {login_msg}")
                    return make_error("账号已存在，密码错误")
            return make_error(msg)
    except Exception as e:
        logger.error(f"调用8090注册异常: {e}")
        return make_error("注册失败，请稍后重试")


@app.route('/v1/user/sms/verifycode', methods=['POST'])
def verify_code():
    data = request.get_json(silent=True) or {}
    phone = data.get('phone', '').strip()
    code = data.get('code', '').strip()
    biz_type = data.get('biz', 'register')

    if not phone or not code:
        return make_error("手机号和验证码不能为空")

    biz = Config.BIZ_REGISTER if biz_type == "register" else Config.BIZ_LOGIN
    channel = "phone"
    key = code_key(biz, channel, phone)
    stored_code = cache.get(key)

    if not stored_code:
        return make_error("验证码已过期，请重新获取")
    if stored_code != code:
        return make_error("验证码错误")

    return make_success({"verified": True})


# ==================== 邮箱验证码接口 ====================

@app.route('/v1/user/email/registercode', methods=['POST'])
def send_email_register_code():
    data = request.get_json(silent=True) or {}
    email = data.get('email', '').strip()

    if not email:
        return make_error("邮箱不能为空")
    if '@' not in email or '.' not in email:
        return make_error("邮箱格式错误")

    # 先检查是否已注册
    exist = check_email_registered(email)

    biz = Config.BIZ_REGISTER
    channel = "email"

    ok, msg = check_rate_limit(biz, channel, email)
    if not ok:
        return make_error(msg, 429)

    code = generate_code()
    key = code_key(biz, channel, email)
    cache.set(key, code, ttl=Config.CODE_VALID_TIME)

    success, send_msg = email_service.send_verify_code(email, code)

    if not success:
        cache.delete(key)
        return make_error(send_msg or "邮件发送失败")

    record_rate_limit(biz, channel, email)
    logger.info(f"邮箱验证码发送成功: email={email}, biz=register, exist={exist}")

    return make_success({"exist": exist})


@app.route('/v1/user/email/verifycode', methods=['POST'])
def verify_email_code():
    data = request.get_json(silent=True) or {}
    email = data.get('email', '').strip()
    code = data.get('code', '').strip()
    biz_type = data.get('biz', 'register')

    if not email or not code:
        return make_error("邮箱和验证码不能为空")

    biz = Config.BIZ_REGISTER if biz_type == "register" else Config.BIZ_LOGIN
    channel = "email"
    key = code_key(biz, channel, email)
    stored_code = cache.get(key)

    if not stored_code:
        return make_error("验证码已过期，请重新获取")
    if stored_code != code:
        return make_error("验证码错误")

    return make_success({"verified": True})


@app.route('/v1/user/email/register', methods=['POST'])
def email_register():
    data = request.get_json(silent=True) or {}
    email = data.get('email', '').strip()
    email_code = data.get('code', '').strip()
    password = data.get('password', '').strip()
    invite_code = data.get('invite_code', '').strip()

    if not email:
        return make_error("邮箱不能为空")
    if not email_code:
        return make_error("验证码不能为空")
    if not password:
        return make_error("密码不能为空")
    if len(password) < 6 or len(password) > 20:
        return make_error("密码长度必须是6~20位")

    ip = get_client_ip()
    ok, msg = check_ip_register_limit(ip)
    if not ok:
        return make_error(msg, 429)

    biz = Config.BIZ_REGISTER
    channel = "email"
    key = code_key(biz, channel, email)
    stored_code = cache.get(key)

    if not stored_code:
        return make_error("验证码已过期，请重新获取")
    if stored_code != email_code:
        return make_error("验证码错误")

    cache.delete(key)
    record_ip_register(ip)

    logger.info(f"邮箱注册成功: email={email}, ip={ip}")

    # 调用8090悟空IM服务创建用户（token由8090颁发，IM接口通用）
    try:
        im_resp = requests.post(
            "http://127.0.0.1:8091/v1/user/register",
            json={
                "email": email,
                "code": email_code,
                "password": password,
            },
            timeout=10,
        )
        im_data = im_resp.json()
        if im_resp.status_code == 200 and "uid" in im_data:
            logger.info(f"8090邮箱用户创建成功: uid={im_data.get('uid')}")
            cache.set(f"registered:email:{email}", "1")
            # 存储token->uid映射
            im_token = im_data.get("token", "")
            im_uid = im_data.get("uid", "")
            if im_token and im_uid:
                cache.set(f"im_token:uid:{im_token}", im_uid)
            # 生成short_no并存储到MySQL
            short_no = generate_short_no()
            try:
                conn = pymysql.connect(
                    host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
                    user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
                    database=Config.MYSQL_DATABASE, charset='utf8mb4',
                    cursorclass=pymysql.cursors.DictCursor
                )
                try:
                    with conn.cursor() as cursor:
                        cursor.execute(
                            "INSERT INTO user (uid, short_no, username, password_hash, email, nickname, status, created_at) "
                            "VALUES (%s, %s, %s, %s, %s, %s, 1, NOW()) "
                            "ON DUPLICATE KEY UPDATE short_no=%s",
                            (im_uid, short_no, email, password, email, email.split('@')[0], short_no)
                        )
                    conn.commit()
                    logger.info(f"邮箱用户信息已存储到MySQL: uid={im_uid}, short_no={short_no}")
                finally:
                    conn.close()
            except Exception as e:
                logger.error(f"存储邮箱用户信息失败: {e}")
            im_data["short_no"] = short_no
            im_data["email"] = email
            return make_success(im_data)
        else:
            msg = im_data.get("msg", "注册失败")
            logger.error(f"8090邮箱用户创建失败: {msg}")
            return make_error(msg)
    except Exception as e:
        logger.error(f"调用8090邮箱注册异常: {e}")
        return make_error("注册失败，请稍后重试")


@app.route('/v1/user/sms/forgetpwd', methods=['POST'])
def sms_forget_pwd():
    data = request.get_json(silent=True) or {}
    zone = data.get('zone', '0086')
    phone = data.get('phone', '').strip()

    if not phone:
        return make_error("手机号不能为空")

    country_code = zone[2:] if len(zone) > 2 else "86"

    if country_code == "86" and len(phone) != 11:
        return make_error("手机号格式错误")

    biz = Config.BIZ_RESET_PWD
    channel = "phone"

    ok, msg = check_rate_limit(biz, channel, phone)
    if not ok:
        return make_error(msg, 429)

    code = generate_code()
    key = code_key(biz, channel, phone)
    cache.set(key, code, ttl=Config.CODE_VALID_TIME)

    success, send_msg, biz_id = sms_service.send_verify_code(phone, code, country_code)

    if not success:
        cache.delete(key)
        return make_error(send_msg or "短信发送失败")

    record_rate_limit(biz, channel, phone)
    logger.info(f"短信验证码发送成功: phone={phone}, biz=resetpwd")

    return make_success({"status": 200, "msg": "发送成功"})


@app.route('/v1/user/pwdforget', methods=['POST'])
def sms_pwd_forget():
    data = request.get_json(silent=True) or {}
    zone = data.get('zone', '0086')
    phone = data.get('phone', '').strip()
    code = data.get('code', '').strip()
    pwd = data.get('pwd', '').strip()

    if not phone or not code or not pwd:
        return make_error("手机号、验证码和新密码不能为空")
    if len(pwd) < 6 or len(pwd) > 20:
        return make_error("密码长度必须是6~20位")

    biz = Config.BIZ_RESET_PWD
    channel = "phone"
    key = code_key(biz, channel, phone)
    stored_code = cache.get(key)

    if not stored_code:
        return make_error("验证码已过期，请重新获取")
    if stored_code != code:
        return make_error("验证码错误")

    # 直接修改8090数据库中的密码（8090使用双重MD5加密）
    try:
        import hashlib
        import pymysql

        hashed_pwd = hash_password(pwd)

        conn = pymysql.connect(
            host=Config.MYSQL_HOST,
            port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER,
            password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE,
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )

        try:
            with conn.cursor() as cursor:
                # 先查询用户是否存在
                cursor.execute(
                    "SELECT uid FROM user WHERE zone = %s AND phone = %s",
                    (zone, phone)
                )
                user = cursor.fetchone()
                if not user:
                    return make_error("该手机号未注册")

                # 更新密码
                cursor.execute(
                    "UPDATE user SET password = %s, updated_at = NOW() WHERE zone = %s AND phone = %s",
                    (hashed_pwd, zone, phone)
                )
                conn.commit()
                cache.delete(key)
                logger.info(f"密码重置成功: phone={phone}, uid={user['uid']}")
                return make_success({"status": 200, "msg": "密码重置成功"})
        finally:
            conn.close()

    except Exception as e:
        logger.error(f"密码重置异常: {e}")
        return make_error("密码重置失败，请稍后重试")


@app.route('/v1/user/email/forgetpwd', methods=['POST'])
def email_forget_pwd():
    data = request.get_json(silent=True) or {}
    email = data.get('email', '').strip()

    if not email:
        return make_error("邮箱不能为空")

    biz = Config.BIZ_RESET_PWD
    channel = "email"

    ok, msg = check_rate_limit(biz, channel, email)
    if not ok:
        return make_error(msg, 429)

    code = generate_code()
    key = code_key(biz, channel, email)
    cache.set(key, code, ttl=Config.CODE_VALID_TIME)

    success, send_msg = email_service.send_verify_code(email, code)

    if not success:
        cache.delete(key)
        return make_error(send_msg or "邮件发送失败")

    record_rate_limit(biz, channel, email)
    logger.info(f"邮箱验证码发送成功: email={email}, biz=resetpwd")

    return make_success({})


@app.route('/v1/user/email/pwdforget', methods=['POST'])
def email_pwd_forget():
    data = request.get_json(silent=True) or {}
    email = data.get('email', '').strip()
    code = data.get('code', '').strip()
    pwd = data.get('pwd', '').strip()

    if not email or not code or not pwd:
        return make_error("邮箱、验证码和新密码不能为空")
    if len(pwd) < 6 or len(pwd) > 20:
        return make_error("密码长度必须是6~20位")

    biz = Config.BIZ_RESET_PWD
    channel = "email"
    key = code_key(biz, channel, email)
    stored_code = cache.get(key)

    if not stored_code:
        return make_error("验证码已过期，请重新获取")
    if stored_code != code:
        return make_error("验证码错误")

    # 直接修改8090数据库中的密码
    try:
        import hashlib
        import pymysql

        hashed_pwd = hash_password(pwd)

        conn = pymysql.connect(
            host=Config.MYSQL_HOST,
            port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER,
            password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE,
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )

        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "SELECT uid FROM user WHERE email = %s",
                    (email,)
                )
                user = cursor.fetchone()
                if not user:
                    return make_error("该邮箱未注册")

                cursor.execute(
                    "UPDATE user SET password = %s, updated_at = NOW() WHERE email = %s",
                    (hashed_pwd, email)
                )
                conn.commit()
                cache.delete(key)
                logger.info(f"邮箱密码重置成功: email={email}, uid={user['uid']}")
                return make_success({"status": 200, "msg": "密码重置成功"})
        finally:
            conn.close()

    except Exception as e:
        logger.error(f"邮箱密码重置异常: {e}")
        return make_error("密码重置失败，请稍后重试")


# ==================== 绑定手机/邮箱接口 ====================

@app.route('/v1/user/sms/bindcode', methods=['POST'])
def send_bind_phone_code():
    """发送绑定手机验证码"""
    uid = get_current_uid()
    if not uid:
        return make_error("请先登录", 401)

    data = request.get_json(silent=True) or {}
    zone = data.get('zone', '0086')
    phone = data.get('phone', '').strip()

    if not phone:
        return make_error("手机号不能为空")

    country_code = zone[2:] if len(zone) > 2 else "86"

    if country_code == "86" and len(phone) != 11:
        return make_error("手机号格式错误")

    # 检查手机号是否已被其他用户绑定
    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "SELECT uid FROM user WHERE zone = %s AND phone = %s LIMIT 1",
                    (zone, phone)
                )
                row = cursor.fetchone()
                if row and str(row['uid']) != str(uid):
                    return make_error("该手机号已被其他账号绑定")
        finally:
            conn.close()
    except Exception as e:
        logger.warning(f"检查手机号绑定状态失败: {e}")

    biz = Config.BIZ_BIND
    channel = "phone"

    ok, msg = check_rate_limit(biz, channel, phone)
    if not ok:
        return make_error(msg, 429)

    code = generate_code()
    key = code_key(biz, channel, phone)
    cache.set(key, code, ttl=Config.CODE_VALID_TIME)

    success, send_msg, biz_id = sms_service.send_verify_code(phone, code, country_code)

    if not success:
        cache.delete(key)
        return make_error(send_msg or "短信发送失败")

    record_rate_limit(biz, channel, phone)
    logger.info(f"绑定手机验证码发送成功: phone={phone}, uid={uid}")

    return make_success({"status": 200, "msg": "发送成功"})


@app.route('/v1/user/bindphone', methods=['POST'])
def bind_phone():
    """绑定手机"""
    uid = get_current_uid()
    if not uid:
        return make_error("请先登录", 401)

    data = request.get_json(silent=True) or {}
    zone = data.get('zone', '0086')
    phone = data.get('phone', '').strip()
    code = data.get('code', '').strip()

    if not phone or not code:
        return make_error("手机号和验证码不能为空")
    if len(code) != 6:
        return make_error("验证码格式错误")

    biz = Config.BIZ_BIND
    channel = "phone"
    key = code_key(biz, channel, phone)
    stored_code = cache.get(key)

    if not stored_code:
        return make_error("验证码已过期，请重新获取")
    if stored_code != code:
        return make_error("验证码错误")

    cache.delete(key)

    # 检查手机号是否已被其他用户绑定
    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "SELECT uid FROM user WHERE zone = %s AND phone = %s LIMIT 1",
                    (zone, phone)
                )
                row = cursor.fetchone()
                if row and str(row['uid']) != str(uid):
                    return make_error("该手机号已被其他账号绑定")

                # 更新绑定手机号
                cursor.execute(
                    "UPDATE user SET zone = %s, phone = %s, updated_at = NOW() WHERE uid = %s",
                    (zone, phone, uid)
                )
                conn.commit()
                logger.info(f"手机绑定成功: uid={uid}, phone={phone}")
                return make_success({"status": 200, "msg": "绑定成功"})
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"手机绑定异常: {e}")
        return make_error("绑定失败，请稍后重试")


@app.route('/v1/user/email/bindcode', methods=['POST'])
def send_bind_email_code():
    """发送绑定邮箱验证码"""
    uid = get_current_uid()
    if not uid:
        return make_error("请先登录", 401)

    data = request.get_json(silent=True) or {}
    email = data.get('email', '').strip()

    if not email:
        return make_error("邮箱不能为空")
    if '@' not in email or '.' not in email:
        return make_error("邮箱格式错误")

    # 检查邮箱是否已被其他用户绑定
    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "SELECT uid FROM user WHERE email = %s LIMIT 1",
                    (email,)
                )
                row = cursor.fetchone()
                if row and str(row['uid']) != str(uid):
                    return make_error("该邮箱已被其他账号绑定")
        finally:
            conn.close()
    except Exception as e:
        logger.warning(f"检查邮箱绑定状态失败: {e}")

    biz = Config.BIZ_BIND
    channel = "email"

    ok, msg = check_rate_limit(biz, channel, email)
    if not ok:
        return make_error(msg, 429)

    code = generate_code()
    key = code_key(biz, channel, email)
    cache.set(key, code, ttl=Config.CODE_VALID_TIME)

    # 发送邮箱验证码
    try:
        import requests
        subject = "邮箱绑定验证码"
        html_content = f'''
        <div style="max-width:600px;margin:0 auto;padding:20px;font-family:Arial,sans-serif;">
            <h2 style="color:#333;">邮箱绑定验证</h2>
            <p style="color:#666;font-size:14px;">您好，您正在进行邮箱绑定操作，验证码如下：</p>
            <div style="background:#f5f7fa;padding:20px;text-align:center;margin:20px 0;">
                <span style="font-size:32px;font-weight:bold;color:#3F74FC;letter-spacing:6px;">{code}</span>
            </div>
            <p style="color:#999;font-size:13px;">验证码{Config.CODE_VALID_DISPLAY}分钟内有效，请勿告知他人。</p>
        </div>
        '''
        resp = requests.post(
            Config.RESEND_API_URL,
            headers={
                "Authorization": f"Bearer {Config.RESEND_API_KEY}",
                "Content-Type": "application/json"
            },
            json={
                "from": f"{Config.RESEND_FROM_NAME} <{Config.RESEND_FROM_EMAIL}>",
                "to": [email],
                "subject": subject,
                "html": html_content
            },
            timeout=10
        )
        result = resp.json()
        if not result.get('id'):
            cache.delete(key)
            return make_error("邮件发送失败，请稍后重试")
    except Exception as e:
        cache.delete(key)
        logger.error(f"绑定邮箱验证码发送异常: {e}")
        return make_error("邮件发送失败，请稍后重试")

    record_rate_limit(biz, channel, email)
    logger.info(f"绑定邮箱验证码发送成功: email={email}, uid={uid}")

    return make_success({"status": 200, "msg": "发送成功"})


@app.route('/v1/user/bindemail', methods=['POST'])
def bind_email():
    """绑定邮箱"""
    uid = get_current_uid()
    if not uid:
        return make_error("请先登录", 401)

    data = request.get_json(silent=True) or {}
    email = data.get('email', '').strip()
    code = data.get('code', '').strip()

    if not email or not code:
        return make_error("邮箱和验证码不能为空")
    if len(code) != 6:
        return make_error("验证码格式错误")

    biz = Config.BIZ_BIND
    channel = "email"
    key = code_key(biz, channel, email)
    stored_code = cache.get(key)

    if not stored_code:
        return make_error("验证码已过期，请重新获取")
    if stored_code != code:
        return make_error("验证码错误")

    cache.delete(key)

    # 检查邮箱是否已被其他用户绑定
    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "SELECT uid FROM user WHERE email = %s LIMIT 1",
                    (email,)
                )
                row = cursor.fetchone()
                if row and str(row['uid']) != str(uid):
                    return make_error("该邮箱已被其他账号绑定")

                # 更新绑定邮箱
                cursor.execute(
                    "UPDATE user SET email = %s, updated_at = NOW() WHERE uid = %s",
                    (email, uid)
                )
                conn.commit()
                logger.info(f"邮箱绑定成功: uid={uid}, email={email}")
                return make_success({"status": 200, "msg": "绑定成功"})
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"邮箱绑定异常: {e}")
        return make_error("绑定失败，请稍后重试")


# ==================== 注销账号接口 ====================

@app.route('/v1/user/sms/destroycode', methods=['POST'])
def send_destroy_sms_code():
    """发送注销账号手机验证码"""
    uid = get_current_uid()
    if not uid:
        return make_error("请先登录", 401)

    data = request.get_json(silent=True) or {}
    phone = data.get('phone', '').strip()
    zone = data.get('zone', '+86').strip()

    if not phone:
        return make_error("手机号不能为空")
    country_code = zone[1:] if zone.startswith('+') else zone
    if country_code == "86" and len(phone) != 11:
        return make_error("手机号格式错误")

    # 验证手机号是否为当前用户绑定的手机号
    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "SELECT phone FROM user WHERE uid = %s LIMIT 1",
                    (uid,)
                )
                row = cursor.fetchone()
                if not row or not row.get('phone') or row['phone'] != phone:
                    return make_error("该手机号未绑定当前账号")
        except Exception as e:
            logger.warning(f"检查手机号绑定失败: {e}")
        finally:
            conn.close()
    except Exception as e:
        logger.warning(f"检查手机号绑定异常: {e}")

    biz = Config.BIZ_DESTROY
    channel = "phone"
    account = zone + phone

    ok, msg = check_rate_limit(biz, channel, account)
    if not ok:
        return make_error(msg, 429)

    code = generate_code()
    key = code_key(biz, channel, account)
    cache.set(key, code, ttl=Config.CODE_VALID_TIME)

    logger.info(f"注销验证码已生成: phone={phone}, code={code}")

    # 异步发送短信
    def send_sms_async():
        try:
            success, send_msg, biz_id = sms_service.send_verify_code(phone, code, country_code)
            if success:
                logger.info(f"注销短信发送成功: phone={phone}, biz_id={biz_id}")
            else:
                logger.error(f"注销短信发送失败: phone={phone}, msg={send_msg}")
        except Exception as e:
            logger.error(f"异步发送注销短信异常: {e}")

    threading.Thread(target=send_sms_async, daemon=True).start()

    return make_success({"status": 200, "msg": "验证码已发送"})


@app.route('/v1/user/email/destroycode', methods=['POST'])
def send_destroy_email_code():
    """发送注销账号邮箱验证码"""
    uid = get_current_uid()
    if not uid:
        return make_error("请先登录", 401)

    data = request.get_json(silent=True) or {}
    email = data.get('email', '').strip()

    if not email:
        return make_error("邮箱不能为空")
    if '@' not in email or '.' not in email:
        return make_error("邮箱格式错误")

    # 验证邮箱是否为当前用户绑定的邮箱
    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "SELECT email FROM user WHERE uid = %s LIMIT 1",
                    (uid,)
                )
                row = cursor.fetchone()
                if not row or not row.get('email') or row['email'] != email:
                    return make_error("该邮箱未绑定当前账号")
        finally:
            conn.close()
    except Exception as e:
        logger.warning(f"检查邮箱绑定异常: {e}")

    biz = Config.BIZ_DESTROY
    channel = "email"

    ok, msg = check_rate_limit(biz, channel, email)
    if not ok:
        return make_error(msg, 429)

    code = generate_code()
    key = code_key(biz, channel, email)
    cache.set(key, code, ttl=Config.CODE_VALID_TIME)

    # 发送邮箱验证码
    success, send_msg = email_service.send_verify_code(email, code)
    if success:
        logger.info(f"注销邮箱验证码发送成功: email={email}")
        return make_success({"status": 200, "msg": "验证码已发送"})
    else:
        logger.error(f"注销邮箱验证码发送失败: email={email}, msg={send_msg}")
        return make_error("验证码发送失败，请稍后重试")


@app.route('/v1/user/destroy/verifycode', methods=['POST'])
def verify_destroy_code():
    """验证注销账号验证码"""
    uid = get_current_uid()
    if not uid:
        return make_error("请先登录", 401)

    data = request.get_json(silent=True) or {}
    account = data.get('account', '').strip()
    code = data.get('code', '').strip()
    account_type = data.get('type', 'phone').strip()  # phone or email
    zone = data.get('zone', '+86').strip()

    if not account or not code:
        return make_error("账号和验证码不能为空")
    if len(code) != 6:
        return make_error("验证码格式错误")

    biz = Config.BIZ_DESTROY
    channel = "phone" if account_type == "phone" else "email"

    if account_type == "phone":
        key = code_key(biz, channel, zone + account)
    else:
        key = code_key(biz, channel, account)

    stored_code = cache.get(key)

    if not stored_code:
        return make_error("验证码已过期，请重新获取")
    if stored_code != code:
        return make_error("验证码错误")

    # 验证通过后删除验证码，防止重复使用
    cache.delete(key)

    return make_success({"verified": True})


@app.route('/v1/user/destroy', methods=['POST'])
def destroy_account():
    """注销账号"""
    uid = get_current_uid()
    if not uid:
        return make_error("请先登录", 401)

    data = request.get_json(silent=True) or {}
    account = data.get('account', '').strip()
    code = data.get('code', '').strip()
    account_type = data.get('type', 'phone').strip()
    zone = data.get('zone', '+86').strip()

    if not account or not code:
        return make_error("账号和验证码不能为空")

    # 先验证验证码
    biz = Config.BIZ_DESTROY
    channel = "phone" if account_type == "phone" else "email"

    if account_type == "phone":
        key = code_key(biz, channel, zone + account)
    else:
        key = code_key(biz, channel, account)

    stored_code = cache.get(key)
    if not stored_code:
        return make_error("请先获取验证码")
    if stored_code != code:
        return make_error("验证码错误")

    # 执行注销
    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "UPDATE user SET is_destroy = 1, status = 0, updated_at = NOW() WHERE uid = %s",
                    (uid,)
                )
                conn.commit()
                logger.info(f"账号注销成功: uid={uid}")
        finally:
            conn.close()

        # 删除验证码
        cache.delete(key)

        return make_success({"status": 200, "msg": "账号已注销"})
    except Exception as e:
        logger.error(f"账号注销异常: {e}")
        return make_error("注销失败，请稍后重试")


# ==================== 登录态修改密码接口 ====================

@app.route('/v1/user/email/pwdchange', methods=['POST'])
def email_change_pwd():
    """登录态下通过邮箱验证码修改密码"""
    uid = get_current_uid()
    if not uid:
        return make_error("请先登录", 401)

    data = request.get_json(silent=True) or {}
    email = data.get('email', '').strip()
    code = data.get('code', '').strip()
    pwd = data.get('pwd', '').strip()

    if not email or not code or not pwd:
        return make_error("邮箱、验证码和新密码不能为空")
    if len(pwd) < 6 or len(pwd) > 20:
        return make_error("密码长度必须是6~20位")

    biz = Config.BIZ_RESET_PWD
    channel = "email"
    key = code_key(biz, channel, email)
    stored_code = cache.get(key)

    if not stored_code:
        return make_error("验证码已过期，请重新获取")
    if stored_code != code:
        return make_error("验证码错误")

    cache.delete(key)

    # 修改密码
    try:
        import hashlib
        import pymysql

        hashed_pwd = hash_password(pwd)

        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                # 验证邮箱是否属于当前用户
                cursor.execute(
                    "SELECT uid FROM user WHERE email = %s LIMIT 1",
                    (email,)
                )
                user = cursor.fetchone()
                if not user or str(user['uid']) != str(uid):
                    return make_error("邮箱与当前账号不匹配")

                cursor.execute(
                    "UPDATE user SET password = %s, updated_at = NOW() WHERE uid = %s",
                    (hashed_pwd, uid)
                )
                conn.commit()
                logger.info(f"登录态密码修改成功: uid={uid}, email={email}")
                return make_success({"status": 200, "msg": "密码修改成功"})
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"登录态密码修改异常: {e}")
        return make_error("密码修改失败，请稍后重试")


@app.route('/v1/user/sms/pwdchangecode', methods=['POST'])
def sms_pwd_change_code():
    """登录态下发送手机修改密码验证码"""
    uid = get_current_uid()
    if not uid:
        return make_error("请先登录", 401)

    data = request.get_json(silent=True) or {}
    zone = data.get('zone', '0086').strip()
    phone = data.get('phone', '').strip()

    if not phone:
        return make_error("手机号不能为空")

    # 验证手机号是否属于当前用户
    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "SELECT uid FROM user WHERE zone = %s AND phone = %s LIMIT 1",
                    (zone, phone)
                )
                user = cursor.fetchone()
                if not user or str(user['uid']) != str(uid):
                    return make_error("手机号与当前账号不匹配")
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"验证手机归属异常: {e}")
        return make_error("服务器错误")

    # 生成6位验证码
    import random
    code = str(random.randint(100000, 999999))
    biz = Config.BIZ_RESET_PWD
    channel = "sms"
    key = code_key(biz, channel, zone + phone)

    # 限制60秒内不能重复发送
    last_key = key + ":last"
    last_time = cache.get(last_key)
    if last_time:
        import time
        if int(time.time()) - int(last_time) < 60:
            return make_error("发送过于频繁，请60秒后再试")

    cache.set(key, code, ttl=300)  # 5分钟有效
    cache.set(last_key, str(int(time.time())), ttl=60)

    # 发送短信
    try:
        success, send_msg, biz_id = sms_service.send_verify_code(phone, code, zone)
        if success:
            logger.info(f"验证码已生成: phone={phone}, code={code}, biz=reset_pwd")
            return make_success({"status": 200, "msg": "验证码已发送"})
        else:
            logger.warning(f"验证码短信发送失败: phone={phone}, msg={send_msg}")
            return make_error("验证码发送失败，请稍后重试")
    except Exception as e:
        logger.error(f"发送短信异常: phone={phone}, error={e}")
        return make_error("验证码发送失败，请稍后重试")


@app.route('/v1/user/sms/pwdchange', methods=['POST'])
def sms_pwd_change():
    """登录态下通过手机验证码修改密码"""
    uid = get_current_uid()
    if not uid:
        return make_error("请先登录", 401)

    data = request.get_json(silent=True) or {}
    zone = data.get('zone', '0086').strip()
    phone = data.get('phone', '').strip()
    code = data.get('code', '').strip()
    pwd = data.get('pwd', '').strip()

    if not phone or not code or not pwd:
        return make_error("手机号、验证码和新密码不能为空")
    if len(pwd) < 6 or len(pwd) > 20:
        return make_error("密码长度必须是6~20位")

    biz = Config.BIZ_RESET_PWD
    channel = "sms"
    key = code_key(biz, channel, zone + phone)
    stored_code = cache.get(key)

    if not stored_code:
        return make_error("验证码已过期，请重新获取")
    if stored_code != code:
        return make_error("验证码错误")

    cache.delete(key)

    # 修改密码
    try:
        import hashlib
        import pymysql

        hashed_pwd = hash_password(pwd)

        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                # 验证手机号是否属于当前用户
                cursor.execute(
                    "SELECT uid FROM user WHERE zone = %s AND phone = %s LIMIT 1",
                    (zone, phone)
                )
                user = cursor.fetchone()
                if not user or str(user['uid']) != str(uid):
                    return make_error("手机号与当前账号不匹配")

                cursor.execute(
                    "UPDATE user SET password = %s, updated_at = NOW() WHERE uid = %s",
                    (hashed_pwd, uid)
                )
                conn.commit()
                logger.info(f"登录态密码修改成功: uid={uid}, phone={phone}")
                return make_success({"status": 200, "msg": "密码修改成功"})
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"登录态手机修改密码异常: {e}")
        return make_error("密码修改失败，请稍后重试")


@app.route('/v1/user/verify_login_pwd', methods=['POST'])
def verify_login_pwd():
    """登录态下验证登录密码是否正确"""
    uid = get_current_uid()
    if not uid:
        return make_error("请先登录", 401)

    data = request.get_json(silent=True) or {}
    pwd = data.get('pwd', '').strip()

    if not pwd:
        return make_error("密码不能为空")

    try:
        import pymysql

        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "SELECT password FROM user WHERE uid = %s LIMIT 1",
                    (uid,)
                )
                user = cursor.fetchone()
                if not user:
                    return make_error("用户不存在")
                stored = user.get('password', '')
                if verify_password(pwd, stored):
                    if is_legacy_hash(stored):
                        new_hash = hash_password(pwd)
                        cursor.execute("UPDATE user SET password=%s WHERE uid=%s", (new_hash, uid))
                        conn.commit()
                    return make_success({"status": 200, "msg": "密码正确"})
                else:
                    return make_error("密码错误")
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"验证登录密码异常: {e}")
        return make_error("验证失败，请稍后重试")


def ensure_lock_screen_fields():
    """确保user表有锁屏密码相关字段"""
    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute("SHOW COLUMNS FROM user LIKE 'lock_screen_pwd'")
                if not cursor.fetchone():
                    cursor.execute("ALTER TABLE user ADD COLUMN lock_screen_pwd VARCHAR(64) DEFAULT '' COMMENT '锁屏密码MD5'")
                cursor.execute("SHOW COLUMNS FROM user LIKE 'lock_after_minute'")
                if not cursor.fetchone():
                    cursor.execute("ALTER TABLE user ADD COLUMN lock_after_minute INT DEFAULT 0 COMMENT '自动锁屏时间(分钟)'")
            conn.commit()
        finally:
            conn.close()
    except Exception as e:
        logger.warning(f"确保锁屏字段存在异常: {e}")


@app.route('/v1/user/lockscreenpwd', methods=['POST'])
def set_lock_screen_pwd():
    """设置锁屏密码"""
    uid = get_current_uid()
    if not uid:
        return make_error("请先登录", 401)

    data = request.get_json(silent=True) or {}
    pwd = data.get('pwd', '').strip()

    if not pwd or len(pwd) < 4:
        return make_error("密码不能为空或过短")

    ensure_lock_screen_fields()

    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "UPDATE user SET lock_screen_pwd = %s WHERE uid = %s",
                    (pwd, uid)
                )
            conn.commit()
            return make_success({"status": 200, "msg": "设置成功"})
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"设置锁屏密码异常: {e}")
        return make_error("设置失败，请稍后重试")


@app.route('/v1/user/lockscreenpwd', methods=['DELETE'])
def delete_lock_screen_pwd():
    """关闭锁屏密码"""
    uid = get_current_uid()
    if not uid:
        return make_error("请先登录", 401)

    ensure_lock_screen_fields()

    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "UPDATE user SET lock_screen_pwd = '' WHERE uid = %s",
                    (uid,)
                )
            conn.commit()
            return make_success({"status": 200, "msg": "关闭成功"})
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"关闭锁屏密码异常: {e}")
        return make_error("关闭失败，请稍后重试")


@app.route('/v1/user/lock_after_minute', methods=['PUT'])
def update_lock_after_minute():
    """更新自动锁屏时间"""
    uid = get_current_uid()
    if not uid:
        return make_error("请先登录", 401)

    data = request.get_json(silent=True) or {}
    minute = data.get('minute', 0)

    ensure_lock_screen_fields()

    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "UPDATE user SET lock_after_minute = %s WHERE uid = %s",
                    (minute, uid)
                )
            conn.commit()
            return make_success({"status": 200, "msg": "设置成功"})
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"设置自动锁屏时间异常: {e}")
        return make_error("设置失败，请稍后重试")


@app.route('/v1/user/search', methods=['GET'])
def search_user():
    keyword = request.args.get('keyword', '').strip()
    if not keyword:
        return make_success({"exist": 0, "data": None})

    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST,
            port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER,
            password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE,
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "SELECT uid, username, name, short_no, sex, vercode, "
                    "status, robot, version, is_destroy, updated_at, created_at "
                    "FROM user WHERE uid = %s OR short_no = %s OR username = %s OR phone = %s LIMIT 1",
                    (keyword, keyword, keyword, keyword)
                )
                row = cursor.fetchone()
                if not row:
                    return make_success({"exist": 0, "data": None})

                user_data = {
                    "uid": str(row.get('uid', '')),
                    "name": row.get('name', '') or '',
                    "username": row.get('username', '') or '',
                    "short_no": row.get('short_no', '') or '',
                    "sex": row.get('sex', 0) or 0,
                    "vercode": row.get('vercode', '') or '',
                    "follow": 0,
                    "status": row.get('status', 0) or 0,
                    "is_deleted": row.get('is_destroy', 0) or 0,
                    "be_deleted": 0,
                    "be_blacklist": 0,
                    "mute": 0,
                    "top": 0,
                    "chat_pwd_on": 0,
                    "screenshot": 0,
                    "revoke_remind": 0,
                    "receipt": 0,
                    "online": 0,
                    "last_offline": 0,
                    "robot": row.get('robot', 0) or 0,
                    "version": int(row.get('version', 0) or 0),
                    "updated_at": str(row.get('updated_at', '') or ''),
                    "created_at": str(row.get('created_at', '') or ''),
                }
                return make_success({"exist": 1, "data": user_data})
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"搜索用户异常: {e}")
        return make_error("搜索失败，请稍后重试")


@app.route('/v1/user/qrcode', methods=['GET'])
def user_qrcode():
    """获取用户二维码数据"""
    uid = get_current_uid()
    logger.info(f"[qrcode] uid from token: {uid}")
    if not uid:
        return make_error("未登录")
    # 查询用户short_no
    short_no = ""
    logger.error(f"[QR_DEBUG] uid={uid}, starting query")
    try:
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        logger.error(f"[QR_DEBUG] db connected, database={Config.MYSQL_DATABASE}")
        try:
            with conn.cursor() as cursor:
                cursor.execute("SELECT short_no FROM user WHERE uid=%s", (uid,))
                row = cursor.fetchone()
                logger.error(f"[QR_DEBUG] query row={row}")
                if row:
                    short_no = row.get('short_no', '') or ''
                    logger.error(f"[QR_DEBUG] short_no from db='{short_no}', len={len(short_no) if short_no else 0}")
                    # 如果short_no为空或格式不正确，自动生成
                    if not is_valid_short_no(short_no):
                        logger.error(f"[QR_DEBUG] short_no invalid, generating new one")
                        short_no = generate_short_no()
                        result = cursor.execute("UPDATE user SET short_no=%s WHERE uid=%s", (short_no, uid))
                        conn.commit()
                        logger.error(f"[QR_DEBUG] updated short_no='{short_no}', rows={result}")
                else:
                    logger.error(f"[QR_DEBUG] no row found for uid={uid}")
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"[QR_DEBUG] exception: {e}", exc_info=True)
    logger.error(f"[QR_DEBUG] final short_no='{short_no}', uid='{uid}', will return='{short_no if short_no else uid}'")
    # 返回二维码内容(用short_no或uid)
    qr_data = short_no if short_no else uid
    return make_success({"data": qr_data})

@app.route('/v1/qrcode/<path:short_no>', methods=['GET'])
def scan_qrcode(short_no):
    """扫描二维码：先解析个人二维码，若不存在则转发到8091处理群二维码。"""
    short_no = (short_no or '').strip('/')
    if not short_no:
        return make_error('二维码无效')
    try:
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "SELECT uid, name, short_no, vercode, status, is_destroy "
                    "FROM user WHERE short_no=%s LIMIT 1",
                    (short_no,)
                )
                row = cursor.fetchone()
                if row:
                    if row.get('is_destroy', 0):
                        return make_error('该用户已注销')
                    data = {
                        'uid': str(row.get('uid', '') or ''),
                        'name': row.get('name', '') or '',
                        'short_no': row.get('short_no', '') or '',
                        'vercode': row.get('vercode', '') or '',
                    }
                    return make_success({
                        'forward': 'native',
                        'type': 'userInfo',
                        'data': data,
                    })
        finally:
            conn.close()
    except Exception as e:
        logger.warning(f'个人二维码解析失败，尝试群二维码: {e}')

    # 个人二维码不存在，转发到8091处理群二维码
    try:
        token = get_token_from_header()
        headers = {"Content-Type": "application/json"}
        if token:
            headers["token"] = token
        resp = requests.get(
            f"http://127.0.0.1:8091/v1/qrcode/{short_no}",
            headers=headers, timeout=10
        )
        if resp.status_code == 200:
            # 8091返回格式可能需要转换
            try:
                data = resp.json()
                # 如果8091返回成功格式，直接透传
                return resp.content, 200, {'Content-Type': 'application/json'}
            except:
                return resp.content, resp.status_code, {'Content-Type': 'application/json'}
        else:
            return resp.content, resp.status_code, {'Content-Type': 'application/json'}
    except Exception as e:
        logger.error(f'群二维码解析异常: {e}', exc_info=True)
        return make_error('二维码无效或已过期')




@app.route('/v1/user/login', methods=['POST'])
def login():
    data = request.get_json(silent=True) or {}
    username = data.get('username', '').strip()
    password = data.get('password', '').strip()
    device = data.get('device', {})

    if not username or not password:
        return make_error("用户名和密码不能为空")

    if len(password) < 6 or len(password) > 20:
        return make_error("密码长度必须是6~20位")

    # 登录防暴力破解：检查是否已被锁定
    client_ip = get_client_ip()
    login_fail_key = f"login_fail:{username}:{client_ip}"
    lock_key = f"login_lock:{username}:{client_ip}"

    locked_until = cache.get(lock_key)
    if locked_until:
        remaining = int(float(locked_until) - time.time())
        if remaining > 0:
            return make_error(f"账号已被临时锁定，请{remaining}秒后重试", 429)

    logger.info(f"登录请求: username={username}, ip={client_ip}")

    # 调用8090悟空IM登录接口
    try:
        login_resp = requests.post(
            "http://127.0.0.1:8091/v1/user/login",
            json={
                "username": username,
                "password": password,
                "device": device,
            },
            timeout=10,
        )
        login_data = login_resp.json()
        if login_resp.status_code == 200 and "uid" in login_data:
            logger.info(f"登录成功: uid={login_data.get('uid')}, username={username}")
            # 存储token->uid映射
            im_token = login_data.get("token", "")
            im_uid = login_data.get("uid", "")
            if im_token and im_uid:
                cache.set(f"im_token:uid:{im_token}", im_uid)
            # 查询short_no
            short_no = ""
            try:
                conn = pymysql.connect(
                    host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
                    user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
                    database=Config.MYSQL_DATABASE, charset='utf8mb4',
                    cursorclass=pymysql.cursors.DictCursor
                )
                try:
                    with conn.cursor() as cursor:
                        cursor.execute("SELECT short_no FROM user WHERE uid=%s", (im_uid,))
                        row = cursor.fetchone()
                        if row:
                            short_no = row.get('short_no', '') or ''
                            # 如果short_no为空或格式不正确，自动生成
                            if not is_valid_short_no(short_no):
                                short_no = generate_short_no()
                                cursor.execute("UPDATE user SET short_no=%s WHERE uid=%s", (short_no, im_uid))
                                conn.commit()
                                logger.info(f"为老用户 {im_uid} 生成short_no={short_no}")
                finally:
                    conn.close()
            except Exception as e:
                logger.error(f"查询short_no失败: {e}")
            login_data["short_no"] = short_no
            # 补充手机号（8090登录接口不返回phone字段）
            try:
                conn2 = pymysql.connect(
                    host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
                    user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
                    database=Config.MYSQL_DATABASE, charset='utf8mb4',
                    cursorclass=pymysql.cursors.DictCursor
                )
                try:
                    with conn2.cursor() as cursor2:
                        cursor2.execute("SELECT phone, zone, email FROM user WHERE uid=%s LIMIT 1", (im_uid,))
                        user_row = cursor2.fetchone()
                        if user_row:
                            if user_row.get('phone'):
                                login_data["phone"] = user_row['phone']
                            if user_row.get('zone'):
                                login_data["zone"] = user_row['zone']
                            if user_row.get('email'):
                                login_data["email"] = user_row['email']
                finally:
                    conn2.close()
            except Exception as e:
                logger.error(f"查询用户手机号失败: {e}")
            cache.delete(login_fail_key)
            cache.delete(lock_key)
            return make_success(login_data)
        else:
            msg = login_data.get("msg", "账号或密码错误")
            fail_count = cache.incr(login_fail_key, ttl=Config.LOGIN_FAIL_WINDOW)
            if fail_count and int(fail_count) >= Config.LOGIN_FAIL_MAX:
                cache.set(lock_key, str(time.time() + Config.LOGIN_LOCK_DURATION), ttl=Config.LOGIN_LOCK_DURATION)
                logger.warning(f"登录锁定: username={username}, ip={client_ip}, fails={fail_count}")
            logger.warning(f"登录失败: {msg}, username={username}, ip={client_ip}, fails={fail_count}")
            return make_error(msg)
    except Exception as e:
        logger.error(f"登录异常: {e}")
        return make_error("登录失败，请稍后重试")


@app.route('/v1/common/countries', methods=['GET'])
def get_countries():
    countries = [
        {"code": "0086", "name": "中国", "icon": "cn"},
        {"code": "00852", "name": "中国香港", "icon": "hk"},
        {"code": "00853", "name": "中国澳门", "icon": "mo"},
        {"code": "00886", "name": "中国台湾", "icon": "tw"},
        {"code": "001", "name": "美国", "icon": "us"},
        {"code": "0044", "name": "英国", "icon": "gb"},
        {"code": "0081", "name": "日本", "icon": "jp"},
        {"code": "0082", "name": "韩国", "icon": "kr"},
        {"code": "0065", "name": "新加坡", "icon": "sg"},
        {"code": "0060", "name": "马来西亚", "icon": "my"},
        {"code": "0066", "name": "泰国", "icon": "th"},
        {"code": "0084", "name": "越南", "icon": "vn"},
        {"code": "0062", "name": "印度尼西亚", "icon": "id"},
        {"code": "0063", "name": "菲律宾", "icon": "ph"},
        {"code": "0091", "name": "印度", "icon": "in"},
        {"code": "0061", "name": "澳大利亚", "icon": "au"},
        {"code": "0049", "name": "德国", "icon": "de"},
        {"code": "0033", "name": "法国", "icon": "fr"},
        {"code": "0039", "name": "意大利", "icon": "it"},
        {"code": "007", "name": "俄罗斯", "icon": "ru"},
        {"code": "0055", "name": "巴西", "icon": "br"},
        {"code": "001", "name": "加拿大", "icon": "ca"},
    ]
    return make_success(countries)


@app.route('/v1/common/appconfig', methods=['GET'])
def get_app_config():
    return make_success({
        "register_invite_on": 0,
        "version": "1.0.0",
    })


# ==================== Token 验证 ====================

def get_token_from_header():
    auth_header = request.headers.get('token', '')
    if not auth_header:
        auth_header = request.headers.get('Authorization', '')
        if auth_header.startswith('Bearer '):
            auth_header = auth_header[7:]
    return auth_header


def get_current_uid():
    token = get_token_from_header()
    if not token:
        return None
    # 先查缓存
    uid = cache.get(f"im_token:uid:{token}")
    if uid:
        return str(uid)
    # 缓存没有，查数据库兜底
    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST,
            port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER,
            password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE,
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "SELECT uid FROM user_token WHERE token = %s LIMIT 1",
                    (token,)
                )
                row = cursor.fetchone()
                if row:
                    uid = str(row['uid'])
                    # 回填缓存
                    cache.set(f"im_token:uid:{token}", uid)
                    return uid
        finally:
            conn.close()
    except Exception as e:
        logger.warning(f"从数据库查询token失败: {e}")
    return None


def verify_token():
    """验证token，返回(uid, user_info)或(None, None)"""
    uid = get_current_uid()
    if not uid:
        return None, None
    # 简单返回uid，user_info暂不查询
    return uid, None


# ==================== 用户头像上传 ====================

@app.route('/v1/user/avatar', methods=['POST'])
def upload_avatar():
    uid = get_current_uid()
    if not uid:
        return make_error("登录已过期，请重新登录", 401)

    # 获取上传的文件
    if 'file' not in request.files:
        return make_error("请选择要上传的文件")

    file = request.files['file']
    if file.filename == '':
        return make_error("请选择要上传的文件")

    token = get_token_from_header()

    # 转发到8090头像上传接口
    try:
        files = {'file': (file.filename, file.stream, file.content_type)}
        headers = {'token': token}
        im_resp = requests.post(
            f"http://127.0.0.1:8091/v1/users/{uid}/avatar",
            files=files,
            headers=headers,
            timeout=30,
        )
        im_data = im_resp.json() if im_resp.headers.get('content-type', '').startswith('application/json') else {}

        if im_resp.status_code == 200 and im_data.get("status") == 200:
            # 构造头像访问URL（8090的头像访问路径）
            avatar_url = f"{IM_SERVER_URL}/v1/users/{uid}/avatar"
            logger.info(f"头像上传成功: uid={uid}")
            return make_success({
                "path": avatar_url,
                "avatar": avatar_url,
            })
        else:
            msg = im_data.get("msg", "头像上传失败")
            logger.error(f"8090头像上传失败: {msg}")
            return make_error(msg)
    except Exception as e:
        logger.error(f"转发头像上传异常: {e}")
        return make_error("头像上传失败，请稍后重试")


# ==================== 聊天图片/文件上传 ====================

UPLOAD_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'uploads', 'chat')
ALLOWED_IMAGE_EXT = {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'}
ALLOWED_FILE_EXT = {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.mp4', '.mov', '.avi', '.mkv',
                    '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt', '.zip', '.rar',
                    '.7z', '.mp3', '.aac', '.wav', '.flac', '.amr', '.silk'}
MAX_FILE_SIZE = 100 * 1024 * 1024  # 100MB

IM_SERVER_URL = os.getenv("IM_SERVER_URL", "http://43.133.39.170:8090")


@app.route('/v1/upload/image', methods=['POST'])
def upload_image():
    """聊天图片上传接口 - 本地存储"""
    uid = get_current_uid()
    if not uid:
        return make_error("登录已过期，请重新登录", 401)

    if 'file' not in request.files:
        return make_error("未找到上传文件")

    file = request.files['file']
    if file.filename == '':
        return make_error("文件名为空")

    filename = file.filename
    ext = os.path.splitext(filename)[1].lower()
    if ext not in ALLOWED_IMAGE_EXT:
        return make_error(f"不支持的图片格式: {ext}")

    return _save_upload_local(file, ext, 'image')


@app.route('/v1/upload/file', methods=['POST'])
def upload_file():
    """聊天文件/视频上传接口 - 本地存储"""
    uid = get_current_uid()
    if not uid:
        return make_error("登录已过期，请重新登录", 401)

    if 'file' not in request.files:
        return make_error("未找到上传文件")

    file = request.files['file']
    if file.filename == '':
        return make_error("文件名为空")

    filename = file.filename
    ext = os.path.splitext(filename)[1].lower()
    if ext not in ALLOWED_FILE_EXT:
        return make_error(f"不支持的文件格式: {ext}")

    return _save_upload_local(file, ext, 'file')


def _save_upload_local(file, ext, sub_dir):
    """聊天文件本地存储"""
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    saved_name = f"{int(time.time() * 1000)}_{random.randint(1000, 9999)}{ext}"
    save_path = os.path.join(UPLOAD_DIR, saved_name)
    file.save(save_path)

    file_url = f"static/chat/{saved_name}"
    logger.info(f"本地存储上传文件: {save_path}")
    return make_success({"path": file_url, "url": file_url})


@app.route('/v1/file/upload', methods=['POST'])
def file_upload():
    """兼容WuKongIM SDK的文件上传端点
    WKUploader使用此端点上传聊天图片/视频/文件
    路径参数: type=chat, path=/{channelType}/{channelID}/{filename}
    """
    uid = get_current_uid()
    if not uid:
        return make_error("登录已过期，请重新登录", 401)

    if 'file' not in request.files:
        return make_error("未找到上传文件")

    file = request.files['file']
    if file.filename == '':
        return make_error("文件名为空")

    filename = file.filename
    ext = os.path.splitext(filename)[1].lower()

    # 检查文件大小
    file.seek(0, 2)
    file_size = file.tell()
    file.seek(0)
    if file_size > MAX_FILE_SIZE:
        return make_error(f"文件大小超过限制: {MAX_FILE_SIZE // (1024*1024)}MB")

    # 根据扩展名判断存储方式（与v1/upload/image和v1/upload/file保持一致）
    if ext in ALLOWED_IMAGE_EXT:
        return _save_upload_local(file, ext, 'image')
    elif ext in ALLOWED_FILE_EXT:
        return _save_upload_local(file, ext, 'file')
    else:
        return make_error(f"不支持的文件格式: {ext}")


# ==================== MinIO 预签名直传 ====================

_minio_client = None
_minio_inited = False

def _get_minio_client():
    """获取 MinIO 客户端（懒加载，单例）"""
    global _minio_client, _minio_inited
    if _minio_inited:
        return _minio_client
    try:
        from minio import Minio
        endpoint = os.getenv("MINIO_ENDPOINT", "127.0.0.1:9000")
        access_key = os.getenv("MINIO_ROOT_USER", "minio")
        secret_key = os.getenv("MINIO_ROOT_PASSWORD", "Abc123456!")
        secure = os.getenv("MINIO_SECURE", "false").lower() == "true"
        _minio_client = Minio(endpoint, access_key=access_key, secret_key=secret_key, secure=secure)
        _minio_inited = True
        logger.info(f"MinIO client initialized: endpoint={endpoint}")
    except Exception as e:
        logger.error(f"MinIO init failed: {e}")
        _minio_client = None
        # 不标记为已初始化，允许下次请求时重试
    return _minio_client


@app.route('/v1/file/presign', methods=['GET'])
def file_presign():
    """生成腾讯云COS预签名 PUT URL，客户端直传文件到COS，绕过应用服务器
    参数:
      - path: 文件相对路径，如 /2/12345/1694861234_abc.mp4
      - type: bucket类型，chat/avatar/group，默认 chat
      - content_type: 文件MIME类型，可选
    返回:
      - upload_url: 预签名PUT上传地址（客户端用PUT上传到此地址）
      - path: 完整CDN访问URL（https://bucket.cos.region.myqcloud.com/chat/xxx）
      - url: 同path
      - access_url: 同path
      - expires: 过期时间（秒）
    """
    uid = get_current_uid()
    if not uid:
        return make_error("登录已过期，请重新登录", 401)

    file_path = request.args.get('path', '').strip()
    bucket_type = request.args.get('type', 'chat').strip()
    content_type = request.args.get('content_type', 'application/octet-stream').strip()

    if not file_path:
        return make_error("文件路径不能为空")

    if '..' in file_path:
        return make_error("非法文件路径")
    if file_path.startswith('/'):
        file_path = file_path[1:]

    valid_buckets = {'chat', 'avatar', 'group'}
    if bucket_type not in valid_buckets:
        return make_error(f"不支持的存储类型: {bucket_type}")

    client = _get_cos_client()
    if not client:
        return make_error("存储服务暂不可用", 503)

    bucket = os.getenv("COS_BUCKET", "")
    if not bucket:
        return make_error("COS未配置bucket", 503)

    try:
        from qcloud_cos import CosConfig as _CosConfig

        cdn_domain = os.getenv("COS_CDN_DOMAIN", "").rstrip("/")
        if not cdn_domain:
            region = os.getenv("COS_REGION", "ap-guangzhou")
            cdn_domain = f"https://{bucket}.cos.{region}.myqcloud.com"

        cos_key = f"{bucket_type}/{file_path}"

        presigned_url = client.get_presigned_url(
            Method="PUT",
            Bucket=bucket,
            Key=cos_key,
            Expired=900,
        )

        result_path = f"{cdn_domain}/{cos_key}"

        logger.info(f"COS presign: bucket={bucket_type}, path={file_path}, uid={uid}")

        return make_success({
            "upload_url": presigned_url,
            "path": result_path,
            "url": result_path,
            "access_url": result_path,
            "expires": 900,
        })

    except Exception as e:
        logger.error(f"COS presign failed: {e}")
        return make_error(f"生成上传地址失败: {str(e)}", 500)


# ==================== 腾讯云COS直传 ====================

_cos_client = None

def _get_cos_client():
    """获取 COS 客户端（懒加载单例）"""
    global _cos_client
    if _cos_client is not None:
        return _cos_client
    secret_id = os.getenv("COS_SECRET_ID", "")
    secret_key = os.getenv("COS_SECRET_KEY", "")
    region = os.getenv("COS_REGION", "ap-guangzhou")
    if not secret_id or not secret_key:
        logger.warning("COS credentials not configured")
        return None
    try:
        from qcloud_cos import CosConfig, CosS3Client
        config = CosConfig(
            Region=region,
            SecretId=secret_id,
            SecretKey=secret_key,
            Scheme="https",
        )
        _cos_client = CosS3Client(config)
        logger.info(f"COS client initialized: region={region}")
    except Exception as e:
        logger.error(f"COS init failed: {e}")
        _cos_client = None
    return _cos_client


@app.route('/v1/file/cos-presign', methods=['POST'])
def cos_batch_presign():
    """批量生成腾讯云COS预签名PUT URL，客户端直传多个文件到COS

    适用于HLS视频上传场景：一个视频需要上传 m3u8 + 多个ts分片 + 封面

    请求体 JSON:
      - paths: ["video/2/xxx/segment_000.ts", "video/2/xxx/master.m3u8", ...]
      - type: "chat"（存储目录前缀）

    返回:
      - urls: { "video/2/xxx/segment_000.ts": "https://bucket.cos.region.myqcloud.com/video/...签名", ... }
      - cdn_domain: "https://cdn.example.com"（如果配置了CDN）
      - expires: 900
    """
    uid = get_current_uid()
    if not uid:
        return make_error("登录已过期，请重新登录", 401)

    data = request.get_json(silent=True) or {}
    paths = data.get("paths", [])
    bucket_type = data.get("type", "chat")

    if not paths or not isinstance(paths, list):
        return make_error("paths不能为空且必须为数组")

    client = _get_cos_client()
    if not client:
        return make_error("存储服务暂不可用", 503)

    bucket = os.getenv("COS_BUCKET", "")
    if not bucket:
        return make_error("COS未配置bucket", 503)

    from qcloud_cos import CosConfig as _CosConfig

    cdn_domain = os.getenv("COS_CDN_DOMAIN", "").rstrip("/")
    if not cdn_domain:
        region = os.getenv("COS_REGION", "ap-guangzhou")
        cdn_domain = f"https://{bucket}.cos.{region}.myqcloud.com"
    result_urls = {}

    for raw_path in paths:
        if not raw_path or ".." in raw_path:
            continue
        path = raw_path.lstrip("/")
        key = f"{bucket_type}/{path}"

        try:
            presigned_url = client.get_presigned_url(
                Method="PUT",
                Bucket=bucket,
                Key=key,
                Expired=900,
            )
            result_urls[raw_path] = presigned_url
        except Exception as e:
            logger.error(f"COS presign failed for {key}: {e}")
            return make_error(f"生成上传地址失败: {str(e)}", 500)

    logger.info(f"COS batch presign: {len(result_urls)} files, uid={uid}")

    return make_success({
        "urls": result_urls,
        "cdn_domain": cdn_domain,
        "bucket": bucket,
        "expires": 900,
    })


@app.route('/v1/static/chat/<filename>', methods=['GET'])
def get_chat_file(filename):
    """访问本地存储的聊天文件"""
    from flask import send_from_directory
    if '..' in filename or '/' in filename or '\\' in filename:
        return make_error("非法文件名")
    try:
        return send_from_directory(UPLOAD_DIR, filename)
    except Exception as e:
        logger.warning(f"获取聊天文件失败: filename={filename}, error={e}")
        return make_error("文件不存在")


# ==================== 用户信息更新 ====================

@app.route('/v1/user/current', methods=['PUT'])
def update_user_info():
    uid = get_current_uid()
    if not uid:
        return make_error("登录已过期，请重新登录", 401)

    data = request.get_json(silent=True) or {}
    token = get_token_from_header()

    # 转发到8090更新用户信息
    try:
        headers = {
            'token': token,
            'Content-Type': 'application/json',
        }
        im_resp = requests.put(
            "http://127.0.0.1:8091/v1/user/current",
            json=data,
            headers=headers,
            timeout=10,
        )
        if im_resp.status_code == 200:
            try:
                im_data = im_resp.json()
            except Exception:
                im_data = {}
            if im_data.get("status") == 200:
                logger.info(f"用户信息更新成功: uid={uid}")
                return make_success({
                    "status": 200,
                    "msg": "更新成功",
                })
            else:
                msg = im_data.get("msg") or (im_resp.text[:200] if im_resp.text else "更新失败")
                logger.warning(f"用户信息更新返回非成功状态: uid={uid}, msg={msg}")
                return make_error(msg)
        else:
            logger.error(f"8090用户信息更新失败: status={im_resp.status_code}")
            return make_error("更新失败")
    except Exception as e:
        logger.error(f"转发用户信息更新异常: {e}")
        return make_error("更新失败，请稍后重试")


# ==================== 静态文件访问 ====================

@app.route('/v1/static/avatars/<filename>', methods=['GET'])
def get_avatar(filename):
    from flask import send_from_directory
    # 安全校验：防止路径遍历
    if '..' in filename or '/' in filename or '\\' in filename:
        return make_error("无效的文件名", 400)
    upload_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'uploads', 'avatars')
    try:
        return send_from_directory(upload_dir, filename)
    except Exception as e:
        logger.warning(f"获取头像失败: filename={filename}, error={e}")
        return make_error("文件不存在", 404)


@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        "status": "ok",
        "timestamp": datetime.now().isoformat(),
        "redis": not isinstance(cache, MemoryCache),
        "sms_sdk": sms_service._available,
        "email_service": email_service._available,
    })


# ==================== 群组管理代理 ====================
# WuKongIM原生不支持的群组操作，通过Flask后端代理

def get_wkim_token():
    """从请求头获取token"""
    token = request.headers.get('token', '')
    if not token:
        token = request.headers.get('Authorization', '')
        if token.startswith('Bearer '):
            token = token[7:]
    return token


def _insert_system_message(channel_id, from_uid, payload_dict):
    """
    直接向数据库插入一条系统消息，确保群成员能看到通知
    payload_dict 应包含 type, content, extra, data 等字段
    """
    import json
    import time
    import pymysql

    conn = pymysql.connect(
        host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
        user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
        database=Config.MYSQL_DATABASE, charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor
    )
    try:
        with conn.cursor() as cursor:
            # 获取当前最大message_seq
            cursor.execute(
                "SELECT MAX(message_seq) as max_seq FROM message WHERE channel_id=%s AND channel_type=2",
                (channel_id,)
            )
            row = cursor.fetchone()
            max_seq = row['max_seq'] if row and row['max_seq'] else 0
            new_seq = max_seq + 1

            # 生成message_id (时间戳+序号形式)
            timestamp = int(time.time())
            message_id = f"{int(time.time() * 1000)}{new_seq:03d}"

            payload_json = json.dumps(payload_dict, ensure_ascii=False)

            # 插入消息（signal/setting/timestamp 是 MySQL 保留字，需用反引号）
            cursor.execute(
                "INSERT INTO message (message_id, message_seq, client_msg_no, header, `setting`, `signal`, "
                "from_uid, channel_id, channel_type, `timestamp`, payload, is_deleted, voice_status) "
                "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 0, 0)",
                (message_id, new_seq, '', '', 0, 0,
                 from_uid, channel_id, 2, timestamp, payload_json)
            )
            conn.commit()

            # 更新channel_offset
            cursor.execute(
                "INSERT INTO channel_offset (channel_id, channel_type, message_seq) VALUES (%s, 2, %s) "
                "ON DUPLICATE KEY UPDATE message_seq = GREATEST(message_seq, %s)",
                (channel_id, new_seq, new_seq)
            )
            conn.commit()

            return message_id
    finally:
        conn.close()


@app.route('/v1/groups/<group_no>/disband', methods=['POST'])
def disband_group(group_no):
    """解散群聊 - 直接更新数据库标记群为已解散"""
    token = get_wkim_token()
    if not token:
        return jsonify({"status": 401, "msg": "token不能为空"}), 401

    current_uid = get_current_uid(token)
    if not current_uid:
        return jsonify({"status": 401, "msg": "无法获取用户信息"}), 401

    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        with conn.cursor() as cursor:
            # 验证群主权限
            cursor.execute(
                "SELECT role FROM group_member WHERE group_no=%s AND uid=%s AND is_deleted=0",
                (group_no, current_uid)
            )
            row = cursor.fetchone()
            if not row or row.get("role") != 1:
                return jsonify({"status": 403, "msg": "只有群主可以解散群聊"}), 403

            # 更新群状态为已解散(status=2)
            cursor.execute(
                "UPDATE `group` SET status=2, updated_at=NOW() WHERE group_no=%s",
                (group_no,)
            )

            # 标记所有群成员为已删除
            cursor.execute(
                "UPDATE group_member SET is_deleted=1, version=version+1, updated_at=NOW() WHERE group_no=%s AND is_deleted=0",
                (group_no,)
            )

            # 插入群解散系统消息
            _insert_system_message(group_no, current_uid, {
                "type": "group_disband",
                "content": "群聊已解散",
                "operator": current_uid
            })

        conn.commit()
        conn.close()

        # 尝试通知TangSeng刷新（非关键，失败不影响）
        try:
            headers = {"token": token, "Content-Type": "application/json"}
            requests.post(
                f"http://127.0.0.1:8091/v1/channel/info",
                json={"channel_id": group_no, "channel_type": 2, "disband": 1},
                headers=headers, timeout=3
            )
        except Exception:
            pass

        logger.info(f"群解散成功: group={group_no}, operator={current_uid}")
        return jsonify({"status": 200, "msg": "群聊已解散"})
    except Exception as e:
        logger.error(f"解散群聊异常: {e}")
        return jsonify({"status": 500, "msg": f"服务器异常: {str(e)}"}), 500


@app.route('/v1/groups/<group_no>/managers', methods=['POST'])
def add_group_managers(group_no):
    """添加群管理员 - 更新数据库role=2，并转发到TangSeng(8091)触发CMD推送"""
    token = get_wkim_token()
    if not token:
        return jsonify({"status": 401, "msg": "token不能为空"}), 401

    data = request.get_json(silent=True) or {}
    uids = data.get('uids', [])
    if not uids:
        return jsonify({"status": 400, "msg": "uids不能为空"}), 400

    try:
        import pymysql
        headers = {"token": token, "Content-Type": "application/json"}
        db = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT, user=Config.MYSQL_USER,
            password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        results = []
        added_names = []
        added_uids = []
        try:
            with db.cursor() as cursor:
                for uid in uids:
                    cursor.execute(
                        "UPDATE group_member SET role=2, version=version+1, updated_at=NOW() WHERE group_no=%s AND uid=%s AND is_deleted=0",
                        (group_no, uid)
                    )
                    affected = cursor.rowcount
                    if affected > 0:
                        results.append({"uid": uid, "code": 200})
                        added_uids.append(uid)
                        cursor.execute(
                            "SELECT name FROM user WHERE uid=%s LIMIT 1",
                            (uid,)
                        )
                        user_row = cursor.fetchone()
                        if user_row and user_row.get('name'):
                            added_names.append(user_row['name'])
                    else:
                        results.append({"uid": uid, "code": 404, "msg": "成员不存在"})
            db.commit()

            operator_uid = get_current_uid() or ''
            operator_name = '群主'
            try:
                with db.cursor() as cursor:
                    cursor.execute("SELECT name FROM user WHERE uid=%s LIMIT 1", (operator_uid,))
                    op_row = cursor.fetchone()
                    if op_row and op_row.get('name'):
                        operator_name = op_row['name']
            except:
                pass
        finally:
            db.close()

        # 转发到TangSeng(8091)，让它处理CMD推送（TangSeng会发送groupAdminAdd CMD给所有群成员）
        # TangSeng期望JSON数组格式: ["uid1", "uid2"]
        try:
            ts_resp = requests.post(
                f"http://127.0.0.1:8091/v1/groups/{group_no}/managers",
                json=uids, headers=headers, timeout=10
            )
            logger.info(f"转发添加管理员到TangSeng: status={ts_resp.status_code}, resp={ts_resp.text[:200]}")
        except Exception as ts_err:
            logger.warning(f"转发添加管理员到TangSeng异常: {ts_err}")

        # 插入type=1008系统消息到数据库（带用户信息，触发客户端groupMembersSync）
        if added_uids:
            try:
                # 构建extra数组（用户信息）
                extra_list = []
                for uid in added_uids:
                    # 获取用户名
                    uname = ''
                    for i, uid2 in enumerate(added_uids):
                        if uid2 == uid and i < len(added_names):
                            uname = added_names[i] if i < len(added_names) else ''
                            break
                    extra_list.append({"uid": uid, "name": uname})

                # 构建消息内容模板
                names_text = "、".join(added_names) if added_names else "成员"
                notify_content = f'{operator_name} 将 {{0}} 设为群管理员'

                payload = {
                    "type": 1008,
                    "content": notify_content,
                    "extra": extra_list,
                    "data": {}
                }
                _insert_system_message(group_no, operator_uid, payload)
                logger.info(f"管理员添加系统消息插入成功: group={group_no}, uids={added_uids}")
            except Exception as msg_err:
                logger.warning(f"插入管理员添加系统消息异常: {msg_err}")

        all_success = all(r["code"] == 200 for r in results)
        if all_success:
            return jsonify({"status": 200, "msg": "添加成功"})
        else:
            return jsonify({"status": 500, "msg": "部分添加失败", "results": results})
    except Exception as e:
        logger.error(f"添加管理员异常: {e}", exc_info=True)
        return jsonify({"status": 500, "msg": f"服务器异常: {str(e)}"}), 500


@app.route('/v1/groups/<group_no>/managers', methods=['DELETE'])
def remove_group_managers(group_no):
    """移除群管理员 - 更新数据库role=0，并转发到TangSeng(8091)触发CMD推送"""
    token = get_wkim_token()
    if not token:
        return jsonify({"status": 401, "msg": "token不能为空"}), 401

    data = request.get_json(silent=True) or {}
    uids = data.get('uids', [])
    if not uids:
        return jsonify({"status": 400, "msg": "uids不能为空"}), 400

    try:
        import pymysql
        headers = {"token": token, "Content-Type": "application/json"}
        db = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT, user=Config.MYSQL_USER,
            password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        results = []
        removed_uids = []
        removed_names = []
        try:
            with db.cursor() as cursor:
                for uid in uids:
                    cursor.execute(
                        "UPDATE group_member SET role=0, version=version+1, updated_at=NOW() WHERE group_no=%s AND uid=%s AND is_deleted=0",
                        (group_no, uid)
                    )
                    affected = cursor.rowcount
                    if affected > 0:
                        results.append({"uid": uid, "code": 200})
                        removed_uids.append(uid)
                        cursor.execute(
                            "SELECT name FROM user WHERE uid=%s LIMIT 1",
                            (uid,)
                        )
                        user_row = cursor.fetchone()
                        if user_row and user_row.get('name'):
                            removed_names.append(user_row['name'])
                    else:
                        results.append({"uid": uid, "code": 404, "msg": "成员不存在"})
            db.commit()

            operator_uid = get_current_uid() or ''
            operator_name = '群主'
            try:
                with db.cursor() as cursor:
                    cursor.execute("SELECT name FROM user WHERE uid=%s LIMIT 1", (operator_uid,))
                    op_row = cursor.fetchone()
                    if op_row and op_row.get('name'):
                        operator_name = op_row['name']
            except:
                pass
        finally:
            db.close()

        # 转发到TangSeng(8091)，让它处理CMD推送
        try:
            ts_resp = requests.delete(
                f"http://127.0.0.1:8091/v1/groups/{group_no}/managers",
                json=uids, headers=headers, timeout=10
            )
            logger.info(f"转发移除管理员到TangSeng: status={ts_resp.status_code}, resp={ts_resp.text[:200]}")
        except Exception as ts_err:
            logger.warning(f"转发移除管理员到TangSeng异常: {ts_err}")

        # 插入type=1008系统消息到数据库（带用户信息，触发客户端groupMembersSync）
        if removed_uids:
            try:
                extra_list = []
                for i, uid in enumerate(removed_uids):
                    uname = removed_names[i] if i < len(removed_names) else ''
                    extra_list.append({"uid": uid, "name": uname})

                notify_content = f'{operator_name} 将 {{0}} 移出群管理员'

                payload = {
                    "type": 1008,
                    "content": notify_content,
                    "extra": extra_list,
                    "data": {}
                }
                _insert_system_message(group_no, operator_uid, payload)
                logger.info(f"管理员移除系统消息插入成功: group={group_no}, uids={removed_uids}")
            except Exception as msg_err:
                logger.warning(f"插入管理员移除系统消息异常: {msg_err}")

        all_success = all(r["code"] == 200 for r in results)
        if all_success:
            return jsonify({"status": 200, "msg": "移除成功"})
        else:
            return jsonify({"status": 500, "msg": "部分移除失败", "results": results})
    except Exception as e:
        logger.error(f"移除管理员异常: {e}")
        return jsonify({"status": 500, "msg": f"服务器异常: {str(e)}"}), 500


@app.route('/v1/groups/<group_no>/membersync', methods=['GET'])
def group_member_sync(group_no):
    """群成员增量同步 - 从group_member表返回更新过的成员数据"""
    try:
        version = int(request.args.get('version', 0))
        limit = int(request.args.get('limit', 1000))

        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                # 查询version大于客户端当前版本的所有成员（增量同步）
                cursor.execute(
                    "SELECT gm.uid, gm.role, gm.status, gm.is_deleted, gm.version, "
                    "gm.created_at, gm.updated_at, gm.invite_uid, gm.forbidden_expir_time, "
                    "gm.vercode, gm.robot, "
                    "u.name, u.username, u.phone AS remark "
                    "FROM group_member gm "
                    "LEFT JOIN user u ON u.uid = gm.uid "
                    "WHERE gm.group_no=%s AND gm.version > %s "
                    "ORDER BY gm.version ASC LIMIT %s",
                    (group_no, version, limit)
                )
                rows = cursor.fetchall()
                result = []
                for row in rows:
                    item = {
                        "uid": row.get("uid", ""),
                        "name": row.get("name", "") or "",
                        "username": row.get("username", "") or "",
                        "remark": row.get("remark", "") or "",
                        "group_no": group_no,
                        "role": row.get("role", 0) or 0,
                        "status": row.get("status", 0) or 0,
                        "is_deleted": row.get("is_deleted", 0) or 0,
                        "robot": row.get("robot", 0) or 0,
                        "version": row.get("version", 0) or 0,
                        "created_at": str(row.get("created_at", "")) if row.get("created_at") else "",
                        "updated_at": str(row.get("updated_at", "")) if row.get("updated_at") else "",
                        "invite_uid": row.get("invite_uid", "") or "",
                        "forbidden_expir_time": row.get("forbidden_expir_time", 0) or 0,
                        "vercode": row.get("vercode", "") or ""
                    }
                    result.append(item)
                return jsonify(result)
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"群成员同步异常: {e}", exc_info=True)
        return jsonify([])


@app.route('/v1/groups/<group_id>/transfer/<uid>', methods=['POST'])
def transfer_group_ownership(group_id, uid):
    """转让群主 - 验证当前用户是群主后，两步操作转让并支持回滚"""
    token = get_wkim_token()
    if not token:
        return jsonify({"status": 401, "msg": "token不能为空"}), 401

    # 获取当前登录用户uid（原群主）
    current_uid = get_current_uid()
    if not current_uid:
        return jsonify({"status": 401, "msg": "登录已过期，请重新登录"}), 401

    if current_uid == uid:
        return jsonify({"status": 400, "msg": "不能转让给自己"}), 400

    try:
        headers = {"token": token, "Content-Type": "application/json"}

        # 验证当前用户是否是群主（role=1）
        resp_member = requests.get(f"http://127.0.0.1:8091/v1/groups/{group_id}/members/{current_uid}",
                                  headers=headers, timeout=10)
        is_owner = False
        new_owner_original_role = 0
        if resp_member.status_code == 200:
            try:
                member_data = resp_member.json()
                if isinstance(member_data, dict):
                    m = member_data.get('data', member_data)
                    if isinstance(m, dict) and m.get('role') == 1:
                        is_owner = True
            except Exception:
                pass

        if not is_owner:
            return jsonify({"status": 403, "msg": "只有群主才能转让群主权限"}), 403

        # 获取新群主当前的role，用于回滚
        resp_new_member = requests.get(f"http://127.0.0.1:8091/v1/groups/{group_id}/members/{uid}",
                                      headers=headers, timeout=10)
        if resp_new_member.status_code == 200:
            try:
                new_member_data = resp_new_member.json()
                if isinstance(new_member_data, dict):
                    nm = new_member_data.get('data', new_member_data)
                    if isinstance(nm, dict):
                        new_owner_original_role = nm.get('role', 0) or 0
            except Exception:
                pass

        # Step 1: 将新群主提升为群主 (role=1)
        resp1 = requests.put(f"http://127.0.0.1:8091/v1/groups/{group_id}/members/{uid}",
                            json={"role": 1}, headers=headers, timeout=10)
        if resp1.status_code != 200:
            try:
                return resp1.json(), resp1.status_code
            except:
                return jsonify({"status": resp1.status_code, "msg": "提升新群主失败"}), resp1.status_code

        # Step 2: 将原群主（当前用户）降级为普通成员 (role=0)
        resp2 = requests.put(f"http://127.0.0.1:8091/v1/groups/{group_id}/members/{current_uid}",
                            json={"role": 0}, headers=headers, timeout=10)
        if resp2.status_code != 200:
            # 回滚：将新群主恢复为原来的role
            try:
                requests.put(f"http://127.0.0.1:8091/v1/groups/{group_id}/members/{uid}",
                            json={"role": new_owner_original_role}, headers=headers, timeout=10)
            except Exception as rollback_err:
                logger.error(f"群主转让回滚失败: {rollback_err}")
            try:
                return resp2.json(), resp2.status_code
            except:
                return jsonify({"status": resp2.status_code, "msg": "原群主降级失败，已回滚"}), resp2.status_code

        return jsonify({"status": 200, "msg": "群主转让成功"})
    except Exception as e:
        logger.error(f"转让群主异常: {e}")
        return jsonify({"status": 500, "msg": f"服务器异常: {str(e)}"}), 500


@app.route('/v1/groups/<group_no>/blacklist/<action>', methods=['POST'])
def group_blacklist(group_no, action):
    """群黑名单 - 加入/移出黑名单"""
    token = get_wkim_token()
    if not token:
        return jsonify({"status": 401, "msg": "token不能为空"}), 401

    data = request.get_json(silent=True) or {}
    uid = data.get('uid', '')
    if not uid:
        return jsonify({"status": 400, "msg": "uid不能为空"}), 400

    try:
        headers = {"token": token, "Content-Type": "application/json"}
        if action == "add":
            wkim_url = "http://127.0.0.1:8091/v1/channel/blacklist_add"
        else:
            wkim_url = "http://127.0.0.1:8091/v1/channel/blacklist_remove"

        payload = {
            "channel_id": group_no,
            "channel_type": 2,
            "uids": [uid]
        }
        resp = requests.post(wkim_url, json=payload, headers=headers, timeout=10)
        if resp.status_code == 200:
            return jsonify({"status": 200, "msg": "操作成功"})
        else:
            try:
                return resp.json(), resp.status_code
            except:
                return jsonify({"status": resp.status_code, "msg": "操作失败"}), resp.status_code
    except Exception as e:
        logger.error(f"黑名单操作异常: {e}")
        return jsonify({"status": 500, "msg": f"服务器异常: {str(e)}"}), 500


@app.route('/v1/groups/<group_no>/forbidden_with_member', methods=['POST'])
def forbid_group_member(group_no):
    """禁言群成员"""
    token = get_wkim_token()
    if not token:
        return jsonify({"status": 401, "msg": "token不能为空"}), 401

    data = request.get_json(silent=True) or {}
    uid = data.get('uid', '')
    expire = data.get('expire', 0)
    if not uid:
        return jsonify({"status": 400, "msg": "uid不能为空"}), 400

    try:
        headers = {"token": token, "Content-Type": "application/json"}
        # 通过WuKongIM setting接口设置成员禁言
        payload = {
            "uid": uid,
            "forbidden_expir_time": expire
        }
        resp = requests.put(f"http://127.0.0.1:8091/v1/groups/{group_no}/members/{uid}",
                           json=payload, headers=headers, timeout=10)
        if resp.status_code == 200:
            return jsonify({"status": 200, "msg": "禁言成功"})
        else:
            try:
                return resp.json(), resp.status_code
            except:
                return jsonify({"status": resp.status_code, "msg": "禁言失败"}), resp.status_code
    except Exception as e:
        logger.error(f"禁言成员异常: {e}")
        return jsonify({"status": 500, "msg": f"服务器异常: {str(e)}"}), 500


@app.route('/v1/group/update_avatar', methods=['POST'])
def update_group_avatar():
    """更新群头像"""
    token = get_wkim_token()
    if not token:
        return jsonify({"status": 401, "msg": "token不能为空"}), 401

    data = request.get_json(silent=True) or {}
    group_no = data.get('group_no', '')
    avatar = data.get('avatar', '')
    if not group_no:
        return jsonify({"status": 400, "msg": "group_no不能为空"}), 400

    try:
        headers = {"token": token, "Content-Type": "application/json"}

        # 权限校验：只有群主(1)或管理员(2)可以修改群头像
        current_uid = get_current_uid()
        if not current_uid:
            return jsonify({"status": 401, "msg": "请先登录"}), 401
        role = get_user_group_role(group_no, current_uid, token)
        if role != 1 and role != 2:
            return jsonify({"status": 403, "msg": "只有群主或管理员可以修改群头像"}), 403
        payload = {"avatar": avatar}
        resp = requests.put(f"http://127.0.0.1:8091/v1/groups/{group_no}",
                          json=payload, headers=headers, timeout=10)
        if resp.status_code == 200:
            return jsonify({"status": 200, "msg": "头像更新成功"})
        else:
            try:
                return resp.json(), resp.status_code
            except:
                return jsonify({"status": resp.status_code, "msg": "更新失败"}), resp.status_code
    except Exception as e:
        logger.error(f"更新群头像异常: {e}")
        return jsonify({"status": 500, "msg": f"服务器异常: {str(e)}"}), 500


@app.route('/v1/group/my', methods=['GET'])
def get_my_saved_groups():
    """获取我保存的群组列表 - 从group_setting表读取save=1的群组"""
    uid = get_current_uid()
    if not uid:
        return jsonify({"status": 401, "msg": "请先登录"}), 401

    try:
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                # 查询用户保存的群组（save=1），关联group表获取群信息
                cursor.execute(
                    "SELECT g.group_no, g.name, g.notice, g.forbidden, g.invite, "
                    "g.forbidden_add_friend, g.allow_view_history_msg, g.status, "
                    "g.created_at, g.updated_at, "
                    "gs.save, gs.mute, gs.top, gs.show_nick, gs.remark, gs.receipt, "
                    "gs.screenshot, gs.chat_pwd_on, gs.revoke_remind, "
                    "gs.flame, gs.flame_second, gs.join_group_remind "
                    "FROM group_setting gs "
                    "LEFT JOIN `group` g ON g.group_no = gs.group_no "
                    "WHERE gs.uid=%s AND gs.save=1 AND g.group_no IS NOT NULL "
                    "ORDER BY gs.updated_at DESC",
                    (uid,)
                )
                rows = cursor.fetchall()
                result = []
                for row in rows:
                    item = {
                        "group_no": row.get("group_no", ""),
                        "name": row.get("name", ""),
                        "remark": row.get("remark", "") or "",
                        "notice": row.get("notice", "") or "",
                        "mute": row.get("mute", 0) or 0,
                        "forbidden": row.get("forbidden", 0) or 0,
                        "invite": row.get("invite", 0) or 0,
                        "status": row.get("status", 0) or 0,
                        "top": row.get("top", 0) or 0,
                        "save": row.get("save", 0) or 0,
                        "receipt": row.get("receipt", 0) or 0,
                        "show_nick": row.get("show_nick", 0) or 0,
                        "forbidden_add_friend": row.get("forbidden_add_friend", 0) or 0,
                        "screenshot": row.get("screenshot", 0) or 0,
                        "chat_pwd_on": row.get("chat_pwd_on", 0) or 0,
                        "allow_view_history_msg": row.get("allow_view_history_msg", 0) or 0,
                        "join_group_remind": row.get("join_group_remind", 0) or 0,
                        "revoke_remind": row.get("revoke_remind", 0) or 0,
                        "avatar": "",
                        "created_at": str(row.get("created_at", "")) if row.get("created_at") else "",
                        "updated_at": str(row.get("updated_at", "")) if row.get("updated_at") else ""
                    }
                    result.append(item)
                return jsonify(result)
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"获取已保存群组列表异常: {e}", exc_info=True)
        return jsonify({"status": 500, "msg": f"服务器异常: {str(e)}"}), 500


@app.route('/v1/groups/<group_no>/setting', methods=['PUT'])
def update_group_setting(group_no):
    """更新群设置 - 标准字段直接更新，自定义字段存储到remote_extra中"""
    token = get_wkim_token()
    if not token:
        return jsonify({"status": 401, "msg": "token不能为空"}), 401

    data = request.get_json(silent=True) or {}
    if not data:
        return jsonify({"status": 400, "msg": "参数不能为空"}), 400

    try:
        headers = {"token": token, "Content-Type": "application/json"}

        # 权限校验：只有群主(1)或管理员(2)可以修改群设置
        current_uid = get_current_uid()
        if not current_uid:
            return jsonify({"status": 401, "msg": "请先登录"}), 401
        role = get_user_group_role(group_no, current_uid, token)
        if role != 1 and role != 2:
            return jsonify({"status": 403, "msg": "只有群主或管理员可以修改群设置"}), 403

        all_fields = ['forbidden', 'invite', 'forbidden_add_friend',
                       'allow_view_history_msg', 'forbid_member_send_temp_msg']

        payload = {}
        for key in all_fields:
            if key in data:
                payload[key] = data[key]

        if not payload:
            return jsonify({"status": 400, "msg": "没有有效的设置项"}), 400

        # TangSeng /setting端点支持的字段
        tsdd_fields = {k: v for k, v in payload.items() if k != 'forbid_member_send_temp_msg'}
        # forbid_member_send_temp_msg 需要直接更新数据库(TangSeng不支持此字段)
        custom_fields = {k: v for k, v in payload.items() if k == 'forbid_member_send_temp_msg'}

        resp = requests.put(f"http://127.0.0.1:8091/v1/groups/{group_no}/setting",
                           json=tsdd_fields, headers=headers, timeout=10) if tsdd_fields else None

        # 直接更新数据库中的 forbid_member_send_temp_msg
        if custom_fields:
            try:
                conn = pymysql.connect(
                    host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
                    user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
                    database=Config.MYSQL_DATABASE, charset='utf8mb4',
                    cursorclass=pymysql.cursors.DictCursor
                )
                try:
                    with conn.cursor() as cursor:
                        for k, v in custom_fields.items():
                            cursor.execute(
                                f"UPDATE `group` SET {k}=%s WHERE group_no=%s",
                                (int(v), group_no)
                            )
                    conn.commit()
                    logger.info(f"直接更新数据库: {custom_fields} for group {group_no}")
                finally:
                    conn.close()
            except Exception as db_err:
                logger.error(f"数据库更新失败: {db_err}")
                if not resp or resp.status_code == 200:
                    return jsonify({"status": 500, "msg": f"数据库更新失败: {str(db_err)}"}), 500

        if resp and resp.status_code != 200:
            error_msg = "设置更新失败"
            try:
                error_resp = resp.json()
                logger.error(f"TangSeng群更新失败: status={resp.status_code}, response={error_resp}")
                if isinstance(error_resp, dict):
                    error_msg = error_resp.get('msg', error_resp.get('error', error_msg))
                return jsonify({"status": resp.status_code, "msg": error_msg}), resp.status_code
            except:
                logger.error(f"TangSeng群更新失败: status={resp.status_code}, response={resp.text}")
                return jsonify({"status": resp.status_code, "msg": error_msg}), resp.status_code

        # 所有更新成功
        # 群设置变更成功后，发送系统通知消息到群聊
        setting_msgs = {
            'forbidden': {1: '开启了全员禁言', 0: '关闭了全员禁言'},
            'invite': {1: '开启了入群审核', 0: '关闭了入群审核'},
            'forbidden_add_friend': {1: '开启了禁止添加好友', 0: '关闭了禁止添加好友'},
            'forbid_member_send_temp_msg': {1: '开启了禁止临时会话', 0: '关闭了禁止临时会话'},
            'allow_view_history_msg': {1: '允许新成员查看历史消息', 0: '禁止新成员查看历史消息'},
        }
        # 获取操作者信息
        operator_name = '管理员'
        try:
            operator_uid = request.headers.get('uid', '')
            if operator_uid:
                conn = pymysql.connect(
                    host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
                    user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
                    database=Config.MYSQL_DATABASE, charset='utf8mb4',
                    cursorclass=pymysql.cursors.DictCursor
                )
                try:
                    with conn.cursor() as cursor:
                        cursor.execute("SELECT name FROM `user` WHERE uid=%s", (operator_uid,))
                        user_row = cursor.fetchone()
                        if user_row and user_row.get('name'):
                            operator_name = user_row['name']
                finally:
                    conn.close()
        except:
            pass

        for key in all_fields:
            if key in data:
                action_text = setting_msgs.get(key, {}).get(data[key], '')
                if action_text:
                    notify_content = f'{operator_name}{action_text}'
                    try:
                        operator_uid = request.headers.get('uid', '')
                        msg_payload = {
                            "from_uid": operator_uid,
                            "channel_id": group_no,
                            "channel_type": 2,
                            "content": notify_content,
                            "type": 1000
                        }
                        notify_resp = requests.post(
                            f"http://127.0.0.1:8091/v1/message/send",
                            json=msg_payload, headers=headers, timeout=10
                        )
                        if notify_resp.status_code == 200:
                            logger.info(f"群设置通知发送成功: {notify_content}")
                        else:
                            logger.warning(f"群设置通知发送失败: {notify_content}, status={notify_resp.status_code}, resp={notify_resp.text[:200]}")
                    except Exception as notify_err:
                        logger.warning(f"群设置通知发送异常: {notify_err}")

        result_data = {}
        for key in all_fields:
            if key in data:
                result_data[key] = data[key]
        return jsonify({"status": 200, "msg": "设置更新成功", "data": result_data})
    except Exception as e:
        logger.error(f"更新群设置异常: {e}")
        return jsonify({"status": 500, "msg": f"服务器异常: {str(e)}"}), 500


@app.route('/v1/groups/<group_no>/mysetting', methods=['PUT'])
def update_my_group_setting(group_no):
    """更新用户个人群设置（保存到通讯录、免打扰、置顶等）- group_setting表"""
    uid = get_current_uid()
    if not uid:
        return jsonify({"status": 401, "msg": "请先登录"}), 401

    data = request.get_json(silent=True) or {}
    if not data:
        return jsonify({"status": 400, "msg": "参数不能为空"}), 400

    # 允许更新的用户级别设置字段
    allowed_fields = ['save', 'mute', 'top', 'show_nick', 'remark',
                      'chat_pwd_on', 'revoke_remind', 'screenshot', 'receipt',
                      'flame', 'flame_second', 'join_group_remind']

    update_fields = {}
    for key in allowed_fields:
        if key in data:
            update_fields[key] = data[key]

    if not update_fields:
        return jsonify({"status": 400, "msg": "没有有效的设置项"}), 400

    try:
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                # 检查是否已有记录
                cursor.execute(
                    "SELECT id FROM group_setting WHERE uid=%s AND group_no=%s LIMIT 1",
                    (uid, group_no)
                )
                row = cursor.fetchone()
                if row:
                    # 更新
                    set_clause = ", ".join([f"{k}=%s" for k in update_fields.keys()])
                    values = list(update_fields.values()) + [uid, group_no]
                    cursor.execute(
                        f"UPDATE group_setting SET {set_clause}, version=version+1, updated_at=NOW() WHERE uid=%s AND group_no=%s",
                        values
                    )
                else:
                    # 插入
                    keys = list(update_fields.keys()) + ['uid', 'group_no']
                    placeholders = ", ".join(["%s"] * len(keys))
                    values = list(update_fields.values()) + [uid, group_no]
                    cursor.execute(
                        f"INSERT INTO group_setting ({', '.join(keys)}) VALUES ({placeholders})",
                        values
                    )
                conn.commit()
                logger.info(f"用户群设置更新成功: uid={uid}, group={group_no}, fields={list(update_fields.keys())}")
                return jsonify({"status": 200, "msg": "设置更新成功", "data": update_fields})
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"更新用户群设置异常: {e}", exc_info=True)
        return jsonify({"status": 500, "msg": f"设置更新失败: {str(e)}"}), 500


@app.route('/v1/channels/<channel_id>/<int:channel_type>', methods=['GET'])
def proxy_channel_info(channel_id, channel_type):
    """代理channel信息端点 - 添加TangSeng不支持的forbid_member_send_temp_msg字段及用户级群设置"""
    token = get_wkim_token()
    if not token:
        return jsonify({"status": 401, "msg": "token不能为空"}), 401

    try:
        headers = {"token": token, "Content-Type": "application/json"}
        resp = requests.get(
            f"http://127.0.0.1:8091/v1/channels/{channel_id}/{channel_type}",
            headers=headers, timeout=10
        )

        if resp.status_code == 200 and channel_type == 2:
            data = resp.json()
            uid = get_current_uid()
            try:
                conn = pymysql.connect(
                    host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
                    user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
                    database=Config.MYSQL_DATABASE, charset='utf8mb4',
                    cursorclass=pymysql.cursors.DictCursor
                )
                try:
                    with conn.cursor() as cursor:
                        # 读取群级别设置 forbid_member_send_temp_msg
                        cursor.execute(
                            "SELECT forbid_member_send_temp_msg FROM `group` WHERE group_no=%s",
                            (channel_id,)
                        )
                        row = cursor.fetchone()
                        if row and 'extra' in data and isinstance(data['extra'], dict):
                            data['extra']['forbid_member_send_temp_msg'] = row.get('forbid_member_send_temp_msg', 0)

                        # 读取用户个人群设置（保存到通讯录、免打扰、置顶等）
                        if uid:
                            cursor.execute(
                                "SELECT save, mute, top, show_nick, remark, chat_pwd_on, "
                                "revoke_remind, screenshot, receipt, flame, flame_second, join_group_remind "
                                "FROM group_setting WHERE uid=%s AND group_no=%s LIMIT 1",
                                (uid, channel_id)
                            )
                            setting_row = cursor.fetchone()
                            if setting_row:
                                # 注入用户级设置到频道信息顶层
                                if setting_row.get('save') is not None:
                                    data['save'] = setting_row['save']
                                if setting_row.get('mute') is not None:
                                    data['mute'] = setting_row['mute']
                                if setting_row.get('top') is not None:
                                    data['stick'] = setting_row['top']  # 客户端字段名为stick
                                if setting_row.get('show_nick') is not None:
                                    data['show_nick'] = setting_row['show_nick']
                                if setting_row.get('remark') is not None:
                                    data['remark'] = setting_row['remark']
                                if setting_row.get('receipt') is not None:
                                    data['receipt'] = setting_row['receipt']
                                if setting_row.get('flame') is not None:
                                    data['flame'] = setting_row['flame']
                                if setting_row.get('flame_second') is not None:
                                    data['flame_second'] = setting_row['flame_second']
                finally:
                    conn.close()
            except Exception as db_err:
                logger.warning(f"读取群设置失败(降级处理): {db_err}")
            return jsonify(data)
        return resp.content, resp.status_code, {'Content-Type': 'application/json'}
    except Exception as e:
        logger.error(f"代理channel信息异常: {e}")
        return jsonify({"status": 500, "msg": f"服务器异常: {str(e)}"}), 500


# ==================== 入群审核辅助函数 ====================

def get_group_info(group_no, token):
    """获取群信息，返回群信息字典（含name、remote_extra等）"""
    try:
        headers = {"token": token, "Content-Type": "application/json"}
        resp = requests.get(f"http://127.0.0.1:8091/v1/groups/{group_no}",
                           headers=headers, timeout=10)
        if resp.status_code == 200:
            data = resp.json()
            # WuKongIM返回格式可能是直接数据或包裹在data中
            if isinstance(data, dict) and 'data' in data and isinstance(data['data'], dict):
                return data['data']
            return data if isinstance(data, dict) else {}
        return {}
    except Exception as e:
        logger.error(f"获取群信息异常: {e}")
        return {}


def get_group_invite_setting(group_no, token):
    """获取群的入群审核设置 invite，0=关闭，1=开启，默认0"""
    group_info = get_group_info(group_no, token)
    if not group_info:
        return 0
    remote_extra = group_info.get('remote_extra')
    if not remote_extra:
        return 0
    if isinstance(remote_extra, str):
        try:
            remote_extra = json.loads(remote_extra)
        except:
            return 0
    if isinstance(remote_extra, dict):
        return int(remote_extra.get('invite', 0) or 0)
    return 0


def get_group_owners_and_managers(group_no, token):
    """获取群主(role=1)和管理员(role=2)的uid列表"""
    try:
        headers = {"token": token, "Content-Type": "application/json"}
        resp = requests.get(f"http://127.0.0.1:8091/v1/groups/{group_no}/members",
                           headers=headers, timeout=10)
        if resp.status_code != 200:
            return []
        data = resp.json()
        members = []
        if isinstance(data, dict):
            members = data.get('data', []) or data.get('members', []) or []
        if not isinstance(members, list):
            return []
        result = []
        for m in members:
            if not isinstance(m, dict):
                continue
            role = m.get('role', 0)
            uid = m.get('uid', '')
            if uid and (role == 1 or role == 2):
                result.append(uid)
        return result
    except Exception as e:
        logger.error(f"获取群管理员异常: {e}")
        return []


def get_user_group_role(group_no, uid, token):
    """获取用户在群中的角色 0=普通成员 1=群主 2=管理员 -1=非群成员"""
    try:
        headers = {"token": token, "Content-Type": "application/json"}
        resp = requests.get(f"http://127.0.0.1:8091/v1/groups/{group_no}/{uid}",
                           headers=headers, timeout=10)
        if resp.status_code == 200:
            data = resp.json()
            if isinstance(data, dict):
                member = data.get('data', data)
                if isinstance(member, dict):
                    return int(member.get('role', 0) or 0)
        return -1
    except Exception as e:
        logger.error(f"获取用户群角色异常: {e}")
        return -1


def get_user_info_by_uid(uid, token):
    """根据uid获取用户信息（昵称、头像等）"""
    try:
        headers = {"token": token, "Content-Type": "application/json"}
        resp = requests.get(f"http://127.0.0.1:8091/v1/user/{uid}",
                           headers=headers, timeout=10)
        if resp.status_code == 200:
            data = resp.json()
            if isinstance(data, dict):
                if 'data' in data and isinstance(data['data'], dict):
                    return data['data']
                return data
        return {}
    except Exception as e:
        logger.error(f"获取用户信息异常: {e}")
        return {}


def ensure_group_apply_table():
    """确保入群申请表存在，不存在则创建"""
    try:
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS group_apply (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        apply_uid VARCHAR(64) NOT NULL COMMENT '申请人UID',
                        apply_name VARCHAR(128) DEFAULT '' COMMENT '申请人昵称',
                        apply_avatar VARCHAR(512) DEFAULT '' COMMENT '申请人头像',
                        group_no VARCHAR(64) NOT NULL COMMENT '群编号',
                        group_name VARCHAR(128) DEFAULT '' COMMENT '群名称',
                        remark VARCHAR(512) DEFAULT '' COMMENT '申请备注',
                        status TINYINT DEFAULT 0 COMMENT '状态: 0=待审核, 1=已通过, 2=已拒绝',
                        handle_uid VARCHAR(64) DEFAULT '' COMMENT '处理人UID',
                        handle_remark VARCHAR(512) DEFAULT '' COMMENT '处理备注',
                        token VARCHAR(128) DEFAULT '' COMMENT '申请唯一标识',
                        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                        INDEX idx_group_no (group_no),
                        INDEX idx_apply_uid (apply_uid),
                        INDEX idx_status (status)
                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='入群申请表'
                """)
            conn.commit()
        finally:
            conn.close()
    except Exception as e:
        logger.warning(f"创建入群申请表失败: {e}")


def create_group_apply_record(apply_uid, apply_name, apply_avatar, group_no, group_name, remark):
    """创建入群申请记录，返回申请token"""
    ensure_group_apply_table()
    import uuid
    apply_token = uuid.uuid4().hex
    try:
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                # 检查是否已有待审核的申请
                cursor.execute(
                    "SELECT id FROM group_apply WHERE apply_uid=%s AND group_no=%s AND status=0 LIMIT 1",
                    (apply_uid, group_no)
                )
                existing = cursor.fetchone()
                if existing:
                    # 更新现有申请的备注和时间
                    cursor.execute(
                        "UPDATE group_apply SET remark=%s, updated_at=NOW() WHERE id=%s",
                        (remark or '', existing['id'])
                    )
                    conn.commit()
                    # 获取token
                    cursor.execute("SELECT token FROM group_apply WHERE id=%s", (existing['id'],))
                    row = cursor.fetchone()
                    return row['token'] if row else apply_token
                # 创建新申请
                cursor.execute(
                    "INSERT INTO group_apply (apply_uid, apply_name, apply_avatar, group_no, group_name, remark, status, token) "
                    "VALUES (%s, %s, %s, %s, %s, %s, 0, %s)",
                    (apply_uid, apply_name or '', apply_avatar or '', group_no, group_name or '', remark or '', apply_token)
                )
                conn.commit()
                return apply_token
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"创建入群申请记录异常: {e}")
        return apply_token


def update_group_apply_status(group_no, apply_uid, status, handle_uid='', handle_remark=''):
    """更新入群申请状态"""
    ensure_group_apply_table()
    try:
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "UPDATE group_apply SET status=%s, handle_uid=%s, handle_remark=%s, updated_at=NOW() "
                    "WHERE group_no=%s AND apply_uid=%s AND status=0 ORDER BY id DESC LIMIT 1",
                    (status, handle_uid, handle_remark, group_no, apply_uid)
                )
                conn.commit()
                return cursor.rowcount > 0
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"更新入群申请状态异常: {e}")
        return False


def send_group_apply_cmd(admin_uids, apply_uid, apply_name, apply_avatar, group_no, group_name, remark, token, wkim_token):
    """向群主和管理员发送入群申请CMD消息"""
    headers = {"token": wkim_token, "Content-Type": "application/json"}
    content = json.dumps({
        "type": 1,  # 1=入群申请
        "apply_uid": apply_uid,
        "apply_name": apply_name,
        "apply_avatar": apply_avatar,
        "group_no": group_no,
        "group_name": group_name,
        "remark": remark,
        "token": token
    }, ensure_ascii=False)

    for admin_uid in admin_uids:
        try:
            payload = {
                "from": "system",
                "to": admin_uid,
                "channel_id": admin_uid,
                "channel_type": 1,
                "type": 100,  # 系统消息/CMD消息
                "content": content
            }
            requests.post("http://127.0.0.1:8091/v1/message/send",
                         json=payload, headers=headers, timeout=5)
        except Exception as e:
            logger.error(f"发送入群申请CMD消息失败 to {admin_uid}: {e}")


def send_system_message(to_uid, content_data, wkim_token):
    """发送系统消息"""
    try:
        headers = {"token": wkim_token, "Content-Type": "application/json"}
        payload = {
            "from": "system",
            "to": to_uid,
            "channel_id": to_uid,
            "channel_type": 1,
            "type": 100,
            "content": json.dumps(content_data, ensure_ascii=False)
        }
        resp = requests.post("http://127.0.0.1:8091/v1/message/send",
                            json=payload, headers=headers, timeout=10)
        return resp.status_code == 200
    except Exception as e:
        logger.error(f"发送系统消息异常: {e}")
        return False


# ==================== 入群审核接口 ====================

@app.route('/v1/groups/<group_no>/member/invite', methods=['POST'])
def invite_group_members(group_no):
    """群邀请/入群申请接口代理
    - 群主(role=1)或管理员(role=2)邀请：直接加入群聊，在聊天窗口内通知
    - 普通成员(role=0)邀请好友入群：需要群主或管理员在新朋友页面审核通过或拒绝
    """
    token = get_wkim_token()
    if not token:
        return jsonify({"status": 401, "msg": "token不能为空"}), 401

    data = request.get_json(silent=True) or {}
    uids = data.get('uids', [])
    remark = data.get('remark', '')

    if not group_no:
        return jsonify({"status": 400, "msg": "group_no不能为空"}), 400
    if not uids or not isinstance(uids, list):
        return jsonify({"status": 400, "msg": "uids不能为空且必须是数组"}), 400

    try:
        headers = {"token": token, "Content-Type": "application/json"}

        # 获取当前用户在群中的角色
        current_uid = get_current_uid()
        if not current_uid:
            return jsonify({"status": 401, "msg": "请先登录"}), 401

        inviter_role = get_user_group_role(group_no, current_uid, token)
        group_info = get_group_info(group_no, token)
        group_name = group_info.get('name', '') if isinstance(group_info, dict) else ''

        if inviter_role == 1 or inviter_role == 2:
            # 群主或管理员邀请：直接加入群聊
            payload = {
                "uids": uids,
                "role": 0
            }
            resp = requests.post(f"http://127.0.0.1:8091/v1/groups/{group_no}/members",
                                json=payload, headers=headers, timeout=10)
            if resp.status_code == 200:
                # 在群聊窗口内发送通知消息
                inviter_name = ''
                try:
                    inviter_info = get_user_info_by_uid(current_uid, token)
                    inviter_name = inviter_info.get('name', inviter_info.get('nickname', '')) if isinstance(inviter_info, dict) else ''
                except:
                    pass

                for uid in uids:
                    invitee_info = get_user_info_by_uid(uid, token)
                    invitee_name = invitee_info.get('name', invitee_info.get('nickname', '')) if isinstance(invitee_info, dict) else ''
                    notify_text = f'{inviter_name}邀请{invitee_name}加入了群聊'
                    try:
                        msg_payload = {
                            "from_uid": current_uid,
                            "channel_id": group_no,
                            "channel_type": 2,
                            "content": notify_text,
                            "type": 1000
                        }
                        requests.post(
                            f"http://127.0.0.1:8091/v1/message/send",
                            json=msg_payload, headers=headers, timeout=10
                        )
                        logger.info(f"入群通知发送: {notify_text}")
                    except Exception as notify_err:
                        logger.warning(f"入群通知发送失败: {notify_err}")

                return jsonify({
                    "status": 200,
                    "msg": "添加成功",
                    "data": {
                        "invite": 0,
                        "results": [{"uid": uid, "status": "joined"} for uid in uids]
                    }
                })
            else:
                try:
                    return resp.json(), resp.status_code
                except:
                    return jsonify({"status": resp.status_code, "msg": "邀请失败"}), resp.status_code
        else:
            # 普通成员邀请好友入群：需要群主或管理员审核
            admin_uids = get_group_owners_and_managers(group_no, token)

            results = []
            for uid in uids:
                # 获取申请人信息
                user_info = get_user_info_by_uid(uid, token)
                apply_name = user_info.get('name', user_info.get('nickname', '')) if isinstance(user_info, dict) else ''
                apply_avatar = user_info.get('avatar', '') if isinstance(user_info, dict) else ''

                # 创建申请记录
                apply_token = create_group_apply_record(
                    apply_uid=uid,
                    apply_name=apply_name,
                    apply_avatar=apply_avatar,
                    group_no=group_no,
                    group_name=group_name,
                    remark=remark
                )

                # 向群主和管理员发送CMD消息
                if admin_uids:
                    send_group_apply_cmd(
                        admin_uids=admin_uids,
                        apply_uid=uid,
                        apply_name=apply_name,
                        apply_avatar=apply_avatar,
                        group_no=group_no,
                        group_name=group_name,
                        remark=remark,
                        token=apply_token,
                        wkim_token=token
                    )

                results.append({"uid": uid, "status": "pending", "token": apply_token})

            return jsonify({
                "status": 200,
                "msg": "申请已发送，等待管理员审核",
                "data": {
                    "invite": 1,
                    "results": results
                }
            })
    except Exception as e:
        logger.error(f"群邀请异常: {e}")
        return jsonify({"status": 500, "msg": f"服务器异常: {str(e)}"}), 500


@app.route('/v1/groups/<group_no>/members', methods=['DELETE'])
def delete_group_members(group_no):
    """删除群成员（踢人）- 代理WuKongIM删除成员接口，并向被踢用户发送系统通知"""
    token = get_wkim_token()
    if not token:
        return jsonify({"status": 401, "msg": "token不能为空"}), 401

    data = request.get_json(silent=True) or {}
    # 前端发送的key为members，兼容uids
    uids = data.get('members') or data.get('uids') or []
    if not uids or not isinstance(uids, list):
        return jsonify({"status": 400, "msg": "members不能为空且必须是数组"}), 400

    try:
        headers = {"token": token, "Content-Type": "application/json"}

        # 获取群名称用于通知
        group_name = ''
        group_info = get_group_info(group_no, token)
        if isinstance(group_info, dict):
            group_name = group_info.get('name', '')

        results = []
        for uid in uids:
            resp = requests.delete(f"http://127.0.0.1:8091/v1/groups/{group_no}/members/{uid}",
                                   headers=headers, timeout=10)
            results.append({"uid": uid, "code": resp.status_code})
            # 踢成功后向被踢用户发送系统通知
            if resp.status_code == 200:
                try:
                    notify_content = f"您已被移除群聊{group_name}" if group_name else "您已被移除群聊"
                    msg_payload = {
                        "from_uid": "system",
                        "channel_id": uid,
                        "channel_type": 1,
                        "content": notify_content,
                        "type": 1000
                    }
                    requests.post(
                        f"http://127.0.0.1:8091/v1/message/send",
                        json=msg_payload, headers=headers, timeout=10
                    )
                    logger.info(f"踢人通知发送: uid={uid}, group={group_name}")
                except Exception as notify_err:
                    logger.warning(f"踢人通知发送失败: {notify_err}")

        all_success = all(r["code"] == 200 for r in results)
        if all_success:
            return jsonify({"status": 200, "msg": "删除成功"})
        else:
            return jsonify({"status": 500, "msg": "部分删除失败", "results": results})
    except Exception as e:
        logger.error(f"删除群成员异常: {e}")
        return jsonify({"status": 500, "msg": f"服务器异常: {str(e)}"}), 500


@app.route('/v1/group/apply/reject', methods=['POST'])
def reject_group_apply():
    """拒绝入群申请"""
    token = get_wkim_token()
    if not token:
        return jsonify({"status": 401, "msg": "token不能为空"}), 401

    data = request.get_json(silent=True) or {}
    group_no = data.get('group_no', '')
    uid = data.get('uid', '')
    remark = data.get('remark', '')
    if not group_no:
        return jsonify({"status": 400, "msg": "group_no不能为空"}), 400
    if not uid:
        return jsonify({"status": 400, "msg": "uid不能为空"}), 400

    try:
        headers = {"token": token, "Content-Type": "application/json"}

        # 权限校验：只有群主或管理员可以拒绝入群申请
        handle_uid = get_current_uid() or ''
        if handle_uid:
            role = get_user_group_role(group_no, handle_uid, token)
            if role != 1 and role != 2:
                return jsonify({"status": 403, "msg": "只有群主或管理员可以审核入群申请"}), 403

        # 获取群信息
        group_info = get_group_info(group_no, token)
        group_name = group_info.get('name', '') if isinstance(group_info, dict) else ''

        # 更新申请状态为已拒绝
        update_group_apply_status(
            group_no=group_no,
            apply_uid=uid,
            status=2,  # 已拒绝
            handle_uid=handle_uid,
            handle_remark=remark
        )

        # 获取申请人信息
        user_info = get_user_info_by_uid(uid, token)
        apply_name = user_info.get('name', user_info.get('nickname', '')) if isinstance(user_info, dict) else ''
        apply_avatar = user_info.get('avatar', '') if isinstance(user_info, dict) else ''

        # 发送系统消息通知用户被拒绝（格式与前端NewFriendEntity对应）
        sys_content = {
            "type": "group_apply_reject",
            "group_no": group_no,
            "group_name": group_name,
            "apply_uid": uid,
            "apply_name": apply_name,
            "apply_avatar": apply_avatar,
            "remark": remark,
            "status": 2
        }
        send_system_message(uid, sys_content, token)

        return jsonify({"status": 200, "msg": "已拒绝入群申请"})
    except Exception as e:
        logger.error(f"拒绝入群申请异常: {e}")
        return jsonify({"status": 500, "msg": f"服务器异常: {str(e)}"}), 500


@app.route('/v1/group/apply/approve', methods=['POST'])
def approve_group_apply():
    """通过入群申请"""
    token = get_wkim_token()
    if not token:
        return jsonify({"status": 401, "msg": "token不能为空"}), 401

    data = request.get_json(silent=True) or {}
    group_no = data.get('group_no', '')
    uid = data.get('uid', '')
    if not group_no:
        return jsonify({"status": 400, "msg": "group_no不能为空"}), 400
    if not uid:
        return jsonify({"status": 400, "msg": "uid不能为空"}), 400

    try:
        headers = {"token": token, "Content-Type": "application/json"}

        # 权限校验：只有群主或管理员可以通过入群申请
        current_uid = get_current_uid()
        if current_uid:
            role = get_user_group_role(group_no, current_uid, token)
            if role != 1 and role != 2:
                return jsonify({"status": 403, "msg": "只有群主或管理员可以审核入群申请"}), 403

        # 将用户加入群聊
        payload = {
            "uids": [uid],
            "role": 0
        }
        resp = requests.post(f"http://127.0.0.1:8091/v1/groups/{group_no}/members",
                            json=payload, headers=headers, timeout=10)
        if resp.status_code == 200:
            # 获取当前处理人
            handle_uid = get_current_uid() or ''

            # 获取群信息
            group_info = get_group_info(group_no, token)
            group_name = group_info.get('name', '') if isinstance(group_info, dict) else ''

            # 更新申请状态为已通过
            update_group_apply_status(
                group_no=group_no,
                apply_uid=uid,
                status=1,  # 已通过
                handle_uid=handle_uid
            )

            # 获取申请人信息
            user_info = get_user_info_by_uid(uid, token)
            apply_name = user_info.get('name', user_info.get('nickname', '')) if isinstance(user_info, dict) else ''
            apply_avatar = user_info.get('avatar', '') if isinstance(user_info, dict) else ''

            # 发送系统消息通知用户已通过（格式与前端NewFriendEntity对应）
            sys_content = {
                "type": "group_apply_approve",
                "group_no": group_no,
                "group_name": group_name,
                "apply_uid": uid,
                "apply_name": apply_name,
                "apply_avatar": apply_avatar,
                "status": 1
            }
            send_system_message(uid, sys_content, token)

            return jsonify({"status": 200, "msg": "已通过入群申请"})
        else:
            try:
                return resp.json(), resp.status_code
            except:
                return jsonify({"status": resp.status_code, "msg": "通过失败"}), resp.status_code
    except Exception as e:
        logger.error(f"通过入群申请异常: {e}")
        return jsonify({"status": 500, "msg": f"服务器异常: {str(e)}"}), 500


# ==================== 腾讯实时音视频 TRTC ====================

import zlib

def gen_trtc_user_sig(sdk_app_id, secret_key, user_id, expire=86400):
    """
    生成 TRTC UserSig (HMAC-SHA256 + zlib + base64)
    算法参考腾讯云官方 GenerateTestUserSig 实现
    """
    curr_time = int(time.time())

    # 1. 构建待签名字符串
    raw_content = (
        f"TLS.identifier:{user_id}\n"
        f"TLS.appid:{sdk_app_id}\n"
        f"TLS.expire:{expire}\n"
        f"TLS.time:{curr_time}\n"
    )

    # 2. HMAC-SHA256 签名
    sig = base64.b64encode(
        hmac.new(secret_key.encode('utf-8'),
                 raw_content.encode('utf-8'),
                 hashlib.sha256).digest()
    ).decode('utf-8')

    # 3. 组装 sig_doc
    sig_doc = {
        "TLS.appid": str(sdk_app_id),
        "TLS.account_type": "0",
        "TLS.identifier": str(user_id),
        "TLS.expire": str(expire),
        "TLS.time": str(curr_time),
        "TLS.sig": sig,
    }

    # 4. JSON 序列化 -> zlib 压缩 -> base64 编码
    json_str = json.dumps(sig_doc, separators=(',', ':'))
    compressed = zlib.compress(json_str.encode('utf-8'))
    user_sig = base64.b64encode(compressed).decode('utf-8')

    # 5. URL 安全替换
    user_sig = user_sig.replace('+', '*').replace('/', '-').replace('=', '_')

    return user_sig


@app.route('/v1/trtc/usersig', methods=['GET'])
def get_trtc_usersig():
    """获取 TRTC UserSig（需登录）"""
    uid = get_current_uid()
    if not uid:
        return make_error("登录已过期，请重新登录", 401)

    if not Config.TRTC_SDK_APP_ID or not Config.TRTC_SECRET_KEY:
        return make_error("TRTC未配置，请在服务端设置TRTC_SDK_APP_ID和TRTC_SECRET_KEY", 500)

    try:
        user_sig = gen_trtc_user_sig(
            Config.TRTC_SDK_APP_ID,
            Config.TRTC_SECRET_KEY,
            uid,
            expire=86400
        )
        return make_success({
            "sdk_app_id": Config.TRTC_SDK_APP_ID,
            "user_id": uid,
            "user_sig": user_sig,
            "expire": 86400
        })
    except Exception as e:
        logger.error(f"生成TRTC UserSig异常: {e}")
        return make_error(f"生成签名失败: {str(e)}", 500)


# ==================== 消息搜索 ====================

@app.route('/v1/messages/search', methods=['POST'])
def search_messages():
    """搜索消息 - 根据关键词搜索用户相关的消息记录"""
    uid = get_current_uid()
    if not uid:
        return make_error("登录已过期，请重新登录", 401)

    data = request.get_json(silent=True) or {}
    keyword = (data.get('keyword') or '').strip()
    if not keyword:
        return make_success({"results": []})

    page = max(1, int(data.get('page', 1)))
    limit = min(50, max(1, int(data.get('limit', 20))))
    offset = (page - 1) * limit

    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "SELECT message_id, channel_id, channel_type, from_uid, "
                    "`timestamp`, payload, is_deleted "
                    "FROM message "
                    "WHERE (from_uid=%s OR channel_id IN ("
                    "  SELECT channel_id FROM channel_member WHERE uid=%s"
                    ")) "
                    "AND is_deleted=0 "
                    "AND payload LIKE %s "
                    "ORDER BY `timestamp` DESC "
                    "LIMIT %s OFFSET %s",
                    (uid, uid, f'%{keyword}%', limit, offset)
                )
                rows = cursor.fetchall()
                results = []
                for row in rows:
                    import json as _json
                    payload = {}
                    try:
                        payload = _json.loads(row['payload']) if row['payload'] else {}
                    except Exception:
                        pass
                    content = ''
                    msg_type = 1
                    if isinstance(payload, dict):
                        content = payload.get('content', '') or ''
                        msg_type = payload.get('type', 1) or 1
                    results.append({
                        "message_id": str(row.get('message_id', '')),
                        "channel_id": str(row.get('channel_id', '')),
                        "channel_type": row.get('channel_type', 1),
                        "from_uid": str(row.get('from_uid', '') or ''),
                        "content": content,
                        "type": msg_type,
                        "timestamp": int(row.get('timestamp', 0) or 0),
                    })
                return make_success({"results": results, "total": len(results)})
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"搜索消息异常: {e}", exc_info=True)
        return make_error(f"搜索失败: {str(e)}", 500)


# ==================== 全局搜索 ====================

@app.route('/v1/search/global', methods=['POST'])
def global_search():
    """全局跨会话搜索 - 返回好友、群聊、消息三类结果"""
    uid = get_current_uid()
    if not uid:
        return make_error("登录已过期，请重新登录", 401)

    data = request.get_json(silent=True) or {}
    keyword = (data.get('keyword') or '').strip()
    if not keyword:
        return make_success({"friends": [], "groups": [], "messages": []})

    page = max(1, int(data.get('page', 1)))
    size = min(50, max(1, int(data.get('size', 20))))
    offset = (page - 1) * size

    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                friends = []
                groups = []
                messages = []

                if page == 1:
                    cursor.execute(
                        "SELECT uid, name, avatar FROM `user` "
                        "WHERE uid IN ("
                        "  SELECT friend_uid FROM friend WHERE uid=%s"
                        ") AND name LIKE %s LIMIT 10",
                        (uid, f'%{keyword}%')
                    )
                    for row in cursor.fetchall():
                        friends.append({
                            "channel_id": row.get("uid", ""),
                            "name": row.get("name", ""),
                            "avatar": row.get("avatar"),
                            "channel_type": 1
                        })

                    cursor.execute(
                        "SELECT g.group_no, g.name, g.avatar "
                        "FROM `group` g "
                        "INNER JOIN group_member gm ON g.group_no = gm.group_no "
                        "WHERE gm.uid = %s AND g.name LIKE %s "
                        "GROUP BY g.group_no LIMIT 10",
                        (uid, f'%{keyword}%')
                    )
                    for row in cursor.fetchall():
                        groups.append({
                            "channel_id": row.get("group_no", ""),
                            "name": row.get("name", ""),
                            "avatar": row.get("avatar"),
                            "channel_type": 2
                        })

                content_types = data.get('content_types', [1, 3])
                placeholders = ','.join(['%s'] * len(content_types))
                cursor.execute(
                    "SELECT message_id, channel_id, channel_type, from_uid, "
                    "`timestamp`, payload "
                    "FROM message "
                    "WHERE (from_uid=%s OR channel_id IN ("
                    "  SELECT channel_id FROM channel_member WHERE uid=%s"
                    ")) AND is_deleted=0 "
                    "AND payload LIKE %s "
                    "ORDER BY `timestamp` DESC "
                    f"LIMIT %s OFFSET %s",
                    (uid, uid, f'%{keyword}%', size, offset)
                )
                import json as _json
                for row in cursor.fetchall():
                    payload = {}
                    try:
                        payload = _json.loads(row['payload']) if row['payload'] else {}
                    except Exception:
                        pass
                    content = ''
                    if isinstance(payload, dict):
                        content = payload.get('content', '') or ''

                    channel_name = ''
                    if row.get('channel_type') == 1:
                        cursor.execute(
                            "SELECT name FROM `user` WHERE uid=%s",
                            (row.get('from_uid', ''),)
                        )
                        u = cursor.fetchone()
                        channel_name = u.get('name', '') if u else ''
                    else:
                        cursor.execute(
                            "SELECT name FROM `group` WHERE group_no=%s",
                            (row.get('channel_id', ''),)
                        )
                        g = cursor.fetchone()
                        channel_name = g.get('name', '') if g else ''

                    cursor.execute(
                        "SELECT name, avatar FROM `user` WHERE uid=%s",
                        (row.get('from_uid', ''),)
                    )
                    sender = cursor.fetchone()

                    messages.append({
                        "message_id": str(row.get('message_id', '')),
                        "channel_id": str(row.get('channel_id', '')),
                        "channel_name": channel_name,
                        "from_uid": str(row.get('from_uid', '') or ''),
                        "from_name": sender.get('name', '') if sender else '',
                        "avatar": sender.get('avatar') if sender else None,
                        "content": content,
                        "created_at": str(row.get('timestamp', '')),
                        "order_seq": 0
                    })

                return make_success({
                    "friends": friends,
                    "groups": groups,
                    "messages": messages
                })
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"全局搜索异常: {e}", exc_info=True)
        return make_error(f"搜索失败: {str(e)}", 500)


# ==================== 收藏管理 ====================

def _ensure_favorite_table(cursor):
    cursor.execute(
        "CREATE TABLE IF NOT EXISTS `favorite` ("
        "`id` BIGINT AUTO_INCREMENT PRIMARY KEY, "
        "`uid` VARCHAR(40) NOT NULL, "
        "`type` INT DEFAULT 1, "
        "`content` TEXT, "
        "`extra` TEXT, "
        "`sender_name` VARCHAR(100) DEFAULT '', "
        "`from_conversation` VARCHAR(100) DEFAULT '', "
        "`created_at` BIGINT, "
        "INDEX `idx_uid` (`uid`)"
        ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
    )


@app.route('/v1/favorites', methods=['GET'])
def get_favorites():
    """获取用户收藏列表"""
    uid = get_current_uid()
    if not uid:
        return make_error("登录已过期，请重新登录", 401)

    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                _ensure_favorite_table(cursor)
                conn.commit()
                cursor.execute(
                    "SELECT id, type, content, extra, sender_name, "
                    "from_conversation, created_at "
                    "FROM favorite WHERE uid=%s ORDER BY created_at DESC",
                    (uid,)
                )
                rows = cursor.fetchall()
                items = []
                for row in rows:
                    items.append({
                        "id": row['id'],
                        "type": row.get('type', 1),
                        "content": row.get('content', '') or '',
                        "extra": row.get('extra', '') or '',
                        "sender_name": row.get('sender_name', '') or '',
                        "from_conversation": row.get('from_conversation', '') or '',
                        "created_at": row.get('created_at', 0) or 0,
                    })
                return make_success({"items": items})
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"获取收藏列表异常: {e}", exc_info=True)
        return make_error(f"获取收藏失败: {str(e)}", 500)


@app.route('/v1/favorites', methods=['POST'])
def add_favorite():
    """添加收藏"""
    uid = get_current_uid()
    if not uid:
        return make_error("登录已过期，请重新登录", 401)

    data = request.get_json(silent=True) or {}
    fav_type = int(data.get('type', 1))
    content = data.get('content', '')
    extra = data.get('extra', '')
    sender_name = data.get('sender_name', '')
    from_conversation = data.get('from_conversation', '')

    if not content:
        return make_error("收藏内容不能为空")

    try:
        import pymysql
        import time as _time
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                _ensure_favorite_table(cursor)
                ts = int(_time.time() * 1000)
                cursor.execute(
                    "INSERT INTO favorite (uid, type, content, extra, sender_name, "
                    "from_conversation, created_at) VALUES (%s, %s, %s, %s, %s, %s, %s)",
                    (uid, fav_type, content, extra, sender_name, from_conversation, ts)
                )
                conn.commit()
                fav_id = cursor.lastrowid
                return make_success({"id": fav_id, "message": "收藏成功"})
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"添加收藏异常: {e}", exc_info=True)
        return make_error(f"收藏失败: {str(e)}", 500)


@app.route('/v1/favorites/<int:fav_id>', methods=['DELETE'])
def delete_favorite(fav_id):
    """删除收藏"""
    uid = get_current_uid()
    if not uid:
        return make_error("登录已过期，请重新登录", 401)

    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                _ensure_favorite_table(cursor)
                cursor.execute(
                    "DELETE FROM favorite WHERE id=%s AND uid=%s",
                    (fav_id, uid)
                )
                conn.commit()
                if cursor.rowcount == 0:
                    return make_error("收藏不存在或已删除", 404)
                return make_success({"message": "删除成功"})
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"删除收藏异常: {e}", exc_info=True)
        return make_error(f"删除失败: {str(e)}", 500)


# ==================== 消息表情反应 ====================

@app.route('/v1/messages/react', methods=['POST'])
def react_message():
    """消息表情反应 - 代理到TangSeng的 /v1/reactions 接口"""
    uid = get_current_uid()
    if not uid:
        return make_error("登录已过期，请重新登录", 401)

    data = request.get_json(silent=True) or {}
    message_id = data.get('message_id', '')
    channel_id = data.get('channel_id', '')
    channel_type = data.get('channel_type', 1)
    emoji = data.get('emoji', '')

    if not message_id or not emoji:
        return make_error("message_id和emoji不能为空")

    token = get_wkim_token()
    if not token:
        return make_error("token不能为空", 401)

    try:
        headers = {"token": token, "Content-Type": "application/json"}
        payload = {
            "message_id": message_id,
            "channel_id": channel_id,
            "channel_type": channel_type,
            "emoji": emoji,
        }
        resp = requests.post(
            Config.wkim_url("/v1/reactions"),
            json=payload, headers=headers, timeout=10
        )
        if resp.status_code == 200:
            return make_success({"message": "操作成功"})
        else:
            logger.error(f"TangSeng反应接口失败: status={resp.status_code}, resp={resp.text[:200]}")
            return make_error(f"操作失败: {resp.text[:200]}", resp.status_code)
    except Exception as e:
        logger.error(f"消息反应异常: {e}", exc_info=True)
        return make_error(f"操作失败: {str(e)}", 500)


# ==================== 群公告管理 ====================

@app.route('/v1/groups/<group_no>/announcement', methods=['GET'])
def get_group_announcement(group_no):
    """获取群公告"""
    uid = get_current_uid()
    if not uid:
        return make_error("登录已过期，请重新登录", 401)

    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "SELECT notice FROM `group` WHERE group_no=%s LIMIT 1",
                    (group_no,)
                )
                row = cursor.fetchone()
                if not row:
                    return make_error("群不存在", 404)
                notice = row.get('notice', '') or ''
                return make_success({"notice": notice})
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"获取群公告异常: {e}", exc_info=True)
        return make_error(f"获取失败: {str(e)}", 500)


@app.route('/v1/groups/<group_no>/announcement', methods=['PUT'])
def update_group_announcement(group_no):
    """更新群公告 - 需群主或管理员权限"""
    uid = get_current_uid()
    if not uid:
        return make_error("登录已过期，请重新登录", 401)

    data = request.get_json(silent=True) or {}
    notice = (data.get('notice') or '').strip()
    if len(notice) > 300:
        return make_error("群公告不能超过300字")

    token = get_wkim_token()
    if not token:
        return make_error("token不能为空", 401)

    # 权限校验
    role = get_user_group_role(group_no, uid, token)
    if role != 1 and role != 2:
        return make_error("只有群主或管理员可以修改群公告", 403)

    try:
        # 通过TangSeng更新群信息（notice字段）
        headers = {"token": token, "Content-Type": "application/json"}
        resp = requests.put(
            Config.wkim_url(f"/v1/groups/{group_no}"),
            json={"notice": notice}, headers=headers, timeout=10
        )
        if resp.status_code != 200:
            logger.error(f"TangSeng更新群公告失败: status={resp.status_code}, resp={resp.text[:200]}")
            return make_error(f"更新失败: {resp.text[:200]}", resp.status_code)

        # 插入系统消息通知群成员
        if notice:
            sys_payload = {
                "type": 1000,
                "content": f"群公告已更新: {notice}",
                "extra": {"notice": notice, "operator": uid},
                "data": {"notice": notice},
            }
            _insert_system_message(group_no, uid, sys_payload)

        return make_success({"notice": notice, "message": "群公告更新成功"})
    except Exception as e:
        logger.error(f"更新群公告异常: {e}", exc_info=True)
        return make_error(f"更新失败: {str(e)}", 500)


# ==================== 设备管理 ====================

@app.route('/v1/user/devices', methods=['GET'])
def get_device_list():
    """获取当前用户已登录设备列表"""
    uid = get_current_uid()
    if not uid:
        return make_error("请先登录", 401)

    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "SELECT device_id, device_name, device_model, last_active, created_at "
                    "FROM user_device WHERE uid = %s ORDER BY last_active DESC",
                    (uid,)
                )
                rows = cursor.fetchall()

                current_device = request.headers.get('X-Device-Id', '')
                devices = []
                for row in rows:
                    is_current = (row.get('device_id') == current_device) if current_device else False
                    name = row.get('device_name') or row.get('device_model') or '未知设备'
                    info_parts = []
                    if row.get('device_model'):
                        info_parts.append(row['device_model'])
                    if row.get('last_active'):
                        info_parts.append(f"最近活跃: {row['last_active']}")
                    if is_current:
                        info_parts.append("当前设备")
                    info = ' - '.join(info_parts) if info_parts else ''
                    devices.append({
                        'device_id': row.get('device_id') or str(row.get('id', '')),
                        'name': name,
                        'info': info,
                        'is_current': is_current
                    })

                if not devices:
                    devices.append({
                        'device_id': 'local',
                        'name': '当前设备',
                        'info': '当前登录设备',
                        'is_current': True
                    })

                return make_success(devices)
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"获取设备列表异常: {e}")
        return make_success([{
            'device_id': 'local',
            'name': '当前设备',
            'info': '当前登录设备',
            'is_current': True
        }])


@app.route('/v1/user/devices/<device_id>', methods=['DELETE'])
def kick_device(device_id):
    """下线指定设备"""
    uid = get_current_uid()
    if not uid:
        return make_error("请先登录", 401)

    if device_id == 'local':
        return make_error("无法下线当前设备")

    try:
        import pymysql
        conn = pymysql.connect(
            host=Config.MYSQL_HOST, port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER, password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE, charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "DELETE FROM user_device WHERE uid = %s AND device_id = %s",
                    (uid, device_id)
                )
                conn.commit()
                if cursor.rowcount > 0:
                    logger.info(f"设备下线成功: uid={uid}, device_id={device_id}")
                    return make_success({"status": 200, "msg": "设备已下线"})
                return make_error("设备不存在或已下线")
        finally:
            conn.close()
    except Exception as e:
        logger.error(f"下线设备异常: {e}")
        return make_error("下线失败，请稍后重试")


if __name__ == '__main__':
    logger.info(f"服务启动: {Config.HOST}:{Config.PORT}")
    logger.info(f"Redis: {'已连接' if not isinstance(cache, MemoryCache) else '使用内存缓存(回退)'}")
    logger.info(f"阿里云SDK: {'已加载' if sms_service._available else '未加载'}")
    logger.info(f"短信签名: {'已配置' if Config.ALIYUN_SMS_SIGN_NAME else '未配置-请在config.py设置ALIYUN_SMS_SIGN_NAME'}")
    logger.info(f"Resend邮箱: {'已配置' if email_service._available else '未配置'}")
    logger.info(f"TRTC: {'已配置' if Config.TRTC_SDK_APP_ID and Config.TRTC_SECRET_KEY else '未配置-请在config.py或.env设置TRTC_SDK_APP_ID和TRTC_SECRET_KEY'}")
    app.run(host=Config.HOST, port=Config.PORT, debug=Config.DEBUG)

