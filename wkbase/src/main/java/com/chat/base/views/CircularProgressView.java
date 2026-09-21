package com.chat.base.views;

import android.content.Context;
import android.util.AttributeSet;
import android.view.View;

public class CircularProgressView extends View {
    private int progress;
    private int color;
    private float strokeWidth;
    private float max = 100f;

    public CircularProgressView(Context context) { super(context); }
    public CircularProgressView(Context context, AttributeSet attrs) { super(context, attrs); }
    public CircularProgressView(Context context, AttributeSet attrs, int defStyleAttr) { super(context, attrs, defStyleAttr); }

    public void setProgress(int progress) { this.progress = progress; }
    public int getProgress() { return progress; }
    public void setColor(int color) { this.color = color; }
    public void setProgColor(int color) { this.color = color; }
    public void setStrokeWidth(float strokeWidth) { this.strokeWidth = strokeWidth; }
    public void setMax(float max) { this.max = max; }
}