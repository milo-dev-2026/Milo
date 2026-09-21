package com.chat.uikit.label;

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
 * 标签成员适配器
 */
public class LabelMemberAdapter extends RecyclerView.Adapter<LabelMemberAdapter.ViewHolder> {

    private List<LabelEntity.LabelMember> list;
    private OnMemberDeleteListener deleteListener;
    private OnAddMemberListener addListener;
    private boolean showAddButton = true;

    public interface OnMemberDeleteListener {
        void onDelete(int position);
    }

    public interface OnAddMemberListener {
        void onAdd();
    }

    public void setOnMemberDeleteListener(OnMemberDeleteListener listener) {
        this.deleteListener = listener;
    }

    public void setOnAddMemberListener(OnAddMemberListener listener) {
        this.addListener = listener;
    }

    public void setShowAddButton(boolean show) {
        this.showAddButton = show;
    }

    public LabelMemberAdapter(List<LabelEntity.LabelMember> list) {
        this.list = list;
    }

    @Override
    public int getItemViewType(int position) {
        if (showAddButton && position == list.size()) {
            return 1; // 添加按钮
        }
        return 0; // 普通成员
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view;
        if (viewType == 1) {
            view = LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.item_label_member_add_layout, parent, false);
        } else {
            view = LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.item_label_member_layout, parent, false);
        }
        return new ViewHolder(view, viewType);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        if (getItemViewType(position) == 1) {
            // 添加按钮
            holder.itemView.setOnClickListener(v -> {
                if (addListener != null) {
                    addListener.onAdd();
                }
            });
        } else {
            LabelEntity.LabelMember item = list.get(position);
            holder.nameTv.setText(item.name);

            holder.deleteIv.setOnClickListener(v -> {
                if (deleteListener != null) {
                    deleteListener.onDelete(position);
                }
            });
        }
    }

    @Override
    public int getItemCount() {
        int count = list.size();
        if (showAddButton) {
            count++;
        }
        return count;
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        TextView nameTv;
        ImageView deleteIv;

        ViewHolder(View itemView, int viewType) {
            super(itemView);
            if (viewType == 0) {
                nameTv = itemView.findViewById(R.id.nameTv);
                deleteIv = itemView.findViewById(R.id.deleteIv);
            }
        }
    }
}
