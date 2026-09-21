package com.chat.uikit.chat;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import com.chat.uikit.R;
import com.chat.uikit.databinding.ActPreviewChatBgLayoutBinding;

public class PreviewChatBgActivity extends AppCompatActivity {

    private String channelId;
    private int channelType;
    private int bgColor;

    public static void start(Context context, String channelId, int channelType, int bgColor) {
        Intent intent = new Intent(context, PreviewChatBgActivity.class);
        intent.putExtra("channel_id", channelId);
        intent.putExtra("channel_type", channelType);
        intent.putExtra("bg_color", bgColor);
        context.startActivity(intent);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        com.chat.uikit.databinding.ActPreviewChatBgLayoutBinding binding =
                ActPreviewChatBgLayoutBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        channelId = getIntent().getStringExtra("channel_id");
        channelType = getIntent().getIntExtra("channel_type", 1);
        bgColor = getIntent().getIntExtra("bg_color", 0xFFFFFFFF);

        binding.bgPreviewIv.setBackgroundColor(bgColor);

        binding.cancelBtn.setOnClickListener(v -> finish());
        binding.applyBtn.setOnClickListener(v -> {
            // TODO: Apply background to channel via server API
            // For now, save to SharedPreferences
            getSharedPreferences("chat_bg", MODE_PRIVATE)
                    .edit()
                    .putInt("bg_" + channelId, bgColor)
                    .apply();
            finish();
        });
    }
}
