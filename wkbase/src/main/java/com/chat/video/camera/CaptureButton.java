package com.chat.video.camera;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.AnimatorSet;
import android.animation.ValueAnimator;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.RectF;
import android.os.CountDownTimer;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;

import com.chat.video.camera.listener.CaptureListener;

public class CaptureButton extends View {
    private static final String TAG = "CaptureButton";
    public static final int STATE_IDLE = 1;
    public static final int STATE_PRESS = 2;
    public static final int STATE_LONG_PRESS = 3;
    public static final int STATE_RECORDERING = 4;
    public static final int STATE_BAN = 5;

    private float button_inside_radius;
    private float button_outside_radius;
    private float button_radius;
    private int button_size;
    private int button_state;
    private CaptureListener captureLisenter;
    private float center_X;
    private float center_Y;
    private int duration;
    private float event_Y;
    private int inside_reduce_size;
    private LongPressRunnable longPressRunnable;
    private Paint mPaint;
    private int min_duration;
    private int outside_add_size;
    private float progress;
    private int progress_color;
    private int outside_color;
    private int inside_color;
    private int recorded_time;
    private RectF rectF;
    private int state;
    private float strokeWidth;
    private RecordCountDownTimer timer;

    public class LongPressRunnable implements Runnable {
        @Override
        public void run() {
            CaptureButton.this.state = STATE_LONG_PRESS;
            CaptureButton.this.animateButton(
                CaptureButton.this.button_outside_radius,
                CaptureButton.this.button_outside_radius + CaptureButton.this.outside_add_size,
                CaptureButton.this.button_inside_radius,
                CaptureButton.this.button_inside_radius - CaptureButton.this.inside_reduce_size
            );
        }
    }

    public class RecordCountDownTimer extends CountDownTimer {
        public RecordCountDownTimer(long millis, long interval) {
            super(millis, interval);
        }

        @Override
        public void onFinish() {
            CaptureButton.this.updateProgress(0L);
            CaptureButton.this.finishRecording();
        }

        @Override
        public void onTick(long millisUntilFinished) {
            CaptureButton.this.updateProgress(millisUntilFinished);
        }
    }

    public CaptureButton(Context context, int size) {
        super(context);
        this.progress_color = 0xFFE2363E;
        this.outside_color = 0xFFEEEEEE;
        this.inside_color = 0xFFFFFFFF;
        this.button_size = size;
        float half = size / 2.0f;
        this.button_radius = half;
        this.button_outside_radius = half;
        this.button_inside_radius = half * 0.75f;
        this.strokeWidth = size / 15;
        this.outside_add_size = size / 5;
        this.inside_reduce_size = size / 8;
        this.mPaint = new Paint();
        this.mPaint.setAntiAlias(true);
        this.progress = 0.0f;
        this.longPressRunnable = new LongPressRunnable();
        this.state = STATE_IDLE;
        this.button_state = 259;
        this.duration = 10000;
        this.min_duration = 1500;
        int totalSize = this.button_size + (this.outside_add_size * 2);
        this.center_X = totalSize / 2.0f;
        this.center_Y = totalSize / 2.0f;
        float radiusWithAdd = this.outside_add_size + this.button_radius - (this.strokeWidth / 2.0f);
        this.rectF = new RectF(
            this.center_X - radiusWithAdd,
            this.center_Y - radiusWithAdd,
            this.center_X + radiusWithAdd,
            this.center_Y + radiusWithAdd
        );
        this.timer = new RecordCountDownTimer(this.duration, this.duration / 360);
    }

    private void handleActionUp() {
        removeCallbacks(this.longPressRunnable);
        if (this.state == STATE_PRESS) {
            if (this.captureLisenter != null && (this.button_state == 257 || this.button_state == 259)) {
                takePhoto();
            } else {
                this.state = STATE_IDLE;
            }
        } else if (this.state == STATE_RECORDERING) {
            this.timer.cancel();
            finishRecording();
        }
    }

    public boolean isIdle() {
        return this.state == STATE_IDLE;
    }

