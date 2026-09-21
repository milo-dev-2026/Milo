package com.chat.uikit.group;

import android.content.Intent;
import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.endpoint.entity.ChatViewMenu;
import com.chat.base.entity.ChannelInfoEntity;
import com.chat.base.utils.WKReader;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.chat.manager.WKIMUtils;
import com.chat.uikit.contacts.ChooseContactsActivity;
import com.chat.uikit.databinding.ActSaveGroupLayoutBinding;
import com.chat.uikit.group.adapter.SavedGroupAdapter;
import com.chat.uikit.group.service.GroupContract;
import com.chat.uikit.group.service.GroupPresenter;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannel;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.ArrayList;
import java.util.List;

/**
 * 2020-01-30 19:18
 * 我保存的群组
 */
public class SavedGroupsActivity extends WKBaseActivity<ActSaveGroupLayoutBinding> implements GroupContract.GroupView {
    private SavedGroupAdapter groupAdapter;
    private GroupPresenter presenter;
    private List<GroupEntity> allGroups = new ArrayList<>();

    @Override
    protected ActSaveGroupLayoutBinding getViewBinding() {
        return ActSaveGroupLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.saved_groups);
    }

    @Override
    protected void initPresenter() {
        presenter = new GroupPresenter(this);
    }

    @Override
    protected void initView() {
        groupAdapter = new SavedGroupAdapter();
        initAdapter(wkVBinding.recyclerView, groupAdapter);
        wkVBinding.searchIv.setVisibility(View.VISIBLE);
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
        startActivity(intent);
    }

    @Override
    protected void onResume() {
        super.onResume();
        presenter.getMyGroups();
    }

    @Override
    protected void initListener() {
        wkVBinding.refreshLayout.setOnRefreshListener(refreshLayout -> presenter.getMyGroups());
        wkVBinding.searchEt.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                filterGroups(s.toString());
            }

            @Override
            public void afterTextChanged(Editable s) {
            }
        });
        groupAdapter.addChildClickViewIds(R.id.contentLayout);
        groupAdapter.setOnItemChildClickListener((adapter, view1, position) -> {
            GroupEntity channel = groupAdapter.getItem(position);
            if (channel != null) {
                WKIMUtils.getInstance().startChatActivity(new ChatViewMenu(this, channel.group_no, WKChannelType.GROUP, 0, true));
            }
        });
    }

    private void filterGroups(String keyword) {
        if (TextUtils.isEmpty(keyword)) {
            groupAdapter.setList(allGroups);
            return;
        }
        List<GroupEntity> filtered = new ArrayList<>();
        for (GroupEntity entity : allGroups) {
            if (entity.name != null && entity.name.contains(keyword)) {
                filtered.add(entity);
            }
        }
        groupAdapter.setList(filtered);
    }

    @Override
    protected void initData() {
        super.initData();
    }

    @Override
    public void onGroupInfo(ChannelInfoEntity channelInfoEntity) {

    }

    @Override
    public void onRefreshGroupSetting(String key, int value) {

    }

    @Override
    public void setQrData(int day, String qrCode, String expire) {

    }

    @Override
    public void setMyGroups(List<GroupEntity> list) {
        wkVBinding.spinKit.setVisibility(View.GONE);
        wkVBinding.refreshLayout.finishRefresh();
        if (WKReader.isEmpty(list)) {
            wkVBinding.nodataTv.setVisibility(View.VISIBLE);
            allGroups.clear();
            groupAdapter.setList(new ArrayList<>());
        } else {
            wkVBinding.nodataTv.setVisibility(View.GONE);
            List<String> channelIds = new ArrayList<>();
            for (int i = 0, size = list.size(); i < size; i++) {
                channelIds.add(list.get(i).group_no);
            }
            List<WKChannel> channels = WKIM.getInstance().getChannelManager().getWithChannelIdsAndChannelType(channelIds, WKChannelType.GROUP);
            for (int i = 0, size = list.size(); i < size; i++) {
                for (WKChannel channel : channels) {
                    if (channel != null && !TextUtils.isEmpty(channel.channelID) && channel.channelID.equals(list.get(i).group_no)) {
                        list.get(i).avatar = channel.avatarCacheKey;
                        break;
                    }
                }
            }
            allGroups = new ArrayList<>(list);
            groupAdapter.setList(list);
        }

    }

    @Override
    public void showError(String msg) {
        wkVBinding.spinKit.setVisibility(View.GONE);
        wkVBinding.refreshLayout.finishRefresh();
        if (msg != null && !msg.isEmpty()) {
            WKToastUtils.getInstance().showToastNormal(msg);
        }
    }

    @Override
    public void hideLoading() {
        wkVBinding.spinKit.setVisibility(View.GONE);
        wkVBinding.refreshLayout.finishRefresh();
    }
}
