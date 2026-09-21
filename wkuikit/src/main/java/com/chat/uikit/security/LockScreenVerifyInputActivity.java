package com.chat.uikit.security;

import android.content.Intent;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKConfig;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.utils.WKCommonUtils;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityLockScreenVerifyInputBinding;

/**
 * 进入锁屏密码详情页之前的验证页
 * 参考 utalk：盾牌图标 + "请输入锁屏密码" + 6格密码框 + 数字键盘
 */
public class LockScreenVerifyInputActivity extends WKBaseActivity<ActivityLockScreenVerifyInputBinding> {

    private static final String KEY_LOCK_SCREEN_PWD = "lock_screen_pwd";
    private static final int MAX_PWD_LENGTH = 6;
    private static final int SHAKE_DURATION = 500;

    private StringBuilder inputPwd = new StringBuilder();
    private ImageView[] dots = new ImageView[6];
    private int errorCount = 0;

    @Override
    protected ActivityLockScreenVerifyInputBinding getViewBinding() {
        return ActivityLockScreenVerifyInputBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.lock_screen_password);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        dots[0] = wkVBinding.dot1;
        dots[1] = wkVBinding.dot2;
        dots[2] = wkVBinding.dot3;
        dots[3] = wkVBinding.dot4;
        dots[4] = wkVBinding.dot5;
        dots[5] = wkVBinding.dot6;
        updateDots();
    }

    @Override
    protected void initListener() {
        int[] btnIds = {R.id.btn0, R.id.btn1, R.id.btn2, R.id.btn3, R.id.btn4,
                R.id.btn5, R.id.btn6, R.id.btn7, R.id.btn8, R.id.btn9};
        for (int i = 0; i < btnIds.length; i++) {
            final String num = String.valueOf(i);
            findViewById(btnIds[i]).setOnClickListener(v -> appendDigit(num));
        }

        wkVBinding.btnDeleteBtn.setOnClickListener(v -> deleteDigit());
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
        String savedPwd = WKSharedPreferencesUtil.getInstance().getSP(KEY_LOCK_SCREEN_PWD);
        String uid = WKConfig.getInstance().getUid();
        String hashedInput = WKCommonUtils.digest(inputPwd.toString() + uid);

        boolean correct = hashedInput.equals(savedPwd) || inputPwd.toString().equals(savedPwd);

        if (correct) {
            // 如果是旧明文密码，自动升级
            if (inputPwd.toString().equals(savedPwd) && !hashedInput.equals(savedPwd)) {
                WKSharedPreferencesUtil.getInstance().putSP(KEY_LOCK_SCREEN_PWD, hashedInput);
            }
            // 跳转到详情页
            Intent intent = new Intent(this, LockScreenPwdActivity.class);
            startActivity(intent);
            finish();
        } else {
            errorCount++;
            shakeDots();
            new Handler(Looper.getMainLooper()).postDelayed(() -> {
                inputPwd.setLength(0);
                updateDots();
                if (errorCount >= 5) {
                    wkVBinding.subtitleTv.setText("密码错误次数过多，请稍后再试");
                    wkVBinding.subtitleTv.setTextColor(getResources().getColor(R.color.red));
                } else {
                    wkVBinding.subtitleTv.setText("密码错误，请重新输入");
                    wkVBinding.subtitleTv.setTextColor(getResources().getColor(R.color.red));
                    new Handler(Looper.getMainLooper()).postDelayed(() -> {
                        wkVBinding.subtitleTv.setText("验证通过后可管理锁屏密码与自动锁定时间");
                        wkVBinding.subtitleTv.setTextColor(getResources().getColor(R.color.color999));
                    }, 2000);
                }
            }, SHAKE_DURATION);
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
}
