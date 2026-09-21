package com.chat.video.camera;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.AnimatorSet;
import android.animation.ObjectAnimator;
import android.content.Context;
import android.util.AttributeSet;
import android.util.DisplayMetrics;
import android.view.View;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.chat.base.R;
import com.chat.video.camera.listener.CaptureListener;
import com.chat.video.camera.listener.ClickListener;
import com.chat.video.camera.listener.ReturnListener;
import com.chat.video.camera.listener.TypeListener;

public class CaptureLayout extends FrameLayout {
    private TypeButton btn_cancel;
    private CaptureButton btn_capture;
    private TypeButton btn_confirm;
    private ReturnButton btn_return;
    private int button_size;
    private CaptureListener captureLisenter;
    private int iconLeft;
    private int iconRight;
    private boolean isFirst;
    private ImageView iv_custom_left;
    private ImageView iv_custom_right;
    private int layout_height;
    private int layout_width;
    private ClickListener leftClickListener;
    private ReturnListener returnListener;
    private ClickListener rightClickListener;
    private TextView txt_tip;
    private TypeListener typeLisenter;

    public CaptureLayout(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        this.iconLeft = 0;
        this.iconRight = 0;
        this.isFirst = true;
        WindowManager windowManager = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
        DisplayMetrics displayMetrics = new DisplayMetrics();
        windowManager.getDefaultDisplay().getMetrics(displayMetrics);
        int orientation = getResources().getConfiguration().orientation;
        int screenWidth = displayMetrics.widthPixels;
        if (orientation == 1) {
            this.layout_width = screenWidth;
        } else {
            screenWidth /= 2;
            this.layout_width = screenWidth;
        }
        int buttonSize = (int) (screenWidth / 4.5f);
        this.button_size = buttonSize;
        this.layout_height = buttonSize + ((buttonSize / 5) * 2) + 100;
        initView();
        hideButtons();
    }

    private void hideButtons() {
        this.iv_custom_right.setVisibility(View.GONE);
        this.btn_cancel.setVisibility(View.GONE);
        this.btn_confirm.setVisibility(View.GONE);
    }

