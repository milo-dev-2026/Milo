package com.chat.uikit.favorite;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.chat.uikit.R;

import java.util.List;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

public class FavoriteAdapter extends RecyclerView.Adapter<FavoriteAdapter.ViewHolder> {

    private List<FavoriteItem> list;
    private OnItemClickListener listener;
    private OnItemLongClickListener longListener;
    private OnItemShareClickListener shareListener;
    private OnItemMoreClickListener moreListener;
    private boolean isMultiSelect = false;

    public interface OnItemClickListener {
        void onItemClick(int position);
    }

    public interface OnItemLongClickListener {
        void onItemLongClick(int position);
    }

    public interface OnItemShareClickListener {
        void onItemShareClick(int position);
    }

    public interface OnItemMoreClickListener {
        void onItemMoreClick(int position);
    }

    public void setOnItemClickListener(OnItemClickListener listener) {
        this.listener = listener;
    }

    public void setOnItemLongClickListener(OnItemLongClickListener listener) {
        this.longListener = listener;
    }

    public void setOnItemShareClickListener(OnItemShareClickListener listener) {
        this.shareListener = listener;
    }

    public void setOnItemMoreClickListener(OnItemMoreClickListener listener) {
        this.moreListener = listener;
    }

    public void setMultiSelect(boolean multiSelect) {
        this.isMultiSelect = multiSelect;
        if (!multiSelect && list != null) {
            for (FavoriteItem item : list) {
                item.isSelected = false;
            }
        }
        notifyDataSetChanged();
    }

    public boolean isMultiSelect() {
        return isMultiSelect;
    }

    public boolean hasCheckedItem() {
        if (list == null) return false;
        for (FavoriteItem item : list) {
            if (item.isSelected) return true;
        }
        return false;
    }

    public FavoriteAdapter(List<FavoriteItem> list) {
        this.list = list;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_favorite, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        if (list == null || position < 0 || position >= list.size()) return;
        FavoriteItem item = list.get(position);

        if (isMultiSelect) {
            holder.checkIv.setVisibility(View.VISIBLE);
            holder.checkIv.setImageResource(item.isSelected ?
                    com.chat.base.R.mipmap.ic_note_checked : com.chat.base.R.mipmap.ic_uncheck);
            holder.itemView.setPadding(0, 0, 0, 0);
        } else {
            holder.checkIv.setVisibility(View.GONE);
            holder.itemView.setPadding(0, 0, 0, 0);
        }

        holder.mediaLayout.setVisibility(View.GONE);
        holder.locationContainer.setVisibility(View.GONE);
        holder.titleTv.setVisibility(View.GONE);
        holder.summaryTv.setVisibility(View.GONE);
        holder.playIv.setVisibility(View.GONE);
        holder.mediaPlaceholderIv.setVisibility(View.GONE);
        holder.imageView.setImageDrawable(null);

        int typeIconRes = getTypeIconRes(item.type);
        holder.avatarIcon.setImageResource(typeIconRes);

        if (item.type == FavoriteItem.TYPE_IMAGE || item.type == FavoriteItem.TYPE_VIDEO) {
            holder.mediaLayout.setVisibility(View.VISIBLE);
            holder.mediaPlaceholderIv.setVisibility(View.VISIBLE);
            if (item.type == FavoriteItem.TYPE_VIDEO) {
                holder.playIv.setVisibility(View.VISIBLE);
                holder.mediaPlaceholderIv.setImageResource(com.chat.base.R.mipmap.ic_note_video);
            } else {
                holder.mediaPlaceholderIv.setImageResource(com.chat.base.R.mipmap.ic_note_image);
            }
            String mediaUrl = item.extra;
            if (mediaUrl != null && !mediaUrl.isEmpty()) {
                mediaUrl = com.chat.base.config.WKApiConfig.getShowUrl(mediaUrl);
                holder.mediaPlaceholderIv.setVisibility(View.GONE);
                int[] dims = com.chat.base.utils.ImageUtils.getInstance()
                        .getImageWidthAndHeightToTalk(item.width, item.height);
                ViewGroup.LayoutParams lp = holder.imageView.getLayoutParams();
                lp.width = dims[0];
                lp.height = dims[1];
                holder.imageView.setLayoutParams(lp);
                try {
                    com.chat.base.glide.GlideUtils.getInstance().showImg(holder.itemView.getContext(),
                            mediaUrl, dims[0], dims[1], holder.imageView);
                } catch (Exception e) {
                    holder.mediaPlaceholderIv.setVisibility(View.VISIBLE);
                }
            }
            String content = item.content != null ? item.content : "";
            content = content.replace("[图片]", "").replace("[视频]", "").trim();
            if (!content.isEmpty()) {
                holder.titleTv.setVisibility(View.VISIBLE);
                holder.titleTv.setText(content);
            }
        } else if (item.type == FavoriteItem.TYPE_LOCATION) {
            holder.locationContainer.setVisibility(View.VISIBLE);
            String title = extractLocationTitle(item.content);
            String address = extractLocationAddress(item.content);
            holder.locationTitleTv.setText(title);
            holder.locationAddressTv.setText(address);
        } else {
            String content = item.content != null ? item.content : "";
            List<String> lines = getLines(content);
            if (!lines.isEmpty()) {
                holder.titleTv.setVisibility(View.VISIBLE);
                holder.titleTv.setText(lines.get(0));
                if (lines.size() >= 2) {
                    holder.summaryTv.setVisibility(View.VISIBLE);
                    holder.summaryTv.setText(lines.get(1));
                }
            }
        }

        holder.authTv.setText(item.senderName != null ? item.senderName : "");
        holder.timeTv.setText(item.time != null ? item.time : "");

        holder.itemView.setOnClickListener(v -> {
            int pos = holder.getBindingAdapterPosition();
            if (pos == RecyclerView.NO_POSITION) return;
            if (isMultiSelect) {
                item.isSelected = !item.isSelected;
                notifyItemChanged(pos);
                if (listener != null) {
                    listener.onItemClick(pos);
                }
            } else if (listener != null) {
                listener.onItemClick(pos);
            }
        });

        holder.itemView.setOnLongClickListener(v -> {
            int pos = holder.getBindingAdapterPosition();
            if (pos == RecyclerView.NO_POSITION) return true;
            if (longListener != null) {
                longListener.onItemLongClick(pos);
            }
            return true;
        });

        holder.checkIv.setOnClickListener(v -> {
            int pos = holder.getBindingAdapterPosition();
            if (pos == RecyclerView.NO_POSITION) return;
            item.isSelected = !item.isSelected;
            notifyItemChanged(pos);
            if (listener != null) {
                listener.onItemClick(pos);
            }
        });
    }

