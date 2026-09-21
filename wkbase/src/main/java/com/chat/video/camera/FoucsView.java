package com.chat.video.camera;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.util.AttributeSet;
import android.view.View;

import androidx.annotation.Nullable;

import com.chat.base.utils.AndroidUtilities;

public class FoucsView extends View {
    private int center_x;
    private int center_y;
    private int length;
    private Paint mPaint;
    private int size;

    public FoucsView(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        this.size = AndroidUtilities.getScreenWidth() / 3;
        this.mPaint = new Paint();
        this.mPaint.setAntiAlias(true);
        this.mPaint.setDither(true);
        this.mPaint.setColor(0xFFE2363E);
        this.mPaint.setStrokeWidth(4.0f);
        this.mPaint.setStyle(Paint.Style.STROKE);
    }

    @Override
    public void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        canvas.drawRect(
            this.center_x - this.length,
            this.center_y - this.length,
            this.center_x + this.length,
            this.center_y + this.length,
            this.mPaint
        );
        canvas.drawLine(2.0f, getHeight() / 2f, this.size / 10f, getHeight() / 2f, this.mPaint);
        canvas.drawLine(getWidth() - 2, getHeight() / 2f, getWidth() - (this.size / 10f), getHeight() / 2f, this.mPaint);
        canvas.drawLine(getWidth() / 2f, 2.0f, getWidth() / 2f, this.size / 10f, this.mPaint);
        canvas.drawLine(getWidth() / 2f, getHeight() - 2, getWidth() / 2f, getHeight() - (this.size / 10f), this.mPaint);
    }

    @Override
    public void onMeasure(int widthSpec, int heightSpec) {
        super.onMeasure(widthSpec, heightSpec);
        this.center_x = this.size / 2;
        this.center_y = this.size / 2;
        this.length = (this.size / 2) - 2;
        setMeasuredDimension(this.size, this.size);
    }

    public FoucsView(Context context, @Nullable AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public FoucsView(Context context) {
        this(context, null);
    }
}
