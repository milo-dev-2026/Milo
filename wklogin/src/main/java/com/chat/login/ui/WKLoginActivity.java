package com.chat.login.ui;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.CountDownTimer;
import android.os.Handler;
import android.os.Looper;
import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.text.method.HideReturnsTransformationMethod;
import android.text.method.PasswordTransformationMethod;
import android.util.Patterns;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.ViewFlipper;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.core.content.ContextCompat;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.common.WKCommonModel;
import com.chat.base.config.WKApiConfig;
import com.chat.base.config.WKConfig;
import com.chat.base.endpoint.EndpointCategory;
import com.chat.base.endpoint.EndpointManager;
import com.chat.base.endpoint.entity.LoginMenu;
import com.chat.base.endpoint.entity.OtherLoginResultMenu;
import com.chat.base.entity.UserInfoEntity;
import com.chat.base.entity.WKAPPConfig;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.ui.Theme;
import com.chat.base.utils.AndroidUtilities;
import com.chat.base.utils.SoftKeyboardUtils;
import com.chat.base.utils.WKReader;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.login.R;
import com.chat.login.databinding.ActLoginLayoutBinding;
import com.chat.login.entity.CountryCodeEntity;
import com.chat.login.service.LoginContract;
import com.chat.login.service.LoginPresenter;

import java.util.List;
import java.util.Objects;

public class WKLoginActivity extends WKBaseActivity<ActLoginLayoutBinding> implements LoginContract.LoginView {

    private static final int STEP_ACCOUNT_INPUT = 0;
    private static final int STEP_EXISTING_LOGIN = 1;
    private static final int STEP_NEW_REGISTER = 2;

    private static final int ACCOUNT_TYPE_PHONE = 0;
    private static final int ACCOUNT_TYPE_EMAIL = 1;

    private static final int MIN_PASSWORD_LENGTH = 6;
    private static final int MAX_PASSWORD_LENGTH = 20;
    private static final int CHINA_PHONE_LENGTH = 11;
    private static final int CODE_COUNTDOWN_MILLIS = 60000;

    private int currentStep = STEP_ACCOUNT_INPUT;
    private int accountType = ACCOUNT_TYPE_PHONE;
    private String countryCode = "0086";
    private LoginPresenter loginPresenter;
    private WKAPPConfig appConfig;
    private CountDownTimer countDownTimer;

    @Override
    protected ActLoginLayoutBinding getViewBinding() {
        return ActLoginLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void initPresenter() {
        loginPresenter = new LoginPresenter(this);
    }

    @Override
    protected void initView() {
        // 强制LTR布局方向，防止RTL语言导致布局错乱
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            getWindow().getDecorView().setLayoutDirection(View.LAYOUT_DIRECTION_LTR);
        }
        // 动态设置顶部栏padding，适配灵动岛/刘海屏
        int statusBarHeight = com.chat.base.utils.systembar.WKStatusBarUtils.getStatusBarHeight(this);
        wkVBinding.topBarLayout.setPadding(0, statusBarHeight, 0, 0);
        setupAgreementCheckbox();
        updateSubmitButtonState();
        updateStepUI();
    }

    @Override
    public boolean supportSlideBack() {
        return false;
    }

    private void setupAgreementCheckbox() {
        wkVBinding.agreementCb.setResId(getContext(), R.mipmap.round_check2);
        wkVBinding.agreementCb.setDrawBackground(true);
        wkVBinding.agreementCb.setHasBorder(true);
        wkVBinding.agreementCb.setStrokeWidth(AndroidUtilities.dp(1));
        wkVBinding.agreementCb.setBorderColor(ContextCompat.getColor(getContext(), R.color.color999));
        wkVBinding.agreementCb.setSize(18);
        wkVBinding.agreementCb.setColor(Theme.colorAccount, ContextCompat.getColor(getContext(), R.color.white));
        wkVBinding.agreementCb.setVisibility(View.VISIBLE);
        wkVBinding.agreementCb.setEnabled(true);
        wkVBinding.agreementCb.setChecked(false, true);
    }

