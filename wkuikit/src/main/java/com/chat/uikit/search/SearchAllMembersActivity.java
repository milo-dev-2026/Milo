package com.chat.uikit.search;

import android.content.Context;
import android.content.Intent;
import android.text.Editable;
import android.text.TextWatcher;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.chad.library.adapter.base.BaseQuickAdapter;
import com.chad.library.adapter.base.viewholder.BaseViewHolder;
import com.chat.base.base.WKBaseActivity;
import com.chat.base.ui.components.AvatarView;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActSearchAllMembersLayoutBinding;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannelMember;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.ArrayList;
import java.util.List;

public class SearchAllMembersActivity extends WKBaseActivity<ActSearchAllMembersLayoutBinding> {

    private String channelId;
    private int channelType;
    private MemberAdapter adapter;
    private final List<WKChannelMember> allMembers = new ArrayList<>();
    private final List<WKChannelMember> filteredMembers = new ArrayList<>();

    public static void start(Context context, String channelId, int channelType) {
        Intent intent = new Intent(context, SearchAllMembersActivity.class);
        intent.putExtra("channel_id", channelId);
        intent.putExtra("channel_type", channelType);
        context.startActivity(intent);
    }

    @Override
    protected ActSearchAllMembersLayoutBinding getViewBinding() {
        return ActSearchAllMembersLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.search_members);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        channelId = getIntent().getStringExtra("channel_id");
        channelType = getIntent().getIntExtra("channel_type", 2);

        adapter = new MemberAdapter();
        wkVBinding.memberRecyclerView.setLayoutManager(new LinearLayoutManager(this));
        wkVBinding.memberRecyclerView.setAdapter(adapter);

        loadMembers();
    }

    @Override
    protected void initListener() {
        wkVBinding.searchEt.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                filterMembers(s.toString());
            }

            @Override
            public void afterTextChanged(Editable s) {
            }
        });

        adapter.setOnItemClickListener((a, view, position) -> {
            if (position < filteredMembers.size()) {
                WKChannelMember member = filteredMembers.get(position);
                ChatWithFromUIDActivity.start(this, channelId, channelType, member.memberUID);
            }
        });
    }

    private void loadMembers() {
        if (TextUtils.isEmpty(channelId)) {
            wkVBinding.emptyView.setVisibility(View.VISIBLE);
            return;
        }

        List<WKChannelMember> members = WKIM.getInstance().getChannelMembersManager()
                .getMembers(channelId, (byte) channelType);
        allMembers.clear();
        if (members != null) {
            allMembers.addAll(members);
        }
        filteredMembers.clear();
        filteredMembers.addAll(allMembers);
        adapter.setList(filteredMembers);
        wkVBinding.emptyView.setVisibility(filteredMembers.isEmpty() ? View.VISIBLE : View.GONE);
    }

    private void filterMembers(String keyword) {
        filteredMembers.clear();
        if (TextUtils.isEmpty(keyword)) {
            filteredMembers.addAll(allMembers);
        } else {
            for (WKChannelMember member : allMembers) {
                if ((member.memberName != null && member.memberName.contains(keyword))
                        || (member.memberUID != null && member.memberUID.contains(keyword))) {
                    filteredMembers.add(member);
                }
            }
        }
        adapter.setList(filteredMembers);
        wkVBinding.emptyView.setVisibility(filteredMembers.isEmpty() ? View.VISIBLE : View.GONE);
    }

    private static class MemberAdapter extends BaseQuickAdapter<WKChannelMember, BaseViewHolder> {
        public MemberAdapter() {
            super(R.layout.item_group_member_layout);
        }

        @Override
        protected void convert(@NonNull BaseViewHolder helper, WKChannelMember item) {
            AvatarView avatarView = helper.getView(R.id.avatarView);
            avatarView.showAvatar(item.memberUID, WKChannelType.GROUP);

            helper.setText(R.id.nameTv, item.memberName != null ? item.memberName : item.memberUID);
        }
    }
}
