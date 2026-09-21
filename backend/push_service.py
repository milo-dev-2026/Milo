"""
厂商推送服务模块（直连厂商通道）

功能：
1. 直接调用各厂商推送 REST API 发送推送通知（华为/小米/荣耀/OPPO/Vivo）
2. 从 Redis 查询用户设备 token 和设备类型（TangSeng 存储）
3. WuKongIM HTTP webhook 代理：转发事件给 TangSeng，同时发送离线推送
4. 根据 device_type 路由到对应厂商 API

各厂商推送服务端 API 文档：
- 华为: https://developer.huawei.com/consumer/cn/doc/HMS-References/push-sendmessage
- 小米: https://dev.mi.com/xpace/connect/push-server/api
- OPPO: https://open.oppomobile.com/new/developmentDoc/info?id=12968
- Vivo: https://dev.vivo.com.cn/documentCenter/doc/362
"""

import os
import json
import time
import hashlib
import hmac
import base64
import logging
import requests
import pymysql
from flask import Flask, request, jsonify

# 加载 .env 文件
try:
    from dotenv import load_dotenv
    load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), '.env'))
except ImportError:
    pass

logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.config['JSON_AS_ASCII'] = False

# ==================== 厂商推送配置 ====================
# 华为推送（JWT鉴权）
HUAWEI_APP_ID = os.getenv("HUAWEI_PUSH_APP_ID", "118943381")
HUAWEI_PROJECT_ID = os.getenv("HUAWEI_PUSH_PROJECT_ID", "")
HUAWEI_KEY_ID = os.getenv("HUAWEI_PUSH_KEY_ID", "")
HUAWEI_SUB_ACCOUNT = os.getenv("HUAWEI_PUSH_SUB_ACCOUNT", "")
HUAWEI_PRIVATE_KEY = os.getenv("HUAWEI_PUSH_PRIVATE_KEY", "")
HUAWEI_TOKEN_URL = "https://oauth-login.cloud.huawei.com/oauth2/v3/token"
HUAWEI_PUSH_URL = f"https://push-api.cloud.huawei.com/v3/{HUAWEI_PROJECT_ID}/messages:send"

# 小米推送
XIAOMI_APP_ID = os.getenv("XIAOMI_PUSH_APP_ID", "2882303761520580396")
XIAOMI_APP_KEY = os.getenv("XIAOMI_PUSH_APP_KEY", "5972058070396")
XIAOMI_APP_SECRET = os.getenv("XIAOMI_PUSH_APP_SECRET", "")
XIAOMI_PUSH_URL = "https://api.xmpush.xiaomi.com/v3/message/regid"

# OPPO推送
OPPO_APP_KEY = os.getenv("OPPO_PUSH_APP_KEY", "48d56cf2c6414d2fb824924a86282368")
OPPO_APP_SECRET = os.getenv("OPPO_PUSH_APP_SECRET", "24a9a6b614fb4809b12e1917b3019ca2")
OPPO_MASTER_SECRET = os.getenv("OPPO_PUSH_MASTER_SECRET", "")
OPPO_BASE_URL = "https://api-push-cn.heytapmobi.com"
OPPO_AUTH_URL = f"{OPPO_BASE_URL}/server/v1/auth"
OPPO_PUSH_URL = f"{OPPO_BASE_URL}/server/v1/message/notification/notify"

# Vivo推送
VIVO_APP_ID = os.getenv("VIVO_PUSH_APP_ID", "106147728")
VIVO_APP_KEY = os.getenv("VIVO_PUSH_APP_KEY", "c46cfdea94517a83e1c56524571979eb")
VIVO_APP_SECRET = os.getenv("VIVO_PUSH_APP_SECRET", "bb6502a6-f518-447d-8b94-e8c3e9b0f9d2")
VIVO_PUSH_URL = "https://api-push.vivo.com.cn/message/send"

# Redis 配置（TangSeng 存储设备 token）
REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
REDIS_PASSWORD = os.getenv("REDIS_PASSWORD", "")
REDIS_DB = int(os.getenv("REDIS_DB", 0))
USER_DEVICE_TOKEN_PREFIX = "userDeviceToken:"

# TangSeng HTTP webhook 地址（用于转发事件）
TANGSENG_WEBHOOK_URL = os.getenv("TANGSENG_WEBHOOK_URL", "http://tangsengdaodaoserver:8090/v1/webhook")

