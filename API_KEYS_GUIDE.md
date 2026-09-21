闲雷虎虎 - API密钥与配置清单
================================

本文件列出所有需要替换的密钥、配置和敏感信息。
更换环境（新服务器/新应用/新开发者账号）时必须逐项替换。

================================
一、Android 前端配置
================================

1. 服务器地址（2处）
   文件: app/src/main/java/com/xian/leihuhu/TSApplication.java
   - 第30行: DEFAULT_API_URL = "http://43.133.39.170:8090"
   - 第185行: WKApiConfig.initAuthURL("http://43.133.39.170:8090")
   替换为: 你的新服务器地址

2. 高德地图 API Key（1处）
   文件: app/src/main/AndroidManifest.xml
   - 第150行: android:value="f33b95e9b302dbb24b8b2eb12c799ca1"
   获取: https://lbs.amap.com/ 控制台 -> 应用管理 -> 创建应用 -> 获取Key
   注意: Key与包名com.xian.leihuhu和签名SHA1绑定，更换签名需重新获取

3. 华为 agconnect-services.json（整个文件）
   文件: app/agconnect-services.json
   获取: https://developer.huawei.com/ AGC控制台 -> 下载 agconnect-services.json
   包含: app_id, api_key, client_secret, project_id 等

4. 签名证书（1处）
   文件: app/leihuhu.jks
   - storePassword: leihuhu2026
   - keyAlias: leihuhu
   - keyPassword: leihuhu2026
   文件: app/build.gradle 第50-56行
   注意: 更换签名证书后，高德Key和华为配置都需重新绑定

5. AndroidManifest.xml 推送配置（占位变量，通过build.gradle注入）
   文件: app/build.gradle 第33-47行 manifestPlaceholders
   - HM_APPID: 118943381（华为推送AppID）
   - XIAOMI_APPID: 2882303761520580396
   - XIAOMI_APPKEY: 5972058070396
   - OPPO_APPKEY: 48d56cf2c6414d2fb824924a86282368
   - OPPO_APPID: 37703343
   - OPPO_APPSECRET: 24a9a6b614fb4809b12e1917b3019ca2
   - VIVO_APPID: 106147728
   - VIVO_APPKEY: c46cfdea94517a83e1c56524571979eb
   - VIVO_APPSECRET: bb6502a6-f518-447d-8b94-e8c3e9b0f9d2

6. PushKeys.java 推送密钥
   文件: wkpush/src/main/java/com/chat/push/PushKeys.java
   - xiaoMiAppID: 2882303761520580396
   - xiaoMiAppKey: 5972058070396
   - huaweiAPPID: 118943381
   - oppoAppID: 37703343
   - oppoAppKey: 48d56cf2c6414d2fb824924a86282368
   - oppoAppSecret: 24a9a6b614fb4809b12e1917b3019ca2

================================
二、后端配置
================================

7. backend/.env 环境变量文件
   文件: backend/.env
   需替换的变量:
   - ALIYUN_ACCESS_KEY_ID: 阿里云AccessKey
   - ALIYUN_ACCESS_KEY_SECRET: 阿里云AccessKey Secret
   - ALIYUN_SMS_SIGN_NAME: 短信签名（默认"恒创联众"）
   - ALIYUN_SMS_TEMPLATE_CODE: 短信模板CODE
   - RESEND_API_KEY: Resend邮件服务API Key
   - RESEND_FROM_EMAIL: 发件邮箱
   - HUAWEI_PUSH_PROJECT_ID: 华为推送项目ID
   - HUAWEI_PUSH_KEY_ID: 华为推送密钥ID
   - HUAWEI_PUSH_SUB_ACCOUNT: 华为推送子账号
   - HUAWEI_PUSH_PRIVATE_KEY: 华为推送私钥(PEM格式)
   - XIAOMI_PUSH_APP_SECRET: 小米推送App Secret
   - OPPO_PUSH_MASTER_SECRET: OPPO推送Master Secret
   - VIVO_PUSH_APP_SECRET: Vivo推送App Secret
   - COS_SECRET_ID: 腾讯云COS SecretId
   - COS_SECRET_KEY: 腾讯云COS SecretKey
   - COS_BUCKET: COS存储桶名
   - COS_CDN_DOMAIN: CDN域名
   - MYSQL_PASSWORD: MySQL密码（默认Abc123456!）
   - MINIO_ROOT_PASSWORD: MinIO密码

8. backend/config.py 配置默认值
   文件: backend/config.py
   - 第36行: MYSQL_PASSWORD 默认 "Abc123456!"
   - 第92行: HUAWEI_PUSH_APP_ID 默认 "118943381"
   - 第96行: XIAOMI_PUSH_APP_ID 默认 "2882303761520580396"
   - 第97行: XIAOMI_PUSH_APP_KEY 默认 "5972058070396"
   - 第105行: OPPO_PUSH_APP_KEY 默认 "48d56cf2c6414d2fb824924a86282368"
   - 第106行: OPPO_PUSH_APP_SECRET 默认 "24a9a6b614fb4809b12e1917b3019ca2"
   - 第110-112行: VIVO推送默认值

