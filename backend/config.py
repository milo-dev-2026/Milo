import os

# 尝试加载 .env 文件（如果存在）
try:
    from dotenv import load_dotenv
    load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), '.env'))
except ImportError:
    pass


class Config:
    # ==================== 阿里云号码认证服务配置 ====================
    # 阿里云AccessKey
    ALIYUN_ACCESS_KEY_ID = os.getenv("ALIYUN_ACCESS_KEY_ID", "")
    ALIYUN_ACCESS_KEY_SECRET = os.getenv("ALIYUN_ACCESS_KEY_SECRET", "")

    # 阿里云号码认证服务API端点
    ALIYUN_DYPNS_ENDPOINT = "dypnsapi.aliyuncs.com"

    # 短信签名名称 - 在号码认证控制台 -> 赠送签名配置页面获取
    ALIYUN_SMS_SIGN_NAME = os.getenv("ALIYUN_SMS_SIGN_NAME", "恒创联众")

    # 短信模板CODE - 默认赠送模板编号为 100001
    ALIYUN_SMS_TEMPLATE_CODE = os.getenv("ALIYUN_SMS_TEMPLATE_CODE", "100001")

    # ==================== Redis配置 ====================
    REDIS_HOST = os.getenv("REDIS_HOST", "127.0.0.1")
    REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
    REDIS_PASSWORD = os.getenv("REDIS_PASSWORD", "")
    REDIS_DB = int(os.getenv("REDIS_DB", 0))

    # ==================== MySQL配置（8090悟空IM数据库） ====================
    MYSQL_HOST = os.getenv("MYSQL_HOST", "172.19.0.5")
    MYSQL_PORT = int(os.getenv("MYSQL_PORT", 3306))
    MYSQL_USER = os.getenv("MYSQL_USER", "root")
    MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "Abc123456!")
    MYSQL_DATABASE = os.getenv("MYSQL_DATABASE", "im")

    # ==================== 验证码配置 ====================
    CODE_LENGTH = 6
    CODE_VALID_TIME = 300
    CODE_TEMPLATE_VAR = "code"
    CODE_VALID_DISPLAY = "5"

    # ==================== 频控配置 (阿里云默认阈值) ====================
    SMS_SEND_INTERVAL = 60
    SMS_HOURLY_LIMIT = 5

    # ==================== IP限流配置 ====================
    REGISTER_IP_HOURLY_LIMIT = 5

    # ==================== 登录防暴力破解配置 ====================
    LOGIN_FAIL_MAX = 5
    LOGIN_FAIL_WINDOW = 900  # 15分钟窗口
    LOGIN_LOCK_DURATION = 1800  # 锁定30分钟

    # ==================== Resend邮箱服务配置 ====================
    RESEND_API_KEY = os.getenv("RESEND_API_KEY", "")
    RESEND_FROM_EMAIL = os.getenv("RESEND_FROM_EMAIL", "noreply@xn--y71aa709j.cc")
    RESEND_FROM_NAME = os.getenv("RESEND_FROM_NAME", "雷虎虎")
    RESEND_API_URL = "https://api.resend.com/emails"

    # ==================== 缓存Key前缀配置 ====================
    SMS_KEY_PREFIX = "sms:"
    EMAIL_KEY_PREFIX = "email:"

    BIZ_REGISTER = "register:"
    BIZ_LOGIN = "login:"
    BIZ_RESET_PWD = "resetpwd:"
    BIZ_BIND = "bind:"
    BIZ_DESTROY = "destroy:"

    # ==================== 服务配置 ====================
    HOST = os.getenv("HOST", "0.0.0.0")
    PORT = int(os.getenv("PORT", 5001))
    DEBUG = os.getenv("DEBUG", "false").lower() == "true"

    # ==================== WuKongIM服务器配置 ====================
    # IM服务器地址（后端直连IM服务器，不经过nginx）
    WKIM_HOST = os.getenv("WKIM_HOST", "127.0.0.1")
    WKIM_PORT = int(os.getenv("WKIM_PORT", 8091))

    @classmethod
    def wkim_url(cls, path):
        """构造WuKongIM服务器完整URL"""
        return f"http://{cls.WKIM_HOST}:{cls.WKIM_PORT}{path}"

    # ==================== 厂商推送配置（直连厂商通道） ====================
    PUSH_SERVICE_PORT = int(os.getenv("PUSH_SERVICE_PORT", 5002))

    # 华为推送 API
    HUAWEI_PUSH_APP_ID = os.getenv("HUAWEI_PUSH_APP_ID", "118943381")
    HUAWEI_PUSH_APP_SECRET = os.getenv("HUAWEI_PUSH_APP_SECRET", "")

    # 小米推送 API
    XIAOMI_PUSH_APP_ID = os.getenv("XIAOMI_PUSH_APP_ID", "2882303761520580396")
    XIAOMI_PUSH_APP_KEY = os.getenv("XIAOMI_PUSH_APP_KEY", "5972058070396")
    XIAOMI_PUSH_APP_SECRET = os.getenv("XIAOMI_PUSH_APP_SECRET", "")

    # 荣耀推送 API
    HONOR_PUSH_APP_ID = os.getenv("HONOR_PUSH_APP_ID", "")
    HONOR_PUSH_APP_SECRET = os.getenv("HONOR_PUSH_APP_SECRET", "")

    # OPPO推送 API
    OPPO_PUSH_APP_KEY = os.getenv("OPPO_PUSH_APP_KEY", "48d56cf2c6414d2fb824924a86282368")
    OPPO_PUSH_APP_SECRET = os.getenv("OPPO_PUSH_APP_SECRET", "24a9a6b614fb4809b12e1917b3019ca2")
    OPPO_PUSH_MASTER_SECRET = os.getenv("OPPO_PUSH_MASTER_SECRET", "")

    # Vivo推送 API
    VIVO_PUSH_APP_ID = os.getenv("VIVO_PUSH_APP_ID", "106147728")
    VIVO_PUSH_APP_KEY = os.getenv("VIVO_PUSH_APP_KEY", "c46cfdea94517a83e1c56524571979eb")
    VIVO_PUSH_APP_SECRET = os.getenv("VIVO_PUSH_APP_SECRET", "bb6502a6-f518-447d-8b94-e8c3e9b0f9d2")

    # ==================== 腾讯云COS配置 ====================
    COS_SECRET_ID = os.getenv("COS_SECRET_ID", "")
    COS_SECRET_KEY = os.getenv("COS_SECRET_KEY", "")
    COS_REGION = os.getenv("COS_REGION", "ap-guangzhou")
    COS_BUCKET = os.getenv("COS_BUCKET", "")
    COS_CDN_DOMAIN = os.getenv("COS_CDN_DOMAIN", "")

    # ==================== 腾讯实时音视频 TRTC 配置 ====================
    # 获取方式: https://console.cloud.tencent.com/trtc -> 应用管理 -> 创建应用
    # SDKAppID 是应用ID（非敏感，可下发客户端）
    TRTC_SDK_APP_ID = int(os.getenv("TRTC_SDK_APP_ID", "0"))
    # SecretKey 是签名密钥（敏感！仅服务端持有，不可下发客户端）
    TRTC_SECRET_KEY = os.getenv("TRTC_SECRET_KEY", "")
