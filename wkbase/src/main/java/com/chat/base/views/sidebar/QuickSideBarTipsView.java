package com.chat.base.views.sidebar;

import android.content.Context;
import android.util.AttributeSet;
import android.widget.RelativeLayout;

import com.chat.base.views.sidebar.tipsview.QuickSideBarTipsItemView;

public class QuickSideBarTipsView extends RelativeLayout {
    private QuickSideBarTipsItemView mTipsView;

    public QuickSideBarTipsView(Context context, AttributeSet attributeSet, int i) {
        super(context, attributeSet, i);
        init(context, attributeSet);
    }

    private void init(Context context, AttributeSet attributeSet) {
        this.mTipsView = new QuickSideBarTipsItemView(context, attributeSet);
        addView(this.mTipsView, new RelativeLayout.LayoutParams(-1, -2));
    }

    @Override
    public void setBackgroundColor(int i) {
        this.mTipsView.setBackgroundColor(i);
    }

    public void setText(String str, int i, float f) {
        this.mTipsView.setText(str);
        RelativeLayout.LayoutParams layoutParams = (RelativeLayout.LayoutParams) this.mTipsView.getLayoutParams();
        layoutParams.topMargin = (int) (f - (getWidth() / 2.8));
        this.mTipsView.setLayoutParams(layoutParams);
    }

    public QuickSideBarTipsView(Context context, AttributeSet attributeSet) {
        this(context, attributeSet, 0);
    }

    public QuickSideBarTipsView(Context context) {
        this(context, null);
    }
}