9. backend/push_service.py 小米推送模板配置
   文件: backend/push_service.py
   - XIAOMI_TPL_FRIEND: M12762（好友聊天模板）
   - XIAOMI_TPL_GROUP: M12763（群聊消息模板）
   - XIAOMI_TPL_MENTION: M12771（群聊@提及模板）
   - XIAOMI_TPL_CALL: M12764（语音通话模板）
   - XIAOMI_CH_FRIEND: 160639（好友聊天channel_id）
   - XIAOMI_CH_GROUP: 160640（群聊消息channel_id）
   - XIAOMI_CH_MENTION: 160642（群聊互动channel_id）
   - XIAOMI_CH_CALL: 160641（音视频通话channel_id）

10. Nginx配置
    文件: backend/xianleihuhu-sms.nginx.conf
    - server_name: 域名
    - SSL证书路径
    - proxy_pass 后端地址

================================
三、iOS 部署须知（当前无iOS工程）
================================

若后续开发iOS版本，需要以下配置:

A. 推送证书
   - APNs 推送证书（p12/p8）
   - Bundle ID 必须与Android包名对应: com.xian.leihuhu
   - 在各厂商推送平台注册iOS应用:
     * 小米: https://admin.xmpush.xiaomi.com/
     * 华为: https://developer.huawei.com/
     * OPPO: https://push.oppo.com/
     * Vivo: https://dev.vivo.com.cn/

B. 地图SDK
   - 高德地图iOS Key（与Android不同，需单独申请）
   - Bundle ID绑定

C. 服务器地址
   - 与Android第1项相同，iOS代码中配置API地址

D. 签名/打包
   - Apple Developer 证书
   - Provisioning Profile
   - App ID: com.xian.leihuhu

================================
四、各平台开发者后台地址
================================

- 高德地图: https://lbs.amap.com/
- 华为开发者: https://developer.huawei.com/
- 小米推送: https://admin.xmpush.xiaomi.com/
- OPPO推送: https://push.oppo.com/
- Vivo推送: https://dev.vivo.com.cn/
- 阿里云: https://.console.aliyun.com/
- 腾讯云COS: https://console.cloud.tencent.com/cos
- Resend邮件: https://resend.com/

================================
五、更换清单（checklist）
================================

[ ] 1. 替换服务器IP地址（TSApplication.java 2处）
[ ] 2. 替换高德地图API Key（AndroidManifest.xml 1处）
[ ] 3. 替换华为 agconnect-services.json（整个文件）
[ ] 4. 替换签名证书 leihuhu.jks（如更换签名）
[ ] 5. 替换推送密钥（build.gradle + PushKeys.java）
[ ] 6. 替换后端 .env 所有变量
[ ] 7. 替换后端 config.py 默认值
[ ] 8. 替换小米推送模板ID和channel_id（push_service.py）
[ ] 9. 替换Nginx域名和SSL证书
[ ] 10. 重新编译APK并测试推送/地图/登录功能

================================
六、本次修复记录（2026-09-20）
================================

以下文件已修复，更换环境时无需再处理：

A. 已删除的构建垃圾
   - 所有模块的 build/ 目录（约1.2GB）
   - .gradle/ 缓存目录
   - 后端 40+ 一次性部署/测试脚本

B. 已修复的前端Bug
   - wkbase/.../SpinKitView.java: 删除了与外部依赖冲突的桩代码
   - wkuikit/.../EasyConstraintLayout.java: 新建缺失的自定义View（圆角ConstraintLayout）
   - wkuikit/.../EasyButton.java: 新建缺失的自定义View（圆角Button）
   - wkuikit/.../EasyTextView.java: 新建缺失的自定义View（圆角TextView）
   - wkuikit/src/main/res/values/attrs.xml: 添加EasyConstraintLayout自定义属性
   - wkbase/build.gradle: 修复SpinKit依赖冲突（exclude transitive + direct declaration）
   - wkuikit/build.gradle: 启用BuildConfig用于DEBUG检查
   - app/.../TSApplication.java: 移除硬编码服务器URL
   - wkuikit/.../WKUIKitApplication.java: 添加mContext空指针检查
   - wkuikit/.../VertifyPwdActivity.java: 移除硬编码默认密码
   - wkuikit/.../TestToolsActivity.java: 崩溃测试仅在DEBUG模式可用
   - wkbase/.../WKBaseApplication.java: 缓存目录初始化添加内部存储回退
   - wkbase/.../GlideUtils.java: Cursor空指针检查
   - wkbase/.../WKUploader.java: 空列表越界检查

C. 已修复的后端Bug
   - backend/push_service.py: Redis连接重试逻辑、异常处理
   - backend/push_service.py: 华为testMessage标志修复
   - backend/push_service.py: payload解码异常吞咽修复
   - backend/push_service.py: 小米模板推送配置（M12762/M12763/M12771/M12764）

D. 已编译产物
   - APK: app/build/outputs/apk/release/app-release.apk (215.57 MB)
   - iOS API配置指南: IOS_API_CONFIG_GUIDE.html
