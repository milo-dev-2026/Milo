package com.chat.base.views.swipeback;

import android.app.Activity;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.drawable.Drawable;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.View;
import android.widget.FrameLayout;

public class SwipeBackLayout extends FrameLayout {
    public static final int EDGE_LEFT = 0;
    public static final int EDGE_RIGHT = 1;
    public static final int EDGE_BOTTOM = 2;
    public static final int EDGE_ALL = 3;
    public static final int STATE_IDLE = 0;
    public static final int STATE_DRAGGING = 1;
    public static final int STATE_SETTLING = 2;

    public SwipeBackLayout(Context context) { super(context); }
    public SwipeBackLayout(Context context, AttributeSet attrs) { super(context, attrs); }
    public SwipeBackLayout(Context context, AttributeSet attrs, int defStyleAttr) { super(context, attrs, defStyleAttr); }

    public void setSensitivity(Context context, float value) {}
    public void setEnableGesture(boolean enable) {}
    public void setEdgeTrackingEnabled(int edge) {}
    public void setScrimColor(int color) {}
    public void setEdgeSize(int size) {}
    public void setSwipeListener(SwipeListener listener) {}
    public void addSwipeListener(SwipeListener listener) {}
    public void removeSwipeListener(SwipeListener listener) {}
    public void setScrollThresHold(float threshold) {}
    public void setShadow(Drawable shadow, int edge) {}
    public void setShadow(int resId, int edge) {}
    public void scrollToFinishActivity() {}
    public void attachToActivity(Activity activity) {}

    public interface SwipeListener {
        void onScrollStateChange(int state, float scrollPercent);
        void onEdgeTouch(int edgeFlag);
        void onScrollOverThreshold();
    }

    @Override
    public boolean onInterceptTouchEvent(MotionEvent ev) { return super.onInterceptTouchEvent(ev); }

    @Override
    public boolean onTouchEvent(MotionEvent event) { return super.onTouchEvent(event); }

    @Override
    protected void onLayout(boolean changed, int left, int top, int right, int bottom) {
        super.onLayout(changed, left, top, right, bottom);
    }

    @Override
    public void requestLayout() { super.requestLayout(); }

    @Override
    protected boolean drawChild(Canvas canvas, View child, long drawingTime) {
        return super.drawChild(canvas, child, drawingTime);
    }

    @Override
    public void computeScroll() { super.computeScroll(); }
}