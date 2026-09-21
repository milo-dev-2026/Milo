package io.livekit.android.renderer;

import android.content.Context;
import android.util.AttributeSet;
import android.view.TextureView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

public class TextureViewRenderer extends TextureView {
    public TextureViewRenderer(@NonNull Context context) {
        super(context);
    }

    public TextureViewRenderer(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
    }

    public TextureViewRenderer(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }
}