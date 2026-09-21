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
import com.chat.uikit.databinding.ActFileHelperLayoutBinding;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.ArrayList;
import java.util.List;

/**
 * 文件传输助手详情页
 * 用于在手机与电脑间传输文字、图片、音频、视频等文件
 */
public class WKFileHelperActivity extends WKBaseActivity<ActFileHelperLayoutBinding> {

    @Override
    protected ActFileHelperLayoutBinding getViewBinding() {
        return ActFileHelperLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.wk_file_helper);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        // 设置头像
        wkVBinding.avatarView.setSize(70);
        wkVBinding.avatarView.showAvatar(WKSystemAccount.system_file_helper, WKChannelType.PERSONAL);

        // 设置名称和ID
        wkVBinding.nameTv.setText(R.string.wk_file_helper);
        wkVBinding.appIdNumLeftTv.setText(String.format(getString(R.string.app_idnum), getString(R.string.app_name)));
        wkVBinding.appIdNumTv.setText(WKSystemAccount.system_file_helper_short_no);

        // 设置功能描述
        wkVBinding.descTv.setText(R.string.function_desc_tips);
    }

    @Override
    protected void initListener() {
        // 点击头像查看大图
        wkVBinding.avatarView.setOnClickListener(v -> showAvatar());

        // 发消息按钮
        SingleClickUtil.onSingleClick(wkVBinding.sendMsgBtn, v -> startChat());
    }

    /**
     * 打开与文件助手的聊天界面
     */
    private void startChat() {
        WKIMUtils.getInstance().startChatActivity(new ChatViewMenu(
                this,
                WKSystemAccount.system_file_helper,
                WKChannelType.PERSONAL,
                0,
                true
        ));
    }

    /**
     * 显示头像大图
     */
    private void showAvatar() {
        String uri = WKApiConfig.getAvatarUrl(WKSystemAccount.system_file_helper)
                + "?key=" + WKTimeUtils.getInstance().getCurrentMills();
        List<Object> tempImgList = new ArrayList<>();
        List<ImageView> imageViewList = new ArrayList<>();
        imageViewList.add(wkVBinding.avatarView.imageView);
        tempImgList.add(WKApiConfig.getShowUrl(uri));
        int index = 0;
        WKDialogUtils.getInstance().showImagePopup(
                this,
                tempImgList,
                imageViewList,
                wkVBinding.avatarView.imageView,
                index,
                new ArrayList<>(),
                null,
                null
        );
    }
}
