package com.chat.video.camera;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Path;
import android.view.View;

public class ReturnButton extends View {
    private int center_X;
    private int center_Y;
    private Paint paint;
    private Path path;
    private int size;
    private float strokeWidth;

    public ReturnButton(Context context, int size) {
        this(context);
        this.size = size;
        int half = size / 2;
        this.center_X = half;
        this.center_Y = half;
        this.strokeWidth = size / 15.0f;
        this.paint = new Paint();
        this.paint.setAntiAlias(true);
        this.paint.setColor(0xFFFFFFFF);
        this.paint.setStyle(Paint.Style.STROKE);
        this.paint.setStrokeWidth(this.strokeWidth);
        this.path = new Path();
    }

    @Override
    public void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        this.path.moveTo(this.strokeWidth, this.strokeWidth / 2.0f);
        this.path.lineTo(this.center_X, this.center_Y - (this.strokeWidth / 2.0f));
        this.path.lineTo(this.size - this.strokeWidth, this.strokeWidth / 2.0f);
        canvas.drawPath(this.path, this.paint);
    }

    @Override
    public void onMeasure(int widthSpec, int heightSpec) {
        setMeasuredDimension(this.size, this.size / 2);
    }

    public ReturnButton(Context context) {
        super(context);
    }
}
