package com.chat.uikit.user;

import android.widget.ImageView;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKApiConfig;
import com.chat.base.config.WKSystemAccount;
import com.chat.base.endpoint.entity.ChatViewMenu;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.WKTimeUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.chat.manager.WKIMUtils;
import com.chat.uikit.databinding.ActSystemTeamLayoutBinding;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannel;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.ArrayList;
import java.util.List;

/**
 * 1/29/21 12:00 PM
 * 系统团队
 */
public class WKSystemTeamActivity extends WKBaseActivity<ActSystemTeamLayoutBinding> {
    @Override
    protected ActSystemTeamLayoutBinding getViewBinding() {
        return ActSystemTeamLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.wk_system_notice);
    }


    @Override
    protected void initView() {
        wkVBinding.appIdNumLeftTv.setText(String.format(getString(R.string.app_idnum), getString(R.string.app_name)));
        wkVBinding.functionNameTv.setText(String.format(getString(R.string.function_system_team_tips), getString(R.string.app_name)));
        WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(WKSystemAccount.system_team, WKChannelType.PERSONAL);
        wkVBinding.nameTv.setText(R.string.wk_system_notice);
        wkVBinding.appIdNumTv.setText(WKSystemAccount.system_team_short_no);
        wkVBinding.avatarView.setSize(70);
        if (channel != null) {
            wkVBinding.avatarView.showAvatar(channel);
        } else {
            wkVBinding.avatarView.showAvatar(WKSystemAccount.system_team, WKChannelType.PERSONAL);
        }
        SingleClickUtil.onSingleClick(wkVBinding.sendMsgBtn, v -> WKIMUtils.getInstance().startChatActivity(new ChatViewMenu(this, WKSystemAccount.system_team, WKChannelType.PERSONAL, 0, true)));
    }

    @Override
    protected void initListener() {
        wkVBinding.avatarView.setOnClickListener(v -> showImg());
    }

    private void showImg() {
        // 系统团队使用本地头像
        List<Object> tempImgList = new ArrayList<>();
        List<ImageView> imageViewList = new ArrayList<>();
        imageViewList.add(wkVBinding.avatarView.imageView);
        tempImgList.add(com.chat.base.R.drawable.ic_system_avatar);
        int index = 0;
        WKDialogUtils.getInstance().showImagePopup(this, tempImgList, imageViewList, wkVBinding.avatarView.imageView, index, new ArrayList<>(), null, null);
    }
}
