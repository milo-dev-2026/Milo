package com.github.easyview;

import android.content.Context;
import android.content.res.TypedArray;
import android.graphics.drawable.GradientDrawable;
import android.util.AttributeSet;

import androidx.annotation.Nullable;
import androidx.appcompat.widget.AppCompatTextView;

import com.chat.uikit.R;

public class EasyTextView extends AppCompatTextView {

    public EasyTextView(Context context) {
        super(context);
        init(context, null);
    }

    public EasyTextView(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init(context, attrs);
    }

    public EasyTextView(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init(context, attrs);
    }

    private void init(Context context, AttributeSet attrs) {
        if (attrs == null) return;

        TypedArray ta = context.obtainStyledAttributes(attrs, R.styleable.EasyConstraintLayout);

        float defRadius = ta.getDimension(R.styleable.EasyConstraintLayout_ev_radius, 0);
        float topRadius = ta.getDimension(R.styleable.EasyConstraintLayout_ev_top_radius, 0);
        float bottomRadius = ta.getDimension(R.styleable.EasyConstraintLayout_ev_bottom_radius, 0);

        float topLeft = ta.getDimension(R.styleable.EasyConstraintLayout_ev_topLeft_radius,
                defRadius > 0 ? defRadius : topRadius);
        float topRight = ta.getDimension(R.styleable.EasyConstraintLayout_ev_topRight_radius,
                defRadius > 0 ? defRadius : topRadius);
        float bottomLeft = ta.getDimension(R.styleable.EasyConstraintLayout_ev_bottomLeft_radius,
                defRadius > 0 ? defRadius : bottomRadius);
        float bottomRight = ta.getDimension(R.styleable.EasyConstraintLayout_ev_bottomRight_radius,
                defRadius > 0 ? defRadius : bottomRadius);

        int strokeColor = ta.getColor(R.styleable.EasyConstraintLayout_ev_stroke_color, 0);
        float strokeWidth = ta.getDimension(R.styleable.EasyConstraintLayout_ev_stroke_width, 0);

        ta.recycle();

        if (defRadius > 0 || topRadius > 0 || bottomRadius > 0 || strokeColor != 0) {
            GradientDrawable drawable = new GradientDrawable();
            drawable.setCornerRadii(new float[]{
                    topLeft, topLeft,
                    topRight, topRight,
                    bottomRight, bottomRight,
                    bottomLeft, bottomLeft
            });
            if (strokeWidth > 0 && strokeColor != 0) {
                drawable.setStroke((int) strokeWidth, strokeColor);
            }
            setBackground(drawable);
        }
    }
}