# IM 数据库配置（备用）
MYSQL_HOST = os.getenv("MYSQL_HOST", "mysql")
MYSQL_PORT = int(os.getenv("MYSQL_PORT", 3306))
MYSQL_USER = os.getenv("MYSQL_USER", "root")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "Abc123456!")
MYSQL_DATABASE = os.getenv("MYSQL_DATABASE", "im")

# 推送内容配置
APP_NAME = "闲雷虎虎"
NOTIFICATION_CHANNEL_ID = "160639"

# 小米推送模板配置（2026新规：私信消息必须使用模板）
# 官方模板（无需申请，直接使用）：
#   M12762 好友聊天: 标题"您有一条消息来自{$keywords1$}" 内容"{$keywords2$}"
#     keywords1=发送者名称, keywords2=消息内容
#   M12763 群聊消息: 标题"群聊有新消息来自{$keywords1$}" 内容"{$keywords2$}: {$keywords3$}"
#     keywords1=群名称, keywords2=发送者名称, keywords3=消息内容
#   M12771 群聊@提及: 标题"有人在群里@您" 内容"{$keywords1$}在{$keywords2$}中@了您"
#     keywords1=@你的人, keywords2=群名称
#   M12764 语音通话: 标题"语音通话邀请" 内容"{$keywords1$}邀请您进行语音通话"
#     keywords1=来电者名称
XIAOMI_TPL_FRIEND = os.getenv("XIAOMI_TPL_FRIEND", "M12762")
XIAOMI_TPL_GROUP = os.getenv("XIAOMI_TPL_GROUP", "M12763")
XIAOMI_TPL_MENTION = os.getenv("XIAOMI_TPL_MENTION", "M12771")
XIAOMI_TPL_CALL = os.getenv("XIAOMI_TPL_CALL", "M12764")
# 各模板对应的 channel_id（必须与模板的 channel_type 一致）
XIAOMI_CH_FRIEND = os.getenv("XIAOMI_CH_FRIEND", "160639")
XIAOMI_CH_GROUP = os.getenv("XIAOMI_CH_GROUP", "160640")
XIAOMI_CH_MENTION = os.getenv("XIAOMI_CH_MENTION", "160642")
XIAOMI_CH_CALL = os.getenv("XIAOMI_CH_CALL", "160641")
XIAOMI_CHANNEL_ID = os.getenv("XIAOMI_PUSH_CHANNEL_ID", XIAOMI_CH_FRIEND)

# 模板 -> channel_id 映射
XIAOMI_TPL_CHANNEL_MAP = {
    XIAOMI_TPL_FRIEND: XIAOMI_CH_FRIEND,
    XIAOMI_TPL_GROUP: XIAOMI_CH_GROUP,
    XIAOMI_TPL_MENTION: XIAOMI_CH_MENTION,
    XIAOMI_TPL_CALL: XIAOMI_CH_CALL,
}

# OAuth2 token 缓存
_token_cache = {}

# Redis 连接（懒加载）
_redis_client = None
_redis_fail_time = 0
_REDIS_RETRY_INTERVAL = 30  # 失败后30秒才重试


def get_redis():
    """获取 Redis 连接（失败后会定期重试）"""
    global _redis_client, _redis_fail_time
    now = time.time()
    if _redis_client is not None:
        try:
            _redis_client.ping()
            return _redis_client
        except Exception:
            _redis_client = None
    if _redis_client is None and (now - _redis_fail_time) < _REDIS_RETRY_INTERVAL:
        return None
    try:
        import redis as redis_lib
        _redis_client = redis_lib.Redis(
            host=REDIS_HOST,
            port=REDIS_PORT,
            password=REDIS_PASSWORD or None,
            db=REDIS_DB,
            decode_responses=True,
            socket_connect_timeout=5,
            socket_keepalive=True
        )
        _redis_client.ping()
        logger.info(f"Redis 连接成功: {REDIS_HOST}:{REDIS_PORT}")
    except Exception as e:
        logger.error(f"Redis 连接失败: {e}")
        _redis_client = None
        _redis_fail_time = now
    return _redis_client


def get_device_token_from_redis(uid):
    """从 Redis 查询用户的设备推送 token（TangSeng 存储格式）"""
    r = get_redis()
    if not r:
        return None
    try:
        key = f"{USER_DEVICE_TOKEN_PREFIX}{uid}"
        data = r.hgetall(key)
        if data and data.get("device_token"):
            return {
                "device_token": data.get("device_token"),
                "device_type": data.get("device_type", ""),
                "bundle_id": data.get("bundle_id", "")
            }
        return None
    except Exception as e:
        logger.error(f"从Redis查询设备token失败: uid={uid}, error={e}")
        return None


