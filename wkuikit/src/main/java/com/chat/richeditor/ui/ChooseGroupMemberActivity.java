package com.chat.richeditor.ui;

import android.content.Intent;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.chad.library.adapter.base.BaseQuickAdapter;
import com.chad.library.adapter.base.viewholder.BaseViewHolder;
import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKConfig;
import com.chat.base.ui.components.AvatarView;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActChooseMemberLayoutRichBinding;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannelMember;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.ArrayList;
import java.util.List;

public class ChooseGroupMemberActivity extends WKBaseActivity<ActChooseMemberLayoutRichBinding> {

    public static final String KEY_CHANNEL_ID = "channel_id";
    public static final String KEY_CHANNEL_TYPE = "channel_type";

    private String channelID;
    private byte channelType;
    private List<WKChannelMember> memberList = new ArrayList<>();
    private List<WKChannelMember> searchList = new ArrayList<>();
    private MemberAdapter adapter;
    private String searchKey = "";

    @Override
    protected ActChooseMemberLayoutRichBinding getViewBinding() {
        return ActChooseMemberLayoutRichBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.choose_member);
    }

    @Override
    protected void initPresenter() {
        channelID = getIntent().getStringExtra(KEY_CHANNEL_ID);
        channelType = getIntent().getByteExtra(KEY_CHANNEL_TYPE, (byte) 2);
    }

    @Override
    protected void initView() {
        RecyclerView recyclerView = wkVBinding.recyclerView;
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        adapter = new MemberAdapter();
        adapter.setOnItemClickListener((adapter, view, position) -> {
            WKChannelMember member = (WKChannelMember) adapter.getItem(position);
            if (member != null) {
                Intent result = new Intent();
                result.putExtra("member_uid", member.memberUID);
                String name = TextUtils.isEmpty(member.memberRemark) ? member.memberName : member.memberRemark;
                result.putExtra("member_name", name);
                setResult(RESULT_OK, result);
                finish();
            }
        });
        recyclerView.setAdapter(adapter);
    }

    @Override
    protected void initListener() {
        wkVBinding.searchET.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                searchKey = s == null ? "" : s.toString().trim();
                filterMembers();
            }

            @Override
            public void afterTextChanged(Editable s) {}
        });

        wkVBinding.refreshLayout.setOnRefreshListener(refreshLayout -> loadData());
    }

    @Override
    protected void initData() {
        loadData();
    }

    private void loadData() {
        List<WKChannelMember> members = WKIM.getInstance().getChannelMembersManager()
                .getMembers(channelID, channelType);
        if (members != null) {
            memberList.clear();
            String myUID = WKConfig.getInstance().getUid();
            for (WKChannelMember member : members) {
                if (!TextUtils.equals(member.memberUID, myUID)) {
                    memberList.add(member);
                }
            }
            filterMembers();
        }
        wkVBinding.refreshLayout.finishRefresh();
    }

    private void filterMembers() {
        searchList.clear();
        if (TextUtils.isEmpty(searchKey)) {
            searchList.addAll(memberList);
        } else {
            for (WKChannelMember member : memberList) {
                String name = TextUtils.isEmpty(member.memberRemark) ? member.memberName : member.memberRemark;
                if (name != null && name.toLowerCase().contains(searchKey.toLowerCase())) {
                    searchList.add(member);
                }
            }
        }
        adapter.setNewInstance(searchList);
    }

    private static class MemberAdapter extends BaseQuickAdapter<WKChannelMember, MemberAdapter.MemberViewHolder> {

        public MemberAdapter() {
            super(R.layout.item_rich_member_layout);
        }

        @Override
        protected void convert(@NonNull MemberViewHolder holder, WKChannelMember member) {
            String showName = TextUtils.isEmpty(member.memberRemark) ? member.memberName : member.memberRemark;
            holder.nameTv.setText(showName);
            holder.avatarView.setSize(40);
            holder.avatarView.showAvatar(member.memberUID, WKChannelType.PERSONAL, member.memberAvatar);
        }

        static class MemberViewHolder extends BaseViewHolder {
            AvatarView avatarView;
            TextView nameTv;

            public MemberViewHolder(@NonNull View itemView) {
                super(itemView);
                avatarView = itemView.findViewById(R.id.avatarView);
                nameTv = itemView.findViewById(R.id.nameTv);
            }
        }
    }
}
