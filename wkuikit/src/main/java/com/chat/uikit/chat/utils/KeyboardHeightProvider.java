package com.chat.uikit.chat.utils;

import android.app.Activity;
import android.content.Context;
import android.graphics.Rect;
import android.graphics.drawable.ColorDrawable;
import android.view.Gravity;
import android.view.View;
import android.view.ViewTreeObserver;
import android.view.WindowManager;
import android.widget.PopupWindow;

/**
 * 键盘高度检测工具
 * adjustNothing 模式下，Activity 窗口不会被键盘顶起，
 * 需要用 PopupWindow（独立窗口层级）来检测键盘高度
 */
public class KeyboardHeightProvider extends PopupWindow implements ViewTreeObserver.OnGlobalLayoutListener {

    public interface KeyboardHeightListener {
        void onKeyboardHeightChanged(int height, boolean isVisible);
    }

    private final View contentView;
    private final View anchorView;
    private int maxHeight = 0;
    private KeyboardHeightListener listener;
    private boolean lastVisible = false;
    private int lastHeight = 0;

    public KeyboardHeightProvider(Activity activity, View anchor) {
        super(activity);
        this.anchorView = anchor;

        contentView = new View(activity);
        contentView.setLayoutParams(new WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT));
        setContentView(contentView);

        setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);
        setInputMethodMode(PopupWindow.INPUT_METHOD_NEEDED);

        setWidth(0);
        setHeight(WindowManager.LayoutParams.MATCH_PARENT);
        setBackgroundDrawable(new ColorDrawable(0));
    }

    public void start() {
        if (!isShowing() && anchorView.getWindowToken() != null) {
            try {
                contentView.getViewTreeObserver().addOnGlobalLayoutListener(this);
                showAtLocation(anchorView, Gravity.NO_GRAVITY, 0, 0);
            } catch (Exception e) {
                // ignore
            }
        }
    }

    public void setKeyboardHeightListener(KeyboardHeightListener listener) {
        this.listener = listener;
    }

    @Override
    public void onGlobalLayout() {
        if (contentView == null) return;
        Rect rect = new Rect();
        contentView.getWindowVisibleDisplayFrame(rect);

        if (rect.bottom > maxHeight) {
            maxHeight = rect.bottom;
        }

        int keyboardHeight = maxHeight - rect.bottom;
        int screenHeight = contentView.getRootView().getHeight();
        boolean visible = keyboardHeight > screenHeight / 4;

        if (visible != lastVisible || keyboardHeight != lastHeight) {
            lastVisible = visible;
            lastHeight = keyboardHeight;
            if (listener != null) {
                listener.onKeyboardHeightChanged(keyboardHeight, visible);
            }
        }
    }

    public void release() {
        try {
            if (contentView != null) {
                contentView.getViewTreeObserver().removeOnGlobalLayoutListener(this);
            }
            dismiss();
        } catch (Exception e) {
            // ignore
        }
    }
}