    @Override
    public void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        this.mPaint.setStyle(Paint.Style.FILL);
        this.mPaint.setColor(this.outside_color);
        canvas.drawCircle(this.center_X, this.center_Y, this.button_outside_radius, this.mPaint);
        this.mPaint.setColor(this.inside_color);
        canvas.drawCircle(this.center_X, this.center_Y, this.button_inside_radius, this.mPaint);
        if (this.state == STATE_RECORDERING) {
            this.mPaint.setColor(this.progress_color);
            this.mPaint.setStyle(Paint.Style.STROKE);
            this.mPaint.setStrokeWidth(this.strokeWidth);
            canvas.drawArc(this.rectF, -90.0f, this.progress, false, this.mPaint);
        }
    }

    @Override
    public void onMeasure(int widthSpec, int heightSpec) {
        int total = this.button_size + (this.outside_add_size * 2);
        setMeasuredDimension(total, total);
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        int action = event.getAction();
        if (action == MotionEvent.ACTION_DOWN) {
            if (event.getPointerCount() <= 1 && this.state == STATE_IDLE) {
                this.event_Y = event.getY();
                this.state = STATE_PRESS;
                if (this.button_state == 258 || this.button_state == 259) {
                    postDelayed(this.longPressRunnable, 500L);
                }
            }
        } else if (action == MotionEvent.ACTION_MOVE) {
            if (this.captureLisenter != null && this.state == STATE_RECORDERING
                    && (this.button_state == 258 || this.button_state == 259)) {
                this.captureLisenter.c(this.event_Y - event.getY());
            }
        } else if (action == MotionEvent.ACTION_UP) {
            handleActionUp();
        }
        return true;
    }

    private void finishRecording() {
        if (this.captureLisenter != null) {
            if (this.recorded_time < this.min_duration) {
                this.captureLisenter.a(this.recorded_time);
            } else {
                this.captureLisenter.f(this.recorded_time);
            }
        }
        resetAfterCapture();
    }

    private void resetAfterCapture() {
        this.state = STATE_BAN;
        this.progress = 0.0f;
        invalidate();
        animateButton(
            this.button_outside_radius, this.button_radius,
            this.button_inside_radius, 0.75f * this.button_radius
        );
    }

    public void resetState() {
        this.state = STATE_IDLE;
    }

    private void takePhoto() {
        ValueAnimator anim = ValueAnimator.ofFloat(this.button_inside_radius, 0.75f * this.button_inside_radius, this.button_inside_radius);
        anim.addUpdateListener(animation -> {
            CaptureButton.this.button_inside_radius = (float) animation.getAnimatedValue();
            CaptureButton.this.invalidate();
        });
        anim.addListener(new AnimatorListenerAdapter() {
            @Override
            public void onAnimationEnd(Animator animation) {
                if (CaptureButton.this.captureLisenter != null) {
                    CaptureButton.this.captureLisenter.b();
                }
                CaptureButton.this.state = STATE_BAN;
            }
        });
        anim.setDuration(100L);
        anim.start();
    }

    public void setButtonFeatures(int features) {
        this.button_state = features;
    }

    public void setCaptureLisenter(CaptureListener listener) {
        this.captureLisenter = listener;
    }

    public void setDuration(int duration) {
        this.duration = duration;
        this.timer = new RecordCountDownTimer(duration, duration / 360);
    }

    public void setMinDuration(int minDuration) {
        this.min_duration = minDuration;
    }

    private void animateButton(float outsideFrom, float outsideTo, float insideFrom, float insideTo) {
        ValueAnimator outsideAnim = ValueAnimator.ofFloat(outsideFrom, outsideTo);
        ValueAnimator insideAnim = ValueAnimator.ofFloat(insideFrom, insideTo);
        outsideAnim.addUpdateListener(animation -> {
            CaptureButton.this.button_outside_radius = (float) animation.getAnimatedValue();
            CaptureButton.this.invalidate();
        });
        insideAnim.addUpdateListener(animation -> {
            CaptureButton.this.button_inside_radius = (float) animation.getAnimatedValue();
            CaptureButton.this.invalidate();
        });
        AnimatorSet set = new AnimatorSet();
        set.addListener(new AnimatorListenerAdapter() {
            @Override
            public void onAnimationEnd(Animator animation) {
                if (CaptureButton.this.state == STATE_LONG_PRESS) {
                    if (CaptureButton.this.captureLisenter != null) {
                        CaptureButton.this.captureLisenter.d();
                    }
                    CaptureButton.this.state = STATE_RECORDERING;
                    CaptureButton.this.timer.start();
                }
            }
        });
        set.playTogether(outsideAnim, insideAnim);
        set.setDuration(100L);
        set.start();
    }

    private void updateProgress(long millisUntilFinished) {
        this.recorded_time = (int) (this.duration - millisUntilFinished);
        this.progress = 360.0f - (((float) millisUntilFinished / this.duration) * 360.0f);
        invalidate();
    }

    public CaptureButton(Context context) {
        super(context);
        this.progress_color = 0xFFE2363E;
        this.outside_color = 0xFFEEEEEE;
        this.inside_color = 0xFFFFFFFF;
    }
}
