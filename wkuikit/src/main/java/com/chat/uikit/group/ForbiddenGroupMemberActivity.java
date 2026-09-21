package com.chat.uikit.group;

import android.annotation.SuppressLint;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.WKReader;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActForbiddenWitchGroupMemberLayoutBinding;
import com.chat.uikit.group.adapter.ForbiddenMemberAdapter;
import com.chat.uikit.group.service.GroupModel;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannelMember;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.ArrayList;
import java.util.List;

/**
 * 群禁言成员页面
 */
public class ForbiddenGroupMemberActivity extends WKBaseActivity<ActForbiddenWitchGroupMemberLayoutBinding> {
    private String groupNo;
    private ForbiddenMemberAdapter adapter;

    @Override
    protected ActForbiddenWitchGroupMemberLayoutBinding getViewBinding() {
        return ActForbiddenWitchGroupMemberLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.forbidden_members);
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
        adapter = new ForbiddenMemberAdapter(new ArrayList<>());
        wkVBinding.recyclerView.setAdapter(adapter);
    }

    @Override
    protected void initListener() {
        adapter.setOnItemChildClickListener((adapter1, view, position) -> {
            WKChannelMember member = (WKChannelMember) adapter1.getItem(position);
            if (member != null && view.getId() == R.id.removeIv) {
                // 解除禁言
                WKDialogUtils.getInstance().showDialog(this, getString(R.string.unforbidden_member),
                        getString(R.string.unforbidden_member_tips), true, "",
                        getString(R.string.confirm), 0, getResources().getColor(R.color.colorAccent, null), index -> {
                            if (index == 1) {
                                unForbiddenMember(member.memberUID, position);
                            }
                        });
            }
        });
    }

    @Override
    protected void initData() {
        super.initData();
        loadForbiddenMembers();
    }

    private void loadForbiddenMembers() {
        // 从本地数据库获取群成员，筛选出禁言成员（status == 2）
        List<WKChannelMember> allMembers = WKIM.getInstance().getChannelMembersManager()
                .getMembers(groupNo, WKChannelType.GROUP);
        List<WKChannelMember> forbiddenList = new ArrayList<>();
        if (WKReader.isNotEmpty(allMembers)) {
            for (WKChannelMember member : allMembers) {
                if (member.status == 2) {
                    forbiddenList.add(member);
                }
            }
        }
        adapter.setList(forbiddenList);
        updateEmptyView(forbiddenList);
    }

    private void unForbiddenMember(String uid, int position) {
        GroupModel.getInstance().updateGroupMemberInfo(groupNo, uid, "status", "0", (code, msg) -> {
            if (code == HttpResponseCode.success) {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.operation_success));
                // 从列表中移除
                adapter.removeAt(position);
                updateEmptyView(adapter.getData());
            } else {
                WKToastUtils.getInstance().showToastNormal(msg);
            }
        });
    }

    private void updateEmptyView(List<WKChannelMember> list) {
        if (WKReader.isEmpty(list)) {
            wkVBinding.emptyTv.setVisibility(View.VISIBLE);
        } else {
            wkVBinding.emptyTv.setVisibility(View.GONE);
        }
    }
}
