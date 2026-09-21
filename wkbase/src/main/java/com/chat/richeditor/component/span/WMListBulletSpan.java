package com.chat.richeditor.component.span;

import android.graphics.Canvas;
import android.graphics.Paint;
import android.text.Layout;
import android.text.Spanned;
import android.text.style.BulletSpan;

public class WMListBulletSpan extends BulletSpan {
    private int color;
    private int bulletRadius = 6;
    private int gapWidth = 24;

    public WMListBulletSpan() {
        super();
    }

    public WMListBulletSpan(int color) {
        super();
        this.color = color;
    }

    public int getColor() {
        return color;
    }

    @Override
    public int getLeadingMargin(boolean first) {
        return bulletRadius * 2 + gapWidth;
    }

    @Override
    public void drawLeadingMargin(Canvas c, Paint p, int x, int dir, int top, int baseline, int bottom, CharSequence text, int start, int end, boolean first, Layout layout) {
        if (((Spanned) text).getSpanStart(this) == start) {
            Paint.Style style = p.getStyle();
            int oldColor = p.getColor();
            p.setStyle(Paint.Style.FILL);
            p.setColor(color != 0 ? color : 0xff333333);
            float bulletCenterX = x + dir * bulletRadius + gapWidth / 2f;
            float bulletCenterY = (top + bottom) / 2f;
            c.drawCircle(bulletCenterX, bulletCenterY, bulletRadius, p);
            p.setStyle(style);
            p.setColor(oldColor);
        }
    }
}
