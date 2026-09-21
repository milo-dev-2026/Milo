package com.chat.richeditor.component.span;

import android.text.TextPaint;
import android.text.style.ClickableSpan;
import android.view.View;

import androidx.annotation.NonNull;

public class WMMentionSpan extends ClickableSpan {
    private String uid;
    private String name;
    private int color;
    private boolean isBold = true;
    private OnMentionClickListener listener;

    public interface OnMentionClickListener {
        void onMentionClick(String uid, String name);
    }

    public WMMentionSpan(String uid, String name) {
        this.uid = uid;
        this.name = name;
    }

    public WMMentionSpan(String uid, String name, int color) {
        this.uid = uid;
        this.name = name;
        this.color = color;
    }

    public String getUid() {
        return uid;
    }

    public String getName() {
        return name;
    }

    public int getColor() {
        return color;
    }

    public boolean isBold() {
        return isBold;
    }

    public void setBold(boolean bold) {
        isBold = bold;
    }

    public void setOnMentionClickListener(OnMentionClickListener listener) {
        this.listener = listener;
    }

    @Override
    public void onClick(@NonNull View widget) {
        if (listener != null) {
            listener.onMentionClick(uid, name);
        }
    }

    @Override
    public void updateDrawState(android.text.TextPaint ds) {
        if (color != 0) {
            ds.setColor(color);
        }
        ds.setUnderlineText(false);
    }
}
