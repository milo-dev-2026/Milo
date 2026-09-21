package com.chat.uikit.sticker;

import android.widget.TextView;

import com.bumptech.glide.Glide;
import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityStickerDetailBinding;

public class StickerDetailActivity extends WKBaseActivity<ActivityStickerDetailBinding> {

    public static final String KEY_STICKER_ID = "sticker_id";
    public static final String KEY_STICKER_URL = "sticker_url";
    public static final String KEY_STICKER_NAME = "sticker_name";
    public static final String KEY_CATEGORY_ID = "category_id";

    private String stickerId;
    private String stickerUrl;
    private String stickerName;
    private String categoryId;

    @Override
    protected ActivityStickerDetailBinding getViewBinding() {
        return ActivityStickerDetailBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.sticker_detail);
    }

    @Override
    protected void initPresenter() {
        if (getIntent() != null) {
            stickerId = getIntent().getStringExtra(KEY_STICKER_ID);
            stickerUrl = getIntent().getStringExtra(KEY_STICKER_URL);
            stickerName = getIntent().getStringExtra(KEY_STICKER_NAME);
            categoryId = getIntent().getStringExtra(KEY_CATEGORY_ID);
        }
    }

    @Override
    protected void initView() {
        if (stickerName != null) {
            wkVBinding.stickerNameTv.setText(stickerName);
        }
        if (stickerUrl != null && !stickerUrl.isEmpty()) {
            Glide.with(this).load(stickerUrl).into(wkVBinding.stickerIv);
            int type = 0;
            if (stickerUrl.endsWith(".gif")) {
                type = 1;
            }
            wkVBinding.stickerInfoTv.setText(getString(R.string.sticker_info_format,
                    stickerUrl.endsWith(".gif") ? "GIF" : "图片",
                    120, 120));
        } else {
            wkVBinding.stickerIv.setVisibility(android.view.View.INVISIBLE);
            wkVBinding.stickerInfoTv.setText(getString(R.string.sticker_info_format, "图片", 120, 120));
        }
    }

    @Override
    protected void initListener() {
        SingleClickUtil.onSingleClick(wkVBinding.sendBtn, v -> {
            WKToastUtils.getInstance().showToastNormal(getString(R.string.sticker_sent));
            finish();
        });

        SingleClickUtil.onSingleClick(wkVBinding.addBtn, v -> {
            if (stickerId == null || stickerId.isEmpty()) {
                stickerId = "sticker_" + System.currentTimeMillis();
            }
            StickerEntity sticker = new StickerEntity();
            sticker.stickerID = stickerId;
            sticker.categoryID = categoryId != null ? categoryId : "custom";
            sticker.url = stickerUrl;
            sticker.name = stickerName;
            sticker.type = 2;
            sticker.isCustom = true;

            boolean success = StickerService.getInstance().addSticker(sticker);
            if (success) {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.sticker_added));
            } else {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.sticker_already_added));
            }
        });
    }
}