    @Override
    protected void initListener() {
        // 输入框焦点监听 - 控制标签颜色和边框颜色
        setupFocusChangeListener(wkVBinding.phoneEt, wkVBinding.phoneLabelTv, wkVBinding.phoneInputBox);
        setupFocusChangeListener(wkVBinding.emailEt, wkVBinding.emailLabelTv, wkVBinding.emailEt);
        // 其他输入框的父容器在布局完成后获取
        wkVBinding.getRoot().post(() -> {
            setupFocusChangeListener(wkVBinding.loginPwdEt, wkVBinding.loginPwdLabelTv, (View) wkVBinding.loginPwdEt.getParent());
            setupFocusChangeListener(wkVBinding.verfiEt, wkVBinding.verfiLabelTv, (View) wkVBinding.verfiEt.getParent());
            setupFocusChangeListener(wkVBinding.registerPwdEt, wkVBinding.registerPwdLabelTv, (View) wkVBinding.registerPwdEt.getParent());
        });

        // Agreement checkbox toggle
        wkVBinding.agreeTv.setOnClickListener(v -> {
            wkVBinding.agreementCb.setChecked(!wkVBinding.agreementCb.isChecked(), true);
            updateSubmitButtonState();
        });
        wkVBinding.agreementCb.setOnClickListener(v -> {
            wkVBinding.agreementCb.setChecked(!wkVBinding.agreementCb.isChecked(), true);
            updateSubmitButtonState();
        });

        // Agreement links
        wkVBinding.privacyPolicyTv.setOnClickListener(v -> showWebView(WKApiConfig.baseWebUrl + "privacy_policy.html"));
        wkVBinding.userAgreementTv.setOnClickListener(v -> showWebView(WKApiConfig.baseWebUrl + "user_agreement.html"));

        // Tab switching
        wkVBinding.phoneTab.setOnClickListener(v -> switchAccountType(ACCOUNT_TYPE_PHONE));
        wkVBinding.emailTab.setOnClickListener(v -> switchAccountType(ACCOUNT_TYPE_EMAIL));

        // Country code selector
        SingleClickUtil.onSingleClick(wkVBinding.chooseCodeTv, v -> {
            Intent intent = new Intent(this, ChooseAreaCodeActivity.class);
            intentActivityResultLauncher.launch(intent);
        });

        // Back button
        wkVBinding.backBtn.setOnClickListener(v -> returnToAccountInput());

        // Password visibility toggles
        wkVBinding.loginPwdVisibleCb.setOnCheckedChangeListener((buttonView, isChecked) -> {
            togglePasswordVisibility(wkVBinding.loginPwdEt, isChecked);
        });
        wkVBinding.registerPwdVisibleCb.setOnCheckedChangeListener((buttonView, isChecked) -> {
            togglePasswordVisibility(wkVBinding.registerPwdEt, isChecked);
        });

        // Text watchers for submit button state
        wkVBinding.phoneEt.addTextChangedListener(new SimpleTextWatcher() {
            @Override
            public void afterTextChanged(Editable s) {
                updateSubmitButtonState();
            }
        });
        wkVBinding.emailEt.addTextChangedListener(new SimpleTextWatcher() {
            @Override
            public void afterTextChanged(Editable s) {
                updateSubmitButtonState();
            }
        });
        wkVBinding.loginPwdEt.addTextChangedListener(new SimpleTextWatcher() {
            @Override
            public void afterTextChanged(Editable s) {
                updateSubmitButtonState();
            }
        });
        wkVBinding.verfiEt.addTextChangedListener(new SimpleTextWatcher() {
            @Override
            public void afterTextChanged(Editable s) {
                updateSubmitButtonState();
            }
        });
        wkVBinding.registerPwdEt.addTextChangedListener(new SimpleTextWatcher() {
            @Override
            public void afterTextChanged(Editable s) {
                updateSubmitButtonState();
            }
        });

        // Submit button
        wkVBinding.submitBtn.setOnClickListener(v -> onSubmit());

        // Get verification code
        SingleClickUtil.onSingleClick(wkVBinding.getVCodeBtn, v -> onGetVerificationCode());

        // Forget password
        SingleClickUtil.onSingleClick(wkVBinding.forgetPwdTv, v -> {
            Intent intent = new Intent(this, WKResetLoginPwdActivity.class);
            intent.putExtra("canEditPhone", true);
            intent.putExtra("type", accountType);
            startActivity(intent);
        });

        // Third party login result
        EndpointManager.getInstance().setMethod("other_login_result", object -> {
            if (!(object instanceof OtherLoginResultMenu)) return null;
            OtherLoginResultMenu menu = (OtherLoginResultMenu) object;
            if (menu.getCode() == 0) {
                loginResult(menu.getUserInfoEntity());
            } else {
                UserInfoEntity userInfo = menu.getUserInfoEntity();
                String uid = userInfo != null ? userInfo.uid : "";
                String phone = userInfo != null ? userInfo.phone : "";
                setLoginFail(menu.getCode(), uid, phone);
            }
            return null;
        });
    }