def get_mysql_conn():
    return pymysql.connect(
        host=MYSQL_HOST,
        port=MYSQL_PORT,
        user=MYSQL_USER,
        password=MYSQL_PASSWORD,
        database=MYSQL_DATABASE,
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor
    )


def get_device_token_from_mysql(uid):
    """从 MySQL 查询设备 token（备用）"""
    conn = None
    try:
        conn = get_mysql_conn()
        cursor = conn.cursor()
        cursor.execute(
            "SELECT device_token, device_type, bundle_id FROM device_token WHERE uid = %s ORDER BY created_at DESC LIMIT 1",
            (uid,)
        )
        row = cursor.fetchone()
        return row
    except Exception as e:
        logger.error(f"MySQL查询设备token失败: uid={uid}, error={e}")
        return None
    finally:
        if conn:
            try:
                conn.close()
            except Exception:
                pass


def get_device_token_by_uid(uid):
    """查询用户设备 token（优先 Redis，失败则 MySQL）"""
    # 优先从 Redis 查询（TangSeng 存储）
    token_info = get_device_token_from_redis(uid)
    if token_info:
        return token_info
    # 降级到 MySQL
    return get_device_token_from_mysql(uid)


# ==================== 华为推送（JWT鉴权） ====================

def _generate_huawei_jwt():
    """基于服务账号密钥生成 JWT 鉴权令牌"""
    if not all([HUAWEI_KEY_ID, HUAWEI_SUB_ACCOUNT, HUAWEI_PRIVATE_KEY]):
        return None

    import jwt as pyjwt
    from cryptography.hazmat.primitives import serialization

    private_key_pem = HUAWEI_PRIVATE_KEY.replace('\\n', '\n')
    private_key = serialization.load_pem_private_key(private_key_pem.encode(), password=None)

    now = int(time.time())
    payload = {
        "aud": HUAWEI_TOKEN_URL,
        "iss": HUAWEI_SUB_ACCOUNT,
        "exp": now + 3600,
        "iat": now
    }
    header = {
        "kid": HUAWEI_KEY_ID,
        "typ": "JWT",
        "alg": "PS256"
    }
    return pyjwt.encode(payload=payload, key=private_key, algorithm="PS256", headers=header)


def send_huawei_push(device_token, title, text, extras=None):
    """通过华为 Push Kit V3 API 发送推送"""
    if not HUAWEI_PROJECT_ID:
        return False, "华为推送配置未完善"
    jwt_token = _generate_huawei_jwt()
    if not jwt_token:
        return False, "华为JWT参数未配置"

    message = {
        "payload": {
            "notification": {
                "category": "IM",
                "title": title,
                "body": text,
                "clickAction": {"actionType": 0},
                "foregroundShow": True,
                "notifyId": int(time.time()) % 100000
            },
            "data": json.dumps(extras or {})
        },
        "target": {
            "token": [device_token]
        },
        "pushOptions": {
            "testMessage": os.getenv("HUAWEI_PUSH_TEST_MESSAGE", "false").lower() == "true",
            "ttl": 86400
        }
    }
    headers = {
        "Authorization": f"Bearer {jwt_token}",
        "Content-Type": "application/json",
        "push-type": "0"
    }
    try:
        resp = requests.post(HUAWEI_PUSH_URL, json=message, headers=headers, timeout=10)
        result = resp.json()
        if resp.status_code == 200 and result.get("code") == "80000000":
            logger.info(f"华为推送成功: token={device_token[:20]}...")
            return True, result
        else:
            logger.error(f"华为推送失败: code={resp.status_code}, result={result}")
            return False, json.dumps(result, ensure_ascii=False)
    except Exception as e:
        logger.error(f"华为推送异常: {e}")
        return False, str(e)


# ==================== 小米推送 ====================

