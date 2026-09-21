package com.chat.base.ui.components;

import android.content.Context;
import android.graphics.Typeface;
import android.util.AttributeSet;
import android.view.View;

public class NumberTextView extends View {
    public NumberTextView(Context context) { super(context); }
    public NumberTextView(Context context, AttributeSet attrs) { super(context, attrs); }
    public NumberTextView(Context context, AttributeSet attrs, int defStyleAttr) { super(context, attrs, defStyleAttr); }

    public void setProgress(float progress) {}
    public int getCurrentNumber() { return 0; }
    public float getProgress() { return 0f; }
    public void setAddNumber() {}
    public void setNumber(int num, boolean animated) {}
    public void setTextSize(int size) {}
    public void setTextColor(int color) {}
    public void setTypeface(Typeface tf) {}
    public void setCenterAlign(boolean center) {}
}