    @Override
    protected void initData() {
        super.initData();
        WKCommonModel.getInstance().getAppConfig((code, msg, wkappConfig) -> {
            this.appConfig = wkappConfig;
            if (appConfig != null && appConfig.register_invite_on == 1) {
                wkVBinding.inviteCodeEt.setHint(R.string.input_invite_code_must);
                wkVBinding.inviteLayout.setVisibility(View.VISIBLE);
            }
        });

        // Pre-fill phone if available
        UserInfoEntity userInfoEntity = WKConfig.getInstance().getUserInfo();
        if (userInfoEntity != null && !TextUtils.isEmpty(userInfoEntity.phone)) {
            wkVBinding.phoneEt.setText(userInfoEntity.phone);
            wkVBinding.phoneEt.setSelection(userInfoEntity.phone.length());
            String zone = userInfoEntity.zone;
            if (!TextUtils.isEmpty(zone)) {
                countryCode = zone;
                String codeName = countryCode.substring(2);
                wkVBinding.codeTv.setText(String.format("+%s", codeName));
            }
        }
    }

    // ==================== Tab切换 ====================

    private void switchAccountType(int type) {
        if (accountType == type) return;
        accountType = type;

        if (type == ACCOUNT_TYPE_PHONE) {
            wkVBinding.phoneTab.setSelected(true);
            wkVBinding.emailTab.setSelected(false);
            wkVBinding.phoneTab.setTextColor(ContextCompat.getColor(getContext(), R.color.color_main));
            wkVBinding.phoneTab.setTypeface(wkVBinding.phoneTab.getTypeface(), android.graphics.Typeface.BOLD);
            wkVBinding.emailTab.setTextColor(ContextCompat.getColor(getContext(), R.color.color999));
            wkVBinding.emailTab.setTypeface(wkVBinding.emailTab.getTypeface(), android.graphics.Typeface.NORMAL);

            wkVBinding.phoneInputLayout.setVisibility(View.VISIBLE);
            wkVBinding.emailInputFrame.setVisibility(View.GONE);
            wkVBinding.emailEt.setText("");
        } else {
            wkVBinding.phoneTab.setSelected(false);
            wkVBinding.emailTab.setSelected(true);
            wkVBinding.phoneTab.setTextColor(ContextCompat.getColor(getContext(), R.color.color999));
            wkVBinding.phoneTab.setTypeface(wkVBinding.phoneTab.getTypeface(), android.graphics.Typeface.NORMAL);
            wkVBinding.emailTab.setTextColor(ContextCompat.getColor(getContext(), R.color.color_main));
            wkVBinding.emailTab.setTypeface(wkVBinding.emailTab.getTypeface(), android.graphics.Typeface.BOLD);

            wkVBinding.phoneInputLayout.setVisibility(View.GONE);
            wkVBinding.emailInputFrame.setVisibility(View.VISIBLE);
            wkVBinding.phoneEt.setText("");
        }
        updateSubmitButtonState();
    }

    // ==================== 步骤切换 ====================