def send_xiaomi_push(device_token, title, text, extras=None, package_name=None, template_params=None, template_id=None):
    """通过小米推送 API 发送推送（2026新规：私信消息必须使用模板）
    template_params: 模板变量字典，如 {"keywords1": "张三", "keywords2": "吃了吗"}
    template_id: 指定模板ID，不传则用好友聊天默认模板
    """
    if not XIAOMI_APP_SECRET:
        return False, "小米推送配置未完善"

    tpl_id = template_id or XIAOMI_TPL_FRIEND
    ch_id = XIAOMI_TPL_CHANNEL_MAP.get(tpl_id, XIAOMI_CH_FRIEND)
    tp = template_params or {}
    params = {
        "registration_id": device_token,
        "title": title,
        "description": text,
        "payload": json.dumps(extras or {}),
        "notify_type": 1,
        "restricted_package_name": package_name or "com.xian.leihuhu",
        "extra.channel_id": ch_id,
        "extra.template_id": tpl_id,
        "extra.template_param": json.dumps(tp, ensure_ascii=False) if tp else "{}"
    }
    headers = {
        "X-XIAOMI-PUSH-APP-ID": XIAOMI_APP_ID,
        "Authorization": f"key={XIAOMI_APP_SECRET}",
        "Content-Type": "application/x-www-form-urlencoded"
    }
    try:
        resp = requests.post(XIAOMI_PUSH_URL, data=params, headers=headers, timeout=10)
        result = resp.json()
        if resp.status_code == 200 and result.get("code") == 0:
            logger.info(f"小米推送成功: template={tpl_id}, token={device_token[:20]}...")
            return True, result
        else:
            logger.error(f"小米推送失败: template={tpl_id}, code={result.get('code')}, reason={result.get('reason')}")
            return False, json.dumps(result, ensure_ascii=False)
    except Exception as e:
        logger.error(f"小米推送异常: {e}")
        return False, str(e)


# ==================== OPPO推送 ====================

def get_oppo_token():
    """获取 OPPO 推送 auth_token"""
    cache_key = "oppo"
    cached = _token_cache.get(cache_key)
    if cached and cached["expire_time"] > time.time():
        return cached["token"]

    timestamp = str(int(time.time() * 1000))
    sign_str = OPPO_APP_KEY + timestamp + OPPO_MASTER_SECRET
    sign = hashlib.sha256(sign_str.encode('utf-8')).hexdigest()
    params = {
        "app_key": OPPO_APP_KEY,
        "sign": sign,
        "timestamp": timestamp
    }
    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    try:
        resp = requests.post(OPPO_AUTH_URL, data=params, headers=headers, timeout=10)
        result = resp.json()
        if result.get("code") == 0:
            token = result["data"]["auth_token"]
            _token_cache[cache_key] = {
                "token": token,
                "expire_time": time.time() + 82800
            }
            return token
        else:
            logger.error(f"获取OPPO token失败: {result}")
    except Exception as e:
        logger.error(f"获取OPPO token失败: {e}")
    return None


def send_oppo_push(device_token, title, text, extras=None):
    """通过 OPPO Push API 发送推送"""
    if not OPPO_APP_KEY or not OPPO_MASTER_SECRET:
        return False, "OPPO推送配置未完善"

    access_token = get_oppo_token()
    if not access_token:
        return False, "获取OPPO access_token失败"

    params = {
        "app_key": OPPO_APP_KEY,
        "registration_id": device_token,
        "title": title,
        "content": text,
        "channel_id": NOTIFICATION_CHANNEL_ID,
        "action_parameters": json.dumps(extras or {})
    }
    headers = {
        "auth_token": access_token,
        "Content-Type": "application/x-www-form-urlencoded"
    }
    try:
        resp = requests.post(OPPO_PUSH_URL, data=params, headers=headers, timeout=10)
        result = resp.json()
        if result.get("code") == 0:
            logger.info(f"OPPO推送成功: token={device_token[:20]}...")
            return True, result
        else:
            logger.error(f"OPPO推送失败: result={result}")
            return False, json.dumps(result, ensure_ascii=False)
    except Exception as e:
        logger.error(f"OPPO推送异常: {e}")
        return False, str(e)


# ==================== Vivo推送 ====================

