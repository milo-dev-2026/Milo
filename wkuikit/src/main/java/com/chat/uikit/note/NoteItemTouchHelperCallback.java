package com.chat.uikit.note;

import android.graphics.Canvas;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.cardview.widget.CardView;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.RecyclerView;

import java.util.Collections;
import java.util.List;

/**
 * 笔记块拖拽排序回调
 * 参照 utalk 的 NoteItemTouchHelperCallback 实现
 */
public class NoteItemTouchHelperCallback extends ItemTouchHelper.SimpleCallback {

    private final NoteBlockAdapter noteAdapter;
    private final ItemTouchHelper itemTouchHelper;
    private List<NoteBlock> blockList;

    public NoteItemTouchHelperCallback(NoteBlockAdapter adapter, List<NoteBlock> blockList) {
        super(ItemTouchHelper.UP | ItemTouchHelper.DOWN, 0);
        this.noteAdapter = adapter;
        this.blockList = blockList;
        this.itemTouchHelper = new ItemTouchHelper(this);
    }

    /**
     * 附加到 RecyclerView
     */
    public void attachToRecyclerView(RecyclerView recyclerView) {
        itemTouchHelper.attachToRecyclerView(recyclerView);
    }

    /**
     * 解绑 RecyclerView
     */
    public void detachFromRecyclerView() {
        itemTouchHelper.attachToRecyclerView(null);
    }

    /**
     * 更新数据列表引用
     */
    public void setBlockList(List<NoteBlock> blockList) {
        this.blockList = blockList;
    }

    @Override
    public boolean onMove(@NonNull RecyclerView recyclerView,
                          @NonNull RecyclerView.ViewHolder viewHolder,
                          @NonNull RecyclerView.ViewHolder target) {
        int fromPosition = viewHolder.getAdapterPosition();
        int toPosition = target.getAdapterPosition();

        if (blockList == null || fromPosition < 0 || toPosition < 0
                || fromPosition >= blockList.size() || toPosition >= blockList.size()) {
            return false;
        }

        // 标题块（TYPE_TITLE）不参与排序
        NoteBlock fromBlock = blockList.get(fromPosition);
        NoteBlock toBlock = blockList.get(toPosition);
        if (fromBlock.type == NoteBlock.TYPE_TITLE || toBlock.type == NoteBlock.TYPE_TITLE) {
            return false;
        }

        // 交换数据
        if (fromPosition < toPosition) {
            for (int i = fromPosition; i < toPosition; i++) {
                Collections.swap(blockList, i, i + 1);
            }
        } else {
            for (int i = fromPosition; i > toPosition; i--) {
                Collections.swap(blockList, i, i - 1);
            }
        }
        noteAdapter.notifyItemMoved(fromPosition, toPosition);
        return true;
    }

    @Override
    public void onSwiped(@NonNull RecyclerView.ViewHolder viewHolder, int direction) {
        // 不处理滑动删除
    }

    @Override
    public void onChildDraw(@NonNull Canvas c, @NonNull RecyclerView recyclerView,
                            @NonNull RecyclerView.ViewHolder viewHolder,
                            float dX, float dY, int actionState, boolean isCurrentlyActive) {
        super.onChildDraw(c, recyclerView, viewHolder, dX, dY, actionState, isCurrentlyActive);

        // 拖拽时的视觉效果：卡片阴影 + 透明度变化
        if (actionState == ItemTouchHelper.ACTION_STATE_DRAG) {
            View itemView = viewHolder.itemView;
            if (itemView instanceof CardView) {
                CardView cardView = (CardView) itemView;
                if (isCurrentlyActive) {
                    float density = cardView.getContext().getResources().getDisplayMetrics().density;
                    cardView.setCardElevation(6 * density + 0.5f);
                } else {
                    cardView.setCardElevation(0);
                }
                float alpha = 1.0f - (Math.abs(dY) / cardView.getHeight());
                cardView.setAlpha(Math.max(0.9f, Math.min(1.0f, alpha)));
            }
        }
    }

    @Override
    public void clearView(@NonNull RecyclerView recyclerView, @NonNull RecyclerView.ViewHolder viewHolder) {
        super.clearView(recyclerView, viewHolder);
        // 拖拽结束后恢复卡片状态
        View itemView = viewHolder.itemView;
        if (itemView instanceof CardView) {
            CardView cardView = (CardView) itemView;
            cardView.setCardElevation(0);
            cardView.setAlpha(1.0f);
        }
    }
}
