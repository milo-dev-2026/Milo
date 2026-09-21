package com.chat.base.ui.components;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.RectF;
import android.view.View;

public class CheckBox extends View {
    private boolean checked = false;
    private int size = 26;
    private int strokeWidth = 2;
    private int checkedColor = 0xFF5B8DEF;
    private int uncheckedColor = 0xFFCCCCCC;
    private int borderColor = 0xFFCCCCCC;
    private boolean drawBackground = true;
    private boolean hasBorder = true;
    private int resId = 0;
    private Paint paint;
    private RectF rectF;

    public CheckBox(Context context) {
        super(context);
        init();
    }
    public CheckBox(Context context, int size) {
        super(context);
        this.size = size;
        init();
    }
    public CheckBox(Context context, android.util.AttributeSet attrs) {
        super(context, attrs);
        init();
    }
    public CheckBox(Context context, android.util.AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    private void init() {
        paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        rectF = new RectF();
    }

    public void setChecked(boolean checked) {
        this.checked = checked;
        invalidate();
    }
    public void setChecked(boolean checked, boolean animated) {
        this.checked = checked;
        invalidate();
    }
    public boolean isChecked() { return checked; }

    public void setResId(Context context, int resId) {
        this.resId = resId;
    }
    public void setStrokeWidth(int strokeWidth) {
        this.strokeWidth = strokeWidth;
        invalidate();
    }
    public void setSize(int size) {
        this.size = size;
        requestLayout();
    }
    public void setColor(int checkedColor, int uncheckedColor) {
        this.checkedColor = checkedColor;
        this.uncheckedColor = uncheckedColor;
        invalidate();
    }
    public void setBorderColor(int borderColor) {
        this.borderColor = borderColor;
        invalidate();
    }
    public void setDrawBackground(boolean draw) {
        this.drawBackground = draw;
        invalidate();
    }
    public void setHasBorder(boolean hasBorder) {
        this.hasBorder = hasBorder;
        invalidate();
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        int w = getWidth();
        int h = getHeight();
        rectF.set(strokeWidth, strokeWidth, w - strokeWidth, h - strokeWidth);
        if (checked) {
            paint.setColor(checkedColor);
            paint.setStyle(Paint.Style.FILL);
            canvas.drawRoundRect(rectF, size / 4f, size / 4f, paint);
        } else {
            if (drawBackground) {
                paint.setColor(uncheckedColor);
                paint.setStyle(Paint.Style.FILL);
                canvas.drawRoundRect(rectF, size / 4f, size / 4f, paint);
            }
            if (hasBorder) {
                paint.setColor(borderColor);
                paint.setStyle(Paint.Style.STROKE);
                paint.setStrokeWidth(strokeWidth);
                canvas.drawRoundRect(rectF, size / 4f, size / 4f, paint);
            }
        }
    }
}