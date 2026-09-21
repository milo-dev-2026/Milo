package com.chat.richeditor.component.span;

import android.graphics.Canvas;
import android.graphics.Paint;
import android.text.Layout;
import android.text.style.QuoteSpan;

public class WMQuoteSpan extends QuoteSpan {
    private int color;
    private int stripeWidth = 8;
    private int gapWidth = 24;

    public WMQuoteSpan() {
        super();
    }

    public WMQuoteSpan(int color) {
        super(color);
        this.color = color;
    }

    public int getColor() {
        return color;
    }

    @Override
    public int getLeadingMargin(boolean first) {
        return stripeWidth + gapWidth;
    }

    @Override
    public void drawLeadingMargin(Canvas c, Paint p, int x, int dir, int top, int baseline, int bottom, CharSequence text, int start, int end, boolean first, Layout layout) {
        Paint.Style style = p.getStyle();
        int color = p.getColor();
        p.setStyle(Paint.Style.FILL);
        p.setColor(this.color != 0 ? this.color : 0xffbbbbbb);
        c.drawRect(x, top, x + dir * stripeWidth, bottom, p);
        p.setStyle(style);
        p.setColor(color);
    }
}
