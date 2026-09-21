package com.chat.login.ui;

import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKConfig;
import com.chat.base.endpoint.EndpointCategory;
import com.chat.base.endpoint.EndpointManager;
import com.chat.base.endpoint.entity.LoginMenu;
import com.chat.base.entity.UserInfoEntity;
import com.chat.base.glide.ChooseMimeType;
import com.chat.base.glide.ChooseResult;
import com.chat.base.glide.GlideUtils;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.ui.Theme;
import com.chat.base.utils.WKReader;
import com.chat.login.R;
import com.chat.login.databinding.ActPerfectUserInfoLayoutBinding;
import com.chat.login.service.LoginModel;
import com.xinbida.wukongim.entity.WKChannelType;

import java.io.File;
import java.util.List;
import java.util.Objects;

/**
 * 2020-08-28 13:43
 * 完善个人资料
 */
public class PerfectUserInfoActivity extends WKBaseActivity<ActPerfectUserInfoLayoutBinding> {

    String path;

    @Override
    protected ActPerfectUserInfoLayoutBinding getViewBinding() {
        return ActPerfectUserInfoLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.wklogin_perfect_userinfo);
    }

    @Override
    protected void initView() {
        wkVBinding.avatarView.setSize(120);
        wkVBinding.avatarView.setStrokeWidth(0);
        wkVBinding.avatarView.imageView.setImageResource(R.mipmap.icon_default_header);
    }

    @Override
    protected void initListener() {
        wkVBinding.sureBtn.getBackground().setTint(Theme.colorAccount);
        wkVBinding.avatarView.setOnClickListener(v -> chooseIMG());
        wkVBinding.sureBtn.setOnClickListener(v -> {
            try {
                if (TextUtils.isEmpty(path)) {
                    showToast(R.string.wklogin_must_upload_header);
                    return;
                }
                if (!checkEditInputIsEmpty(wkVBinding.nameEt, R.string.nickname_not_null)) {
                    safeShowLoading();
                    LoginModel.getInstance().updateUserInfo("name", Objects.requireNonNull(wkVBinding.nameEt.getText()).toString(), (code, msg) -> {
                        runOnUiThread(() -> {
                            if (isActivityDestroyed()) return;
                            safeDismissLoading();
                            if (code == HttpResponseCode.success) {
                                UserInfoEntity userInfoEntity = WKConfig.getInstance().getUserInfo();
                                userInfoEntity.name = wkVBinding.nameEt.getText().toString();
                                WKConfig.getInstance().saveUserInfo(userInfoEntity);
                                WKConfig.getInstance().setUserName(wkVBinding.nameEt.getText().toString());
                                List<LoginMenu> list = EndpointManager.getInstance().invokes(EndpointCategory.loginMenus, null);
                                if (WKReader.isNotEmpty(list)) {
                                    for (LoginMenu menu : list) {
                                        if (menu.iMenuClick != null)
                                            menu.iMenuClick.onClick();
                                    }
                                }
                                setResult(RESULT_OK);
                                finish();
                            } else {
                                if (!TextUtils.isEmpty(msg)) {
                                    showToast(msg);
                                } else {
                                    showToast(R.string.wklogin_save_failed);
                                }
                            }
                        });
                    });
                }
            } catch (Exception e) {
                Log.e("PerfectUserInfo", "sureBtn click error", e);
                safeDismissLoading();
                showToast(R.string.wklogin_save_failed);
            }
        });
    }

    private boolean isActivityDestroyed() {
        return isFinishing() || isDestroyed();
    }

    private void safeShowLoading() {
        try {
            if (!isActivityDestroyed() && loadingPopup != null && !loadingPopup.isShow()) {
                loadingPopup.show();
            }
        } catch (Exception e) {
            Log.e("PerfectUserInfo", "safeShowLoading error", e);
        }
    }

    private void safeDismissLoading() {
        try {
            if (!isActivityDestroyed() && loadingPopup != null && loadingPopup.isShow()) {
                loadingPopup.dismiss();
            }
        } catch (Exception e) {
            Log.e("PerfectUserInfo", "safeDismissLoading error", e);
        }
    }

    private void chooseIMG() {
        try {
            GlideUtils.getInstance().chooseIMG(this, 1, true, ChooseMimeType.img, false, new GlideUtils.ISelectBack() {
                @Override
                public void onBack(List<ChooseResult> paths) {
                    try {
                        if (WKReader.isNotEmpty(paths) && paths.get(0) != null) {
                            String selectedPath = paths.get(0).path;
                            if (TextUtils.isEmpty(selectedPath)) {
                                runOnUiThread(() -> showToast(R.string.wklogin_image_select_error));
                                return;
                            }
                            runOnUiThread(() -> {
                                if (isActivityDestroyed()) return;
                                try {
                                    safeShowLoading();
                                    loadingPopup.setTitle(getString(R.string.wklogin_compressing));
                                } catch (Exception e) {
                                    Log.e("PerfectUserInfo", "show loading error", e);
                                }
                            });
                            compressAndUploadAvatar(selectedPath);
                        }
                    } catch (Exception e) {
                        Log.e("PerfectUserInfo", "onBack error", e);
                        runOnUiThread(() -> {
                            safeDismissLoading();
                            showToast(R.string.wklogin_image_select_error);
                        });
                    }
                }

                @Override
                public void onCancel() {
                    // 用户取消选择，不需要处理
                }
            });
        } catch (Exception e) {
            Log.e("PerfectUserInfo", "chooseIMG error", e);
            showToast(R.string.wklogin_image_select_error);
        }
    }

    private void compressAndUploadAvatar(String originalPath) {
        try {
            if (TextUtils.isEmpty(originalPath)) {
                runOnUiThread(() -> {
                    if (!isActivityDestroyed()) {
                        safeDismissLoading();
                        showToast(R.string.wklogin_image_not_exist);
                    }
                });
                return;
            }
            File imgFile = new File(originalPath);
            if (!imgFile.exists() || imgFile.length() <= 0) {
                runOnUiThread(() -> {
                    if (!isActivityDestroyed()) {
                        safeDismissLoading();
                        showToast(R.string.wklogin_image_not_exist);
                    }
                });
                return;
            }
            GlideUtils.getInstance().compressImg(this, originalPath, files -> {
                // Luban回调在子线程，切换到主线程
                runOnUiThread(() -> {
                    if (isActivityDestroyed()) return;
                    try {
                        String uploadPath;
                        if (WKReader.isNotEmpty(files) && files.get(0) != null && files.get(0).exists()) {
                            uploadPath = files.get(0).getAbsolutePath();
                        } else {
                            // 压缩失败时使用原图
                            uploadPath = originalPath;
                        }
                        path = uploadPath;
                        doUploadAvatar(uploadPath);
                    } catch (Exception e) {
                        Log.e("PerfectUserInfo", "compress result error", e);
                        safeDismissLoading();
                        showToast(R.string.wklogin_upload_failed);
                    }
                });
            });
        } catch (Exception e) {
            Log.e("PerfectUserInfo", "compress error", e);
            runOnUiThread(() -> {
                if (!isActivityDestroyed()) {
                    safeDismissLoading();
                    // 压缩失败时尝试直接上传原图
                    doUploadAvatar(originalPath);
                }
            });
        }
    }

    private void doUploadAvatar(String uploadPath) {
        try {
            if (TextUtils.isEmpty(uploadPath)) {
                safeDismissLoading();
                showToast(R.string.wklogin_image_not_exist);
                return;
            }
            File f = new File(uploadPath);
            if (!f.exists() || f.length() <= 0) {
                safeDismissLoading();
                showToast(R.string.wklogin_image_not_exist);
                return;
            }
            loadingPopup.setTitle(getString(R.string.wklogin_uploading));
            LoginModel.getInstance().uploadAvatar(uploadPath, code -> {
                // 上传回调可能在子线程，切换到主线程
                runOnUiThread(() -> {
                    if (isActivityDestroyed()) return;
                    try {
                        safeDismissLoading();
                        if (code == HttpResponseCode.success) {
                            GlideUtils.getInstance().showAvatarImg(PerfectUserInfoActivity.this, WKConfig.getInstance().getUid(), WKChannelType.PERSONAL, "", wkVBinding.avatarView.imageView);
                            wkVBinding.coverIv.setVisibility(View.GONE);
                        } else {
                            showToast(R.string.wklogin_upload_failed);
                        }
                    } catch (Exception e) {
                        Log.e("PerfectUserInfo", "upload callback error", e);
                        safeDismissLoading();
                        showToast(R.string.wklogin_upload_failed);
                    }
                });
            });
        } catch (Exception e) {
            Log.e("PerfectUserInfo", "upload error", e);
            runOnUiThread(() -> {
                if (!isActivityDestroyed()) {
                    safeDismissLoading();
                    showToast(R.string.wklogin_upload_failed);
                }
            });
        }
    }
}
