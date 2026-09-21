# ==================== 厂商推送 ProGuard 规则（直连厂商通道） ====================

# 小米推送
-keep class com.xiaomi.** { *; }
-dontwarn com.xiaomi.**

# 华为推送
-keep class com.huawei.hianalytics.**{*;}
-keep class com.huawei.updatesdk.**{*;}
-keep class com.huawei.hms.**{*;}

# OPPO推送
-keep public class * extends android.app.Service
-keep class com.heytap.msp.** { *; }
-dontwarn com.heytap.msp.**

# Vivo推送
-dontwarn com.vivo.push.**
-keep class com.vivo.push.** {*;}
-keep class com.vivo.vms.** {*;}
