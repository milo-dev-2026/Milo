package com.chat.uikit.group;

import android.content.Intent;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.endpoint.entity.ChatViewMenu;
import com.chat.base.utils.WKReader;
import com.chat.uikit.R;
import com.chat.uikit.chat.manager.WKIMUtils;
import com.chat.uikit.contacts.ChooseContactsActivity;
import com.chat.uikit.databinding.ActJoinedGroupsLayoutBinding;
import com.chat.uikit.group.adapter.JoinedGroupAdapter;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannel;
import com.xinbida.wukongim.entity.WKConversationMsg;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.ArrayList;
import java.util.List;

/**
 * 我加入的群组
 */
public class JoinedGroupsActivity extends WKBaseActivity<ActJoinedGroupsLayoutBinding> {
    private JoinedGroupAdapter groupAdapter;

    @Override
    protected ActJoinedGroupsLayoutBinding getViewBinding() {
        return ActJoinedGroupsLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.joined_groups);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        groupAdapter = new JoinedGroupAdapter();
        wkVBinding.rvGroupList.setLayoutManager(new androidx.recyclerview.widget.LinearLayoutManager(this));
        wkVBinding.rvGroupList.setAdapter(groupAdapter);
        wkVBinding.refreshLayout.setEnableRefresh(true);
        wkVBinding.refreshLayout.setEnableLoadMore(false);
    }

    @Override
    protected String getRightTvText(TextView textView) {
        return getString(R.string.create_new_group);
    }

    @Override
    protected void rightLayoutClick() {
        super.rightLayoutClick();
        Intent intent = new Intent(this, ChooseContactsActivity.class);
        intent.putExtra("type", 1);
        startActivity(intent);
    }

    @Override
    protected void initListener() {
        // 下拉刷新
        wkVBinding.refreshLayout.setOnRefreshListener(refreshLayout -> loadJoinedGroups());

        groupAdapter.addChildClickViewIds(R.id.contentLayout);
        groupAdapter.setOnItemChildClickListener((adapter, view1, position) -> {
            GroupEntity channel = groupAdapter.getItem(position);
            if (channel != null) {
                WKIMUtils.getInstance().startChatActivity(new ChatViewMenu(this, channel.group_no, WKChannelType.GROUP, 0, true));
            }
        });
    }

    @Override
    protected void initData() {
        super.initData();
        loadJoinedGroups();
    }

    private void loadJoinedGroups() {
        // 从会话列表获取所有群聊
        List<WKConversationMsg> conversations = WKIM.getInstance().getConversationManager().getWithChannelType(WKChannelType.GROUP);
        List<GroupEntity> list = new ArrayList<>();
        if (WKReader.isNotEmpty(conversations)) {
            for (WKConversationMsg conv : conversations) {
                if (conv != null) {
                    GroupEntity entity = new GroupEntity();
                    entity.group_no = conv.channelID;
                    // 从ChannelManager获取群名称
                    WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(conv.channelID, WKChannelType.GROUP);
                    if (channel != null) {
                        String showName = channel.channelRemark;
                        if (TextUtils.isEmpty(showName)) {
                            showName = channel.channelName;
                        }
                        entity.name = showName;
                        entity.remark = channel.channelRemark;
                        entity.avatar = channel.avatarCacheKey;
                    } else {
                        entity.name = conv.channelID;
                    }
                    list.add(entity);
                }
            }
        }
        wkVBinding.tvGroupCount.setText(String.format(getString(R.string.group_count_format), list.size()));
        groupAdapter.setList(list);
        wkVBinding.spinKit.setVisibility(View.GONE);
        wkVBinding.refreshLayout.finishRefresh();
    }

    @Override
    protected void onResume() {
        super.onResume();
        loadJoinedGroups();
    }
}