    private void switchStep(int step, boolean forward) {
        currentStep = step;

        if (forward) {
            wkVBinding.stepFlipper.setInAnimation(this, R.anim.login_step_forward_in);
            wkVBinding.stepFlipper.setOutAnimation(this, R.anim.login_step_forward_out);
        } else {
            wkVBinding.stepFlipper.setInAnimation(this, R.anim.login_step_backward_in);
            wkVBinding.stepFlipper.setOutAnimation(this, R.anim.login_step_backward_out);
        }
        wkVBinding.stepFlipper.setDisplayedChild(step);
        updateStepUI();
        updateSubmitButtonState();
    }

    private void updateStepUI() {
        switch (currentStep) {
            case STEP_ACCOUNT_INPUT:
                wkVBinding.backBtn.setVisibility(View.GONE);
                wkVBinding.titleTv.setText(R.string.login_sign);
                wkVBinding.subtitleTv.setText(R.string.login_account_entry_desc);
                wkVBinding.submitBtn.setText(R.string.login_next_step);
                break;
            case STEP_EXISTING_LOGIN:
                wkVBinding.backBtn.setVisibility(View.VISIBLE);
                wkVBinding.titleTv.setText(R.string.login);
                wkVBinding.subtitleTv.setText(R.string.login_account_existing_desc);
                wkVBinding.submitBtn.setText(R.string.login_sure);
                updateAccountDisplay(wkVBinding.accountDisplayTv2);
                break;
            case STEP_NEW_REGISTER:
                wkVBinding.backBtn.setVisibility(View.VISIBLE);
                wkVBinding.titleTv.setText(R.string.register);
                wkVBinding.subtitleTv.setText(R.string.login_account_new_desc);
                wkVBinding.submitBtn.setText(R.string.register);
                updateAccountDisplay(wkVBinding.accountDisplayTv3);
                break;
        }
    }

    private void updateAccountDisplay(TextView tv) {
        if (accountType == ACCOUNT_TYPE_PHONE) {
            String codeName = countryCode.substring(2);
            String phone = Objects.requireNonNull(wkVBinding.phoneEt.getText()).toString();
            tv.setText(String.format("+%s %s", codeName, phone));
        } else {
            String email = Objects.requireNonNull(wkVBinding.emailEt.getText()).toString();
            tv.setText(email);
        }
    }

    private void returnToAccountInput() {
        if (countDownTimer != null) {
            countDownTimer.cancel();
            countDownTimer = null;
            resetVerificationCodeButton();
        }
        wkVBinding.verfiEt.setText("");
        wkVBinding.registerPwdEt.setText("");
        wkVBinding.loginPwdEt.setText("");
        switchStep(STEP_ACCOUNT_INPUT, false);
    }

    // ==================== 提交逻辑 ====================

    private void onSubmit() {
        switch (currentStep) {
            case STEP_ACCOUNT_INPUT:
                checkAccountRegistration();
                break;
            case STEP_EXISTING_LOGIN:
                doLogin();
                break;
            case STEP_NEW_REGISTER:
                doRegister();
                break;
        }
    }

    // ==================== 账号校验 ====================

    private boolean validateAccount() {
        if (accountType == ACCOUNT_TYPE_PHONE) {
            String phone = Objects.requireNonNull(wkVBinding.phoneEt.getText()).toString().trim();
            if (TextUtils.isEmpty(phone)) {
                showSingleBtnDialog(getString(R.string.login_account_not_empty));
                return false;
            }
            if (countryCode.equals("0086") && phone.length() != CHINA_PHONE_LENGTH) {
                showSingleBtnDialog(getString(R.string.phone_error));
                return false;
            }
            return true;
        } else {
            String email = Objects.requireNonNull(wkVBinding.emailEt.getText()).toString().trim();
            if (TextUtils.isEmpty(email)) {
                showSingleBtnDialog(getString(R.string.login_account_not_empty));
                return false;
            }
            if (!Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
                showSingleBtnDialog(getString(R.string.login_email_invalid));
                return false;
            }
            return true;
        }
    }

