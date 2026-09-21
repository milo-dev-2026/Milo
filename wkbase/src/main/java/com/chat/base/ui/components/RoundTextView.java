package com.chat.base.ui.components;

import android.content.Context;
import android.graphics.drawable.GradientDrawable;
import android.util.AttributeSet;
import androidx.appcompat.widget.AppCompatTextView;
import com.chat.base.utils.AndroidUtilities;

public class RoundTextView extends AppCompatTextView {
    private final GradientDrawable drawable = new GradientDrawable();

    public RoundTextView(Context context) {
        super(context);
        drawable.setShape(GradientDrawable.RECTANGLE);
        setBackground(drawable);
    }

    public RoundTextView(Context context, AttributeSet attrs) {
        super(context, attrs);
        drawable.setShape(GradientDrawable.RECTANGLE);
        setBackground(drawable);
    }

    public RoundTextView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        drawable.setShape(GradientDrawable.RECTANGLE);
        setBackground(drawable);
    }

    public void setBackGroundColor(int color) {
        drawable.setColor(color);
        setBackground(drawable);
    }

    public void setBorderColor(int color) {
        drawable.setStroke(AndroidUtilities.dp(1), color);
        setBackground(drawable);
    }

    public void setAllRadius(float radius) {
        drawable.setCornerRadius(AndroidUtilities.dp(radius));
        setBackground(drawable);
    }
}
