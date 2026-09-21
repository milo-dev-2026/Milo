package com.chat.base.views;

import android.content.Context;
import android.graphics.Color;
import android.util.AttributeSet;
import android.widget.FrameLayout;

public class ChatItemView extends FrameLayout {
    public ChatItemView(Context context) {
        super(context);
        setBackground(null);
    }
    public ChatItemView(Context context, AttributeSet attrs) {
        super(context, attrs);
        setBackground(null);
    }
    public ChatItemView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        setBackground(null);
    }

    public void setTouchData(boolean flag, Runnable callback) {}
}
