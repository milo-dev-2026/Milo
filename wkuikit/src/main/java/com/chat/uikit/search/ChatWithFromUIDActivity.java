package com.chat.uikit.search;

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
import com.chat.base.utils.WKTimeUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActChatWithFromUidLayoutBinding;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannelType;
import com.xinbida.wukongim.entity.WKMsg;

import java.util.ArrayList;
import java.util.List;

public class ChatWithFromUIDActivity extends WKBaseActivity<ActChatWithFromUidLayoutBinding> {

    private String channelId;
    private int channelType;
    private String fromUID;
    private MsgAdapter adapter;
    private final List<WKMsg> msgList = new ArrayList<>();

    public static void start(Context context, String channelId, int channelType, String fromUID) {
        Intent intent = new Intent(context, ChatWithFromUIDActivity.class);
        intent.putExtra("channel_id", channelId);
        intent.putExtra("channel_type", channelType);
        intent.putExtra("from_uid", fromUID);
        context.startActivity(intent);
    }

    @Override
    protected ActChatWithFromUidLayoutBinding getViewBinding() {
        return ActChatWithFromUidLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.search_by_sender);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        channelId = getIntent().getStringExtra("channel_id");
        channelType = getIntent().getIntExtra("channel_type", 1);
        fromUID = getIntent().getStringExtra("from_uid");

        adapter = new MsgAdapter();
        wkVBinding.msgRecyclerView.setLayoutManager(new LinearLayoutManager(this));
        wkVBinding.msgRecyclerView.setAdapter(adapter);

        loadMessages();
    }

    @Override
    protected void initListener() {
    }

    private void loadMessages() {
        if (TextUtils.isEmpty(channelId) || TextUtils.isEmpty(fromUID)) {
            wkVBinding.emptyView.setVisibility(View.VISIBLE);
            return;
        }

        List<WKMsg> list = WKIM.getInstance().getMsgManager()
                .getWithFromUID(channelId, (byte) channelType, fromUID, 0, 500);
        msgList.clear();
        if (list != null) {
            msgList.addAll(list);
        }
        adapter.setList(msgList);
        wkVBinding.emptyView.setVisibility(msgList.isEmpty() ? View.VISIBLE : View.GONE);
    }

    private static class MsgAdapter extends BaseQuickAdapter<WKMsg, BaseViewHolder> {
        public MsgAdapter() {
            super(R.layout.item_record_msg_layout);
        }

        @Override
        protected void convert(@NonNull BaseViewHolder helper, WKMsg item) {
            AvatarView avatarView = helper.getView(R.id.avatarView);
            avatarView.showAvatar(item.fromUID, WKChannelType.PERSONAL);

            helper.setText(R.id.senderNameTv, item.fromUID != null ? item.fromUID : "");
            helper.setText(R.id.contentTv, item.baseContentMsgModel != null ? item.baseContentMsgModel.getDisplayContent() : "");
            helper.setText(R.id.timeTv, WKTimeUtils.getInstance().getTimeString(item.timestamp));
        }
    }
}