    private void checkAccountRegistration() {
        if (!validateAccount()) return;
        if (!wkVBinding.agreementCb.isChecked()) {
            showSingleBtnDialog(getString(R.string.login_agree_auth_tips));
            return;
        }
        loadingPopup.show();
        loadingPopup.setTitle(getString(R.string.logging_in));
        String account = getAccount();
        loginPresenter.isRegister(countryCode, account, accountType);
    }

    // ==================== 登录 ====================

    private void doLogin() {
        String password = Objects.requireNonNull(wkVBinding.loginPwdEt.getText()).toString();
        if (TextUtils.isEmpty(password)) {
            showSingleBtnDialog(getString(R.string.pwd_not_null));
            return;
        }
        if (password.length() < MIN_PASSWORD_LENGTH || password.length() > MAX_PASSWORD_LENGTH) {
            showSingleBtnDialog(getString(R.string.pwd_length_error));
            return;
        }
        loadingPopup.show();
        loadingPopup.setTitle(getString(R.string.logging_in));
        String fullAccount = getFullAccount();
        loginPresenter.login(fullAccount, password);
    }

    // ==================== 注册 ====================

    private void doRegister() {
        String code = Objects.requireNonNull(wkVBinding.verfiEt.getText()).toString().trim();
        String password = Objects.requireNonNull(wkVBinding.registerPwdEt.getText()).toString();
        String inviteCode = Objects.requireNonNull(wkVBinding.inviteCodeEt.getText()).toString().trim();

        if (TextUtils.isEmpty(code)) {
            showSingleBtnDialog(getString(R.string.hint_verfi));
            return;
        }
        if (TextUtils.isEmpty(password)) {
            showSingleBtnDialog(getString(R.string.pwd_not_null));
            return;
        }
        if (password.length() < MIN_PASSWORD_LENGTH || password.length() > MAX_PASSWORD_LENGTH) {
            showSingleBtnDialog(getString(R.string.pwd_length_error));
            return;
        }
        if (appConfig != null && appConfig.register_invite_on == 1 && TextUtils.isEmpty(inviteCode)) {
            showSingleBtnDialog(getString(R.string.invite_code_not_null));
            return;
        }
        loadingPopup.show();
        loadingPopup.setTitle(getString(R.string.logging_in));
        if (accountType == ACCOUNT_TYPE_PHONE) {
            String phone = Objects.requireNonNull(wkVBinding.phoneEt.getText()).toString();
            loginPresenter.registerApp(code, countryCode, "", phone, password, inviteCode);
        } else {
            String email = Objects.requireNonNull(wkVBinding.emailEt.getText()).toString().trim();
            loginPresenter.emailRegisterApp(code, email, password, inviteCode);
        }
    }

    // ==================== 获取验证码 ====================

    private void onGetVerificationCode() {
        if (accountType == ACCOUNT_TYPE_PHONE) {
            String phone = Objects.requireNonNull(wkVBinding.phoneEt.getText()).toString().trim();
            if (TextUtils.isEmpty(phone)) {
                showSingleBtnDialog(getString(R.string.login_account_not_empty));
                return;
            }
            if (countryCode.equals("0086") && phone.length() != CHINA_PHONE_LENGTH) {
                showSingleBtnDialog(getString(R.string.phone_error));
                return;
            }
            loginPresenter.registerCode(countryCode, phone);
        } else {
            String email = Objects.requireNonNull(wkVBinding.emailEt.getText()).toString().trim();
            if (TextUtils.isEmpty(email)) {
                showSingleBtnDialog(getString(R.string.login_account_not_empty));
                return;
            }
            if (!Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
                showSingleBtnDialog(getString(R.string.login_email_invalid));
                return;
            }
            loginPresenter.emailRegisterCode(email);
        }
    }

    // ==================== 提交按钮状态 ====================

