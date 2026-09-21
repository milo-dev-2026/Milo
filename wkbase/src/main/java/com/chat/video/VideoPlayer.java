package com.chat.video;

import android.content.Context;
import android.util.AttributeSet;
import android.view.GestureDetector;
import android.view.MotionEvent;
import android.view.View;
import android.widget.ImageView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.chat.base.R;
import com.shuyu.gsyvideoplayer.video.StandardGSYVideoPlayer;
import com.shuyu.gsyvideoplayer.video.base.GSYVideoControlView;

public class VideoPlayer extends StandardGSYVideoPlayer {
    private ILongClick iLongClick;

    public interface ILongClick {
        void onLongClick();
    }

    public VideoPlayer(@NonNull Context context, Boolean fullScreen) {
        super(context, fullScreen);
    }

    @Override
    public int getLayoutId() {
        return R.layout.video_layout_normal;
    }

    @Override
    public void init(@NonNull Context context) {
        post(() -> {
            gestureDetector = new GestureDetector(context.getApplicationContext(), new GestureDetector.SimpleOnGestureListener() {
                @Override
                public boolean onDoubleTap(MotionEvent e) {
                    VideoPlayer.this.touchDoubleUp(e);
                    return super.onDoubleTap(e);
                }

                @Override
                public void onLongPress(MotionEvent e) {
                    super.onLongPress(e);
                    if (iLongClick != null) {
                        iLongClick.onLongClick();
                    }
                }

                @Override
                public boolean onSingleTapConfirmed(MotionEvent e) {
                    if (!mChangePosition && !mChangeVolume && !mBrightness) {
                        VideoPlayer.this.onClickUiToggle(e);
                    }
                    return super.onSingleTapConfirmed(e);
                }
            });
        });
        super.init(context);
    }

    public void setLongClick(ILongClick longClick) {
        this.iLongClick = longClick;
    }

    @Override
    protected void updateStartImage() {
        View view = mStartButton;
        if (view instanceof ImageView) {
            ImageView imageView = (ImageView) view;
            if (mCurrentState == GSYVideoControlView.CURRENT_STATE_PLAYING) {
                imageView.setImageResource(R.drawable.video_click_pause_selector);
            } else {
                imageView.setImageResource(R.drawable.video_click_play_selector);
            }
        }
    }

    public VideoPlayer(@NonNull Context context) {
        super(context);
    }

    public VideoPlayer(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
    }
}
