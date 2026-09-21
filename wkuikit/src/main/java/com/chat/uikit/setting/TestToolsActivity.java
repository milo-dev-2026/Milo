package com.chat.uikit.setting;

import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKApiConfig;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.BuildConfig;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityTestToolsBinding;

public class TestToolsActivity extends WKBaseActivity<ActivityTestToolsBinding> {

    @Override
    protected ActivityTestToolsBinding getViewBinding() {
        return ActivityTestToolsBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.test_tools);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        try {
            PackageInfo pInfo = getPackageManager().getPackageInfo(getPackageName(), 0);
            String version = pInfo.versionName + " (" + pInfo.versionCode + ")";
            wkVBinding.appVersionTv.setText(version);
        } catch (PackageManager.NameNotFoundException e) {
            wkVBinding.appVersionTv.setText("unknown");
        }

        String apiHost = WKApiConfig.baseUrl;
        if (apiHost == null || apiHost.isEmpty()) {
            apiHost = "default";
        }
        wkVBinding.apiEndpointTv.setText(apiHost);
    }

    @Override
    protected void initListener() {
        SingleClickUtil.onSingleClick(wkVBinding.notificationTestLayout, v -> {
            WKToastUtils.getInstance().showToastNormal(getString(R.string.notification_test_sent));
        });

        SingleClickUtil.onSingleClick(wkVBinding.pushTestLayout, v -> {
            WKToastUtils.getInstance().showToastNormal(getString(R.string.push_test_sent));
        });

        SingleClickUtil.onSingleClick(wkVBinding.crashTestLayout, v -> {
            if (BuildConfig.DEBUG) {
                throw new RuntimeException("Test crash from TestToolsActivity");
            } else {
                WKToastUtils.getInstance().showToastNormal("崩溃测试仅在调试模式下可用");
            }
        });

        SingleClickUtil.onSingleClick(wkVBinding.deviceInfoLayout, v -> {
            String info = "Brand: " + android.os.Build.BRAND
                    + "\nModel: " + android.os.Build.MODEL
                    + "\nOS: " + android.os.Build.VERSION.RELEASE
                    + "\nSDK: " + android.os.Build.VERSION.SDK_INT;
            WKToastUtils.getInstance().showToastNormal(info);
        });

        SingleClickUtil.onSingleClick(wkVBinding.appVersionLayout, v -> {
            try {
                PackageInfo pInfo = getPackageManager().getPackageInfo(getPackageName(), 0);
                WKToastUtils.getInstance().showToastNormal("v" + pInfo.versionName);
            } catch (PackageManager.NameNotFoundException e) {
                WKToastUtils.getInstance().showToastNormal("unknown");
            }
        });

        SingleClickUtil.onSingleClick(wkVBinding.apiEndpointLayout, v -> {
            String apiHost = WKApiConfig.baseUrl;
            WKToastUtils.getInstance().showToastNormal(apiHost != null ? apiHost : "default");
        });
    }
}