def send_vivo_push(device_token, title, text, extras=None):
    """通过 Vivo Push API 发送推送"""
    if not VIVO_APP_ID or not VIVO_APP_KEY or not VIVO_APP_SECRET:
        return False, "Vivo推送配置未完善"

    sign_str = VIVO_APP_ID + VIVO_APP_KEY + VIVO_APP_SECRET
    sign = hashlib.md5(sign_str.encode('utf-8')).hexdigest().upper()
    params = {
        "appId": VIVO_APP_ID,
        "appKey": VIVO_APP_KEY,
        "sign": sign,
        "regId": device_token,
        "notifyType": 1,
        "title": title,
        "content": text,
        "requestId": str(int(time.time() * 1000)),
        "extra": json.dumps({"channel_id": NOTIFICATION_CHANNEL_ID, **(extras or {})})
    }
    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    try:
        resp = requests.post(VIVO_PUSH_URL, data=params, headers=headers, timeout=10)
        result = resp.json()
        if result.get("code") == 0:
            logger.info(f"Vivo推送成功: token={device_token[:20]}...")
            return True, result
        else:
            logger.error(f"Vivo推送失败: result={result}")
            return False, json.dumps(result, ensure_ascii=False)
    except Exception as e:
        logger.error(f"Vivo推送异常: {e}")
        return False, str(e)


# ==================== APNs (iOS) 推送 ====================

APNS_KEY_ID = os.getenv("APNS_KEY_ID", "__PLACEHOLDER_APNS_KEY_ID__")
APNS_TEAM_ID = os.getenv("APNS_TEAM_ID", "__PLACEHOLDER_APNS_TEAM_ID__")
APNS_KEY_PATH = os.getenv("APNS_KEY_PATH", "__PLACEHOLDER_APNS_KEY_PATH__")
APNS_BUNDLE_ID = os.getenv("APNS_BUNDLE_ID", "com.xian.leihuhu")
APNS_PRODUCTION = os.getenv("APNS_PRODUCTION", "false").lower() == "true"


def get_apns_token():
    """获取 APNs JWT token (有效期1小时)"""
    import datetime
    cached = _token_cache.get("apns")
    if cached and cached.get("expires_at", 0) > time.time() + 60:
        return cached["token"]

    try:
        from cryptography.hazmat.primitives import serialization
        from cryptography.hazmat.primitives.asymmetric import ec
        from cryptography.hazmat.backends import default_backend
        import jwt as pyjwt
    except ImportError:
        logger.error("APNs推送需要 PyJWT 和 cryptography 库: pip install PyJWT cryptography")
        return None

    try:
        with open(APNS_KEY_PATH, 'rb') as f:
            key_data = f.read()
        secret_key = serialization.load_pem_private_key(
            key_data, password=None, backend=default_backend()
        )

        now = datetime.datetime.utcnow()
        payload = {
            "iss": APNS_TEAM_ID,
            "iat": int(now.timestamp()),
            "exp": int((now + datetime.timedelta(hours=1)).timestamp()),
            "aud": "https://appleid.apple.com",
            "sub": f"com.xian.leihuhu"
        }

        headers = {
            "alg": "ES256",
            "kid": APNS_KEY_ID,
            "typ": "JWT"
        }

        token = pyjwt.encode(payload, secret_key, algorithm="ES256", headers=headers)
        if isinstance(token, bytes):
            token = token.decode('utf-8')

        _token_cache["apns"] = {
            "token": token,
            "expires_at": int((now + datetime.timedelta(minutes=50)).timestamp())
        }
        logger.info("APNs JWT token 获取成功")
        return token
    except Exception as e:
        logger.error(f"APNs JWT token 获取失败: {e}")
        return None


def send_apns_push(device_token, title, text, extras=None):
    """发送 APNs 推送通知 (iOS设备)"""
    if "__PLACEHOLDER" in APNS_KEY_ID or "__PLACEHOLDER" in APNS_KEY_PATH:
        logger.warning("APNs推送未配置: 请设置APNS_KEY_ID和APNS_KEY_PATH")
        return False, "APns not configured"

    jwt_token = get_apns_token()
    if not jwt_token:
        return False, "Failed to get APNs JWT token"

    host = "api.push.apple.com" if APNS_PRODUCTION else "api.sandbox.push.apple.com"
    url = f"https://{host}/3/device/{device_token}"

    payload = {
        "aps": {
            "alert": {
                "title": title,
                "body": text
            },
            "sound": "default",
            "mutable-content": 1
        }
    }
    if extras:
        payload["extras"] = extras

    headers = {
        "authorization": f"bearer {jwt_token}",
        "apns-topic": APNS_BUNDLE_ID,
        "apns-push-type": "alert",
        "apns-priority": "10"
    }

    try:
        resp = requests.post(
            url,
            json=payload,
            headers=headers,
            timeout=10
        )
        if resp.status_code == 200:
            logger.info(f"APNs推送成功: token={device_token[:20]}...")
            return True, "success"
        else:
            error_msg = resp.headers.get("x-Apple-error-description", f"HTTP {resp.status_code}")
            logger.error(f"APNs推送失败: status={resp.status_code}, error={error_msg}")
            if resp.status_code == 410:
                logger.warning("APNs device token已失效，需重新注册")
            return False, error_msg
    except Exception as e:
        logger.error(f"APNs推送异常: {e}")
        return False, str(e)


