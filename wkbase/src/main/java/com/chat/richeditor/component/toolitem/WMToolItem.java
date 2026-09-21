package com.chat.richeditor.component.toolitem;

import android.content.Context;
import android.text.Spannable;
import android.view.View;

import com.chat.richeditor.component.wmview.WMEditText;

import java.util.List;

public abstract class WMToolItem {

    protected WMEditText editText;
    protected boolean styleState = false;
    protected View view;

    public abstract void applyStyle(int start, int end);

    public abstract List<View> getView(Context context);

    public abstract void updateState(int start, int end);

    public abstract boolean checkState(int start, int end);

    public void setEditText(WMEditText editText) {
        this.editText = editText;
    }

    public WMEditText getEditText() {
        return editText;
    }

    public void setStyleState(boolean state) {
        this.styleState = state;
        updateViewState();
    }

    public boolean getStyleState() {
        return styleState;
    }

    protected abstract void updateViewState();

    protected Spannable getSpannable() {
        if (editText == null || editText.getText() == null) {
            return null;
        }
        return editText.getText();
    }

    protected int getSelectionStart() {
        if (editText == null) return 0;
        return editText.getSelectionStart();
    }

    protected int getSelectionEnd() {
        if (editText == null) return 0;
        return editText.getSelectionEnd();
    }
}
