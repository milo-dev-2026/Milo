package com.chat.richeditor.component.span;

import android.graphics.Canvas;
import android.graphics.Paint;
import android.text.TextPaint;
import android.text.style.UnderlineSpan;

public class WMUnderlineSpan extends UnderlineSpan {
    private int color;
    private boolean hasColor = false;

    public WMUnderlineSpan() {
        super();
    }

    public WMUnderlineSpan(int color) {
        super();
        this.color = color;
        this.hasColor = true;
    }

    public int getColor() {
        return color;
    }

    public boolean isHasColor() {
        return hasColor;
    }

    @Override
    public void updateDrawState(TextPaint ds) {
        ds.setUnderlineText(true);
        if (hasColor) {
            ds.linkColor = color;
        }
    }
}