# ==================== 推送路由 ====================

def send_push_by_device_type(device_token, device_type, title, text, extras=None, package_name=None, template_params=None, template_id=None):
    """根据设备类型路由到对应厂商推送 API"""
    dt = (device_type or "").lower()

    if dt in ("hms", "service-华为", "华为", "huawei"):
        return send_huawei_push(device_token, title, text, extras)
    elif dt in ("mi", "小米", "xiaomi"):
        return send_xiaomi_push(device_token, title, text, extras, package_name, template_params, template_id)
    elif dt in ("oppo", "service-oppo"):
        return send_oppo_push(device_token, title, text, extras)
    elif dt in ("vivo", "service-vivo"):
        return send_vivo_push(device_token, title, text, extras)
    elif dt in ("ios", "apns", "apple"):
        return send_apns_push(device_token, title, text, extras)
    else:
        logger.warning(f"未知设备类型: device_type={device_type}, 尝试小米推送")
        return send_xiaomi_push(device_token, title, text, extras, package_name, template_params, template_id)


# ==================== WuKongIM Webhook 代理 ====================

def decode_payload(payload_b64):
    """解码 base64 的消息 payload，提取文本内容"""
    if not payload_b64:
        return "[新消息]"
    try:
        decoded = base64.b64decode(payload_b64).decode('utf-8')
        data = json.loads(decoded)
        if isinstance(data, dict):
            return data.get("content", str(data))
        return str(data)
    except Exception as e1:
        try:
            return base64.b64decode(payload_b64).decode('utf-8')
        except Exception as e2:
            logger.warning(f"payload 解码失败: error1={e1}, error2={e2}, payload_len={len(payload_b64)}")
            return "[新消息]"


def send_offline_push_for_uids(to_uids, from_uid, payload_b64, channel_id, channel_type):
    """为离线用户发送推送通知"""
    results = []
    for uid in to_uids:
        try:
            device_info = get_device_token_by_uid(uid)
            if not device_info:
                logger.warning(f"离线推送: 未找到用户设备token, uid={uid}")
                results.append({"uid": uid, "status": "no_device"})
                continue

            device_token = device_info.get("device_token")
            device_type = device_info.get("device_type", "")
            bundle_id = device_info.get("bundle_id", "")

            if not device_token:
                results.append({"uid": uid, "status": "no_token"})
                continue

            # 解析消息内容
            content = decode_payload(payload_b64)
            if len(content) > 50:
                content = content[:50] + "..."

            # 获取发送者名称
            from_name = "好友"
            group_name = channel_id or "群聊"

            extras = {
                "uid": uid,
                "from_uid": from_uid,
                "channel_id": channel_id,
                "channel_type": channel_type
            }

            # 根据消息类型选择对应小米模板和变量
            if channel_type == 2:  # 群聊 -> M12763
                tpl_id = XIAOMI_TPL_GROUP
                template_params = {
                    "keywords1": group_name,
                    "keywords2": from_name,
                    "keywords3": content
                }
                alert_text = f"{from_name}: {content}"
            else:  # 单聊 -> M12762
                tpl_id = XIAOMI_TPL_FRIEND
                template_params = {
                    "keywords1": from_name,
                    "keywords2": content
                }
                alert_text = f"{from_name}: {content}"

            success, result = send_push_by_device_type(
                device_token, device_type, APP_NAME, alert_text, extras, bundle_id, template_params, tpl_id
            )
            results.append({
                "uid": uid,
                "device_type": device_type,
                "status": "success" if success else "failed",
                "result": str(result)[:100] if not success else "ok"
            })
        except Exception as e:
            logger.error(f"离线推送异常: uid={uid}, error={e}")
            results.append({"uid": uid, "status": "error", "error": str(e)})

    return results