    private void updateSubmitButtonState() {
        boolean enabled = false;
        switch (currentStep) {
            case STEP_ACCOUNT_INPUT:
                if (accountType == ACCOUNT_TYPE_PHONE) {
                    enabled = Objects.requireNonNull(wkVBinding.phoneEt.getText()).length() > 0;
                } else {
                    enabled = Objects.requireNonNull(wkVBinding.emailEt.getText()).length() > 0;
                }
                break;
            case STEP_EXISTING_LOGIN:
                enabled = Objects.requireNonNull(wkVBinding.loginPwdEt.getText()).length() >= MIN_PASSWORD_LENGTH;
                break;
            case STEP_NEW_REGISTER:
                String code = Objects.requireNonNull(wkVBinding.verfiEt.getText()).toString();
                String pwd = Objects.requireNonNull(wkVBinding.registerPwdEt.getText()).toString();
                enabled = code.length() > 0 && pwd.length() >= MIN_PASSWORD_LENGTH;
                break;
        }
        wkVBinding.submitBtn.setEnabled(enabled);
        wkVBinding.submitBtn.setAlpha(enabled ? 1f : 0.5f);
    }

    // ==================== 验证码倒计时 ====================

    private void startCountdown() {
        wkVBinding.getVCodeBtn.setEnabled(false);
        wkVBinding.getVCodeBtn.setAlpha(0.4f);

        countDownTimer = new CountDownTimer(CODE_COUNTDOWN_MILLIS, 1000) {
            @Override
            public void onTick(long millisUntilFinished) {
                int seconds = (int) (millisUntilFinished / 1000);
                wkVBinding.getVCodeBtn.setText(String.format("%ds", seconds));
            }

            @Override
            public void onFinish() {
                resetVerificationCodeButton();
            }
        };
        countDownTimer.start();
    }

    private void resetVerificationCodeButton() {
        wkVBinding.getVCodeBtn.setEnabled(true);
        wkVBinding.getVCodeBtn.setAlpha(1f);
        wkVBinding.getVCodeBtn.setText(R.string.get_verf_code);
    }

    // ==================== 工具方法 ====================

    private String getAccount() {
        if (accountType == ACCOUNT_TYPE_PHONE) {
            return Objects.requireNonNull(wkVBinding.phoneEt.getText()).toString().trim();
        } else {
            return Objects.requireNonNull(wkVBinding.emailEt.getText()).toString().trim();
        }
    }

    private String getFullAccount() {
        if (accountType == ACCOUNT_TYPE_PHONE) {
            return countryCode + Objects.requireNonNull(wkVBinding.phoneEt.getText()).toString().trim();
        } else {
            return Objects.requireNonNull(wkVBinding.emailEt.getText()).toString().trim();
        }
    }

    private void togglePasswordVisibility(EditText editText, boolean show) {
        if (show) {
            editText.setTransformationMethod(HideReturnsTransformationMethod.getInstance());
        } else {
            editText.setTransformationMethod(PasswordTransformationMethod.getInstance());
        }
        editText.setSelection(Objects.requireNonNull(editText.getText()).length());
    }

    // ==================== LoginView 回调 ====================

    @Override
    public void loginResult(UserInfoEntity userInfoEntity) {
        loadingPopup.dismiss();
        SoftKeyboardUtils.getInstance().hideSoftKeyboard(this);

        if (TextUtils.isEmpty(userInfoEntity.name)) {
            Intent intent = new Intent(this, PerfectUserInfoActivity.class);
            startActivity(intent);
            finish();
        } else {
            new Handler(Objects.requireNonNull(Looper.myLooper())).postDelayed(() -> {
                List<LoginMenu> list = EndpointManager.getInstance().invokes(EndpointCategory.loginMenus, null);
                if (WKReader.isNotEmpty(list)) {
                    for (LoginMenu menu : list) {
                        if (menu.iMenuClick != null) menu.iMenuClick.onClick();
                    }
                }
                finish();
            }, 200);
        }
    }

    @Override
    public void setCountryCode(List<CountryCodeEntity> list) {
        if (list != null && !list.isEmpty()) {
            for (CountryCodeEntity entity : list) {
                if (entity != null && entity.code != null && entity.code.equals(countryCode)) {
                    wkVBinding.codeTv.setText(String.format("+%s", entity.code.substring(2)));
                    break;
                }
            }
        }
    }

