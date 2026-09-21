package com.chat.richeditor.component.toolitem;

import android.content.Context;
import android.text.Spannable;
import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.graphics.Typeface;
import android.text.style.StyleSpan;
import android.view.View;

import com.chat.base.R;
import com.chat.base.ui.Theme;
import com.chat.richeditor.component.span.WMMentionSpan;
import com.chat.richeditor.component.wmview.WMImageButton;

import java.util.ArrayList;
import java.util.List;

public class WMToolMention extends WMToolItem {

    private WMImageButton button;
    private OnMentionClickListener mentionClickListener;

    public interface OnMentionClickListener {
        void onMentionClick();
    }

    public void setOnMentionClickListener(OnMentionClickListener listener) {
        this.mentionClickListener = listener;
    }

    @Override
    public List<View> getView(Context context) {
        List<View> views = new ArrayList<>();
        button = new WMImageButton(context);
        button.setImageResource(R.drawable.ic_mention);
        button.setOnClickListener(v -> {
            if (mentionClickListener != null) {
                mentionClickListener.onMentionClick();
            }
        });
        views.add(button);
        return views;
    }

    public void insertMention(String uid, String name) {
        if (editText == null) return;

        int start = editText.getSelectionStart();
        String mentionText = "@" + name + " ";
        SpannableStringBuilder sb = new SpannableStringBuilder(editText.getText());
        sb.insert(start, mentionText);

        int mentionEnd = start + mentionText.length();
        WMMentionSpan mentionSpan = new WMMentionSpan(uid, name, Theme.colorAccount);
        sb.setSpan(mentionSpan, start, mentionEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        sb.setSpan(new StyleSpan(Typeface.BOLD), start, mentionEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);

        editText.setText(sb);
        editText.setSelection(mentionEnd);
    }

    @Override
    public void applyStyle(int start, int end) {
        // @提及通过 insertMention 方法插入
    }

    @Override
    public boolean checkState(int start, int end) {
        Spannable spannable = getSpannable();
        if (spannable == null) return false;
        WMMentionSpan[] spans = spannable.getSpans(start, end, WMMentionSpan.class);
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
