package com.chat.uikit.group;

import android.annotation.SuppressLint;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKReader;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActOutGroupMembersLayoutBinding;
import com.chat.uikit.group.adapter.OutGroupMemberAdapter;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannelMember;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.ArrayList;
import java.util.List;

/**
 * 已退群成员页面
 */
public class OutGroupMembersActivity extends WKBaseActivity<ActOutGroupMembersLayoutBinding> {
    private String groupNo;
    private OutGroupMemberAdapter adapter;

    @Override
    protected ActOutGroupMembersLayoutBinding getViewBinding() {
        return ActOutGroupMembersLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.exit_members);
    }

    @Override
    protected void initPresenter() {
        groupNo = getIntent().getStringExtra("groupNo");
        if (TextUtils.isEmpty(groupNo)) {
            finish();
            return;
        }
    }

    @SuppressLint("SetTextI18n")
    @Override
    protected void initView() {
        wkVBinding.recyclerView.setLayoutManager(new androidx.recyclerview.widget.LinearLayoutManager(this));
        adapter = new OutGroupMemberAdapter(new ArrayList<>());
        wkVBinding.recyclerView.setAdapter(adapter);

        // 禁用下拉刷新和上拉加载（本地数据无需刷新）
        wkVBinding.refreshLayout.setEnableRefresh(false);
        wkVBinding.refreshLayout.setEnableLoadMore(false);
    }

    @Override
    protected void initListener() {
    }

    @Override
    protected void initData() {
        super.initData();
        loadOutGroupMembers();
    }

    /**
     * 加载已退群成员
     * 从本地数据库获取群成员，筛选出已退出的成员（isDeleted == 1）
     * 注意：SDK 的 getMembers() 可能只返回正常成员（isDeleted == 0），
     *       如果本地数据库中没有已删除成员的记录，则显示空状态。
     */
    private void loadOutGroupMembers() {
        List<WKChannelMember> allMembers = WKIM.getInstance().getChannelMembersManager()
                .getMembers(groupNo, WKChannelType.GROUP);
        List<WKChannelMember> outMemberList = new ArrayList<>();
        if (WKReader.isNotEmpty(allMembers)) {
            for (WKChannelMember member : allMembers) {
                // 筛选已删除/已退出的成员
                if (member.isDeleted == 1) {
                    outMemberList.add(member);
                }
            }
        }
        adapter.setList(outMemberList);
        updateEmptyView(outMemberList);
    }

    private void updateEmptyView(List<WKChannelMember> list) {
        if (WKReader.isEmpty(list)) {
            wkVBinding.emptyTv.setVisibility(View.VISIBLE);
            wkVBinding.recyclerView.setVisibility(View.GONE);
        } else {
            wkVBinding.emptyTv.setVisibility(View.GONE);
            wkVBinding.recyclerView.setVisibility(View.VISIBLE);
        }
    }
}
