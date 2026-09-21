package com.chat.uikit.view;

import android.content.Context;
import android.util.AttributeSet;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.widget.AppCompatImageView;

import com.chat.uikit.R;

public class ChatInputPanel extends FrameLayout {
    public ChatInputPanel(@NonNull Context context) {
        super(context);
        init(context);
    }

    public ChatInputPanel(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init(context);
    }

    public ChatInputPanel(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init(context);
    }

    private void init(Context context) {
        LayoutInflater.from(context).inflate(R.layout.chat_input_layout, this, true);
        // 隐藏有问题的按钮（Markdown/A按钮 和 阅后即焚/火花按钮），防止点击闪退
        // 这些功能来自 SDK 但当前项目未完整实现
        post(() -> hideProblemButtons());
        // 监听布局变化，防止 SDK 代码重新显示这些按钮
        addOnLayoutChangeListener((v, left, top, right, bottom, oldLeft, oldTop, oldRight, oldBottom) -> {
            hideProblemButtons();
        });
    }

    private void hideProblemButtons() {
        View flameIV = findViewById(R.id.flameIV);
        if (flameIV != null && flameIV.getVisibility() != GONE) {
            flameIV.setVisibility(GONE);
            flameIV.setOnClickListener(null);
            flameIV.setClickable(false);
        }
        View markdownIv = findViewById(R.id.markdownIv);
        if (markdownIv != null && markdownIv.getVisibility() != GONE) {
            markdownIv.setVisibility(GONE);
            markdownIv.setOnClickListener(null);
            markdownIv.setClickable(false);
        }
    }
}
