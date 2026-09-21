package com.chat.richeditor.component.toolitem;

import android.content.Context;
import android.text.Spannable;
import android.text.Spanned;
import android.text.style.StrikethroughSpan;
import android.view.View;

import com.chat.base.R;
import com.chat.richeditor.component.wmview.WMImageButton;

import java.util.ArrayList;
import java.util.List;

public class WMToolStrikethrough extends WMToolItem {

    private WMImageButton button;

    @Override
    public List<View> getView(Context context) {
        List<View> views = new ArrayList<>();
        button = new WMImageButton(context);
        button.setImageResource(R.drawable.ic_tool_strikethrough);
        button.setOnClickListener(v -> {
            int start = getSelectionStart();
            int end = getSelectionEnd();
            if (start == end) return;
            if (checkState(start, end)) {
                removeStyle(start, end);
            } else {
                applyStyle(start, end);
            }
        });
        views.add(button);
        return views;
    }

    @Override
    public void applyStyle(int start, int end) {
        Spannable spannable = getSpannable();
        if (spannable == null || start == end) return;
        spannable.setSpan(new StrikethroughSpan(), start, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        setStyleState(true);
    }

    public void removeStyle(int start, int end) {
        Spannable spannable = getSpannable();
        if (spannable == null) return;

        StrikethroughSpan[] spans = spannable.getSpans(start, end, StrikethroughSpan.class);
        for (StrikethroughSpan span : spans) {
            int spanStart = spannable.getSpanStart(span);
            int spanEnd = spannable.getSpanEnd(span);
            spannable.removeSpan(span);
            if (spanStart < start) {
                spannable.setSpan(new StrikethroughSpan(), spanStart, start, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
            }
            if (spanEnd > end) {
                spannable.setSpan(new StrikethroughSpan(), end, spanEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
            }
        }
        setStyleState(false);
    }

    @Override
    public boolean checkState(int start, int end) {
        Spannable spannable = getSpannable();
        if (spannable == null || start == end) return false;

        StrikethroughSpan[] spans = spannable.getSpans(start, end, StrikethroughSpan.class);
        return spans.length > 0;
    }

    @Override
    public void updateState(int start, int end) {
        boolean state = checkState(start, end);
        setStyleState(state);
    }

    @Override
    protected void updateViewState() {
        if (button != null) {
            button.setActive(styleState);
        }
    }
}
