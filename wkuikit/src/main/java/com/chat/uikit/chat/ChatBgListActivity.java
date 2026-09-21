package com.chat.uikit.chat;

import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.GridLayoutManager;

import com.chad.library.adapter.base.BaseQuickAdapter;
import com.chad.library.adapter.base.viewholder.BaseViewHolder;
import com.chat.base.base.WKBaseActivity;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActChatBgListLayoutBinding;

import java.util.ArrayList;
import java.util.List;

public class ChatBgListActivity extends WKBaseActivity<ActChatBgListLayoutBinding> {

    private String channelId;
    private int channelType;
    private BgAdapter adapter;
    private int selectedPosition = -1;

    private static final int[] BG_COLORS = {
            0xFFFFFFFF, 0xFFF5F5F5, 0xFFE8F5E9, 0xFFE3F2FD,
            0xFFFCE4EC, 0xFFFFF3E0, 0xFFF3E5F5, 0xFFE0F7FA,
            0xFFEFEBE9, 0xFFECEFF1, 0xFFFFFDE7, 0xFFF1F8E9
    };

    public static void start(Context context, String channelId, int channelType) {
        Intent intent = new Intent(context, ChatBgListActivity.class);
        intent.putExtra("channel_id", channelId);
        intent.putExtra("channel_type", channelType);
        context.startActivity(intent);
    }

    @Override
    protected ActChatBgListLayoutBinding getViewBinding() {
        return ActChatBgListLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.chat_background);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        channelId = getIntent().getStringExtra("channel_id");
        channelType = getIntent().getIntExtra("channel_type", 1);

        adapter = new BgAdapter();
        wkVBinding.bgRecyclerView.setLayoutManager(new GridLayoutManager(this, 2));
        wkVBinding.bgRecyclerView.setAdapter(adapter);

        List<Integer> colors = new ArrayList<>();
        for (int color : BG_COLORS) {
            colors.add(color);
        }
        adapter.setList(colors);
    }

    @Override
    protected void initListener() {
        adapter.setOnItemClickListener((a, view, position) -> {
            selectedPosition = position;
            adapter.notifyDataSetChanged();
            PreviewChatBgActivity.start(this, channelId, channelType, BG_COLORS[position]);
        });
    }

    private static class BgAdapter extends BaseQuickAdapter<Integer, BaseViewHolder> {
        public BgAdapter() {
            super(R.layout.item_chat_bg_layout);
        }

        @Override
        protected void convert(@NonNull BaseViewHolder helper, Integer item) {
            ImageView bgIv = helper.getView(R.id.bgIv);
            bgIv.setBackgroundColor(item);
        }
    }
}
