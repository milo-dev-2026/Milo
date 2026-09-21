package com.chat.wkcircle.util;

import android.content.Context;
import android.util.AttributeSet;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

public class CustomWheelPickerRecyclerView extends FrameLayout {
    public CustomWheelPickerRecyclerView(@NonNull Context context) {
        super(context);
    }

    public CustomWheelPickerRecyclerView(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
    }

    public CustomWheelPickerRecyclerView(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }
}