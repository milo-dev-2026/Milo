package com.chat.richeditor.component.wmview;

import android.content.Context;
import android.graphics.Color;
import android.util.AttributeSet;
import android.view.Gravity;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.widget.AppCompatTextView;

import com.chat.richeditor.component.util.WMUtil;

public class WMButton extends AppCompatTextView {

    private boolean isActive = false;
    private int activeColor = Color.parseColor("#3f74fc");
    private int inactiveColor = Color.parseColor("#666666");

    public WMButton(@NonNull Context context) {
        super(context);
        init();
    }

    public WMButton(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public WMButton(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    private void init() {
        setGravity(Gravity.CENTER);
        setTextSize(14);
        setPadding(
                WMUtil.dp2px(getContext(), 12),
                WMUtil.dp2px(getContext(), 8),
                WMUtil.dp2px(getContext(), 12),
                WMUtil.dp2px(getContext(), 8)
        );
        updateColor();
    }

    public void setActive(boolean active) {
        if (this.isActive != active) {
            this.isActive = active;
            updateColor();
        }
    }

    public boolean isActive() {
        return isActive;
    }

    public void setActiveColor(int color) {
        this.activeColor = color;
        if (isActive) {
            updateColor();
        }
    }

    public void setInactiveColor(int color) {
        this.inactiveColor = color;
        if (!isActive) {
            updateColor();
        }
    }

    private void updateColor() {
        setTextColor(isActive ? activeColor : inactiveColor);
    }
}
