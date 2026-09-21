package com.chat.base.views;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Rect;
import android.graphics.drawable.Drawable;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import androidx.recyclerview.widget.RecyclerView;
import java.util.ArrayList;

public class RecyclerListView extends RecyclerView {
    protected Drawable selectorDrawable;
    protected int selectorPosition;
    protected Rect selectorRect;
    public boolean fastScrollAnimationRunning;

    public RecyclerListView(Context context, AttributeSet attrs) { super(context, attrs); }
    public RecyclerListView(Context context, AttributeSet attrs, int defStyleAttr) { super(context, attrs, defStyleAttr); }
    public RecyclerListView(Context context) { super(context); }

    public View findChildViewUnder(float x, float y) { return null; }
    protected boolean canHighlightChildAt(View child, float x, float y) { return false; }
    public void setDisableHighlightState(boolean disable) {}
    protected View getPressedChildView() { return null; }
    protected void onChildPressed(View child, float x, float y, boolean b) {}
    protected boolean allowSelectChildAtPosition(float x, float y) { return false; }
    protected boolean allowSelectChildAtPosition(View child) { return false; }
    public void cancelClickRunnables(boolean b) {}
    public int[] getResourceDeclareStyleableIntArray(String s1, String s2) { return null; }
    public void setVerticalScrollBarEnabled(boolean enabled) { super.setVerticalScrollBarEnabled(enabled); }

    public void setSelectorType(int type) {}
    public void setSelectorRadius(int radius) {}
    public void setTopBottomSelectorRadius(int radius) {}
    public void setDrawSelectorBehind(boolean behind) {}
    public void setSelectorDrawableColor(int color) {}
    public void checkSection() {}
    public void setListSelectorColor(int color) {}

    public void setOnItemClickListener(OnItemClickListener listener) {}
    public void setOnItemClickListener(OnItemClickListenerExtended listener) {}
    public OnItemClickListener getOnItemClickListener() { return null; }
    public void setOnItemLongClickListener(OnItemLongClickListener listener) {}
    public void setOnItemLongClickListener(OnItemLongClickListenerExtended listener) {}
    public void setEmptyView(View view) {}
    protected boolean updateEmptyViewAnimated() { return false; }
    public View getEmptyView() { return null; }
    public void invalidateViews() {}
    public void updateFastScrollColors() {}
    public void setPinnedHeaderShadowDrawable(Drawable d) {}
    public boolean canScrollVertically(int direction) { return false; }
    public void setScrollEnabled(boolean enabled) {}
    public void highlightRow(IntReturnCallback callback) {}

    @Override
    public boolean onInterceptTouchEvent(MotionEvent e) { return super.onInterceptTouchEvent(e); }

    @Override
    public boolean dispatchTouchEvent(MotionEvent e) { return super.dispatchTouchEvent(e); }

    protected boolean emptyViewIsVisible() { return false; }
    public void hide() {}
    public void show() {}

    @Override
    public void setVisibility(int visibility) { super.setVisibility(visibility); }

    @Override
    public void setOnScrollListener(OnScrollListener listener) { super.setOnScrollListener(listener); }

    public void setHideIfEmpty(boolean hide) {}
    public OnScrollListener getOnScrollListener() { return null; }
    public void setOnInterceptTouchListener(OnInterceptTouchListener listener) {}
    public void setInstantClick(boolean instant) {}
    public void setDisallowInterceptTouchEvents(boolean disallow) {}
    public void setFastScrollEnabled() {}
    public void setFastScrollVisible(boolean visible) {}
    public void setSectionsType(int type) {}
    public void setPinnedSectionOffsetY(int offset) {}
    public void setAllowItemsInteractionDuringAnimation(boolean allow) {}
    public void hideSelector(boolean b) {}

    @Override
    public void onChildAttachedToWindow(View child) { super.onChildAttachedToWindow(child); }

    @Override
    protected void drawableStateChanged() { super.drawableStateChanged(); }

    @Override
    public boolean verifyDrawable(Drawable d) { return super.verifyDrawable(d); }

    @Override
    public void jumpDrawablesToCurrentState() { super.jumpDrawablesToCurrentState(); }

    @Override
    protected void onAttachedToWindow() { super.onAttachedToWindow(); }

    @Override
    public void setAdapter(Adapter adapter) { super.setAdapter(adapter); }

    @Override
    public void stopScroll() { super.stopScroll(); }

    @Override
    public boolean dispatchNestedPreScroll(int dx, int dy, int[] consumed, int[] offsetInWindow, int type) {
        return super.dispatchNestedPreScroll(dx, dy, consumed, offsetInWindow, type);
    }

    public boolean hasOverlappingRendering() { return false; }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
    }

    @Override
    protected void onLayout(boolean changed, int l, int t, int r, int b) {
        super.onLayout(changed, l, t, r, b);
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);
    }

    @Override
    protected void dispatchDraw(Canvas canvas) { super.dispatchDraw(canvas); }

    @Override
    protected void onDetachedFromWindow() { super.onDetachedFromWindow(); }

    public void addOverlayView(View view, FrameLayout.LayoutParams params) {}
    public void removeOverlayView(View view) {}
    public ArrayList<View> getHeaders() { return null; }
    public ArrayList<View> getHeadersCache() { return null; }
    public View getPinnedHeader() { return null; }
    public boolean isFastScrollAnimationRunning() { return false; }

    @Override
    public void requestLayout() { super.requestLayout(); }

    public void setAnimateEmptyView(boolean animate, int delay) {}

    @Override
    public void setTranslationY(float translationY) { super.setTranslationY(translationY); }

    public void startMultiselect(int position, boolean select, onMultiSelectionChanged listener) {}

    @Override
    public boolean onTouchEvent(MotionEvent e) { return super.onTouchEvent(e); }

    // Holder内部类
    public static class Holder extends RecyclerView.ViewHolder {
        public Holder(View itemView) { super(itemView); }
    }

    // SelectionAdapter内部类
    public static abstract class SelectionAdapter extends RecyclerView.Adapter<Holder> {
        public boolean isSelected(int position) { return false; }
        public void toggleSelection(int position) {}
        public void setSelected(int position, boolean selected) {}
        public int getSelectedCount() { return 0; }
        public void clearSelections() {}
        public boolean isSelectAll() { return false; }
        public void selectAll(boolean select) {}
        public boolean isMultiSelect() { return false; }
    }

    // 内部接口
    public interface OnItemClickListener {
        void onItemClick(View view, int position);
    }
    public interface OnItemClickListenerExtended {
        boolean onItemClick(View view, int position, float x, float y);
    }
    public interface OnItemLongClickListener {
        boolean onItemLongClick(View view, int position);
    }
    public interface OnItemLongClickListenerExtended {
        boolean onItemLongClick(View view, int position, float x, float y);
    }
    public interface OnInterceptTouchListener {
        boolean onInterceptTouchEvent(MotionEvent e);
    }
    public interface IntReturnCallback {
        int run();
    }
    public interface onMultiSelectionChanged {
        void onChanged(boolean isSelected, int count);
    }

    // AnimatableAdapter接口
    public interface AnimatableAdapter {
        void onAnimationStart();
        void onAnimationEnd();
    }
}