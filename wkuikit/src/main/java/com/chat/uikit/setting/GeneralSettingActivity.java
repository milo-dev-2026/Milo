package com.chat.uikit.setting;

import android.content.Intent;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.ui.Theme;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityGeneralSettingBinding;

public class GeneralSettingActivity extends WKBaseActivity<ActivityGeneralSettingBinding> {

    @Override
    protected ActivityGeneralSettingBinding getViewBinding() {
        return ActivityGeneralSettingBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.general_settings);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        updateDarkStatus();
        updateLanguageStatus();
    }

    private void updateDarkStatus() {
        String theme = Theme.getTheme();
        if (Theme.DARK_MODE.equals(theme)) {
            wkVBinding.darkStatusTv.setText(R.string.enabled);
        } else {
            wkVBinding.darkStatusTv.setText(R.string.disabled);
        }
    }

    private void updateLanguageStatus() {
        String currentLang = getResources().getConfiguration().locale.getLanguage();
        if ("zh".equals(currentLang)) {
            wkVBinding.languageStatusTv.setText(R.string.language_simplified_chinese);
        } else if ("en".equals(currentLang)) {
            wkVBinding.languageStatusTv.setText(R.string.language_english);
        } else {
            wkVBinding.languageStatusTv.setText(R.string.language_simplified_chinese);
        }
    }

    @Override
    protected void initListener() {
        SingleClickUtil.onSingleClick(wkVBinding.darkLayout, v -> {
            startActivity(new Intent(this, WKThemeSettingActivity.class));
        });

        SingleClickUtil.onSingleClick(wkVBinding.languageLayout, v -> {
            startActivity(new Intent(this, WKLanguageActivity.class));
        });

        SingleClickUtil.onSingleClick(wkVBinding.fontSizeLayout, v -> {
            startActivity(new Intent(this, WKSetFontSizeActivity.class));
        });
    }

    @Override
    protected void onResume() {
        super.onResume();
        updateDarkStatus();
        updateLanguageStatus();
    }
}
