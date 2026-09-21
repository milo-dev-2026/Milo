package com.chat.uikit.sticker;

import android.graphics.drawable.Drawable;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.target.CustomTarget;
import com.bumptech.glide.request.transition.Transition;
import com.chat.sticker.ui.components.StickerView;
import com.chat.uikit.R;

import java.util.List;

import androidx.recyclerview.widget.RecyclerView;

public class StickerDetailAdapter extends RecyclerView.Adapter<StickerDetailAdapter.ViewHolder> {

    private List<StickerEntity> list;
    private OnItemClickListener listener;

    public interface OnItemClickListener {
        void onItemClick(int position);
    }

    public void setOnItemClickListener(OnItemClickListener listener) {
        this.listener = listener;
    }

    public StickerDetailAdapter(List<StickerEntity> list) {
        this.list = list;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_sticker_grid_layout, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        StickerEntity item = list.get(position);
        if (item.url != null && !item.url.isEmpty()) {
            Glide.with(holder.stickerView.getContext())
                    .load(item.url)
                    .into(new CustomTarget<Drawable>(120, 120) {
                        @Override
                        public void onResourceReady(@NonNull Drawable resource, @Nullable Transition<? super Drawable> transition) {
                            holder.stickerView.setBackground(resource);
                        }

                        @Override
                        public void onLoadCleared(@Nullable Drawable placeholder) {
                            holder.stickerView.setBackground(null);
                        }
                    });
        }
        holder.itemView.setOnClickListener(v -> {
            if (listener != null) {
                listener.onItemClick(position);
            }
        });
    }

    @Override
    public int getItemCount() {
        return list.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        StickerView stickerView;

        ViewHolder(View itemView) {
            super(itemView);
            stickerView = itemView.findViewById(R.id.stickerView);
        }
    }
}
