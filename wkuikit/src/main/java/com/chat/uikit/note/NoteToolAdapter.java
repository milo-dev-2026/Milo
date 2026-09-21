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
 * 笔记编辑页工具栏适配器
 */
public class NoteToolAdapter extends RecyclerView.Adapter<NoteToolAdapter.ViewHolder> {

    public static class ToolItem {
        public int iconRes;
        public String name;
        public String id;

        public ToolItem(String id, int iconRes, String name) {
            this.id = id;
            this.iconRes = iconRes;
            this.name = name;
        }
    }

    private List<ToolItem> toolList;
    private OnToolClickListener listener;

    public interface OnToolClickListener {
        void onToolClick(String toolId);
    }

    public void setOnToolClickListener(OnToolClickListener listener) {
        this.listener = listener;
    }

    public NoteToolAdapter(List<ToolItem> toolList) {
        this.toolList = toolList;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_note_tool, parent, false);
        // 每个 item 宽度 = 屏幕宽度 / 6，均匀分布
        int screenWidth = parent.getResources().getDisplayMetrics().widthPixels;
        int itemWidth = screenWidth / 6;
        ViewGroup.LayoutParams params = view.getLayoutParams();
        params.width = itemWidth;
        view.setLayoutParams(params);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        ToolItem item = toolList.get(position);
        holder.iconIv.setImageResource(item.iconRes);
        holder.nameTv.setText(item.name);
        holder.itemView.setOnClickListener(v -> {
            if (listener != null) {
                listener.onToolClick(item.id);
            }
        });
    }

    @Override
    public int getItemCount() {
        return toolList.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        ImageView iconIv;
        TextView nameTv;

        ViewHolder(View itemView) {
            super(itemView);
            iconIv = itemView.findViewById(R.id.iconIv);
            nameTv = itemView.findViewById(R.id.nameTv);
        }
    }
}
