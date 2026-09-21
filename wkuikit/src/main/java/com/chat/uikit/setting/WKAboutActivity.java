package com.chat.uikit.setting;

import android.content.Intent;
import android.net.Uri;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.common.WKCommonModel;
import com.chat.base.config.WKApiConfig;
import com.chat.base.utils.WKDeviceUtils;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActAboutLayoutBinding;

public class WKAboutActivity extends WKBaseActivity<ActAboutLayoutBinding> {

    @Override
    protected ActAboutLayoutBinding getViewBinding() {
        return ActAboutLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.about_us);
    }

    @Override
    protected void initView() {
        String versionName = WKDeviceUtils.getInstance().getVersionName(this);
        wkVBinding.versionTv.setText(String.format(getString(R.string.about_version_format), versionName));
        wkVBinding.appNameTv.setText(R.string.app_name);
        checkNewVersion(false);
    }

    @Override
    protected void initListener() {
        SingleClickUtil.onSingleClick(wkVBinding.userAgreementLayout, v ->
                openWebPage(WKApiConfig.baseWebUrl + "user_agreement.html"));

        SingleClickUtil.onSingleClick(wkVBinding.privacyPolicyLayout, v ->
                openWebPage(WKApiConfig.baseWebUrl + "privacy_policy.html"));

        SingleClickUtil.onSingleClick(wkVBinding.thirdPartyLayout, v ->
                openWebPage(WKApiConfig.baseWebUrl + "sdk_info.html"));

        SingleClickUtil.onSingleClick(wkVBinding.checkUpdateLayout, v -> checkNewVersion(true));
    }

    private void openWebPage(String url) {
        if (TextUtils.isEmpty(url)) {
            showToast(R.string.current_is_latest_version);
            return;
        }
        try {
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
        } catch (Exception e) {
            showToast(R.string.current_is_latest_version);
        }
    }

    private void checkNewVersion(boolean showDialog) {
        WKCommonModel.getInstance().getAppNewVersion(showDialog, version -> {
            if (version != null && !TextUtils.isEmpty(version.download_url)) {
                wkVBinding.newVersionIv.setVisibility(View.VISIBLE);
                if (showDialog) {
                    WKDialogUtils.getInstance().showNewVersionDialog(WKAboutActivity.this, version);
                }
            } else {
                wkVBinding.newVersionIv.setVisibility(View.GONE);
                if (showDialog) {
                    showToast(R.string.current_is_latest_version);
                }
            }
        });
    }
}
