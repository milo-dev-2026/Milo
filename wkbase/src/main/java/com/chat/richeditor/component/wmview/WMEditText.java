package com.chat.richeditor.component.wmview;

import android.content.Context;
import android.text.Editable;
import android.text.Spannable;
import android.text.SpannableStringBuilder;
import android.text.TextWatcher;
import android.util.AttributeSet;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.widget.AppCompatEditText;

import com.chat.richeditor.component.toolitem.WMToolItem;

import java.util.ArrayList;
import java.util.List;

public class WMEditText extends AppCompatEditText {

    private WMToolContainer toolContainer;
    private List<WMToolItem> toolItems = new ArrayList<>();
    private OnSelectionChangedListener selectionChangedListener;
    private boolean isEditable = true;

    public interface OnSelectionChangedListener {
        void onSelectionChanged(int start, int end);
    }

    public WMEditText(@NonNull Context context) {
        super(context);
        init();
    }

    public WMEditText(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public WMEditText(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    private void init() {
        addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
            }

            @Override
            public void afterTextChanged(Editable s) {
                updateToolStates();
            }
        });
    }

    public void setupWithToolContainer(WMToolContainer container) {
        this.toolContainer = container;
        this.toolItems = container.getTools();
        for (WMToolItem tool : toolItems) {
            tool.setEditText(this);
        }
    }

    public void addToolItem(WMToolItem tool) {
        toolItems.add(tool);
        tool.setEditText(this);
    }

    @Override
    protected void onSelectionChanged(int selStart, int selEnd) {
        super.onSelectionChanged(selStart, selEnd);
        if (selectionChangedListener != null) {
            selectionChangedListener.onSelectionChanged(selStart, selEnd);
        }
        updateToolStates();
    }

    private void updateToolStates() {
        if (toolItems == null || toolItems.isEmpty()) return;
        int start = getSelectionStart();
        int end = getSelectionEnd();
        if (start < 0) start = 0;
        if (end < 0) end = 0;
        for (WMToolItem tool : toolItems) {
            tool.updateState(start, end);
        }
    }

    public void setOnSelectionChangedListener(OnSelectionChangedListener listener) {
        this.selectionChangedListener = listener;
    }

    public SpannableStringBuilder getSpannableText() {
        Editable editable = getText();
        if (editable == null) {
            return new SpannableStringBuilder();
        }
        return new SpannableStringBuilder(editable);
    }

    public void setEditable(boolean editable) {
        this.isEditable = editable;
        setFocusable(editable);
        setFocusableInTouchMode(editable);
        setCursorVisible(editable);
    }

    public boolean isEditableState() {
        return isEditable;
    }

    @Override
    public InputConnection onCreateInputConnection(EditorInfo outAttrs) {
        InputConnection inputConnection = super.onCreateInputConnection(outAttrs);
        // 防止回车换行导致布局错乱
        outAttrs.imeOptions |= EditorInfo.IME_FLAG_NO_EXTRACT_UI;
        return inputConnection;
    }
}
