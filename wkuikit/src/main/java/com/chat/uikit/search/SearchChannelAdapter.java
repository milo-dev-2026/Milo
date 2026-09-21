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
import com.xinbida.wukongim.entity.WKChannel;

import java.util.List;

public class SearchChannelAdapter extends RecyclerView.Adapter<SearchChannelAdapter.VH> {
    private final List<WKChannel> list;
    private final String keyword;
    private final OnChannelClickListener listener;
    private final int highlightColor = 0xFF3F74FC;

    public interface OnChannelClickListener {
        void onClick(WKChannel channel);
    }

    public SearchChannelAdapter(List<WKChannel> list, String keyword, OnChannelClickListener listener) {
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
        WKChannel channel = list.get(position);
        if (channel == null) return;

        String name = channel.channelRemark;
        if (name == null || name.isEmpty()) {
            name = channel.channelName;
        }
        if (name == null) name = channel.channelID;

        holder.nameTv.setText(highlightText(name));
        holder.avatarView.setSize(40);
        holder.avatarView.showAvatar(channel.channelID, channel.channelType);

        holder.contentTv.setText("");

        holder.itemView.setOnClickListener(v -> {
            if (listener != null) listener.onClick(channel);
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
