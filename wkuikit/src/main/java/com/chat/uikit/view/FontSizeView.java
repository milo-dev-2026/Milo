package com.chat.uikit.view;

import android.content.Context;
import android.util.AttributeSet;
import android.view.View;

public class FontSizeView extends View {
    private int defaultPosition = 0;
    private OnChangeListener listener;

    public FontSizeView(Context context) { super(context); }
    public FontSizeView(Context context, AttributeSet attrs) { super(context, attrs); }
    public FontSizeView(Context context, AttributeSet attrs, int defStyleAttr) { super(context, attrs, defStyleAttr); }

    public void setChangeCallbackListener(OnChangeListener listener) { this.listener = listener; }
    public void setDefaultPosition(int position) { this.defaultPosition = position; }
    public int getCurrentPosition() { return defaultPosition; }

    public interface OnChangeListener {
        void onPositionChange(int position);
    }
}