@app.route('/wukongim/webhook', methods=['POST'])
def wukongim_webhook():
    """
    WuKongIM HTTP Webhook 代理接口
    
    功能：
    1. 接收 WuKongIM 的 webhook 事件
    2. 转发给 TangSeng 处理业务逻辑
    3. 对于离线消息事件，额外发送厂商推送通知
    
    WuKongIM HTTP webhook 格式：
    - URL query: event=xxx (如 msg.offline, msg.notify)
    - Body: JSON payload
    """
    event_type = request.args.get('event', '')
    raw_data = request.get_data(as_text=True)
    
    logger.info(f"收到 WuKongIM webhook 事件: event={event_type}, body_len={len(raw_data)}")
    
    # Step 1: 转发给 TangSeng 处理业务逻辑
    tangseng_status = 200
    tangseng_result = ""
    try:
        ts_url = f"{TANGSENG_WEBHOOK_URL}?event={event_type}"
        headers = {"Content-Type": request.content_type or "application/json"}
        
        # TangSeng 的 HTTP webhook 要求 msg.offline 事件有 type 字段
        # 如果 WuKongIM 发来的请求没有 type，补充一个默认值
        forward_data = raw_data.encode('utf-8')
        if event_type == 'msg.offline':
            try:
                data_obj = json.loads(raw_data)
                if 'type' not in data_obj:
                    data_obj['type'] = 1  # 默认文本消息类型
                    forward_data = json.dumps(data_obj).encode('utf-8')
                    logger.debug(f"补充 type 字段后转发给 TangSeng")
            except Exception:
                pass
        
        resp = requests.post(ts_url, data=forward_data, headers=headers, timeout=10)
        tangseng_status = resp.status_code
        tangseng_result = resp.text
        logger.info(f"转发到 TangSeng: status={tangseng_status}, event={event_type}")
    except Exception as e:
        logger.error(f"转发到 TangSeng 失败: event={event_type}, error={e}")
        tangseng_status = 502
        tangseng_result = str(e)
    
    # Step 2: 处理离线消息推送
    push_results = []
    if event_type == 'msg.offline':
        try:
            data = request.get_json(silent=True) or {}
            to_uids = data.get("to_uids", [])
            from_uid = data.get("from_uid", "")
            payload_b64 = data.get("payload", "")
            channel_id = data.get("channel_id", "")
            channel_type = data.get("channel_type", 1)
            
            if to_uids:
                logger.info(f"离线消息推送: from={from_uid}, to_count={len(to_uids)}, channel={channel_id}")
                push_results = send_offline_push_for_uids(
                    to_uids, from_uid, payload_b64, channel_id, channel_type
                )
        except Exception as e:
            logger.error(f"处理离线推送异常: event={event_type}, error={e}")
    
    # 返回响应（优先返回 TangSeng 的响应，确保 WuKongIM 知道处理结果）
    if tangseng_status == 200:
        return jsonify({
            "status": 200,
            "push_results": push_results,
            "tangseng_forwarded": True
        }), 200
    else:
        # TangSeng 失败了，但推送可能成功了
        logger.warning(f"TangSeng 转发失败但继续返回成功以避免 WuKongIM 重试: event={event_type}")
        return jsonify({
            "status": 200,
            "push_results": push_results,
            "tangseng_forwarded": False,
            "tangseng_error": tangseng_result[:200]
        }), 200


# ==================== HTTP 接口 ====================

