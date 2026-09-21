package com.chat.richeditor.component.toolitem;

import android.content.Context;
import android.graphics.Color;
import android.text.Spannable;
import android.text.Spanned;
import android.text.style.ForegroundColorSpan;
import android.view.View;

import com.chat.base.R;
import com.chat.richeditor.component.util.WMColor;
import com.chat.richeditor.component.wmview.WMImageButton;

import java.util.ArrayList;
import java.util.List;

public class WMToolTextColor extends WMToolItem {

    private WMImageButton button;
    private int currentColor = Color.RED;
    private OnColorPickerListener colorPickerListener;

    public interface OnColorPickerListener {
        void onShowColorPicker(WMToolTextColor tool);
    }

    public WMToolTextColor() {
        this.currentColor = WMColor.TEXT_COLORS[1]; // 默认红色
    }

    public void setOnColorPickerListener(OnColorPickerListener listener) {
        this.colorPickerListener = listener;
    }

    @Override
    public List<View> getView(Context context) {
        List<View> views = new ArrayList<>();
        button = new WMImageButton(context);
        button.setImageResource(R.drawable.ic_tool_text_color);
        button.setActiveColor(currentColor);
        button.setOnClickListener(v -> {
            if (colorPickerListener != null) {
                colorPickerListener.onShowColorPicker(this);
            }
        });
        views.add(button);
        return views;
    }

    public void setColor(int color) {
        this.currentColor = color;
        if (button != null) {
            button.setActiveColor(color);
        }
        int start = getSelectionStart();
        int end = getSelectionEnd();
        if (start != end) {
            applyStyle(start, end);
        }
    }

    public int getCurrentColor() {
        return currentColor;
    }

    @Override
    public void applyStyle(int start, int end) {
        Spannable spannable = getSpannable();
        if (spannable == null || start == end) return;

        // 移除同范围内已有的颜色span
        ForegroundColorSpan[] spans = spannable.getSpans(start, end, ForegroundColorSpan.class);
        for (ForegroundColorSpan span : spans) {
            int spanStart = spannable.getSpanStart(span);
            int spanEnd = spannable.getSpanEnd(span);
            spannable.removeSpan(span);
            if (spanStart < start) {
                spannable.setSpan(new ForegroundColorSpan(span.getForegroundColor()), spanStart, start, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
            }
            if (spanEnd > end) {
                spannable.setSpan(new ForegroundColorSpan(span.getForegroundColor()), end, spanEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
            }
        }

        spannable.setSpan(new ForegroundColorSpan(currentColor), start, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        setStyleState(true);
    }

    @Override
    public boolean checkState(int start, int end) {
        Spannable spannable = getSpannable();
        if (spannable == null || start == end) return false;

        ForegroundColorSpan[] spans = spannable.getSpans(start, end, ForegroundColorSpan.class);
        return spans.length > 0;
    }

    @Override
    public void updateState(int start, int end) {
        Spannable spannable = getSpannable();
        if (spannable == null || start == end) {
            setStyleState(false);
            return;
        }

        ForegroundColorSpan[] spans = spannable.getSpans(start, end, ForegroundColorSpan.class);
        if (spans.length > 0) {
            currentColor = spans[0].getForegroundColor();
            if (button != null) {
                button.setActiveColor(currentColor);
            }
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