    private void initView() {
        setWillNotDraw(false);
        this.btn_capture = new CaptureButton(getContext(), this.button_size);
        this.btn_capture.setMinDuration(1000);
        FrameLayout.LayoutParams captureLp = new FrameLayout.LayoutParams(-1, -1);
        captureLp.gravity = 17;
        this.btn_capture.setLayoutParams(captureLp);
        this.btn_capture.setCaptureLisenter(new CaptureListener() {
            @Override
            public void a(long remainingTime) {
                if (CaptureLayout.this.captureLisenter != null) CaptureLayout.this.captureLisenter.a(remainingTime);
                CaptureLayout.this.fadeOutTip();
            }
            @Override
            public void b() {
                if (CaptureLayout.this.captureLisenter != null) CaptureLayout.this.captureLisenter.b();
            }
            @Override
            public void c(float zoom) {
                if (CaptureLayout.this.captureLisenter != null) CaptureLayout.this.captureLisenter.c(zoom);
            }
            @Override
            public void d() {
                if (CaptureLayout.this.captureLisenter != null) CaptureLayout.this.captureLisenter.d();
                CaptureLayout.this.fadeOutTip();
            }
            @Override
            public void e() {
                if (CaptureLayout.this.captureLisenter != null) CaptureLayout.this.captureLisenter.e();
            }
            @Override
            public void f(long recordedTime) {
                if (CaptureLayout.this.captureLisenter != null) CaptureLayout.this.captureLisenter.f(recordedTime);
                CaptureLayout.this.fadeOutTip();
                CaptureLayout.this.showConfirmCancel();
            }
        });
        this.btn_cancel = new TypeButton(getContext(), 1, this.button_size);
        FrameLayout.LayoutParams cancelLp = new FrameLayout.LayoutParams(-1, -1);
        cancelLp.gravity = 16;
        cancelLp.setMargins((this.layout_width / 4) - (this.button_size / 2), 0, 0, 0);
        this.btn_cancel.setLayoutParams(cancelLp);
        this.btn_cancel.setOnClickListener(v -> {
            if (CaptureLayout.this.typeLisenter != null) CaptureLayout.this.typeLisenter.cancel();
            CaptureLayout.this.fadeOutTip();
        });
        this.btn_confirm = new TypeButton(getContext(), 2, this.button_size);
        FrameLayout.LayoutParams confirmLp = new FrameLayout.LayoutParams(-1, -1);
        confirmLp.gravity = 21;
        confirmLp.setMargins(0, 0, (this.layout_width / 4) - (this.button_size / 2), 0);
        this.btn_confirm.setLayoutParams(confirmLp);
        this.btn_confirm.setOnClickListener(v -> {
            if (CaptureLayout.this.typeLisenter != null) CaptureLayout.this.typeLisenter.a();
            CaptureLayout.this.fadeOutTip();
        });
        this.btn_return = new ReturnButton(getContext(), (int) (this.button_size / 2.5f));
        FrameLayout.LayoutParams returnLp = new FrameLayout.LayoutParams(-2, -2);
        returnLp.gravity = 16;
        returnLp.setMargins(this.layout_width / 6, 0, 0, 0);
        this.btn_return.setLayoutParams(returnLp);
        this.btn_return.setOnClickListener(v -> {
            if (CaptureLayout.this.leftClickListener != null) CaptureLayout.this.leftClickListener.onClick();
        });
        this.iv_custom_left = new ImageView(getContext());
        int leftSize = this.button_size;
        FrameLayout.LayoutParams leftImgLp = new FrameLayout.LayoutParams((int) (leftSize / 2.5f), (int) (leftSize / 2.5f));
        leftImgLp.gravity = 16;
        leftImgLp.setMargins(this.layout_width / 6, 0, 0, 0);
        this.iv_custom_left.setLayoutParams(leftImgLp);
        this.iv_custom_left.setOnClickListener(v -> {
            if (CaptureLayout.this.leftClickListener != null) CaptureLayout.this.leftClickListener.onClick();
        });
        this.iv_custom_right = new ImageView(getContext());
        int rightSize = this.button_size;
        FrameLayout.LayoutParams rightImgLp = new FrameLayout.LayoutParams((int) (rightSize / 2.5f), (int) (rightSize / 2.5f));
        rightImgLp.gravity = 21;
        rightImgLp.setMargins(0, 0, this.layout_width / 6, 0);
        this.iv_custom_right.setLayoutParams(rightImgLp);
        this.iv_custom_right.setOnClickListener(v -> {
            if (CaptureLayout.this.rightClickListener != null) CaptureLayout.this.rightClickListener.onClick();
        });
        this.txt_tip = new TextView(getContext());
        FrameLayout.LayoutParams tipLp = new FrameLayout.LayoutParams(-1, -2);
        tipLp.gravity = 1;
        this.txt_tip.setText(getContext().getString(R.string.tap_photo_desc));
        this.txt_tip.setTextColor(0xFFFFFFFF);
        this.txt_tip.setGravity(17);
        this.txt_tip.setLayoutParams(tipLp);
        addView(this.btn_capture);
        addView(this.btn_cancel);
        addView(this.btn_confirm);
        addView(this.btn_return);
        addView(this.iv_custom_left);
        addView(this.iv_custom_right);
        addView(this.txt_tip);
    }

    public void resetState() {
        this.btn_capture.resetState();
        this.btn_cancel.setVisibility(View.GONE);
        this.btn_confirm.setVisibility(View.GONE);
        this.btn_capture.setVisibility(View.VISIBLE);
        if (this.iconLeft != 0) {
            this.iv_custom_left.setVisibility(View.VISIBLE);
        } else {
            this.btn_return.setVisibility(View.VISIBLE);
        }
        if (this.iconRight != 0) {
            this.iv_custom_right.setVisibility(View.VISIBLE);
        }
    }

