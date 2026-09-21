package com.chat.base.ui.components;

import android.content.Context;
import android.graphics.Canvas;
import android.util.AttributeSet;
import android.view.View;

public class RadialProgressView extends View {
    public RadialProgressView(Context context, AttributeSet attrs) { super(context, attrs); }
    public RadialProgressView(Context context, AttributeSet attrs, int defStyleAttr) { super(context, attrs, defStyleAttr); }
    public RadialProgressView(Context context) { super(context); }

    public void setUseSelfAlpha(boolean use) {}
    public void setNoProgress(boolean noProgress) {}
    public void setProgress(float progress) {}
    public void sync(RadialProgressView other) {}
    public void setSize(int size) {}
    public void setStrokeWidth(float width) {}
    public void setProgressColor(int color) {}
    public void toCircle(boolean circle, boolean animated) {}
    public void draw(Canvas canvas, float x, float y) {}
    public boolean isCircle() { return false; }

    @Override
    public void setAlpha(float alpha) { super.setAlpha(alpha); }
}