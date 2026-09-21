package com.chat.base.ui.components;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.ObjectAnimator;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.util.AttributeSet;
import android.view.HapticFeedbackConstants;
import android.view.MotionEvent;
import android.view.View;
import android.view.accessibility.AccessibilityNodeInfo;

public class SwitchView extends View {
    private boolean checked = false;
    private OnCheckedChangeListener listener;
    private Paint trackPaint;
    private Paint thumbPaint;
    private RectF trackRect;
    private float progress = 0f;
    private ObjectAnimator checkAnimator;

    private final int TRACK_WIDTH_DP = 50;
    private final int TRACK_HEIGHT_DP = 30;
    private final int THUMB_RADIUS_DP = 13;

    private int checkedColor = Color.parseColor("#3F74FC");
    private int uncheckedColor = Color.parseColor("#E4E7EA");
    private int thumbColor = Color.WHITE;

    public interface OnCheckedChangeListener {
        void onCheckedChanged(View view, boolean checked);
    }

    public SwitchView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public SwitchView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    public SwitchView(Context context) {
        super(context);
        init();
    }

    private void init() {
        trackPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        trackPaint.setStyle(Paint.Style.FILL);

        thumbPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        thumbPaint.setStyle(Paint.Style.FILL);
        thumbPaint.setColor(thumbColor);

        trackRect = new RectF();
        setOnClickListener(v -> setChecked(!checked, true));
    }

    private float dp(float dp) {
        return dp * getResources().getDisplayMetrics().density;
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        int width = (int) dp(TRACK_WIDTH_DP);
        int height = (int) dp(TRACK_HEIGHT_DP);
        setMeasuredDimension(width, height);
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);
        trackRect.set(0, 0, w, h);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        if (trackRect.width() <= 0) return;

        int r = (int) (Color.red(uncheckedColor) + (Color.red(checkedColor) - Color.red(uncheckedColor)) * progress);
        int g = (int) (Color.green(uncheckedColor) + (Color.green(checkedColor) - Color.green(uncheckedColor)) * progress);
        int b = (int) (Color.blue(uncheckedColor) + (Color.blue(checkedColor) - Color.blue(uncheckedColor)) * progress);
        trackPaint.setColor(Color.rgb(r, g, b));

        float radius = getHeight() / 2f;
        canvas.drawRoundRect(trackRect, radius, radius, trackPaint);

        float thumbRadius = dp(THUMB_RADIUS_DP);
        float thumbX = dp(15f) + (getWidth() - dp(30f)) * progress;
        canvas.drawCircle(thumbX, getHeight() / 2f, thumbRadius, thumbPaint);
    }

    private void animateToState(boolean z) {
        cancelCheckAnimator();
        float target = z ? 1f : 0f;
        ObjectAnimator anim = ObjectAnimator.ofFloat(this, "progress", target);
        checkAnimator = anim;
        anim.setDuration(250);
        anim.addListener(new AnimatorListenerAdapter() {
            @Override
            public void onAnimationEnd(Animator animation) {
                checkAnimator = null;
            }
        });
        anim.start();
    }

    private void cancelCheckAnimator() {
        if (checkAnimator != null) {
            checkAnimator.cancel();
            checkAnimator = null;
        }
    }

    public void setProgress(float progress) {
        if (this.progress != progress) {
            this.progress = progress;
            invalidate();
        }
    }

    public float getProgress() {
        return progress;
    }

    public void setIconProgress(float progress) {}
    public float getIconProgress() { return 0f; }
    public void setDrawIconType(int type) {}
    public void setDrawRipple(boolean draw) {}
    public void setColors(int c1, int c2, int c3, int c4) {
        if (c1 != 0) checkedColor = c1;
        if (c2 != 0) uncheckedColor = c2;
    }
    public void setOnCheckedChangeListener(OnCheckedChangeListener l) { this.listener = l; }

    private void setChecked(boolean z, boolean animate) {
        if (this.checked != z) {
            this.checked = z;
            if (animate) {
                animateToState(z);
            } else {
                cancelCheckAnimator();
                setProgress(z ? 1f : 0f);
            }
            if (listener != null) {
                listener.onCheckedChanged(this, z);
            }
        }
    }

    public void setChecked(boolean checked) {
        this.checked = false;
        setChecked(checked, false);
        this.checked = checked;
    }

    public void setIcon(int icon) {}
    public boolean hasIcon() { return false; }
    public boolean isChecked() { return checked; }
    public void setOverrideColor(int color) {}
    public void setOverrideColorProgress(float p1, float p2, float p3) {}

    @Override
    public void onInitializeAccessibilityNodeInfo(AccessibilityNodeInfo info) {
        super.onInitializeAccessibilityNodeInfo(info);
        info.setClassName("android.widget.Switch");
        info.setCheckable(true);
        info.setChecked(checked);
    }

    @Override
    public boolean isPressed() { return super.isPressed(); }
}
