package com.chat.uikit.trtc;

import android.content.Context;
import android.content.Intent;
import android.graphics.PixelFormat;
import android.os.Build;
import android.provider.Settings;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.TextView;

import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;

public class FloatCallWindow {

    private static FloatCallWindow instance;
    private WindowManager windowManager;
    private View floatView;
    private Context context;
    private boolean isShowing = false;
    private long startTime = 0;
    private Runnable timerRunnable;
    private java.util.concurrent.TimeUnit timeUnit = java.util.concurrent.TimeUnit.MILLISECONDS;

    private FloatCallWindow(Context context) {
        this.context = context.getApplicationContext();
        windowManager = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
    }

    public static FloatCallWindow getInstance(Context context) {
        if (instance == null) {
            synchronized (FloatCallWindow.class) {
                if (instance == null) {
                    instance = new FloatCallWindow(context);
                }
            }
        }
        return instance;
    }

    public boolean checkOverlayPermission(Context activityContext) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(context)) {
            Intent intent = new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    android.net.Uri.parse("package:" + context.getPackageName()));
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            activityContext.startActivity(intent);
            WKToastUtils.getInstance().showToastNormal("请允许悬浮窗权限");
            return false;
        }
        return true;
    }

    public void show(String callerName, boolean isVideoCall) {
        if (isShowing) return;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(context)) {
            WKToastUtils.getInstance().showToastNormal("请允许悬浮窗权限");
            return;
        }

        if (floatView == null) {
            floatView = LayoutInflater.from(context).inflate(R.layout.layout_float_call_window, null);
        }

        int layoutType = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O ?
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY :
                WindowManager.LayoutParams.TYPE_PHONE;

        WindowManager.LayoutParams params = new WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                layoutType,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                PixelFormat.TRANSLUCENT
        );
        params.gravity = Gravity.TOP | Gravity.START;
        params.x = 0;
        params.y = 200;

        TextView timeTv = floatView.findViewById(R.id.timeTv);
        if (timeTv != null) {
            timeTv.setText("00:00");
        }

        setupDrag(floatView, params);

        floatView.setOnClickListener(v -> {
            hide();
            Intent intent = new Intent(context, TRTCCallActivity.class);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
            context.startActivity(intent);
        });

        try {
            windowManager.addView(floatView, params);
            isShowing = true;
            startTime = System.currentTimeMillis();
            startTimer(timeTv);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void setupDrag(View view, WindowManager.LayoutParams params) {
        view.setOnTouchListener(new View.OnTouchListener() {
            int initialX, initialY;
            float initialTouchX, initialTouchY;

            @Override
            public boolean onTouch(View v, android.view.MotionEvent event) {
                switch (event.getAction()) {
                    case MotionEvent.ACTION_DOWN:
                        initialX = params.x;
                        initialY = params.y;
                        initialTouchX = event.getRawX();
                        initialTouchY = event.getRawY();
                        return true;
                    case MotionEvent.ACTION_MOVE:
                        params.x = initialX + (int) (event.getRawX() - initialTouchX);
                        params.y = initialY + (int) (event.getRawY() - initialTouchY);
                        if (isShowing) {
                            windowManager.updateViewLayout(floatView, params);
                        }
                        return true;
                }
                return false;
            }
        });
    }

    private void startTimer(TextView timeTv) {
        if (timerRunnable == null) {
            timerRunnable = new Runnable() {
                @Override
                public void run() {
                    if (isShowing && timeTv != null) {
                        long elapsed = System.currentTimeMillis() - startTime;
                        long minutes = elapsed / 60000;
                        long seconds = (elapsed % 60000) / 1000;
                        timeTv.setText(String.format("%02d:%02d", minutes, seconds));
                        timeTv.postDelayed(this, 1000);
                    }
                }
            };
            timeTv.post(timerRunnable);
        }
    }

    public void hide() {
        if (!isShowing) return;
        if (floatView != null) {
            try {
                windowManager.removeView(floatView);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        isShowing = false;
        if (timerRunnable != null && floatView != null) {
            floatView.removeCallbacks(timerRunnable);
            timerRunnable = null;
        }
    }

    public boolean isShowing() {
        return isShowing;
    }
}
