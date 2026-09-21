package com.chat.uikit.note;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import com.chat.uikit.R;

import java.util.List;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

/**
 * 笔记分组Tab适配器
 */
public class NoteTabAdapter extends RecyclerView.Adapter<NoteTabAdapter.ViewHolder> {

    private List<String> list;
    private int selectPosition = 0;
    private boolean isSortMode = false;
    private OnTabClickListener listener;
    private OnDragStartListener dragStartListener;

    public interface OnTabClickListener {
        void onTabClick(int position);
    }

    public interface OnDragStartListener {
        void onDragStart(ViewHolder viewHolder);
    }

    public void setOnTabClickListener(OnTabClickListener listener) {
        this.listener = listener;
    }

    public void setOnDragStartListener(OnDragStartListener listener) {
        this.dragStartListener = listener;
    }

    public void setSelectPosition(int position) {
        this.selectPosition = position;
        notifyDataSetChanged();
    }

    public void setSortMode(boolean sortMode) {
        this.isSortMode = sortMode;
        notifyDataSetChanged();
    }

    public boolean isSortMode() {
        return isSortMode;
    }

    public NoteTabAdapter(List<String> list) {
        this.list = list;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_note_tab, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        String item = list.get(position);
        holder.tabTv.setText(item);
        // 选中状态设置在 itemView 上（背景在父布局）
        boolean isSelected = selectPosition == position;
        holder.itemView.setSelected(isSelected);
        // 动态设置文字颜色（选中白色，未选中深色）
        holder.tabTv.setTextColor(isSelected
                ? holder.itemView.getResources().getColor(R.color.white)
                : holder.itemView.getResources().getColor(R.color.colorDark));

        // 排序模式下显示拖拽手柄，非排序模式隐藏
        if (isSortMode && position >= 2) {
            holder.dragHandleIv.setVisibility(View.VISIBLE);
        } else {
            holder.dragHandleIv.setVisibility(View.GONE);
        }

        holder.itemView.setOnClickListener(v -> {
            if (!isSortMode && listener != null) {
                listener.onTabClick(holder.getBindingAdapterPosition());
            }
        });

        // 长按拖拽手柄开始拖拽
        holder.dragHandleIv.setOnLongClickListener(v -> {
            if (dragStartListener != null) {
                dragStartListener.onDragStart(holder);
            }
            return true;
        });

        // 长按 tab 也可以开始拖拽（排序模式下）
        holder.itemView.setOnLongClickListener(v -> {
            if (isSortMode && position >= 2 && dragStartListener != null) {
                dragStartListener.onDragStart(holder);
                return true;
            }
            return false;
        });
    }

    @Override
    public int getItemCount() {
        return list.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        TextView tabTv;
        ImageView dragHandleIv;

        ViewHolder(View itemView) {
            super(itemView);
            tabTv = itemView.findViewById(android.R.id.text1);
            dragHandleIv = itemView.findViewById(R.id.dragHandleIv);
        }
    }
}
