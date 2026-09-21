package io.livekit.android.renderer;

import android.content.Context;
import android.util.AttributeSet;
import android.view.SurfaceView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

public class SurfaceViewRenderer extends SurfaceView {
    public SurfaceViewRenderer(@NonNull Context context) {
        super(context);
    }

    public SurfaceViewRenderer(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
    }

    public SurfaceViewRenderer(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }
}