@app.route('/push/offline_notify', methods=['POST'])
def offline_notify():
    """
    离线消息通知接口（手动调用）
    """
    data = request.get_json(silent=True) or {}
    if not data:
        return jsonify({"code": 400, "msg": "参数错误"}), 400

    uid = data.get("uid")
    from_name = data.get("from_name", "新消息")
    content = data.get("content", "你有一条新消息")
    message_type = data.get("message_type", "text")
    push_scene = data.get("push_scene", "friend")  # friend/group/mention/call

    if not uid:
        return jsonify({"code": 400, "msg": "uid不能为空"}), 400

    device_info = get_device_token_by_uid(uid)
    if not device_info:
        logger.warning(f"未找到用户设备token: uid={uid}")
        return jsonify({"code": 404, "msg": "未找到设备token"}), 404

    device_token = device_info.get("device_token")
    device_type = device_info.get("device_type")
    bundle_id = device_info.get("bundle_id")
    if not device_token:
        return jsonify({"code": 404, "msg": "device_token为空"}), 404

    if message_type == "image":
        template_kw2 = "发送了一张图片"
    elif message_type == "voice":
        template_kw2 = "发送了一条语音"
    elif message_type == "video":
        template_kw2 = "发送了一段视频"
    elif message_type == "location":
        template_kw2 = "发送了一个位置"
    else:
        template_kw2 = content

    if len(template_kw2) > 50:
        template_kw2 = template_kw2[:50] + "..."

    extras = {
        "uid": uid,
        "from_uid": data.get("from_uid", ""),
        "from_name": from_name,
        "message_id": data.get("message_id", ""),
        "message_type": message_type
    }

    # 根据推送场景选择模板
    group_name = data.get("group_name", "群聊")
    if push_scene == "call":
        tpl_id = XIAOMI_TPL_CALL
        template_params = {"keywords1": from_name}
        alert_text = f"{from_name}邀请您进行语音通话"
    elif push_scene == "mention":
        tpl_id = XIAOMI_TPL_MENTION
        template_params = {"keywords1": from_name, "keywords2": group_name}
        alert_text = f"{from_name}在{group_name}中@了您"
    elif push_scene == "group":
        tpl_id = XIAOMI_TPL_GROUP
        template_params = {"keywords1": group_name, "keywords2": from_name, "keywords3": template_kw2}
        alert_text = f"{from_name}: {content}"
    else:
        tpl_id = XIAOMI_TPL_FRIEND
        template_params = {"keywords1": from_name, "keywords2": template_kw2}
        alert_text = f"{from_name}: {content}"

    success, result = send_push_by_device_type(device_token, device_type, APP_NAME, alert_text, extras, bundle_id, template_params, tpl_id)

    if success:
        return jsonify({"code": 200, "msg": "推送成功", "data": result}), 200
    else:
        return jsonify({"code": 500, "msg": "推送失败", "error": result}), 500


@app.route('/push/send', methods=['POST'])
def send_push():
    """手动测试推送接口"""
    data = request.get_json(silent=True) or {}
    if not data:
        return jsonify({"code": 400, "msg": "参数错误"}), 400

    device_token = data.get("device_token")
    device_type = data.get("device_type", "mi")
    title = data.get("title", APP_NAME)
    text = data.get("text", "测试推送")
    extras = data.get("extras", {})
    package_name = data.get("package_name")
    template_params = data.get("template_params")
    template_id = data.get("template_id")

    if not device_token:
        return jsonify({"code": 400, "msg": "device_token不能为空"}), 400

    success, result = send_push_by_device_type(device_token, device_type, title, text, extras, package_name, template_params, template_id)

    if success:
        return jsonify({"code": 200, "msg": "推送成功", "data": result}), 200
    else:
        return jsonify({"code": 500, "msg": "推送失败", "error": result}), 500


@app.route('/push/health', methods=['GET'])
def health_check():
    redis_ok = False
    try:
        r = get_redis()
        if r:
            redis_ok = r.ping()
    except Exception:
        pass

    return jsonify({
        "code": 200,
        "msg": "ok",
        "service": "manufacturer-push-service",
        "redis": "connected" if redis_ok else "disconnected",
        "tangseng_webhook": TANGSENG_WEBHOOK_URL,
        "configured": {
            "huawei": bool(HUAWEI_PRIVATE_KEY),
            "xiaomi": bool(XIAOMI_APP_SECRET),
            "oppo": bool(OPPO_MASTER_SECRET),
            "vivo": bool(VIVO_APP_SECRET)
        }
    })


if __name__ == '__main__':
    port = int(os.getenv("PUSH_SERVICE_PORT", 5002))
    logger.info(f"厂商推送服务启动，端口: {port}")
    logger.info(f"Redis: {REDIS_HOST}:{REDIS_PORT}")
    logger.info(f"TangSeng Webhook: {TANGSENG_WEBHOOK_URL}")
    logger.info(f"华为推送: {'已配置' if HUAWEI_PRIVATE_KEY else '未配置'}")
    logger.info(f"小米推送: {'已配置' if XIAOMI_APP_SECRET else '未配置'}")
    logger.info(f"小米模板: 好友聊天={XIAOMI_TPL_FRIEND} 群聊消息={XIAOMI_TPL_GROUP} 群聊@提及={XIAOMI_TPL_MENTION} 语音通话={XIAOMI_TPL_CALL} (channel: {XIAOMI_CHANNEL_ID})")
    logger.info(f"OPPO推送: {'已配置' if OPPO_MASTER_SECRET else '未配置'}")
    logger.info(f"Vivo推送: {'已配置' if VIVO_APP_SECRET else '未配置'}")
    app.run(host='0.0.0.0', port=port, debug=os.getenv("PUSH_SERVICE_DEBUG", "false").lower() == "true")
