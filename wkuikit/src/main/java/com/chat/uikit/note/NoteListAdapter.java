package com.chat.uikit.note;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import com.chat.uikit.R;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

/**
 * 笔记列表适配器
 */
public class NoteListAdapter extends RecyclerView.Adapter<NoteListAdapter.ViewHolder> {

    private List<NoteEntity> list;
    private OnItemClickListener listener;
    private OnItemMoreClickListener moreListener;
    private boolean allSelected = false;
    private boolean selectMode = false;
    private Set<Integer> selectedPositions = new HashSet<>();

    public interface OnItemClickListener {
        void onItemClick(int position);
    }

    public interface OnItemMoreClickListener {
        void onMoreClick(int position);
    }

    public void setOnItemClickListener(OnItemClickListener listener) {
        this.listener = listener;
    }

    public void setOnItemMoreClickListener(OnItemMoreClickListener listener) {
        this.moreListener = listener;
    }

    public void setAllSelected(boolean selected) {
        this.allSelected = selected;
        notifyDataSetChanged();
    }

    public void setSelectMode(boolean mode) {
        this.selectMode = mode;
        if (!mode) {
            selectedPositions.clear();
        }
        notifyDataSetChanged();
    }

    public boolean isSelectMode() {
        return selectMode;
    }

    public void toggleSelect(int position) {
        if (selectedPositions.contains(position)) {
            selectedPositions.remove(position);
        } else {
            selectedPositions.add(position);
        }
        notifyItemChanged(position);
    }

    public List<Integer> getSelectedPositions() {
        return new ArrayList<>(selectedPositions);
    }

    public boolean isAllSelected() {
        return !selectedPositions.isEmpty() && selectedPositions.size() == list.size();
    }

    public void selectAll() {
        selectedPositions.clear();
        for (int i = 0; i < list.size(); i++) {
            selectedPositions.add(i);
        }
        notifyDataSetChanged();
    }

    public void clearSelection() {
        selectedPositions.clear();
        notifyDataSetChanged();
    }

    public boolean isSelected(int position) {
        return selectedPositions.contains(position);
    }

    public NoteListAdapter(List<NoteEntity> list) {
        this.list = list;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_notelist2, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        NoteEntity item = list.get(position);
        holder.titleTv.setText(item.title != null && !item.title.isEmpty() ? item.title : "无标题");
        holder.contentTv.setText(item.content != null ? item.content : "");
        holder.timeTv.setText(item.time != null ? item.time : "");
        holder.tagTv.setText(item.groupName != null ? item.groupName : "未分组");
        holder.topIv.setVisibility(item.isTop && !selectMode ? View.VISIBLE : View.GONE);

        // 选择模式下显示圆圈
        if (selectMode) {
            holder.checkIv.setVisibility(View.VISIBLE);
            holder.moreIv.setVisibility(View.GONE);
            if (isSelected(position)) {
                holder.checkIv.setImageResource(R.mipmap.ic_note_checked);
            } else {
                holder.checkIv.setImageResource(R.mipmap.ic_uncheck);
            }
        } else if (allSelected) {
            holder.checkIv.setVisibility(View.VISIBLE);
            holder.moreIv.setVisibility(View.VISIBLE);
            holder.checkIv.setImageResource(R.mipmap.ic_note_checked);
        } else {
            holder.checkIv.setVisibility(View.GONE);
            holder.moreIv.setVisibility(View.VISIBLE);
        }

        holder.itemView.setOnClickListener(v -> {
            if (selectMode) {
                toggleSelect(holder.getAdapterPosition());
            } else if (listener != null) {
                listener.onItemClick(position);
            }
        });

        holder.moreIv.setOnClickListener(v -> {
            if (moreListener != null) {
                moreListener.onMoreClick(position);
            }
        });
    }

    @Override
    public int getItemCount() {
        return list.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        TextView titleTv;
        TextView contentTv;
        TextView timeTv;
        TextView tagTv;
        ImageView topIv;
        ImageView moreIv;
        ImageView checkIv;

        ViewHolder(View itemView) {
            super(itemView);
            titleTv = itemView.findViewById(R.id.txt_note_title);
            contentTv = itemView.findViewById(R.id.tv_content);
            timeTv = itemView.findViewById(R.id.txt_note_time);
            tagTv = itemView.findViewById(R.id.txt_note_tag);
            topIv = itemView.findViewById(R.id.img_btn_top);
            moreIv = itemView.findViewById(R.id.img_note_more);
            checkIv = itemView.findViewById(R.id.checkIv);
        }
    }
}