    @Override
    public void setRegisterCodeSuccess(int code, String msg, int exist) {
        loadingPopup.dismiss();
        if (code == HttpResponseCode.success) {
            if (exist == 1) {
                showSingleBtnDialog(getString(R.string.account_exist));
            } else {
                startCountdown();
            }
        } else {
            showToast(msg);
        }
    }

    @Override
    public void setAccountRegistrationResult(int code, String msg, int exist) {
        loadingPopup.dismiss();
        if (code == HttpResponseCode.success) {
            if (exist == 1) {
                switchStep(STEP_EXISTING_LOGIN, true);
            } else {
                switchStep(STEP_NEW_REGISTER, true);
            }
        } else if (code == 404) {
            // isregister接口不存在，默认走注册流程
            switchStep(STEP_NEW_REGISTER, true);
        } else {
            showSingleBtnDialog(msg);
        }
    }

    @Override
    public void setLoginFail(int code, String uid, String phone) {
        Intent intent = new Intent(this, LoginAuthActivity.class);
        intent.putExtra("phone", phone);
        intent.putExtra("uid", uid);
        startActivity(intent);
    }

    @Override
    public void setSendCodeResult(int code, String msg) {
        loadingPopup.dismiss();
        if (code == HttpResponseCode.success) {
            startCountdown();
        } else {
            showToast(msg);
        }
    }

    @Override
    public void setEmailRegisterCodeSuccess(int code, String msg) {
        loadingPopup.dismiss();
        if (code == HttpResponseCode.success) {
            startCountdown();
        } else {
            showToast(msg);
        }
    }

    @Override
    public void setResetPwdResult(int code, String msg) {
        loadingPopup.dismiss();
        if (code == HttpResponseCode.success) {
            showToast(msg != null && !msg.isEmpty() ? msg : "密码重置成功");
            finish();
        } else {
            showSingleBtnDialog(msg);
        }
    }

    @Override
    public Button getVerfiCodeBtn() {
        return null;
    }

    @Override
    public EditText getNameEt() {
        return null;
    }

    @Override
    public void showError(String msg) {
        loadingPopup.dismiss();
        showSingleBtnDialog(msg);
    }

    @Override
    public void hideLoading() {
        loadingPopup.dismiss();
    }

    @Override
    public Context getContext() {
        return this;
    }

    // ==================== Country Code Result ====================

    ActivityResultLauncher<Intent> intentActivityResultLauncher = registerForActivityResult(new ActivityResultContracts.StartActivityForResult(), result -> {
        if (result.getData() != null && result.getResultCode() == Activity.RESULT_OK) {
            CountryCodeEntity entity = result.getData().getParcelableExtra("entity");
            if (entity != null) {
                countryCode = entity.code;
                String codeName = countryCode.substring(2);
                wkVBinding.codeTv.setText(String.format("+%s", codeName));
            }
        }
    });

    @Override
    public void finish() {
        super.finish();
        EndpointManager.getInstance().remove("other_login_result");
        if (countDownTimer != null) {
            countDownTimer.cancel();
        }
    }

    private void setupFocusChangeListener(EditText editText, TextView labelTv, View boxView) {
        editText.setOnFocusChangeListener((v, hasFocus) -> {
            if (hasFocus) {
                labelTv.setTextColor(ContextCompat.getColor(getContext(), R.color.color_main));
                if (boxView != null) {
                    boxView.setBackgroundResource(R.drawable.bg_login_outline_input_focused);
                }
            } else {
                labelTv.setTextColor(ContextCompat.getColor(getContext(), R.color.color999));
                if (boxView != null) {
                    boxView.setBackgroundResource(R.drawable.bg_login_outline_input_normal);
                }
            }
        });
    }

    // ==================== TextWatcher ====================

    private abstract static class SimpleTextWatcher implements TextWatcher {
        @Override
        public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

        @Override
        public void onTextChanged(CharSequence s, int start, int before, int count) {}
    }
}
