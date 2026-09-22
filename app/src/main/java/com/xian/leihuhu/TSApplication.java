package com.xian.leihuhu;

import android.app.ActivityManager;
import android.app.Application;
import android.content.Intent;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import java.util.Locale;

import android.util.Log;

import com.chat.base.WKBaseApplication;
import com.chat.base.config.WKApiConfig;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.endpoint.EndpointCategory;
import com.chat.base.endpoint.EndpointManager;
import com.chat.base.msgitem.ReactionSticker;
import com.chat.base.net.RetrofitUtils;
import com.chat.scan.WKScanApplication;
import com.chat.uikit.WKUIKitApplication;
import com.chat.push.WKPushApplication;
import com.chat.uikit.security.LockScreenVerifyActivity;

import java.util.ArrayList;
import java.util.List;

public class TSApplication extends Application {

    private static final String TAG = "TSApplication_Lock";
    private static final String DEFAULT_API_URL = "http://43.133.39.170:8090";
    private static TSApplication instance;
    private AppFrontBackHelper appFrontBackHelper;
    private boolean isAppLocked = false;
    private long lastBackgroundTime = 0;
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    @Override
    public void onCreate() {
        super.onCreate();
        instance = this;

        // 强制使用简体中文，避免在英文系统上显示英文界面
        forceChineseLocale();

        // 非主进程（如:channel推送进程）不初始化IM，避免多进程同时连接导致互踢断连
        String processName = getCurrentProcessName();
        if (processName != null && processName.contains(":")) {
            // 子进程只初始化推送，不初始化IM和UI模块
            WKPushApplication.getInstance().init("com.xian.leihuhu", this);
            return;
        }

        // 初始化高德地图隐私合规（必须在调用任何高德SDK接口之前调用）
        initAMapPrivacy();

        // 初始化基础应用
        WKBaseApplication.getInstance().init("com.xian.leihuhu", this);

        // 初始化API地址（必须在WKUIKitApplication.init之前，确保网络请求时baseUrl已就绪）
        initApiUrl();

        // 初始化UI Kit模块（注册loginMenus等所有端点）
        WKUIKitApplication.getInstance().init(this);

        // 初始化扫描模块（注册二维码生成、扫描识别等端点）
        WKScanApplication.getInstance().init(this);

        // 初始化推送模块（注册厂商推送SDK、通知渠道、登录后自动注册token）
        WKPushApplication.getInstance().init("com.xian.leihuhu", this);

        // 注册登录成功后的权限引导检查端点
        // 此端点在 WKUIKitApplication 的 loginMenus 之后执行
        // 如果需要显示权限引导，则用 PermissionGuideActivity 替换 TabActivity
        EndpointManager.getInstance().setMethod("", EndpointCategory.loginMenus, object -> new com.chat.base.endpoint.entity.LoginMenu(() -> {
            if (PermissionGuideActivity.shouldShowGuide(getApplicationContext())) {
                Intent guideIntent = new Intent(getApplicationContext(), PermissionGuideActivity.class);
                guideIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                startActivity(guideIntent);
            }
        }));

        // 注册表情反应贴纸端点
        EndpointManager.getInstance().setMethod("reaction_sticker", object -> {
            List<ReactionSticker> list = new ArrayList<>();
            list.add(new ReactionSticker("like", R.raw.like_small));
            list.add(new ReactionSticker("bad", R.raw.bad_small));
            list.add(new ReactionSticker("love", R.raw.love_small));
            list.add(new ReactionSticker("fire", R.raw.fire_small));
            list.add(new ReactionSticker("celebrate", R.raw.celebrate_small));
            list.add(new ReactionSticker("haha", R.raw.haha_small));
            list.add(new ReactionSticker("happy", R.raw.happy_small));
            list.add(new ReactionSticker("terrified", R.raw.terrified_small));
            return list;
        });

        // 注册是否显示表情反应端点
        EndpointManager.getInstance().setMethod("is_show_reaction", object -> true);

        // 注册表情反应发送端点
        EndpointManager.getInstance().setMethod("wk_msg_reaction", object -> {
            com.chat.base.endpoint.entity.MsgReactionMenu menu =
                (com.chat.base.endpoint.entity.MsgReactionMenu) object;
            sendReaction(menu);
            return null;
        });

        // 注册消息上显示表情反应端点
        EndpointManager.getInstance().setMethod("show_msg_reaction", object -> {
            com.chat.base.endpoint.entity.ShowMsgReactionMenu menu =
                (com.chat.base.endpoint.entity.ShowMsgReactionMenu) object;
            showMsgReaction(menu);
            return null;
        });

        // 注册刷新消息表情反应端点
        EndpointManager.getInstance().setMethod("refresh_msg_reaction", object -> {
            com.chat.base.endpoint.entity.ShowMsgReactionMenu menu =
                (com.chat.base.endpoint.entity.ShowMsgReactionMenu) object;
            showMsgReaction(menu);
            return null;
        });

        // 注册update_base_url端点，支持登录页修改服务器地址
        EndpointManager.getInstance().setMethod("update_base_url", object -> {
            String apiUrl = (String) object;
            if (TextUtils.isEmpty(apiUrl)) {
                WKSharedPreferencesUtil.getInstance().putSP("api_base_url", "");
                WKApiConfig.initBaseURL(DEFAULT_API_URL);
            } else {
                WKSharedPreferencesUtil.getInstance().putSP("api_base_url", apiUrl);
                WKApiConfig.initBaseURL(apiUrl);
            }
            RetrofitUtils.getInstance().resetRetrofit();
            com.chat.login.service.LoginModel.resetAuthRetrofit();
            return null;
        });

        // 注册退出登录后跳转登录页的端点
        // exitLogin() 中会 invoke("main_show_home_view")，此端点必须注册才能正常跳转到登录页
        EndpointManager.getInstance().setMethod("main_show_home_view", object -> {
            Intent loginIntent = new Intent(getApplicationContext(), com.chat.login.ui.WKLoginActivity.class);
            loginIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
            startActivity(loginIntent);
            return null;
        });

        // 注册前后台监听
        appFrontBackHelper = new AppFrontBackHelper();
        appFrontBackHelper.register(this, new AppFrontBackHelper.OnAppStatusListener() {
            @Override
            public void onFront() {
                Log.d(TAG, "onFront: app come to foreground");
                // 应用回到前台时，确保IM连接活跃
                try {
                    com.chat.uikit.WKUIKitApplication.getInstance().startChat();
                } catch (Exception e) {
                    e.printStackTrace();
                }
                // 延迟1秒检查锁屏，避免切换动画期间的异常
                mainHandler.removeCallbacks(lockCheckRunnable);
                mainHandler.postDelayed(lockCheckRunnable, 1000);
            }

            @Override
            public void onBack() {
                Log.d(TAG, "onBack: app go to background");
                lastBackgroundTime = System.currentTimeMillis();
                mainHandler.removeCallbacks(lockCheckRunnable);
            }
        });
    }

