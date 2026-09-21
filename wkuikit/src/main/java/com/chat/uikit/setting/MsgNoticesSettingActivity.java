package com.chat.uikit.setting;

import android.app.TimePickerDialog;
import android.text.TextUtils;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKConfig;
import com.chat.base.config.WKConstants;
import com.chat.base.entity.UserInfoEntity;
import com.chat.base.entity.UserInfoSetting;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.utils.systembar.WKOSUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActMsgNoticesSetLayoutBinding;
import com.chat.uikit.user.service.UserModel;

public class MsgNoticesSettingActivity extends WKBaseActivity<ActMsgNoticesSetLayoutBinding> {
    UserInfoEntity userInfoEntity;

    @Override
    protected ActMsgNoticesSetLayoutBinding getViewBinding() {
        return ActMsgNoticesSetLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.message_notification);
    }

    @Override
    protected void initPresenter() {
        userInfoEntity = WKConfig.getInstance().getUserInfo();
        if (userInfoEntity == null) {
            userInfoEntity = new UserInfoEntity();
            UserInfoSetting setting = new UserInfoSetting();
            setting.new_msg_notice = 1;
            setting.voice_on = 1;
            setting.shock_on = 1;
            setting.msg_show_detail = 1;
            setting.dnd_on = 0;
            setting.dnd_start = "22:00";
            setting.dnd_end = "08:00";
            userInfoEntity.setting = setting;
        }
        if (userInfoEntity.setting == null) {
            userInfoEntity.setting = new UserInfoSetting();
            userInfoEntity.setting.new_msg_notice = 1;
            userInfoEntity.setting.voice_on = 1;
            userInfoEntity.setting.shock_on = 1;
            userInfoEntity.setting.msg_show_detail = 1;
            userInfoEntity.setting.dnd_on = 0;
            userInfoEntity.setting.dnd_start = "22:00";
            userInfoEntity.setting.dnd_end = "08:00";
        }
        if (TextUtils.isEmpty(userInfoEntity.setting.dnd_start)) {
            userInfoEntity.setting.dnd_start = "22:00";
        }
        if (TextUtils.isEmpty(userInfoEntity.setting.dnd_end)) {
            userInfoEntity.setting.dnd_end = "08:00";
        }
    }

    @Override
    protected void initView() {
        if (userInfoEntity == null || userInfoEntity.setting == null) return;
        wkVBinding.newMsgNoticeSwitch.setChecked(userInfoEntity.setting.new_msg_notice == 1);
        wkVBinding.voiceSwitch.setChecked(userInfoEntity.setting.voice_on == 1);
        wkVBinding.shockSwitch.setChecked(userInfoEntity.setting.shock_on == 1);
        wkVBinding.newMsgNoticeDetailSwitch.setChecked(userInfoEntity.setting.msg_show_detail == 1);
        wkVBinding.dndSwitch.setChecked(userInfoEntity.setting.dnd_on == 1);
        wkVBinding.dndStartTimeTv.setText(userInfoEntity.setting.dnd_start);
        wkVBinding.dndEndTimeTv.setText(userInfoEntity.setting.dnd_end);
        updateDndTimeViewsEnabled();
    }

    @Override
    protected void initListener() {
        wkVBinding.newMsgNoticeSwitch.setOnCheckedChangeListener((compoundButton, b) -> {
            if (compoundButton.isPressed()) {
                userInfoEntity.setting.new_msg_notice = b ? 1 : 0;
                UserModel.getInstance().updateUserSetting("new_msg_notice", userInfoEntity.setting.new_msg_notice, (code, msg) -> {
                    if (code == HttpResponseCode.success) {
                        WKConfig.getInstance().saveUserInfo(userInfoEntity);
                    } else showToast(msg);
                });
            }
        });
        wkVBinding.voiceSwitch.setOnCheckedChangeListener((compoundButton, b) -> {
            if (compoundButton.isPressed()) {
                userInfoEntity.setting.voice_on = b ? 1 : 0;
                UserModel.getInstance().updateUserSetting("voice_on", userInfoEntity.setting.voice_on, (code, msg) -> {
                    if (code == HttpResponseCode.success) {
                        WKConfig.getInstance().saveUserInfo(userInfoEntity);
                    } else showToast(msg);
                });
            }
        });
        wkVBinding.shockSwitch.setOnCheckedChangeListener((compoundButton, b) -> {
            if (compoundButton.isPressed()) {
                userInfoEntity.setting.shock_on = b ? 1 : 0;
                UserModel.getInstance().updateUserSetting("shock_on", userInfoEntity.setting.shock_on, (code, msg) -> {
                    if (code == HttpResponseCode.success) {
                        WKConfig.getInstance().saveUserInfo(userInfoEntity);
                    } else showToast(msg);
                });
            }
        });
        wkVBinding.newMsgNoticeDetailSwitch.setOnCheckedChangeListener((compoundButton, b) -> {
            if (compoundButton.isPressed()) {
                userInfoEntity.setting.msg_show_detail = b ? 1 : 0;
                UserModel.getInstance().updateUserSetting("msg_show_detail", userInfoEntity.setting.msg_show_detail, (code, msg) -> {
                    if (code == HttpResponseCode.success) {
                        WKConfig.getInstance().saveUserInfo(userInfoEntity);
                    } else showToast(msg);
                });
            }
        });
        wkVBinding.openNoticeLayout.setOnClickListener(v ->
                WKOSUtils.openChannelSetting(this, WKConstants.newMsgChannelID));
        wkVBinding.openRTCNoticeLayout.setOnClickListener(v ->
                WKOSUtils.openChannelSetting(this, WKConstants.newRTCChannelID));

        // 免打扰开关
        wkVBinding.dndSwitch.setOnCheckedChangeListener((compoundButton, b) -> {
            if (compoundButton.isPressed()) {
                userInfoEntity.setting.dnd_on = b ? 1 : 0;
                UserModel.getInstance().updateUserSetting("dnd_on", userInfoEntity.setting.dnd_on, (code, msg) -> {
                    if (code == HttpResponseCode.success) {
                        WKConfig.getInstance().saveUserInfo(userInfoEntity);
                        updateDndTimeViewsEnabled();
                    } else showToast(msg);
                });
            }
        });

        // 免打扰开始时间
        wkVBinding.dndStartTimeLayout.setOnClickListener(v -> showTimePicker(true));
        // 免打扰结束时间
        wkVBinding.dndEndTimeLayout.setOnClickListener(v -> showTimePicker(false));
    }

    private void updateDndTimeViewsEnabled() {
        boolean enabled = userInfoEntity != null && userInfoEntity.setting != null && userInfoEntity.setting.dnd_on == 1;
        wkVBinding.dndStartTimeLayout.setEnabled(enabled);
        wkVBinding.dndEndTimeLayout.setEnabled(enabled);
        wkVBinding.dndStartTimeTv.setAlpha(enabled ? 1f : 0.5f);
        wkVBinding.dndEndTimeTv.setAlpha(enabled ? 1f : 0.5f);
    }

    private void showTimePicker(boolean isStart) {
        String timeStr = isStart ? userInfoEntity.setting.dnd_start : userInfoEntity.setting.dnd_end;
        int hour = 22, minute = 0;
        if (!TextUtils.isEmpty(timeStr) && timeStr.contains(":")) {
            try {
                String[] parts = timeStr.split(":");
                hour = Integer.parseInt(parts[0]);
                minute = Integer.parseInt(parts[1]);
            } catch (Exception ignored) {
            }
        }
        TimePickerDialog dialog = new TimePickerDialog(this, (view, h, m) -> {
            String time = String.format(java.util.Locale.getDefault(), "%02d:%02d", h, m);
            String key = isStart ? "dnd_start" : "dnd_end";
            if (isStart) {
                userInfoEntity.setting.dnd_start = time;
                wkVBinding.dndStartTimeTv.setText(time);
            } else {
                userInfoEntity.setting.dnd_end = time;
                wkVBinding.dndEndTimeTv.setText(time);
            }
            UserModel.getInstance().updateUserSetting(key, time, (code, msg) -> {
                if (code == HttpResponseCode.success) {
                    WKConfig.getInstance().saveUserInfo(userInfoEntity);
                } else showToast(msg);
            });
        }, hour, minute, true);
        dialog.show();
    }
}
