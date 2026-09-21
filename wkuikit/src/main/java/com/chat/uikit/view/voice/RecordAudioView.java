package com.chat.uikit.view.voice;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.Rect;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.View;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;

import com.chat.base.utils.WKToastUtils;

public class RecordAudioView extends FrameLayout {

    public interface IRecordAudioListener {
        boolean onRecordPrepare();
        String onRecordStart();
        boolean onRecordStop();
        boolean onRecordCancel();
        void onSlideTop();
        void onFingerPress();
    }

    private IRecordAudioListener mListener;
    private boolean isRecording = false;
    private boolean isCanceled = false;
    private boolean hasStopped = false; // 防止重复调用stop/cancel
    private Runnable delayedRecordRunnable;
    private static final int CANCEL_DISTANCE = 100; // 滑动取消的距离（dp）
    private float startY = 0;
    private Rect viewRect = new Rect();

    public RecordAudioView(@NonNull Context context) {
        super(context);
        init(context);
    }

    public RecordAudioView(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init(context);
    }

    public RecordAudioView(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init(context);
    }

    private void init(Context context) {
        setClickable(true);
        setFocusable(true);
    }

    public void setRecordAudioListener(IRecordAudioListener listener) {
        this.mListener = listener;
    }

    public void invokeStop() {
        if (hasStopped) return;
        hasStopped = true;
        if (mListener != null) {
            mListener.onRecordStop();
        }
        isRecording = false;
        isCanceled = false;
        removeDelayedRecordRunnable();
    }

    private void removeDelayedRecordRunnable() {
        if (delayedRecordRunnable != null) {
            removeCallbacks(delayedRecordRunnable);
            delayedRecordRunnable = null;
        }
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        if (mListener == null) {
            return super.onTouchEvent(event);
        }

        switch (event.getAction()) {
            case MotionEvent.ACTION_DOWN:
                // 检查录音权限
                if (ContextCompat.checkSelfPermission(getContext(), Manifest.permission.RECORD_AUDIO)
                        != PackageManager.PERMISSION_GRANTED) {
                    WKToastUtils.getInstance().showToastNormal("请先授予录音权限");
                    return false;
                }

                startY = event.getRawY();
                isCanceled = false;
                hasStopped = false;
                removeDelayedRecordRunnable();

                if (mListener.onRecordPrepare()) {
                    mListener.onFingerPress();
                    // 延迟一点开始录制，避免点击就开始
                    delayedRecordRunnable = new Runnable() {
                        @Override
                        public void run() {
                            if (!isCanceled && !hasStopped) {
                                String filePath = mListener.onRecordStart();
                                if (filePath != null) {
                                    isRecording = true;
                                }
                            }
                            delayedRecordRunnable = null;
                        }
                    };
                    postDelayed(delayedRecordRunnable, 300);
                }
                setPressed(true);
                return true;

            case MotionEvent.ACTION_MOVE:
                float currentY = event.getRawY();
                float distanceY = startY - currentY; // 向上滑动为正

                // 获取取消区域位置
                getGlobalVisibleRect(viewRect);
                float cancelThreshold = dpToPx(CANCEL_DISTANCE);

                if (distanceY > cancelThreshold) {
                    if (!isCanceled) {
                        isCanceled = true;
                        mListener.onSlideTop();
                    }
                } else {
                    if (isCanceled && isRecording) {
                        isCanceled = false;
                        mListener.onFingerPress();
                    }
                }
                return true;

            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_CANCEL:
                setPressed(false);
                removeDelayedRecordRunnable();

                if (!hasStopped) {
                    hasStopped = true;
                    if (isCanceled) {
                        mListener.onRecordCancel();
                    } else {
                        mListener.onRecordStop();
                    }
                }

                isRecording = false;
                isCanceled = false;
                return true;
        }

        return super.onTouchEvent(event);
    }

    private int dpToPx(int dp) {
        float density = getResources().getDisplayMetrics().density;
        return (int) (dp * density + 0.5f);
    }
}
