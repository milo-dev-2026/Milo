package com.chat.richeditor.component.toolitem;

import android.content.Context;
import android.text.Spannable;
import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.view.View;

import com.chat.base.R;
import com.chat.base.ui.components.AlignImageSpan;
import com.chat.richeditor.component.wmview.WMImageButton;

import java.util.ArrayList;
import java.util.List;

public class WMToolImage extends WMToolItem {

    private WMImageButton button;
    private OnImageClickListener imageClickListener;

    public interface OnImageClickListener {
        void onImageClick();
    }

    public void setOnImageClickListener(OnImageClickListener listener) {
        this.imageClickListener = listener;
    }

    @Override
    public List<View> getView(Context context) {
        List<View> views = new ArrayList<>();
        button = new WMImageButton(context);
        button.setImageResource(R.drawable.ic_photo);
        button.setOnClickListener(v -> {
            if (imageClickListener != null) {
                imageClickListener.onImageClick();
            }
        });
        views.add(button);
        return views;
    }

    public void insertImage(String imageUrl, int width, int height) {
        if (editText == null) return;

        int start = editText.getSelectionStart();
        String imageText = "\uFFFC "; // 对象替换字符 + 空格
        SpannableStringBuilder sb = new SpannableStringBuilder(editText.getText());
        sb.insert(start, imageText);

        int imageEnd = start + 1; // 只占一个字符位置

        // 这里使用占位，实际图片加载由外部处理
        // AlignImageSpan 需要 drawable，这里先创建一个占位
        try {
            android.graphics.drawable.Drawable drawable = new android.graphics.drawable.ColorDrawable(0xffeeeeee);
            drawable.setBounds(0, 0, width, height);
            AlignImageSpan imageSpan = new AlignImageSpan(drawable, AlignImageSpan.ALIGN_CENTER) {
                @Override
                public void onClick(View view) {
                    // 图片点击事件
                }
            };
            sb.setSpan(imageSpan, start, imageEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        } catch (Exception e) {
            e.printStackTrace();
        }

        editText.setText(sb);
        editText.setSelection(imageEnd + 1); // 移到空格后
    }

    @Override
    public void applyStyle(int start, int end) {
        // 图片通过 insertImage 方法插入
    }

    @Override
    public boolean checkState(int start, int end) {
        return false;
    }

    @Override
    public void updateState(int start, int end) {
        setStyleState(false);
    }

    @Override
    protected void updateViewState() {
        if (button != null) {
            button.setActive(styleState);
        }
    }
}
