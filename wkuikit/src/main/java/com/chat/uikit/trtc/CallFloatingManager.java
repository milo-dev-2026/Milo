package com.chat.uikit.trtc;

import android.content.Context;
import android.graphics.PixelFormat;
import android.os.Build;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.widget.TextView;

import com.chat.uikit.R;

/**
 * 通话悬浮窗管理（单例）
 */
public class CallFloatingManager {

    private static CallFloatingManager instance;
    private WindowManager windowManager;
    private View floatingView;
    private WindowManager.LayoutParams params;
    private boolean isShowing = false;
    private FloatingClickListener listener;
    private Context appContext;

    private int screenWidth;
    private float downX, downY;
    private float moveX, moveY;
    private boolean isMoved = false;

    public interface FloatingClickListener {
        void onFloatingClick();
    }

    public static CallFloatingManager getInstance() {
        if (instance == null) {
            synchronized (CallFloatingManager.class) {
                if (instance == null) {
                    instance = new CallFloatingManager();
                }
            }
        }
        return instance;
    }

    private CallFloatingManager() {
    }

    public Context getAppContext() {
        return appContext;
    }

    public void show(Context context, String name, String status, FloatingClickListener clickListener) {
        if (isShowing) return;
        Context appContext = context.getApplicationContext();
        this.appContext = appContext;
        windowManager = (WindowManager) appContext.getSystemService(Context.WINDOW_SERVICE);
        screenWidth = windowManager.getDefaultDisplay().getWidth();
        listener = clickListener;

        floatingView = LayoutInflater.from(appContext).inflate(R.layout.floating_call_layout, null);
        TextView nameTv = floatingView.findViewById(R.id.floatingNameTv);
        TextView timeTv = floatingView.findViewById(R.id.floatingTimeTv);
        nameTv.setText(name);
        timeTv.setText(status);

        params = new WindowManager.LayoutParams();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            params.type = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY;
        } else {
            params.type = WindowManager.LayoutParams.TYPE_PHONE;
        }
        params.format = PixelFormat.TRANSLUCENT;
        params.flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                | WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
                | WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN;
        params.gravity = Gravity.START | Gravity.TOP;
        params.width = WindowManager.LayoutParams.WRAP_CONTENT;
        params.height = WindowManager.LayoutParams.WRAP_CONTENT;
        params.x = (int) (screenWidth * 0.75f);
        params.y = (int) (screenWidth * 0.3f);

        floatingView.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(View v, MotionEvent event) {
                switch (event.getAction()) {
                    case MotionEvent.ACTION_DOWN:
                        downX = event.getRawX();
                        downY = event.getRawY();
                        moveX = event.getRawX();
                        moveY = event.getRawY();
                        isMoved = false;
                        return true;
                    case MotionEvent.ACTION_MOVE:
                        float dx = event.getRawX() - moveX;
                        float dy = event.getRawY() - moveY;
                        if (Math.abs(dx) > 3 || Math.abs(dy) > 3) {
                            isMoved = true;
                        }
                        params.x += dx;
                        params.y += dy;
                        windowManager.updateViewLayout(floatingView, params);
                        moveX = event.getRawX();
                        moveY = event.getRawY();
                        return true;
                    case MotionEvent.ACTION_UP:
                        if (!isMoved && listener != null) {
                            listener.onFloatingClick();
                        } else {
                            // 吸附到最近的边缘
                            int viewWidth = floatingView.getWidth();
                            int centerX = params.x + viewWidth / 2;
                            if (centerX < screenWidth / 2) {
                                params.x = 0;
                            } else {
                                params.x = screenWidth - viewWidth;
                            }
                            windowManager.updateViewLayout(floatingView, params);
                        }
                        return true;
                }
                return false;
            }
        });

        try {
            windowManager.addView(floatingView, params);
            isShowing = true;
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void updateTime(String time) {
        if (floatingView != null && isShowing) {
            TextView timeTv = floatingView.findViewById(R.id.floatingTimeTv);
            if (timeTv != null) {
                timeTv.post(() -> timeTv.setText(time));
            }
        }
    }

    public void updateStatus(String status) {
        if (floatingView != null && isShowing) {
            TextView timeTv = floatingView.findViewById(R.id.floatingTimeTv);
            if (timeTv != null) {
                timeTv.post(() -> timeTv.setText(status));
            }
        }
    }

    public void hide() {
        if (!isShowing || windowManager == null || floatingView == null) return;
        try {
            windowManager.removeView(floatingView);
        } catch (Exception e) {
            e.printStackTrace();
        }
        isShowing = false;
        floatingView = null;
        listener = null;
    }

    public boolean isShowing() {
        return isShowing;
    }
}