    public void setIcon(int leftIcon, int rightIcon) {
        this.iconLeft = leftIcon;
        this.iconRight = rightIcon;
        if (leftIcon != 0) {
            this.iv_custom_left.setImageResource(leftIcon);
            this.iv_custom_left.setVisibility(View.VISIBLE);
            this.btn_return.setVisibility(View.GONE);
        } else {
            this.iv_custom_left.setVisibility(View.GONE);
            this.btn_return.setVisibility(View.VISIBLE);
        }
        if (rightIcon != 0) {
            this.iv_custom_right.setImageResource(rightIcon);
            this.iv_custom_right.setVisibility(View.VISIBLE);
        } else {
            this.iv_custom_right.setVisibility(View.GONE);
        }
    }

    public void showTip() {
        this.txt_tip.setVisibility(View.VISIBLE);
    }

    public void fadeOutTip() {
        if (this.isFirst) {
            ObjectAnimator anim = ObjectAnimator.ofFloat(this.txt_tip, "alpha", 1.0f, 0.0f);
            anim.setDuration(500L);
            anim.start();
            this.isFirst = false;
        }
    }

    public void showConfirmCancel() {
        if (this.iconLeft != 0) {
            this.iv_custom_left.setVisibility(View.GONE);
        } else {
            this.btn_return.setVisibility(View.GONE);
        }
        if (this.iconRight != 0) {
            this.iv_custom_right.setVisibility(View.GONE);
        }
        this.btn_capture.setVisibility(View.GONE);
        this.btn_cancel.setVisibility(View.VISIBLE);
        this.btn_confirm.setVisibility(View.VISIBLE);
        this.btn_cancel.setClickable(false);
        this.btn_confirm.setClickable(false);
        ObjectAnimator cancelAnim = ObjectAnimator.ofFloat(this.btn_cancel, "translationX", this.layout_width / 4f, 0.0f);
        ObjectAnimator confirmAnim = ObjectAnimator.ofFloat(this.btn_confirm, "translationX", -this.layout_width / 4f, 0.0f);
        AnimatorSet set = new AnimatorSet();
        set.playTogether(cancelAnim, confirmAnim);
        set.addListener(new AnimatorListenerAdapter() {
            @Override
            public void onAnimationEnd(Animator animation) {
                CaptureLayout.this.btn_cancel.setClickable(true);
                CaptureLayout.this.btn_confirm.setClickable(true);
            }
        });
        set.setDuration(200L);
        set.start();
    }

    @Override
    public void onMeasure(int widthSpec, int heightSpec) {
        super.onMeasure(widthSpec, heightSpec);
        setMeasuredDimension(this.layout_width, this.layout_height);
    }

    public void setButtonFeatures(int features) {
        this.btn_capture.setButtonFeatures(features);
    }

    public void setCaptureLisenter(CaptureListener listener) {
        this.captureLisenter = listener;
    }

    public void setDuration(int duration) {
        this.btn_capture.setDuration(duration);
    }

    public void setLeftClickListener(ClickListener listener) {
        this.leftClickListener = listener;
    }

    public void setReturnLisenter(ReturnListener listener) {
        this.returnListener = listener;
    }

    public void setRightClickListener(ClickListener listener) {
        this.rightClickListener = listener;
    }

    public void setTextWithAnimation(String text) {
        this.txt_tip.setText(text);
        ObjectAnimator anim = ObjectAnimator.ofFloat(this.txt_tip, "alpha", 0.0f, 1.0f, 1.0f, 0.0f);
        anim.setDuration(2500L);
        anim.start();
    }

    public void setTip(String text) {
        this.txt_tip.setText(text);
    }

    public void setTypeLisenter(TypeListener listener) {
        this.typeLisenter = listener;
    }

    public CaptureLayout(@NonNull Context context, @Nullable AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public CaptureLayout(@NonNull Context context) {
        this(context, null);
    }
}
