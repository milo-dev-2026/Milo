package com.xian.leihuhu;

import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.WindowManager;

import androidx.appcompat.app.AppCompatActivity;

import com.chat.base.config.WKConfig;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.uikit.security.LockScreenVerifyActivity;

public class MainActivity extends AppCompatActivity {

    private static final int SPLASH_DURATION = 300;
    private static final int REQUEST_LOCK_SCREEN = 1001;

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

        // 快速进入应用，和 utalk/tsdd_original 类似的体验
        new Handler(Looper.getMainLooper()).postDelayed(this::proceedToNext, SPLASH_DURATION);
    }

    private void proceedToNext() {
        boolean isAppLockEnabled = WKSharedPreferencesUtil.getInstance().getBoolean("lock_screen_pwd_enabled");
        String lockPwd = WKSharedPreferencesUtil.getInstance().getSP("lock_screen_pwd");

        if (isAppLockEnabled && lockPwd != null && !lockPwd.isEmpty()) {
            Intent intent = new Intent(this, LockScreenVerifyActivity.class);
            startActivityForResult(intent, REQUEST_LOCK_SCREEN);
        } else {
            enterMainContent();
        }
    }

    private void enterMainContent() {
        String uid = WKConfig.getInstance().getUid();

        // 已登录用户：检查是否需要显示权限引导弹窗
        if (uid != null && !uid.isEmpty() && PermissionGuideActivity.shouldShowGuide(this)) {
            Intent intent = new Intent(this, PermissionGuideActivity.class);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
            startActivity(intent);
            finish();
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
}
