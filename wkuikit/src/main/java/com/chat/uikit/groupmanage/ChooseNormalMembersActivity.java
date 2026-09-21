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
import androidx.recyclerview.widget.LinearLayoutManager;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKConfig;
import com.chat.base.msgitem.WKChannelMemberRole;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.utils.WKReader;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActChooseNormalMembersBinding;
import com.chat.uikit.group.GroupMemberEntity;
import com.chat.uikit.group.adapter.DeleteGroupMemberAdapter;
import com.chat.uikit.groupmanage.service.GroupManageModel;
import com.scwang.smart.refresh.layout.api.RefreshLayout;
import com.scwang.smart.refresh.layout.listener.OnRefreshLoadMoreListener;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannelMember;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.ArrayList;
import java.util.List;

/**
 * 选择普通成员添加为管理员
 * 从群成员列表中筛选role==0的普通成员
 * 多选模式，确认后调用 POST /v1/groups/{group_no}/managers API
 */
public class ChooseNormalMembersActivity extends WKBaseActivity<ActChooseNormalMembersBinding> {

    private String groupNo;
    private DeleteGroupMemberAdapter memberAdapter;
    private TextView rightBtn;
    private int page = 1;

    @Override
    protected ActChooseNormalMembersBinding getViewBinding() {
        return ActChooseNormalMembersBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.choose_normal_members);
    }

    @Override
    protected String getRightTvText(TextView textView) {
        this.rightBtn = textView;
        return getString(R.string.sure);
    }

    @Override
    protected void initView() {
        groupNo = getIntent().getStringExtra("groupNo");
        if (TextUtils.isEmpty(groupNo)) {
            finish();
            return;
        }
        memberAdapter = new DeleteGroupMemberAdapter(new ArrayList<>());
        wkVBinding.recyclerView.setLayoutManager(new LinearLayoutManager(this));
        wkVBinding.recyclerView.setAdapter(memberAdapter);
        // 隐藏顶部已选用户列表
        wkVBinding.selectUserRecyclerView.setVisibility(View.GONE);
    }

    @SuppressLint("ClickableViewAccessibility")
    @Override
    protected void initListener() {
        wkVBinding.refreshLayout.setEnableRefresh(false);
        wkVBinding.refreshLayout.setOnRefreshLoadMoreListener(new OnRefreshLoadMoreListener() {
            @Override
            public void onLoadMore(@NonNull RefreshLayout refreshLayout) {
                page++;
                getData();
            }

            @Override
            public void onRefresh(@NonNull RefreshLayout refreshLayout) {
            }
        });

        memberAdapter.setOnItemClickListener((adapter, view, position) -> {
            GroupMemberEntity entity = (GroupMemberEntity) adapter.getItem(position);
            if (entity != null && entity.isCanCheck == 1) {
                entity.checked = entity.checked == 1 ? 0 : 1;
                adapter.notifyItemChanged(position, entity);
                setRightBtn();
            }
        });
    }

    @Override
    protected void initData() {
        super.initData();
        getData();
    }

    @Override
    protected void rightLayoutClick() {
        super.rightLayoutClick();
        // 收集选中的用户UID
        List<String> selectedUids = new ArrayList<>();
        for (int i = 0, size = memberAdapter.getData().size(); i < size; i++) {
            GroupMemberEntity entity = memberAdapter.getData().get(i);
            if (entity.checked == 1) {
                selectedUids.add(entity.member.memberUID);
            }
        }

        if (WKReader.isEmpty(selectedUids)) {
            WKToastUtils.getInstance().showToastNormal(getString(R.string.choose_normal_members));
            return;
        }

        showTitleRightLoading();
        GroupManageModel.getInstance().addManagers(groupNo, selectedUids, (code, msg) -> {
            new Handler(Looper.getMainLooper()).post(() -> {
                hideTitleRightLoading();
                if (code == HttpResponseCode.success) {
                    WKToastUtils.getInstance().showToastNormal(getString(R.string.manager_added));
                    setResult(RESULT_OK);
                    finish();
                } else {
                    WKToastUtils.getInstance().showToastNormal(msg);
                }
            });
        });
    }

    private void setRightBtn() {
        int count = 0;
        for (int i = 0, size = memberAdapter.getData().size(); i < size; i++) {
            if (memberAdapter.getData().get(i).checked == 1) {
                count++;
            }
        }
        if (count > 0) {
            rightBtn.setVisibility(View.VISIBLE);
            rightBtn.setText(String.format("%s(%s)", getString(R.string.sure), count));
            showTitleRightView();
        } else {
            rightBtn.setText(R.string.sure);
            rightBtn.setVisibility(View.INVISIBLE);
            hideTitleRightView();
        }
    }

    private void getData() {
        WKIM.getInstance().getChannelMembersManager().getWithPageOrSearch(groupNo, WKChannelType.GROUP, "", page, 100, (list, b) -> {
            // 普通群直接处理数据，超级群需要等b=true（服务器返回完成）
            resortData(list);
        });
    }

    private void resortData(List<WKChannelMember> list) {
        List<GroupMemberEntity> tempList = new ArrayList<>();
        String loginUID = WKConfig.getInstance().getUid();

        for (int i = 0, size = list.size(); i < size; i++) {
            WKChannelMember member = list.get(i);
            // 排除自己
            if (loginUID.equals(member.memberUID)) continue;
            // 只显示普通成员(role==0)
            if (member.role != WKChannelMemberRole.normal) continue;

            GroupMemberEntity entity = new GroupMemberEntity(member);
            tempList.add(entity);
        }

        wkVBinding.refreshLayout.finishLoadMore();
        if (WKReader.isEmpty(tempList)) {
            wkVBinding.refreshLayout.finishLoadMoreWithNoMoreData();
        }

        if (page == 1) {
            memberAdapter.setList(tempList);
        } else {
            memberAdapter.addData(tempList);
        }

        // 初始隐藏确认按钮
        if (page == 1) {
            hideTitleRightView();
        }
    }
}
