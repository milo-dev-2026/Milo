package com.chat.uikit.sticker;

import android.content.Context;
import android.graphics.Canvas;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActStickerReorderLayoutBinding;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class StickerReorderActivity extends WKBaseActivity<ActStickerReorderLayoutBinding> {

    private StickerReorderAdapter adapter;
    private final List<StickerEntity> stickerList = new ArrayList<>();

    @Override
    protected ActStickerReorderLayoutBinding getViewBinding() {
        return ActStickerReorderLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText("表情排序");
    }

    @Override
    protected String getRightTvText(TextView textView) {
        return "完成";
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        wkVBinding.recyclerView.setLayoutManager(new LinearLayoutManager(this));
        adapter = new StickerReorderAdapter(this, stickerList);
        wkVBinding.recyclerView.setAdapter(adapter);

        ItemTouchHelper itemTouchHelper = new ItemTouchHelper(new ItemTouchHelper.SimpleCallback(
                ItemTouchHelper.UP | ItemTouchHelper.DOWN, 0) {
            @Override
            public boolean onMove(@NonNull RecyclerView recyclerView, @NonNull RecyclerView.ViewHolder viewHolder, @NonNull RecyclerView.ViewHolder target) {
                int from = viewHolder.getBindingAdapterPosition();
                int to = target.getBindingAdapterPosition();
                Collections.swap(stickerList, from, to);
                adapter.notifyItemMoved(from, to);
                return true;
            }

            @Override
            public void onSwiped(@NonNull RecyclerView.ViewHolder viewHolder, int direction) {
            }

            @Override
            public void onChildDraw(@NonNull Canvas c, @NonNull RecyclerView recyclerView, @NonNull RecyclerView.ViewHolder viewHolder, float dX, float dY, @Nullable int actionState, boolean isCurrentlyActive) {
                super.onChildDraw(c, recyclerView, viewHolder, dX, dY, actionState, isCurrentlyActive);
            }
        });
        itemTouchHelper.attachToRecyclerView(wkVBinding.recyclerView);

        loadData();
    }

    @Override
    protected void initListener() {
    }

    @Override
    public void rightLayoutClick() {
        super.rightLayoutClick();
        StickerService.getInstance().reorderStickers(stickerList);
        WKToastUtils.getInstance().showToastNormal("排序已保存");
        finish();
    }

    private void loadData() {
        List<StickerEntity> stickers = StickerService.getInstance().getMyStickers();
        stickerList.clear();
        stickerList.addAll(stickers);
        adapter.notifyDataSetChanged();
    }

    static class StickerReorderAdapter extends RecyclerView.Adapter<StickerReorderAdapter.ViewHolder> {
        private final Context context;
        private final List<StickerEntity> list;

        StickerReorderAdapter(Context context, List<StickerEntity> list) {
            this.context = context;
            this.list = list;
        }

        @NonNull
        @Override
        public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
            View view = LayoutInflater.from(context).inflate(R.layout.item_sticker_reorder, parent, false);
            return new ViewHolder(view);
        }

        @Override
        public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
            StickerEntity sticker = list.get(position);
            holder.nameTv.setText(sticker.name != null && !sticker.name.isEmpty() ? sticker.name : "表情" + (position + 1));
            Glide.with(context).load(sticker.url).into(holder.stickerIv);
        }

        @Override
        public int getItemCount() {
            return list.size();
        }

        static class ViewHolder extends RecyclerView.ViewHolder {
            ImageView stickerIv;
            ImageView dragIv;
            TextView nameTv;

            ViewHolder(View itemView) {
                super(itemView);
                stickerIv = itemView.findViewById(R.id.stickerIv);
                dragIv = itemView.findViewById(R.id.dragIv);
                nameTv = itemView.findViewById(R.id.nameTv);
            }
        }
    }
}
