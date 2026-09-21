package com.chat.base.ui.components;

import android.content.Context;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.util.AttributeSet;
import com.google.android.material.imageview.ShapeableImageView;
import com.google.android.material.shape.CornerFamily;
import com.google.android.material.shape.ShapeAppearanceModel;

public class FilterImageView extends ShapeableImageView {
    public final float[] BG_PRESSED = new float[8];
    public final float[] BG_NOT_PRESSED = new float[8];
    private float strokeWidth = 0f;

    public FilterImageView(Context context) { super(context); }
    public FilterImageView(Context context, AttributeSet attrs) { super(context, attrs); }
    public FilterImageView(Context context, AttributeSet attrs, int defStyleAttr) { super(context, attrs, defStyleAttr); }

    public void setStrokeWidth(float width) {
        this.strokeWidth = width;
        super.setStrokeWidth(width * getResources().getDisplayMetrics().density);
    }

    public void setStrokeColor(int color) {
        super.setStrokeColor(ColorStateList.valueOf(color));
    }

    public void setAllCorners(int radius) {
        float r = radius * getResources().getDisplayMetrics().density;
        ShapeAppearanceModel model = new ShapeAppearanceModel.Builder()
            .setTopLeftCorner(CornerFamily.ROUNDED, r)
            .setTopRightCorner(CornerFamily.ROUNDED, r)
            .setBottomLeftCorner(CornerFamily.ROUNDED, r)
            .setBottomRightCorner(CornerFamily.ROUNDED, r)
            .build();
        setShapeAppearanceModel(model);
    }

    public void setCorners(int topLeft, int topRight, int bottomLeft, int bottomRight) {
        float density = getResources().getDisplayMetrics().density;
        ShapeAppearanceModel model = new ShapeAppearanceModel.Builder()
            .setTopLeftCorner(CornerFamily.ROUNDED, topLeft * density)
            .setTopRightCorner(CornerFamily.ROUNDED, topRight * density)
            .setBottomLeftCorner(CornerFamily.ROUNDED, bottomLeft * density)
            .setBottomRightCorner(CornerFamily.ROUNDED, bottomRight * density)
            .build();
        setShapeAppearanceModel(model);
    }

    public void setPressed(boolean pressed) {}
}
