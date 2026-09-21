package com.chat.richeditor.component.toolitem;

import android.content.Context;
import android.text.Spannable;
import android.text.Spanned;
import android.text.style.AbsoluteSizeSpan;
import android.view.View;

import com.chat.base.R;
import com.chat.richeditor.component.util.WMColor;
import com.chat.richeditor.component.wmview.WMImageButton;

import java.util.ArrayList;
import java.util.List;

public class WMToolTextSize extends WMToolItem {

    private WMImageButton button;
    private int currentSize = 16;
    private OnSizePickerListener sizePickerListener;

    public interface OnSizePickerListener {
        void onShowSizePicker(WMToolTextSize tool);
    }

    public WMToolTextSize() {
        this.currentSize = WMColor.TEXT_SIZES[2]; // 默认16sp
    }

    public void setOnSizePickerListener(OnSizePickerListener listener) {
        this.sizePickerListener = listener;
    }

    @Override
    public List<View> getView(Context context) {
        List<View> views = new ArrayList<>();
        button = new WMImageButton(context);
        button.setImageResource(R.drawable.ic_tool_text_size);
        button.setOnClickListener(v -> {
            if (sizePickerListener != null) {
                sizePickerListener.onShowSizePicker(this);
            }
        });
        views.add(button);
        return views;
    }

    public void setSize(int size) {
        this.currentSize = size;
        int start = getSelectionStart();
        int end = getSelectionEnd();
        if (start != end) {
            applyStyle(start, end);
        }
    }

    public int getCurrentSize() {
        return currentSize;
    }

    @Override
    public void applyStyle(int start, int end) {
        Spannable spannable = getSpannable();
        if (spannable == null || start == end) return;

        AbsoluteSizeSpan[] spans = spannable.getSpans(start, end, AbsoluteSizeSpan.class);
        for (AbsoluteSizeSpan span : spans) {
            int spanStart = spannable.getSpanStart(span);
            int spanEnd = spannable.getSpanEnd(span);
            spannable.removeSpan(span);
            if (spanStart < start) {
                spannable.setSpan(new AbsoluteSizeSpan(span.getSize(), true), spanStart, start, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
            }
            if (spanEnd > end) {
                spannable.setSpan(new AbsoluteSizeSpan(span.getSize(), true), end, spanEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
            }
        }

        spannable.setSpan(new AbsoluteSizeSpan(currentSize, true), start, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        setStyleState(true);
    }

    @Override
    public boolean checkState(int start, int end) {
        Spannable spannable = getSpannable();
        if (spannable == null || start == end) return false;

        AbsoluteSizeSpan[] spans = spannable.getSpans(start, end, AbsoluteSizeSpan.class);
        return spans.length > 0;
    }

    @Override
    public void updateState(int start, int end) {
        Spannable spannable = getSpannable();
        if (spannable == null || start == end) {
            setStyleState(false);
            return;
        }

        AbsoluteSizeSpan[] spans = spannable.getSpans(start, end, AbsoluteSizeSpan.class);
        if (spans.length > 0) {
            currentSize = spans[0].getSize();
            setStyleState(true);
        } else {
            setStyleState(false);
        }
    }

    @Override
    protected void updateViewState() {
        if (button != null) {
            button.setActive(styleState);
        }
    }
}
