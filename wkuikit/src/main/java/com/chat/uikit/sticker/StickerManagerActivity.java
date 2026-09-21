package com.chat.uikit.sticker;

import android.content.Intent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import android.graphics.drawable.Drawable;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.target.CustomTarget;
import com.bumptech.glide.request.transition.Transition;
import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityStickerManagerBinding;

import java.util.ArrayList;
import java.util.List;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

public class StickerManagerActivity extends WKBaseActivity<ActivityStickerManagerBinding> {

    private List<StickerCategoryEntity> categoryList = new ArrayList<>();
    private List<StickerEntity> customList = new ArrayList<>();
    private CategoryAdapter categoryAdapter;
    private CustomAdapter customAdapter;
    private StickerService stickerService;

    @Override
    protected ActivityStickerManagerBinding getViewBinding() {
        return ActivityStickerManagerBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(android.widget.TextView titleTv) {
        titleTv.setText(R.string.sticker_manager);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        stickerService = StickerService.getInstance();

        wkVBinding.categoryRecyclerView.setLayoutManager(new LinearLayoutManager(this));
        categoryAdapter = new CategoryAdapter(categoryList);
        wkVBinding.categoryRecyclerView.setAdapter(categoryAdapter);

        wkVBinding.customRecyclerView.setLayoutManager(new GridLayoutManager(this, 4));
        customAdapter = new CustomAdapter(customList);
        wkVBinding.customRecyclerView.setAdapter(customAdapter);

        loadData();
    }

    private void loadData() {
        categoryList.clear();
        categoryList.addAll(stickerService.getMyCategories());

        customList.clear();
        for (StickerEntity s : stickerService.getMyStickers()) {
            if (s.isCustom) {
                customList.add(s);
            }
        }

        categoryAdapter.notifyDataSetChanged();
        customAdapter.notifyDataSetChanged();
    }

    @Override
    protected void initListener() {
        SingleClickUtil.onSingleClick(wkVBinding.reorderBtn, v -> {
            startActivity(new Intent(this, StickerReorderActivity.class));
        });

        SingleClickUtil.onSingleClick(wkVBinding.addCustomBtn, v -> {
            startActivity(new Intent(this, CustomStickerActivity.class));
        });
    }

    @Override
    protected void onResume() {
        super.onResume();
        loadData();
    }

    // ==================== Category Adapter ====================

    private class CategoryAdapter extends RecyclerView.Adapter<CategoryAdapter.ViewHolder> {

        private List<StickerCategoryEntity> list;

        CategoryAdapter(List<StickerCategoryEntity> list) {
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
                Intent intent = new Intent(StickerManagerActivity.this, StickerStoreDetailActivity.class);
                intent.putExtra(StickerStoreDetailActivity.KEY_CATEGORY_ID, item.categoryID);
                intent.putExtra(StickerStoreDetailActivity.KEY_CATEGORY_NAME, item.name);
                startActivity(intent);
            });
            holder.removeBtn.setOnClickListener(v -> {
                stickerService.removeCategory(item.categoryID);
                list.remove(position);
                notifyItemRemoved(position);
                notifyItemRangeChanged(position, list.size());
                WKToastUtils.getInstance().showToastNormal(getString(R.string.sticker_removed));
            });
        }

        @Override
        public int getItemCount() {
            return list.size();
        }

        class ViewHolder extends RecyclerView.ViewHolder {
            TextView titleTv;
            TextView removeBtn;

            ViewHolder(View itemView) {
                super(itemView);
                titleTv = itemView.findViewById(R.id.titleTv);
                removeBtn = itemView.findViewById(R.id.removeBtn);
            }
        }
    }

    // ==================== Custom Sticker Adapter ====================

    private class CustomAdapter extends RecyclerView.Adapter<CustomAdapter.ViewHolder> {

        private List<StickerEntity> list;

        CustomAdapter(List<StickerEntity> list) {
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
                Glide.with(holder.itemView.getContext())
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
                Intent intent = new Intent(StickerManagerActivity.this, StickerDetailActivity.class);
                intent.putExtra(StickerDetailActivity.KEY_STICKER_ID, item.stickerID);
                intent.putExtra(StickerDetailActivity.KEY_STICKER_URL, item.url);
                intent.putExtra(StickerDetailActivity.KEY_STICKER_NAME, item.name);
                intent.putExtra(StickerDetailActivity.KEY_CATEGORY_ID, item.categoryID);
                startActivity(intent);
            });
            holder.itemView.setOnLongClickListener(v -> {
                stickerService.removeSticker(item.stickerID);
                list.remove(position);
                notifyItemRemoved(position);
                WKToastUtils.getInstance().showToastNormal(getString(R.string.sticker_removed));
                return true;
            });
        }

        @Override
        public int getItemCount() {
            return list.size();
        }

        class ViewHolder extends RecyclerView.ViewHolder {
            com.chat.sticker.ui.components.StickerView stickerView;

            ViewHolder(View itemView) {
                super(itemView);
                stickerView = itemView.findViewById(R.id.stickerView);
            }
        }
    }
}
