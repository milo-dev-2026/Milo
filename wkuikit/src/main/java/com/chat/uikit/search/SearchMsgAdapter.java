package com.chat.uikit.search;

import android.text.Spannable;
import android.text.SpannableStringBuilder;
import android.text.style.ForegroundColorSpan;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.chat.base.ui.components.AvatarView;
import com.chat.uikit.R;
import com.xinbida.wukongim.entity.WKUIConversationMsg;

import java.util.List;

public class SearchMsgAdapter extends RecyclerView.Adapter<SearchMsgAdapter.VH> {
    private final List<WKUIConversationMsg> list;
    private final String keyword;
    private final OnMsgClickListener listener;
    private final int highlightColor = 0xFF3F74FC;

    public interface OnMsgClickListener {
        void onClick(WKUIConversationMsg msg);
    }

    public SearchMsgAdapter(List<WKUIConversationMsg> list, String keyword, OnMsgClickListener listener) {
        this.list = list;
        this.keyword = keyword;
        this.listener = listener;
    }

    @NonNull
    @Override
    public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_search_result_layout, parent, false);
        return new VH(view);
    }

    @Override
    public void onBindViewHolder(@NonNull VH holder, int position) {
        WKUIConversationMsg msg = list.get(position);
        if (msg == null) return;

        String name = "";
        if (msg.getWkChannel() != null) {
            name = msg.getWkChannel().channelRemark;
            if (name == null || name.isEmpty()) {
                name = msg.getWkChannel().channelName;
            }
        }
        if (name == null || name.isEmpty()) name = msg.channelID;

        holder.nameTv.setText(highlightText(name));

        String content = "";
        if (msg.getWkMsg() != null && msg.getWkMsg().baseContentMsgModel != null) {
            content = msg.getWkMsg().baseContentMsgModel.getSearchableWord();
        }
        if (content == null) content = "";
        holder.contentTv.setText(highlightText(content));

        holder.avatarView.setSize(40);
        if (msg.getWkChannel() != null) {
            holder.avatarView.showAvatar(msg.channelID, msg.channelType);
        }

        holder.itemView.setOnClickListener(v -> {
            if (listener != null) listener.onClick(msg);
        });
    }

    @Override
    public int getItemCount() {
        return list == null ? 0 : list.size();
    }

    private CharSequence highlightText(String text) {
        if (text == null || keyword == null || keyword.isEmpty()) return text;
        int index = text.toLowerCase().indexOf(keyword.toLowerCase());
        if (index < 0) return text;
        SpannableStringBuilder builder = new SpannableStringBuilder(text);
        builder.setSpan(new ForegroundColorSpan(highlightColor),
                index, index + keyword.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
        return builder;
    }

    static class VH extends RecyclerView.ViewHolder {
        AvatarView avatarView;
        TextView nameTv;
        TextView contentTv;

        VH(View itemView) {
            super(itemView);
            avatarView = itemView.findViewById(R.id.avatarView);
            nameTv = itemView.findViewById(R.id.nameTv);
            contentTv = itemView.findViewById(R.id.contentTv);
        }
    }
}
