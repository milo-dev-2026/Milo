package com.chat.base.ui.components;

import android.content.Context;
import android.util.AttributeSet;
import android.widget.FrameLayout;

public class RoundLayout extends FrameLayout {
    public RoundLayout(Context context) { super(context); }
    public RoundLayout(Context context, AttributeSet attrs) { super(context, attrs); }
    public RoundLayout(Context context, AttributeSet attrs, int defStyleAttr) { super(context, attrs, defStyleAttr); }
    public RoundLayout(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) { super(context, attrs, defStyleAttr, defStyleRes); }

    public void setCorner(int radius) {}
    public void setCorner(int topLeft, int topRight, int bottomLeft, int bottomRight) {}
    public void setBgColor(int color) {}

    @Override
    protected void onLayout(boolean changed, int left, int top, int right, int bottom) {
        super.onLayout(changed, left, top, right, bottom);
    }
}