package com.chat.richeditor.component.span;

import android.graphics.Canvas;
import android.graphics.Paint;
import android.text.style.ReplacementSpan;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

public class WMSplitLineSpan extends ReplacementSpan {
    private int color = 0xffdddddd;
    private int lineHeight = 2;
    private int paddingTop = 8;
    private int paddingBottom = 8;

    public WMSplitLineSpan() {
    }

    public WMSplitLineSpan(int color) {
        this.color = color;
    }

    public int getColor() {
        return color;
    }

    @Override
    public int getSize(@NonNull Paint paint, CharSequence text, int start, int end, @Nullable Paint.FontMetricsInt fm) {
        if (fm != null) {
            fm.descent = lineHeight + paddingBottom;
            fm.ascent = -paddingTop;
            fm.top = -paddingTop;
            fm.bottom = lineHeight + paddingBottom;
        }
        return 1000; // 返回一个较大的值确保占满宽度
    }

    @Override
    public void draw(@NonNull Canvas canvas, CharSequence text, int start, int end, float x, int top, int y, int bottom, @NonNull Paint paint) {
        int oldColor = paint.getColor();
        Paint.Style oldStyle = paint.getStyle();
        paint.setColor(color);
        paint.setStyle(Paint.Style.FILL);
        float lineY = top + paddingTop + (float) lineHeight / 2;
        canvas.drawRect(0, lineY, canvas.getWidth(), lineY + lineHeight, paint);
        paint.setColor(oldColor);
        paint.setStyle(oldStyle);
    }
}
