package com.chat.base.views.pwdview;

import android.content.Context;
import android.util.AttributeSet;
import android.view.View;
import android.widget.LinearLayout;

public class NumPwdView extends LinearLayout implements View.OnClickListener {
    private INumPwdInputFinish listener;

    public NumPwdView(Context context) { super(context); init(); }
    public NumPwdView(Context context, AttributeSet attrs) { super(context, attrs); init(); }

    private void init() { setOrientation(VERTICAL); }

    public void clearAllPwd() {}
    public void setPwdViewBg() {}
    public void hideCloseIV() {}
    public void setBottomTv(String text, int color, PwdView.IBottomClick listener) {}
    public void setOnFinishInput(INumPwdInputFinish listener) { this.listener = listener; }
    public String getNumPwd() { return ""; }

    @Override
    public void onClick(View v) {}

    public interface INumPwdInputFinish {
        void onFinish();
    }
}