    private void initAMapPrivacy() {
        try {
            // 高德定位SDK隐私合规
            com.amap.api.location.AMapLocationClient.updatePrivacyShow(this, true, true);
            com.amap.api.location.AMapLocationClient.updatePrivacyAgree(this, true);
            // 高德地图SDK隐私合规
            com.amap.api.maps.MapsInitializer.updatePrivacyShow(this, true, true);
            com.amap.api.maps.MapsInitializer.updatePrivacyAgree(this, true);
            // 高德搜索服务隐私合规
            com.amap.api.services.core.ServiceSettings.updatePrivacyShow(this, true, true);
            com.amap.api.services.core.ServiceSettings.updatePrivacyAgree(this, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void initApiUrl() {
        String savedUrl = WKSharedPreferencesUtil.getInstance().getSP("api_base_url", "");
        if (!TextUtils.isEmpty(savedUrl)) {
            WKApiConfig.initBaseURL(savedUrl);
        } else {
            WKApiConfig.initBaseURL(DEFAULT_API_URL);
        }
        // 初始化认证服务地址（用户搜索等功能使用）
        WKApiConfig.initAuthURL("http://43.133.39.170:8090");
    }

    /**
     * 强制应用使用简体中文，无论系统语言设置如何
     */
    private void forceChineseLocale() {
        Locale locale = Locale.SIMPLIFIED_CHINESE;
        Locale.setDefault(locale);
        Resources resources = getResources();
        Configuration config = resources.getConfiguration();
        config.setLocale(locale);
        resources.updateConfiguration(config, resources.getDisplayMetrics());
    }

    private final Runnable lockCheckRunnable = new Runnable() {
        @Override
        public void run() {
            checkAppLockOnForeground();
        }
    };

    private void checkAppLockOnForeground() {
        boolean isAppLockEnabled = WKSharedPreferencesUtil.getInstance().getBoolean("lock_screen_pwd_enabled");
        String savedPwd = WKSharedPreferencesUtil.getInstance().getSP("lock_screen_pwd");
        int autoLockTime = WKSharedPreferencesUtil.getInstance().getInt("lock_screen_auto_lock_time", 0);
        Log.d(TAG, "checkAppLock: enabled=" + isAppLockEnabled
                + ", pwdEmpty=" + TextUtils.isEmpty(savedPwd)
                + ", autoLockTime=" + autoLockTime
                + ", lastBgTime=" + lastBackgroundTime
                + ", isLocked=" + isAppLocked);

        if (!isAppLockEnabled || TextUtils.isEmpty(savedPwd)) {
            isAppLocked = false;
            Log.d(TAG, "checkAppLock: not enabled or no pwd, skip");
            return;
        }

        if (isAppLocked) {
            Log.d(TAG, "checkAppLock: already locked, skip showing again");
            return;
        }

        if (autoLockTime <= 0) {
            isAppLocked = true;
            Log.d(TAG, "checkAppLock: autoLockTime=0, show lock screen immediately");
            showLockScreen();
            return;
        }

        if (lastBackgroundTime <= 0) {
            // 第一次启动没有后台时间，不锁屏
            Log.d(TAG, "checkAppLock: no lastBackgroundTime (first launch), skip");
            return;
        }

        long elapsed = System.currentTimeMillis() - lastBackgroundTime;
        long threshold = autoLockTime * 60 * 1000L;
        Log.d(TAG, "checkAppLock: elapsed=" + elapsed + "ms, threshold=" + threshold + "ms");
        if (elapsed >= threshold) {
            isAppLocked = true;
            Log.d(TAG, "checkAppLock: elapsed >= threshold, show lock screen");
            showLockScreen();
        }
    }

    private void showLockScreen() {
        Intent intent = new Intent(getApplicationContext(), LockScreenVerifyActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        new Handler(Looper.getMainLooper()).post(() -> getApplicationContext().startActivity(intent));
    }

    public static TSApplication getInstance() {
        return instance;
    }

    private String getCurrentProcessName() {
        int pid = android.os.Process.myPid();
        ActivityManager am = (ActivityManager) getSystemService(ACTIVITY_SERVICE);
        if (am != null) {
            for (ActivityManager.RunningAppProcessInfo info : am.getRunningAppProcesses()) {
                if (info.pid == pid) {
                    return info.processName;
                }
            }
        }
        return getPackageName();
    }

    public boolean isAppLocked() {
        return isAppLocked;
    }

    public void setAppLocked(boolean locked) {
        isAppLocked = locked;
    }

    @Override
    public void onTerminate() {
        super.onTerminate();
        if (appFrontBackHelper != null) {
            appFrontBackHelper.unRegister(this);
        }
    }

    private void sendReaction(com.chat.base.endpoint.entity.MsgReactionMenu menu) {
        // 将reaction name映射为emoji字符
        String emoji = menu.emoji;
        if ("like".equals(emoji)) emoji = "\uD83D\uDC4D";
        else if ("bad".equals(emoji)) emoji = "\uD83D\uDC4E";
        else if ("love".equals(emoji)) emoji = "\u2764\uFE0F";
        else if ("fire".equals(emoji)) emoji = "\uD83D\uDD25";
        else if ("celebrate".equals(emoji)) emoji = "\uD83C\uDF89";
        else if ("haha".equals(emoji)) emoji = "\uD83D\uDE02";
        else if ("happy".equals(emoji)) emoji = "\uD83D\uDE04";
        else if ("terrified".equals(emoji)) emoji = "\uD83D\uDE31";
        final String finalEmoji = emoji;
        // 先在主线程立即更新本地数据并刷新UI
        new Handler(Looper.getMainLooper()).post(() -> {
            try {
                java.util.List<com.xinbida.wukongim.entity.WKMsgReaction> reactionList = menu.wkMsg.reactionList;
                if (reactionList == null) {
                    reactionList = new java.util.ArrayList<>();
                    menu.wkMsg.reactionList = reactionList;
                }
                boolean exists = false;
                for (com.xinbida.wukongim.entity.WKMsgReaction r : reactionList) {
                    if (r.emoji.equals(menu.emoji) && r.uid.equals(com.chat.base.config.WKConfig.getInstance().getUid())) {
                        exists = true;
                        break;
                    }
                }
                if (!exists) {
                    com.xinbida.wukongim.entity.WKMsgReaction reaction = new com.xinbida.wukongim.entity.WKMsgReaction();
                    reaction.emoji = finalEmoji;
                    reaction.uid = com.chat.base.config.WKConfig.getInstance().getUid();
                    reactionList.add(reaction);
                }
                if (menu.chatAdapter != null) {
                    java.util.List<com.xinbida.wukongim.entity.WKMsgReaction> finalList = reactionList;
                    int position = -1;
                    for (int i = 0; i < menu.chatAdapter.getData().size(); i++) {
                        if (menu.chatAdapter.getData().get(i).wkMsg != null
                                && menu.chatAdapter.getData().get(i).wkMsg.clientMsgNO != null
                                && menu.chatAdapter.getData().get(i).wkMsg.clientMsgNO.equals(menu.wkMsg.clientMsgNO)) {
                            position = i;
                            break;
                        }
                    }
                    if (position >= 0) {
                        menu.chatAdapter.notifyReaction(position, finalList);
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        });

        // 后台发送HTTP请求（不阻塞UI）
        new Thread(() -> {
            try {
                com.google.gson.JsonObject json = new com.google.gson.JsonObject();
                json.addProperty("channel_id", menu.wkMsg.channelID);
                json.addProperty("channel_type", menu.wkMsg.channelType);
                json.addProperty("message_id", menu.wkMsg.messageID);
                json.addProperty("emoji", menu.emoji);
                okhttp3.MediaType JSON = okhttp3.MediaType.parse("application/json; charset=utf-8");
                okhttp3.RequestBody body = okhttp3.RequestBody.create(json.toString(), JSON);
                String url = WKApiConfig.baseUrl + "reactions";
                okhttp3.Request request = new okhttp3.Request.Builder().url(url).post(body).build();
                okhttp3.OkHttpClient client = com.chat.base.net.OkHttpUtils.getInstance().getOkHttpClient();
                client.newCall(request).execute().close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }).start();
    }

    private void showMsgReaction(com.chat.base.endpoint.entity.ShowMsgReactionMenu menu) {
        android.widget.FrameLayout parentView = menu.getParentView();
        java.util.List<com.xinbida.wukongim.entity.WKMsgReaction> list = menu.getList();
        if (parentView == null) return;
        parentView.removeAllViews();
        if (list == null || list.isEmpty()) {
            parentView.setVisibility(android.view.View.GONE);
            return;
        }
        parentView.setVisibility(android.view.View.VISIBLE);
        android.content.Context ctx = parentView.getContext();
        float density = ctx.getResources().getDisplayMetrics().density;
        // 参照UTalk：发送消息时reaction在左侧，接收消息时在右侧
        android.widget.LinearLayout.LayoutParams params = new android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT);
        if (menu.getFrom() == com.chat.base.msgitem.WKChatIteMsgFromType.SEND) {
            params.gravity = android.view.Gravity.START | android.view.Gravity.BOTTOM;
            params.leftMargin = (int)(5 * density);
        } else {
            params.gravity = android.view.Gravity.END | android.view.Gravity.BOTTOM;
            params.rightMargin = (int)(5 * density);
        }
        params.topMargin = -(int)(10 * density);
        parentView.setLayoutParams(params);

        // 创建圆角背景容器
        android.graphics.drawable.GradientDrawable bgDrawable = new android.graphics.drawable.GradientDrawable();
        bgDrawable.setColor(0xFFFFFFFF);
        bgDrawable.setCornerRadius(20 * density);

        android.widget.LinearLayout container = new android.widget.LinearLayout(ctx);
        container.setOrientation(android.widget.LinearLayout.HORIZONTAL);
        container.setGravity(android.view.Gravity.CENTER_VERTICAL);
        container.setBackground(bgDrawable);
        container.setPadding((int)(8 * density), (int)(2 * density), (int)(8 * density), (int)(2 * density));

        // 获取最多3个不重复的emoji
        java.util.List<String> emojis = new java.util.ArrayList<>();
        for (com.xinbida.wukongim.entity.WKMsgReaction r : list) {
            if (!emojis.contains(r.emoji)) {
                emojis.add(r.emoji);
                if (emojis.size() >= 3) break;
            }
        }

        for (String emoji : emojis) {
            android.widget.TextView tv = new android.widget.TextView(ctx);
            tv.setText(emoji);
            tv.setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, 16f);
            tv.setPadding((int)(2 * density), 0, (int)(2 * density), 0);
            container.addView(tv);
        }

        // 数量文字
        android.widget.TextView countTv = new android.widget.TextView(ctx);
        countTv.setTextColor(0xFF999999);
        countTv.setText(String.valueOf(list.size()));
        countTv.setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, 14f);
        countTv.getPaint().setFakeBoldText(true);
        countTv.setPadding((int)(4 * density), 0, 0, 0);
        container.addView(countTv);

        parentView.addView(container);
    }
}
