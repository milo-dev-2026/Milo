package com.chat.richeditor.component.span;

import android.graphics.Canvas;
import android.graphics.Paint;
import android.text.Layout;
import android.text.Spanned;
import android.text.style.LeadingMarginSpan;

public class WMListNumberSpan implements LeadingMarginSpan {
    private int number;
    private int color;
    private int gapWidth = 24;
    private int numberWidth = 40;

    public WMListNumberSpan(int number) {
        this.number = number;
    }

    public WMListNumberSpan(int number, int color) {
        this.number = number;
        this.color = color;
    }

    public int getNumber() {
        return number;
    }

    public int getColor() {
        return color;
    }

    @Override
    public int getLeadingMargin(boolean first) {
        return numberWidth + gapWidth;
    }

    @Override
    public void drawLeadingMargin(Canvas c, Paint p, int x, int dir, int top, int baseline, int bottom, CharSequence text, int start, int end, boolean first, Layout layout) {
        if (((Spanned) text).getSpanStart(this) == start) {
            Paint.Style style = p.getStyle();
            int oldColor = p.getColor();
            float oldTextSize = p.getTextSize();
            p.setStyle(Paint.Style.FILL);
            p.setColor(color != 0 ? color : 0xff333333);
            p.setTextSize(p.getTextSize());
            String numberStr = number + ". ";
            float textX = x + dir * gapWidth;
            float textY = baseline;
            c.drawText(numberStr, textX, textY, p);
            p.setStyle(style);
            p.setColor(oldColor);
            p.setTextSize(oldTextSize);
        }
    }
}
