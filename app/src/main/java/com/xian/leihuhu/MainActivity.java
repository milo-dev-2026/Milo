package com.xian.leihuhu;

import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.view.WindowManager;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;

import com.chat.base.common.WKCommonModel;
import com.chat.base.config.WKConfig;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.entity.AppVersion;
import com.chat.base.utils.WKDialogUtils;
import com.chat.uikit.security.LockScreenVerifyActivity;

public class MainActivity extends AppCompatActivity {

    private static final int SPLASH_DURATION = 300;
    private static final int REQUEST_LOCK_SCREEN = 1001;

    // 标记：是否正在显示强制更新对话框
    private boolean isShowingForceUpdate = false;
    // 标记：版本检查是否已完成
    private boolean versionCheckCompleted = false;
    // 标记：是否有新版本需要更新
    private boolean hasNewVersion = false;
    private AppVersion pendingVersion = null;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // 防止应用冷启动时短暂显示桌面背景
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN);
        setContentView(R.layout.activity_main);

        // 如果不是从 launcher 冷启动（如从后台恢复），直接跳转避免重复创建
        if (!isTaskRoot()) {
            Intent intent = getIntent();
            if (intent != null && intent.hasCategory(Intent.CATEGORY_LAUNCHER)
                    && Intent.ACTION_MAIN.equals(intent.getAction())) {
                finish();
                return;
            }
        }

        // 【关键修复】启动时立即检查版本更新
        // 优先检查版本，确保有强制更新时用户第一时间看到
        checkVersionOnLaunch();
    }

    /**
     * 启动时检查版本更新
     * 优先使用Application预加载的结果（更快，用户打开App立刻就能看到弹窗）
     * 如果预加载还没完成，则发起新的请求
     */
    private void checkVersionOnLaunch() {
        // 优先检查是否有预加载的版本结果
        AppVersion preloaded = TSApplication.getPreloadedVersion();
        if (TSApplication.isVersionPreloaded() && preloaded != null
                && !TextUtils.isEmpty(preloaded.download_url)) {
            // 预加载已有结果，直接处理
            versionCheckCompleted = true;
            hasNewVersion = true;
            pendingVersion = preloaded;
            TSApplication.clearPreloadedVersion(); // 清掉，避免重复弹窗

            if (preloaded.is_force == 1) {
                showForceUpdateDialog(preloaded);
            } else {
                // 非强制更新：弹窗提醒用户，但不阻塞启动
                showOptionalUpdateDialog(preloaded);
                proceedToNext();
            }
            return;
        }

        // 没有预加载结果，正常发起请求
        WKCommonModel.getInstance().getAppNewVersion(false, new WKCommonModel.IAppNewVersion() {
            @Override
            public void onNewVersion(AppVersion version) {
                versionCheckCompleted = true;
                if (version != null && !TextUtils.isEmpty(version.download_url)) {
                    hasNewVersion = true;
                    pendingVersion = version;
                    // 强制更新：立即显示对话框，拦截后续流程
                    if (version.is_force == 1) {
                        showForceUpdateDialog(version);
                    } else {
                        // 非强制更新：弹窗提醒用户，但不阻塞启动
                        showOptionalUpdateDialog(version);
                        proceedToNext();
                    }
                } else {
                    // 没有新版本，继续正常启动
                    proceedToNext();
                }
            }
        });

        // 容错：如果版本检查超时（如网络慢），最多等待2秒后继续启动
        // 避免因网络问题导致用户一直卡在启动页
        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            if (!versionCheckCompleted && !isShowingForceUpdate) {
                versionCheckCompleted = true;
                proceedToNext();
            }
        }, 2000);
    }

    /**
     * 显示非强制更新对话框
     * 用户可以选择立即更新，也可以关闭弹窗继续使用
     */
    private void showOptionalUpdateDialog(AppVersion version) {
        // 使用 WKDialogUtils 显示更新弹窗（非强制，可关闭）
        WKDialogUtils.getInstance().showNewVersionDialog(this, version);
    }

    /**
     * 显示强制更新对话框
     * 用户必须更新才能继续使用App
     */
    private void showForceUpdateDialog(AppVersion version) {
        isShowingForceUpdate = true;
        // 使用WKDialogUtils显示更新对话框
        WKDialogUtils.getInstance().showNewVersionDialog(this, version);
    }

    @Override
    protected void onResume() {
        super.onResume();
        // 如果用户从安装界面返回（没有安装成功），且是强制更新
        // 则继续显示更新对话框，不允许进入应用
        if (isShowingForceUpdate && pendingVersion != null && pendingVersion.is_force == 1) {
            // 检查是否已经安装了新版本
            try {
                String currentVersion = getPackageManager().getPackageInfo(getPackageName(), 0).versionName;
                if (!TextUtils.isEmpty(currentVersion) && !TextUtils.isEmpty(pendingVersion.app_version)) {
                    int cmp = compareVersion(pendingVersion.app_version, currentVersion);
                    if (cmp <= 0) {
                        // 已经是最新版本，继续启动
                        isShowingForceUpdate = false;
                        proceedToNext();
                        return;
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
            // 还没有更新，重新显示对话框
            WKDialogUtils.getInstance().showNewVersionDialog(this, pendingVersion);
        }
    }

    /**
     * 比较版本号
     */
    private int compareVersion(String version1, String version2) {
        if (TextUtils.isEmpty(version1) || TextUtils.isEmpty(version2)) {
            return 0;
        }
        String[] v1 = version1.trim().split("\\.");
        String[] v2 = version2.trim().split("\\.");
        int len = Math.max(v1.length, v2.length);
        for (int i = 0; i < len; i++) {
            int num1 = i < v1.length ? parseIntSafe(v1[i]) : 0;
            int num2 = i < v2.length ? parseIntSafe(v2[i]) : 0;
            if (num1 > num2) return 1;
            if (num1 < num2) return -1;
        }
        return 0;
    }

    private int parseIntSafe(String s) {
        try {
            return Integer.parseInt(s.trim());
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    private void proceedToNext() {
        // 如果正在显示强制更新，不继续
        if (isShowingForceUpdate) {
            return;
        }

        // 快速进入应用，和 utalk/tsdd_original 类似的体验
        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            boolean isAppLockEnabled = WKSharedPreferencesUtil.getInstance().getBoolean("lock_screen_pwd_enabled");
            String lockPwd = WKSharedPreferencesUtil.getInstance().getSP("lock_screen_pwd");

            if (isAppLockEnabled && lockPwd != null && !lockPwd.isEmpty()) {
                Intent intent = new Intent(this, LockScreenVerifyActivity.class);
                startActivityForResult(intent, REQUEST_LOCK_SCREEN);
            } else {
                enterMainContent();
            }
        }, SPLASH_DURATION);
    }

    private void enterMainContent() {
        // 如果正在显示强制更新，不继续
        if (isShowingForceUpdate) {
            return;
        }

        String uid = WKConfig.getInstance().getUid();

        // 已登录用户：检查是否需要显示权限引导弹窗
        if (uid != null && !uid.isEmpty() && PermissionGuideActivity.shouldShowGuide(this)) {
            Intent intent = new Intent(this, PermissionGuideActivity.class);
            startActivity(intent);
            overridePendingTransition(0, 0);
            return;
        }

        Intent intent;
        if (uid == null || uid.isEmpty()) {
            intent = new Intent(this, com.chat.login.ui.WKLoginActivity.class);
        } else {
            intent = new Intent(this, com.chat.uikit.TabActivity.class);
        }
        // 使用 CLEAR_TASK 确保新 Activity 成为 Task 根，避免 finish 后回退到桌面
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        startActivity(intent);
        finish();
        // 禁用过渡动画，避免闪退回桌面的视觉效果
        overridePendingTransition(0, 0);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_LOCK_SCREEN) {
            if (resultCode == RESULT_OK) {
                TSApplication.getInstance().setAppLocked(false);
                enterMainContent();
            } else {
                finishAffinity();
            }
        }
    }

    @Override
    public void onBackPressed() {
        // 强制更新时，禁止返回键退出
        if (isShowingForceUpdate && pendingVersion != null && pendingVersion.is_force == 1) {
            // 不响应返回键
            return;
        }
        super.onBackPressed();
    }
}
