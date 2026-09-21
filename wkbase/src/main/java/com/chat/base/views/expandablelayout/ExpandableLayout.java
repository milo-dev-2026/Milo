package com.chat.base.views.expandablelayout;

import android.content.Context;
import android.util.AttributeSet;
import android.widget.FrameLayout;

public class ExpandableLayout extends FrameLayout {
    public ExpandableLayout(Context context) { super(context); }
    public ExpandableLayout(Context context, AttributeSet attrs) { super(context, attrs); }
    public ExpandableLayout(Context context, AttributeSet attrs, int defStyleAttr) { super(context, attrs, defStyleAttr); }

    public void setExpanded(boolean expanded) {}
    public void setExpanded(boolean expanded, boolean animated) {}
    public boolean isExpanded() { return false; }
    public void toggle() {}
}