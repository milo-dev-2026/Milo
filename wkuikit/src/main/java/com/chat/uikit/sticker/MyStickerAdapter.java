package com.chat.uikit.sticker;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import com.chat.sticker.ui.components.StickerView;
import com.chat.uikit.R;

import java.util.List;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

public class MyStickerAdapter extends RecyclerView.Adapter<MyStickerAdapter.ViewHolder> {

    private List<StickerCategoryEntity> list;
    private OnItemClickListener listener;
    private OnRemoveListener removeListener;

    public interface OnItemClickListener {
        void onItemClick(int position);
    }

    public interface OnRemoveListener {
        void onRemove(int position);
    }

    public void setOnItemClickListener(OnItemClickListener listener) {
        this.listener = listener;
    }

    public void setOnRemoveListener(OnRemoveListener listener) {
        this.removeListener = listener;
    }

    public MyStickerAdapter(List<StickerCategoryEntity> list) {
        this.list = list;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_sticker_manger_layout, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        StickerCategoryEntity item = list.get(position);
        holder.titleTv.setText(item.name);

        holder.itemView.setOnClickListener(v -> {
            if (listener != null) {
                listener.onItemClick(position);
            }
        });

        holder.removeBtn.setOnClickListener(v -> {
            if (removeListener != null) {
                removeListener.onRemove(position);
            }
        });
    }

    @Override
    public int getItemCount() {
        return list.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        StickerView stickerView;
        TextView titleTv;
        TextView removeBtn;

        ViewHolder(View itemView) {
            super(itemView);
            stickerView = itemView.findViewById(R.id.stickerView);
            titleTv = itemView.findViewById(R.id.titleTv);
            removeBtn = itemView.findViewById(R.id.removeBtn);
        }
    }
}
