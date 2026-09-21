package com.chat.base.views.pwdview;

import android.content.Context;
import android.util.AttributeSet;
import android.widget.LinearLayout;

public class PwdView extends LinearLayout {
    public PwdView(Context context) { super(context); init(); }
    public PwdView(Context context, AttributeSet attrs) { super(context, attrs); init(); }

    private void init() { setOrientation(VERTICAL); }

    public void showPwdView() {}
    public void setBg() {}
    public void hideCloseIV() {}
    public void setBottomTv(String text, int color, IBottomClick listener) {}

    public interface IBottomClick {
        void onClick();
    }

    @Override
    protected void onLayout(boolean changed, int left, int top, int right, int bottom) {
        super.onLayout(changed, left, top, right, bottom);
    }
}