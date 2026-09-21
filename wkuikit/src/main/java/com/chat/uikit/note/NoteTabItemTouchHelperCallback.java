package com.chat.uikit.note;

import android.graphics.Canvas;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.RecyclerView;

import java.util.Collections;
import java.util.List;

/**
 * 笔记分组Tab拖拽排序回调
 * 支持水平方向拖拽排序
 */
public class NoteTabItemTouchHelperCallback extends ItemTouchHelper.SimpleCallback {

    private final NoteTabAdapter adapter;
    private final ItemTouchHelper itemTouchHelper;
    private List<String> tabList;
    private OnTabSortListener sortListener;

    public interface OnTabSortListener {
        void onTabSorted();
    }

    public NoteTabItemTouchHelperCallback(NoteTabAdapter adapter, List<String> tabList) {
        super(ItemTouchHelper.LEFT | ItemTouchHelper.RIGHT, 0);
        this.adapter = adapter;
        this.tabList = tabList;
        this.itemTouchHelper = new ItemTouchHelper(this);
    }

    public void setOnTabSortListener(OnTabSortListener listener) {
        this.sortListener = listener;
    }

    public void attachToRecyclerView(RecyclerView recyclerView) {
        itemTouchHelper.attachToRecyclerView(recyclerView);
    }

    public void detachFromRecyclerView() {
        itemTouchHelper.attachToRecyclerView(null);
    }

    public void setTabList(List<String> tabList) {
        this.tabList = tabList;
    }

    public void startDrag(RecyclerView.ViewHolder viewHolder) {
        itemTouchHelper.startDrag(viewHolder);
    }

    @Override
    public boolean onMove(@NonNull RecyclerView recyclerView,
                          @NonNull RecyclerView.ViewHolder viewHolder,
                          @NonNull RecyclerView.ViewHolder target) {
        int fromPosition = viewHolder.getAdapterPosition();
        int toPosition = target.getAdapterPosition();

        if (tabList == null || fromPosition < 0 || toPosition < 0
                || fromPosition >= tabList.size() || toPosition >= tabList.size()) {
            return false;
        }

        // "全部"和"未分组"（位置0和1）不参与排序
        if (fromPosition < 2 || toPosition < 2) {
            return false;
        }

        // 交换数据
        if (fromPosition < toPosition) {
            for (int i = fromPosition; i < toPosition; i++) {
                Collections.swap(tabList, i, i + 1);
            }
        } else {
            for (int i = fromPosition; i > toPosition; i--) {
                Collections.swap(tabList, i, i - 1);
            }
        }
        adapter.notifyItemMoved(fromPosition, toPosition);
        return true;
    }

    @Override
    public void onSwiped(@NonNull RecyclerView.ViewHolder viewHolder, int direction) {
        // 不处理滑动
    }

    @Override
    public void onChildDraw(@NonNull Canvas c, @NonNull RecyclerView recyclerView,
                            @NonNull RecyclerView.ViewHolder viewHolder,
                            float dX, float dY, int actionState, boolean isCurrentlyActive) {
        super.onChildDraw(c, recyclerView, viewHolder, dX, dY, actionState, isCurrentlyActive);
        if (actionState == ItemTouchHelper.ACTION_STATE_DRAG && isCurrentlyActive) {
            viewHolder.itemView.setAlpha(0.9f);
            viewHolder.itemView.setScaleX(1.05f);
            viewHolder.itemView.setScaleY(1.05f);
        }
    }

    @Override
    public void clearView(@NonNull RecyclerView recyclerView, @NonNull RecyclerView.ViewHolder viewHolder) {
        super.clearView(recyclerView, viewHolder);
        viewHolder.itemView.setAlpha(1.0f);
        viewHolder.itemView.setScaleX(1.0f);
        viewHolder.itemView.setScaleY(1.0f);
        // 排序完成回调
        if (sortListener != null) {
            sortListener.onTabSorted();
        }
    }
}