    private String extractLocationTitle(String content) {
        if (content == null) return "";
        if (content.startsWith("[位置]")) {
            content = content.substring(4).trim();
        }
        int commaIdx = content.indexOf("，");
        int spaceIdx = content.indexOf(" ");
        int cut = -1;
        if (commaIdx >= 0 && spaceIdx >= 0) cut = Math.min(commaIdx, spaceIdx);
        else if (commaIdx >= 0) cut = commaIdx;
        else if (spaceIdx >= 0) cut = spaceIdx;
        if (cut > 0) return content.substring(0, cut);
        return content;
    }

    private String extractLocationAddress(String content) {
        if (content == null) return "";
        if (content.startsWith("[位置]")) {
            content = content.substring(4).trim();
        }
        int commaIdx = content.indexOf("，");
        int spaceIdx = content.indexOf(" ");
        int cut = -1;
        if (commaIdx >= 0 && spaceIdx >= 0) cut = Math.min(commaIdx, spaceIdx);
        else if (commaIdx >= 0) cut = commaIdx;
        else if (spaceIdx >= 0) cut = spaceIdx;
        if (cut >= 0 && cut + 1 < content.length()) return content.substring(cut + 1);
        return content;
    }

    private List<String> getLines(String text) {
        List<String> lines = new java.util.ArrayList<>();
        if (text == null || text.isEmpty()) return lines;
        StringBuilder current = new StringBuilder();
        for (char c : text.toCharArray()) {
            if (c == '\n') {
                if (current.length() > 0) {
                    lines.add(current.toString().trim());
                    current = new StringBuilder();
                }
            } else {
                current.append(c);
            }
        }
        if (current.length() > 0) {
            lines.add(current.toString().trim());
        }
        if (lines.isEmpty() && text.trim().length() > 0) {
            lines.add(text.trim());
        }
        return lines;
    }

    private int getTypeIconRes(int type) {
        switch (type) {
            case FavoriteItem.TYPE_TEXT:
                return com.chat.base.R.mipmap.ic_note_text;
            case FavoriteItem.TYPE_IMAGE:
                return com.chat.base.R.mipmap.ic_note_image;
            case FavoriteItem.TYPE_VIDEO:
                return com.chat.base.R.mipmap.ic_note_video;
            case FavoriteItem.TYPE_LOCATION:
                return com.chat.base.R.mipmap.ic_note_location;
            case FavoriteItem.TYPE_FILE:
                return com.chat.base.R.mipmap.ic_note_edit;
            case FavoriteItem.TYPE_VOICE:
                return com.chat.base.R.mipmap.ic_note_text;
            case FavoriteItem.TYPE_LINK:
                return com.chat.base.R.mipmap.ic_note_share;
            default:
                return com.chat.base.R.mipmap.ic_note_text;
        }
    }

    @Override
    public int getItemCount() {
        return list != null ? list.size() : 0;
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        ImageView checkIv;
        LinearLayout contentLayout;
        FrameLayout mediaLayout;
        ImageView imageView;
        ImageView mediaPlaceholderIv;
        ImageView playIv;
        LinearLayout locationContainer;
        TextView locationTitleTv;
        TextView locationAddressTv;
        TextView titleTv;
        TextView summaryTv;
        ImageView avatarIcon;
        TextView authTv;
        TextView timeTv;

        ViewHolder(View itemView) {
            super(itemView);
            checkIv = itemView.findViewById(R.id.checkIv);
            contentLayout = itemView.findViewById(R.id.contentLayout);
            mediaLayout = itemView.findViewById(R.id.mediaLayout);
            imageView = itemView.findViewById(R.id.imageView);
            mediaPlaceholderIv = itemView.findViewById(R.id.mediaPlaceholderIv);
            playIv = itemView.findViewById(R.id.playIv);
            locationContainer = itemView.findViewById(R.id.locationContainer);
            locationTitleTv = itemView.findViewById(R.id.locationTitleTv);
            locationAddressTv = itemView.findViewById(R.id.locationAddressTv);
            titleTv = itemView.findViewById(R.id.titleTv);
            summaryTv = itemView.findViewById(R.id.summaryTv);
            avatarIcon = itemView.findViewById(R.id.avatarIcon);
            authTv = itemView.findViewById(R.id.authTv);
            timeTv = itemView.findViewById(R.id.timeTv);
        }
    }
}
