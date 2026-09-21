package com.chat.richeditor.component.wmview;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.drawable.Drawable;
import android.util.AttributeSet;
import android.view.Gravity;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.widget.AppCompatImageView;

import com.chat.richeditor.component.util.WMUtil;

public class WMImageButton extends AppCompatImageView {

    private boolean isActive = false;
    private int activeColor = Color.parseColor("#3f74fc");
    private int inactiveColor = Color.parseColor("#666666");
    private Paint paint;
    private OnClickListener clickListener;

    public WMImageButton(@NonNull Context context) {
        super(context);
        init();
    }

    public WMImageButton(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public WMImageButton(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    private void init() {
        paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        setScaleType(ScaleType.CENTER_INSIDE);
        setPadding(
                WMUtil.dp2px(getContext(), 10),
                WMUtil.dp2px(getContext(), 8),
                WMUtil.dp2px(getContext(), 10),
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
        int color = isActive ? activeColor : inactiveColor;
        Drawable drawable = getDrawable();
        if (drawable != null) {
            drawable.mutate().setColorFilter(color, android.graphics.PorterDuff.Mode.SRC_IN);
        }
    }

    @Override
    public void setImageDrawable(@Nullable Drawable drawable) {
        super.setImageDrawable(drawable);
        updateColor();
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
    }
}
