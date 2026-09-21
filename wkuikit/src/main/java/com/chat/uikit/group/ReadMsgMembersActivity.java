package com.chat.uikit.group;

import android.content.Context;
import android.content.Intent;
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
import com.chat.uikit.databinding.ActReadMembersLayoutBinding;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannelMember;
import com.xinbida.wukongim.entity.WKChannelType;
import com.xinbida.wukongim.entity.WKMsg;

import java.util.ArrayList;
import java.util.List;

public class ReadMsgMembersActivity extends WKBaseActivity<ActReadMembersLayoutBinding> {

    private String channelId;
    private int channelType;
    private String messageId;
    private MemberAdapter adapter;
    private final List<WKChannelMember> readMembers = new ArrayList<>();
    private final List<WKChannelMember> unreadMembers = new ArrayList<>();

    public static void start(Context context, String channelId, int channelType, String messageId) {
        Intent intent = new Intent(context, ReadMsgMembersActivity.class);
        intent.putExtra("channel_id", channelId);
        intent.putExtra("channel_type", channelType);
        intent.putExtra("message_id", messageId);
        context.startActivity(intent);
    }

    @Override
    protected ActReadMembersLayoutBinding getViewBinding() {
        return ActReadMembersLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.read_members);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        channelId = getIntent().getStringExtra("channel_id");
        channelType = getIntent().getIntExtra("channel_type", 2);
        messageId = getIntent().getStringExtra("message_id");

        adapter = new MemberAdapter();
        wkVBinding.memberRecyclerView.setLayoutManager(new LinearLayoutManager(this));
        wkVBinding.memberRecyclerView.setAdapter(adapter);

        loadMembers();
    }

    @Override
    protected void initListener() {
    }

    private void loadMembers() {
        if (TextUtils.isEmpty(channelId)) {
            return;
        }

        List<WKChannelMember> allMembers = WKIM.getInstance().getChannelMembersManager()
                .getMembers(channelId, (byte) channelType);

        WKMsg msg = null;
        if (!TextUtils.isEmpty(messageId)) {
            msg = WKIM.getInstance().getMsgManager().getWithMessageID(messageId);
        }

        readMembers.clear();
        unreadMembers.clear();

        if (allMembers != null) {
            for (WKChannelMember member : allMembers) {
                if (msg != null && msg.fromUID != null && msg.fromUID.equals(member.memberUID)) {
                    continue;
                }
                readMembers.add(member);
            }
        }

        wkVBinding.readCountTv.setText(String.format(getString(R.string.read_count), readMembers.size()));
        wkVBinding.unreadCountTv.setText(String.format(getString(R.string.unread_count), unreadMembers.size()));

        adapter.setList(readMembers);
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
