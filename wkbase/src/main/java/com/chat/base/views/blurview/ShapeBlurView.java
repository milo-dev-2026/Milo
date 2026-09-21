package com.chat.base.views.blurview;

import android.content.Context;
import android.util.AttributeSet;
import android.widget.FrameLayout;

public class ShapeBlurView extends FrameLayout {
    public ShapeBlurView(Context context) { super(context); }
    public ShapeBlurView(Context context, AttributeSet attrs) { super(context, attrs); }
    public ShapeBlurView(Context context, AttributeSet attrs, int defStyleAttr) { super(context, attrs, defStyleAttr); }

    public void setBlurRadius(float radius) {}
    public void setOverlayColor(int color) {}

    public void setCornerRadius(float leftTop, float rightTop, float leftBottom, float rightBottom) {}
}