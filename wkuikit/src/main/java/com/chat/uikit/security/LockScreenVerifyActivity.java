package com.chat.uikit.security;

import android.app.Activity;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.TextView;

import com.chat.base.config.WKConfig;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.ui.components.AvatarView;
import com.chat.base.utils.WKCommonUtils;
import com.chat.uikit.R;

/**
 * 应用解锁页（进入应用时的锁屏验证）
 * 参考 utalk：头像 + "锁屏密码" + "请输入6位数字密码以解锁并继续使用" + 6格密码框 + 数字键盘 + 忘记密码
 */
public class LockScreenVerifyActivity extends Activity {

    private static final String SP_KEY_APP_LOCK_PWD = "lock_screen_pwd";
    private static final int MAX_PWD_LENGTH = 6;

    private StringBuilder inputPwd = new StringBuilder();
    private ImageView[] dots = new ImageView[6];
    private int errorCount = 0;
    private TextView subtitleTv;
    private AvatarView avatarIv;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            getWindow().setStatusBarColor(getResources().getColor(R.color.bg_grey_F6F7F9));
        }
        setContentView(R.layout.activity_lock_screen_verify);

        // 透明导航栏
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            getWindow().setNavigationBarColor(getResources().getColor(android.R.color.white));
        }

        initViews();
        loadAvatar();
        setupNumpad();
    }

    private void initViews() {
        dots[0] = findViewById(R.id.dot1);
        dots[1] = findViewById(R.id.dot2);
        dots[2] = findViewById(R.id.dot3);
        dots[3] = findViewById(R.id.dot4);
        dots[4] = findViewById(R.id.dot5);
        dots[5] = findViewById(R.id.dot6);
        subtitleTv = findViewById(R.id.subtitleTv);
        avatarIv = findViewById(R.id.avatarIv);

        TextView forgetTv = findViewById(R.id.forgetPwdTv);
        forgetTv.setOnClickListener(v -> {
            // 忘记密码：跳转到登录页重新登录
            try {
                Intent intent = new Intent();
                intent.setClassName(getPackageName(), "com.xian.leihuhu.module.login.LoginActivity");
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                startActivity(intent);
                finish();
            } catch (Exception e) {
                e.printStackTrace();
            }
        });

        updateDots();
    }

    private void loadAvatar() {
        // 使用 AvatarView 加载头像
        String uid = WKConfig.getInstance().getUid();
        if (uid != null && uid.length() > 0) {
            avatarIv.showAvatar(uid, com.xinbida.wukongim.entity.WKChannelType.PERSONAL);
        }
    }

    private void setupNumpad() {
        int[] btnIds = {R.id.btn0, R.id.btn1, R.id.btn2, R.id.btn3, R.id.btn4,
                R.id.btn5, R.id.btn6, R.id.btn7, R.id.btn8, R.id.btn9};
        for (int i = 0; i < btnIds.length; i++) {
            final String num = String.valueOf(i);
            View btn = findViewById(btnIds[i]);
            if (btn != null) {
                btn.setOnClickListener(v -> appendDigit(num));
            }
        }

        View deleteBtn = findViewById(R.id.btnDeleteBtn);
        if (deleteBtn != null) {
            deleteBtn.setOnClickListener(v -> deleteDigit());
        }
    }

    private void appendDigit(String digit) {
        if (inputPwd.length() < MAX_PWD_LENGTH) {
            inputPwd.append(digit);
            updateDots();
            if (inputPwd.length() == MAX_PWD_LENGTH) {
                verifyPassword();
            }
        }
    }

    private void deleteDigit() {
        if (inputPwd.length() > 0) {
            inputPwd.deleteCharAt(inputPwd.length() - 1);
            updateDots();
        }
    }

    private void updateDots() {
        for (int i = 0; i < MAX_PWD_LENGTH; i++) {
            if (i < inputPwd.length()) {
                dots[i].setBackgroundResource(R.drawable.bg_pwd_box_filled);
            } else {
                dots[i].setBackgroundResource(R.drawable.bg_pwd_box);
            }
        }
    }

    private void verifyPassword() {
        String savedPwd = WKSharedPreferencesUtil.getInstance().getSP(SP_KEY_APP_LOCK_PWD);
        String uid = WKConfig.getInstance().getUid();
        String hashedInput = WKCommonUtils.digest(inputPwd.toString() + uid);

        boolean correct = hashedInput.equals(savedPwd) || inputPwd.toString().equals(savedPwd);

        if (correct) {
            // 如果是旧明文密码，自动升级
            if (inputPwd.toString().equals(savedPwd) && !hashedInput.equals(savedPwd)) {
                WKSharedPreferencesUtil.getInstance().putSP(SP_KEY_APP_LOCK_PWD, hashedInput);
            }
            // 解锁成功，通知 Application
            try {
                Class<?> appClass = Class.forName("com.xian.leihuhu.TSApplication");
                java.lang.reflect.Method getInstanceMethod = appClass.getMethod("getInstance");
                Object appInstance = getInstanceMethod.invoke(null);
                java.lang.reflect.Method setAppLockedMethod = appClass.getMethod("setAppLocked", boolean.class);
                setAppLockedMethod.invoke(appInstance, false);
            } catch (Exception e) {
                e.printStackTrace();
            }
            finish();
        } else {
            errorCount++;
            shakeDots();
            new Handler(Looper.getMainLooper()).postDelayed(() -> {
                inputPwd.setLength(0);
                updateDots();
                subtitleTv.setText("密码错误，请重新输入");
                subtitleTv.setTextColor(getResources().getColor(R.color.red));
                new Handler(Looper.getMainLooper()).postDelayed(() -> {
                    subtitleTv.setText("请输入6位数字密码以解锁并继续使用");
                    subtitleTv.setTextColor(getResources().getColor(R.color.color999));
                }, 2000);
            }, 500);
        }
    }

    private void shakeDots() {
        for (ImageView dot : dots) {
            dot.animate()
                    .translationXBy(20f)
                    .setDuration(50)
                    .withEndAction(() -> dot.animate()
                            .translationXBy(-40f)
                            .setDuration(50)
                            .withEndAction(() -> dot.animate()
                                    .translationXBy(20f)
                                    .setDuration(50)
                                    .start())
                            .start())
                    .start();
        }
    }

    @Override
    public void onBackPressed() {
        // 屏蔽返回键
        moveTaskToBack(true);
    }
}
