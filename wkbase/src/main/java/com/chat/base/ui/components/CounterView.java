package com.chat.base.ui.components;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.graphics.Typeface;
import android.text.TextPaint;
import android.util.AttributeSet;
import android.util.TypedValue;
import android.view.View;

import androidx.core.content.ContextCompat;

public class CounterView extends View {

    private int count = 0;
    private int bgColor = Color.RED;
    private int textColor = Color.WHITE;
    private final TextPaint textPaint = new TextPaint(Paint.ANTI_ALIAS_FLAG);
    private final Paint bgPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final RectF rectF = new RectF();
    private boolean isReverse = false;
    private int gravity = android.view.Gravity.END;

    public CounterView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public CounterView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    public CounterView(Context context) {
        super(context);
        init();
    }

    private void init() {
        float density = getResources().getDisplayMetrics().density;
        textPaint.setTextSize(11 * density);
        textPaint.setTypeface(Typeface.DEFAULT_BOLD);
        textPaint.setTextAlign(Paint.Align.CENTER);
        bgPaint.setStyle(Paint.Style.FILL);
        bgPaint.setAntiAlias(true);
    }

    public void setColors(int color1, int color2) {
        this.textColor = ContextCompat.getColor(getContext(), color1);
        this.bgColor = ContextCompat.getColor(getContext(), color2);
        invalidate();
    }

    public void setGravity(int gravity) {
        this.gravity = gravity;
        invalidate();
    }

    public void setReverse(boolean reverse) {
        this.isReverse = reverse;
    }

    public void setCount(int count, boolean animated) {
        if (count < 0) count = 0;
        int oldCount = this.count;
        this.count = count;
        if (animated && oldCount != count) {
            // 简单的动画效果
            animate().scaleX(1.3f).scaleY(1.3f).setDuration(100).withEndAction(() -> {
                animate().scaleX(1f).scaleY(1f).setDuration(100).start();
            }).start();
        }
        invalidate();
    }

    public int getCount() {
        return count;
    }

    public float getEnterProgress() {
        return count > 0 ? 1f : 0f;
    }

    public boolean isInOutAnimation() {
        return false;
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        float density = getResources().getDisplayMetrics().density;
        int defaultSize = (int) (18 * density);

        if (count <= 0) {
            setMeasuredDimension(0, 0);
            return;
        }

        // 根据数字位数计算宽度
        String countStr = count > 99 ? "99+" : String.valueOf(count);
        int textWidth = (int) (textPaint.measureText(countStr) + 6 * density);
        int width = Math.max(defaultSize, textWidth);
        int height = defaultSize;

        setMeasuredDimension(width, height);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        if (count <= 0) return;

        int width = getWidth();
        int height = getHeight();

        // 绘制圆角矩形背景
        float density = getResources().getDisplayMetrics().density;
        float cornerRadius = height / 2f;

        rectF.set(0, 0, width, height);
        bgPaint.setColor(bgColor);
        canvas.drawRoundRect(rectF, cornerRadius, cornerRadius, bgPaint);

        // 绘制文字
        String countStr = count > 99 ? "99+" : String.valueOf(count);
        textPaint.setColor(textColor);

        float textX = width / 2f;
        float textY = height / 2f - (textPaint.descent() + textPaint.ascent()) / 2f;
        canvas.drawText(countStr, textX, textY, textPaint);
    }

    @Override
    public void setVisibility(int visibility) {
        super.setVisibility(visibility);
        if (visibility == VISIBLE && count > 0) {
            requestLayout();
            invalidate();
        }
    }
}
