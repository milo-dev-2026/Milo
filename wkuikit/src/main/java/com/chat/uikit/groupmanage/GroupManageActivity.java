package com.chat.uikit.groupmanage;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKConfig;
import com.chat.base.msgitem.WKChannelMemberRole;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.WKReader;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActGroupManageLayoutBinding;
import com.chat.uikit.groupmanage.adapter.GroupManageAdapter;
import com.chat.uikit.groupmanage.service.GroupManageModel;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannelMember;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * 群管理主页面
 * 展示群管理员列表(群主+管理员)
 * 群主(role=1)可添加/移除管理员
 * 管理员(role=2)仅可查看
 */
public class GroupManageActivity extends WKBaseActivity<ActGroupManageLayoutBinding> {

    private static final int REQUEST_ADD_MANAGER = 1001;

    private String groupNo;
    private GroupManageAdapter adapter;
    private int memberRole = WKChannelMemberRole.normal;

    @Override
    protected ActGroupManageLayoutBinding getViewBinding() {
        return ActGroupManageLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.group_manage);
    }

    @Override
    protected void initView() {
        groupNo = getIntent().getStringExtra("groupNo");
        if (TextUtils.isEmpty(groupNo)) {
            finish();
            return;
        }
        wkVBinding.refreshLayout.setEnableRefresh(false);
        wkVBinding.refreshLayout.setEnableLoadMore(false);
        wkVBinding.recyclerView.setLayoutManager(new LinearLayoutManager(this));
        adapter = new GroupManageAdapter(new ArrayList<>());
        wkVBinding.recyclerView.setAdapter(adapter);
        adapter.addChildClickViewIds(R.id.removeBtn);
    }

    @Override
    protected void initListener() {
        // 移除管理员按钮点击
        adapter.setOnItemChildClickListener((adapter1, view, position) -> {
            if (view.getId() == R.id.removeBtn) {
                GroupManageItemEntity item = (GroupManageItemEntity) adapter1.getItem(position);
                if (item != null && item.getMember() != null) {
                    showRemoveConfirmDialog(item.getMember());
                }
            }
        });

        // 整项点击(添加管理员按钮)
        adapter.setOnItemClickListener((adapter1, view, position) -> {
            GroupManageItemEntity item = (GroupManageItemEntity) adapter1.getItem(position);
            if (item != null && item.getItemType() == GroupManageItemEntity.TYPE_ADD) {
                Intent intent = new Intent(this, ChooseNormalMembersActivity.class);
                intent.putExtra("groupNo", groupNo);
                startActivityForResult(intent, REQUEST_ADD_MANAGER);
            }
        });

        // 监听群成员信息变化
        WKIM.getInstance().getChannelMembersManager().addOnRefreshChannelMemberInfo("group_manage_refresh_member", (channelMember, isEnd) -> {
            if (channelMember != null
                    && !TextUtils.isEmpty(channelMember.channelID)
                    && channelMember.channelID.equals(groupNo)
                    && channelMember.channelType == WKChannelType.GROUP) {
                if (isEnd) {
                    new Handler(Looper.getMainLooper()).post(this::loadData);
                }
            }
        });
    }

    @SuppressLint("SetTextI18n")
    @Override
    protected void initData() {
        super.initData();
        loadData();
    }

    /**
     * 加载群管理员数据
     */
    private void loadData() {
        // 获取当前用户的角色
        WKChannelMember currentUserMember = WKIM.getInstance().getChannelMembersManager()
                .getMember(groupNo, WKChannelType.GROUP, WKConfig.getInstance().getUid());
        if (currentUserMember != null) {
            memberRole = currentUserMember.role;
        }

        // 获取所有群成员
        List<WKChannelMember> allMembers = WKIM.getInstance().getChannelMembersManager()
                .getMembers(groupNo, WKChannelType.GROUP);

        List<GroupManageItemEntity> itemList = new ArrayList<>();

        if (WKReader.isNotEmpty(allMembers)) {
            // 筛选群主和管理员
            List<WKChannelMember> adminList = new ArrayList<>();
            for (WKChannelMember member : allMembers) {
                if (member.role == WKChannelMemberRole.admin
                        || member.role == WKChannelMemberRole.manager) {
                    adminList.add(member);
                }
            }

            // 排序: 群主在前，管理员在后
            Collections.sort(adminList, (o1, o2) -> {
                if (o1.role == WKChannelMemberRole.admin) return -1;
                if (o2.role == WKChannelMemberRole.admin) return 1;
                return 0;
            });

            for (WKChannelMember member : adminList) {
                itemList.add(new GroupManageItemEntity(GroupManageItemEntity.TYPE_ADMIN, member));
            }
        }

        // 群主可看到添加管理员按钮
        boolean isOwner = memberRole == WKChannelMemberRole.admin;
        adapter.setOwner(isOwner);
        if (isOwner) {
            itemList.add(new GroupManageItemEntity(GroupManageItemEntity.TYPE_ADD));
        }

        adapter.setList(itemList);
    }

    /**
     * 显示移除管理员确认对话框
     */
    private void showRemoveConfirmDialog(WKChannelMember member) {
        String showName = member.memberRemark;
        if (TextUtils.isEmpty(showName)) {
            showName = member.memberName;
        }
        WKDialogUtils.getInstance().showDialog(this,
                getString(R.string.remove_manager),
                String.format("%s？", getString(R.string.remove_manager_tips)),
                true,
                getString(R.string.cancel),
                getString(R.string.sure),
                0,
                ContextCompat.getColor(this, R.color.red),
                index -> {
                    if (index == 1) {
                        removeManager(member.memberUID);
                    }
                });
    }

    /**
     * 调用API移除管理员
     */
    private void removeManager(String uid) {
        showTitleRightLoading();
        GroupManageModel.getInstance().removeManager(groupNo, uid, (code, msg) -> {
            new Handler(Looper.getMainLooper()).post(() -> {
                hideTitleRightLoading();
                if (code == HttpResponseCode.success) {
                    WKToastUtils.getInstance().showToastNormal(getString(R.string.manager_removed));
                    loadData();
                } else {
                    WKToastUtils.getInstance().showToastNormal(msg);
                }
            });
        });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_ADD_MANAGER && resultCode == RESULT_OK) {
            loadData();
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        WKIM.getInstance().getChannelMembersManager().removeRefreshChannelMemberInfo("group_manage_refresh_member");
    }
}
