package com.chat.video.camera;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.view.View;

public class TypeButton extends View {
    public static final int TYPE_CANCEL = 1;
    public static final int TYPE_CONFIRM = 2;
    private float button_radius;
    private int button_size;
    private int button_type;
    private float center_X;
    private float center_Y;
    private float index;
    private Paint mPaint;
    private Path path;
    private RectF rectF;
    private float strokeWidth;

    public TypeButton(Context context, int type, int size) {
        super(context);
        this.button_type = type;
        this.button_size = size;
        float half = size / 2.0f;
        this.button_radius = half;
        this.center_X = half;
        this.center_Y = half;
        this.mPaint = new Paint();
        this.path = new Path();
        this.strokeWidth = size / 50.0f;
        this.index = this.button_size / 12.0f;
        this.rectF = new RectF(
            this.center_X,
            this.center_Y - this.index,
            (2.0f * this.index) + this.center_X,
            this.center_Y + this.index
        );
    }

    @Override
    public void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        if (this.button_type == TYPE_CANCEL) {
            this.mPaint.setAntiAlias(true);
            this.mPaint.setColor(0xFFEEEEEE);
            this.mPaint.setStyle(Paint.Style.FILL);
            canvas.drawCircle(this.center_X, this.center_Y, this.button_radius, this.mPaint);
            this.mPaint.setColor(0xFF000000);
            this.mPaint.setStyle(Paint.Style.STROKE);
            this.mPaint.setStrokeWidth(this.strokeWidth);
            this.path.reset();
            this.path.moveTo(this.center_X - (this.index / 7.0f), this.center_Y + this.index);
            this.path.lineTo(this.center_X + this.index, this.center_Y + this.index);
            this.path.arcTo(this.rectF, 90.0f, -180.0f);
            this.path.lineTo(this.center_X - this.index, this.center_Y - this.index);
            canvas.drawPath(this.path, this.mPaint);
            this.mPaint.setStyle(Paint.Style.FILL);
            this.path.reset();
            this.path.moveTo(this.center_X - this.index, (float)(this.center_Y - (this.index * 1.5d)));
            this.path.lineTo(this.center_X - this.index, (float)(this.center_Y - (this.index / 2.3d)));
            this.path.lineTo((float)(this.center_X - (this.index * 1.6d)), this.center_Y - this.index);
            this.path.close();
            canvas.drawPath(this.path, this.mPaint);
        }
        if (this.button_type == TYPE_CONFIRM) {
            this.mPaint.setAntiAlias(true);
            this.mPaint.setColor(0xFFFFFFFF);
            this.mPaint.setStyle(Paint.Style.FILL);
            canvas.drawCircle(this.center_X, this.center_Y, this.button_radius, this.mPaint);
            this.mPaint.setAntiAlias(true);
            this.mPaint.setStyle(Paint.Style.STROKE);
            this.mPaint.setColor(0xFF00C853);
            this.mPaint.setStrokeWidth(this.strokeWidth);
            this.path.reset();
            this.path.moveTo(this.center_X - (this.button_size / 6.0f), this.center_Y);
            this.path.lineTo(this.center_X - (this.button_size / 21.2f), this.center_Y + (this.button_size / 7.7f));
            this.path.lineTo(this.center_X + (this.button_size / 4.0f), this.center_Y - (this.button_size / 8.5f));
            this.path.lineTo(this.center_X - (this.button_size / 21.2f), this.center_Y + (this.button_size / 9.4f));
            this.path.close();
            canvas.drawPath(this.path, this.mPaint);
        }
    }

    @Override
    public void onMeasure(int widthSpec, int heightSpec) {
        setMeasuredDimension(this.button_size, this.button_size);
    }

    public TypeButton(Context context) {
        super(context);
    }
}
