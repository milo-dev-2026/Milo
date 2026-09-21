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
 * 选择标签适配器
 */
public class ChooseLabelAdapter extends RecyclerView.Adapter<ChooseLabelAdapter.ViewHolder> {

    private List<LabelEntity> list;
    private OnLabelCheckListener listener;

    public interface OnLabelCheckListener {
        void onCheck(int position, boolean isChecked);
    }

    public void setOnLabelCheckListener(OnLabelCheckListener listener) {
        this.listener = listener;
    }

    public ChooseLabelAdapter(List<LabelEntity> list) {
        this.list = list;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_choose_label_layout, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        LabelEntity item = list.get(position);
        holder.nameTv.setText(item.name);
        holder.contentTv.setText(item.memberCount + "个联系人");

        // 根据选中状态设置复选框
        holder.checkIv.setSelected(item.members != null && item.members.size() > 0
                && item.members.stream().anyMatch(m -> m.isSelected));

        holder.itemView.setOnClickListener(v -> {
            boolean newState = !holder.checkIv.isSelected();
            holder.checkIv.setSelected(newState);
            if (listener != null) {
                listener.onCheck(position, newState);
            }
        });
    }

    @Override
    public int getItemCount() {
        return list.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        ImageView checkIv;
        TextView nameTv;
        TextView contentTv;

        ViewHolder(View itemView) {
            super(itemView);
            checkIv = itemView.findViewById(R.id.checkIv);
            nameTv = itemView.findViewById(R.id.nameTv);
            contentTv = itemView.findViewById(R.id.contentTv);
        }
    }
}
