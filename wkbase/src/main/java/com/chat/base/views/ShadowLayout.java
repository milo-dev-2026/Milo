package com.chat.base.views;

import android.content.Context;
import android.util.AttributeSet;
import android.widget.FrameLayout;

public class ShadowLayout extends FrameLayout {
    public ShadowLayout(Context context) { super(context); }
    public ShadowLayout(Context context, AttributeSet attrs) { super(context, attrs); }
    public ShadowLayout(Context context, AttributeSet attrs, int defStyleAttr) { super(context, attrs, defStyleAttr); }

    public void setShadowColor(int color) {}
    public void setShadowRadius(float radius) {}
    public void setShadowDx(float dx) {}
    public void setShadowDy(float dy) {}
}