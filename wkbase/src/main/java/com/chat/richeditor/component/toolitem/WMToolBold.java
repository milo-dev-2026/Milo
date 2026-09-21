package com.chat.richeditor.component.toolitem;

import android.content.Context;
import android.graphics.Typeface;
import android.text.Spannable;
import android.text.Spanned;
import android.text.style.StyleSpan;
import android.view.View;
import android.widget.ImageView;

import com.chat.base.R;
import com.chat.richeditor.component.wmview.WMImageButton;

import java.util.ArrayList;
import java.util.List;

public class WMToolBold extends WMToolItem {

    private WMImageButton button;

    @Override
    public List<View> getView(Context context) {
        List<View> views = new ArrayList<>();
        button = new WMImageButton(context);
        button.setImageResource(R.drawable.ic_tool_bold);
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

        StyleSpan[] spans = spannable.getSpans(start, end, StyleSpan.class);
        boolean hasBold = false;
        for (StyleSpan span : spans) {
            if (span.getStyle() == Typeface.BOLD || span.getStyle() == Typeface.BOLD_ITALIC) {
                int spanStart = spannable.getSpanStart(span);
                int spanEnd = spannable.getSpanEnd(span);
                if (spanStart <= start && spanEnd >= end) {
                    hasBold = true;
                    break;
                }
            }
        }

        if (!hasBold) {
            spannable.setSpan(new StyleSpan(Typeface.BOLD), start, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        }
        setStyleState(true);
    }

    public void removeStyle(int start, int end) {
        Spannable spannable = getSpannable();
        if (spannable == null) return;

        StyleSpan[] spans = spannable.getSpans(start, end, StyleSpan.class);
        for (StyleSpan span : spans) {
            if (span.getStyle() == Typeface.BOLD) {
                int spanStart = spannable.getSpanStart(span);
                int spanEnd = spannable.getSpanEnd(span);
                spannable.removeSpan(span);
                if (spanStart < start) {
                    spannable.setSpan(new StyleSpan(Typeface.BOLD), spanStart, start, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
                }
                if (spanEnd > end) {
                    spannable.setSpan(new StyleSpan(Typeface.BOLD), end, spanEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
                }
            } else if (span.getStyle() == Typeface.BOLD_ITALIC) {
                int spanStart = spannable.getSpanStart(span);
                int spanEnd = spannable.getSpanEnd(span);
                spannable.removeSpan(span);
                if (spanStart < start) {
                    spannable.setSpan(new StyleSpan(Typeface.BOLD_ITALIC), spanStart, start, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
                }
                if (spanEnd > end) {
                    spannable.setSpan(new StyleSpan(Typeface.BOLD_ITALIC), end, spanEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
                }
                spannable.setSpan(new StyleSpan(Typeface.ITALIC), Math.max(spanStart, start), Math.min(spanEnd, end), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
            }
        }
        setStyleState(false);
    }

    @Override
    public boolean checkState(int start, int end) {
        Spannable spannable = getSpannable();
        if (spannable == null || start == end) return false;

        StyleSpan[] spans = spannable.getSpans(start, end, StyleSpan.class);
        for (StyleSpan span : spans) {
            if (span.getStyle() == Typeface.BOLD || span.getStyle() == Typeface.BOLD_ITALIC) {
                return true;
            }
        }
        return false;
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
