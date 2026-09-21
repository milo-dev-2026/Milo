package com.chat.uikit.sticker;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import com.bumptech.glide.Glide;
import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityCustomStickerBinding;

public class CustomStickerActivity extends WKBaseActivity<ActivityCustomStickerBinding> {

    private static final int REQUEST_PICK_IMAGE = 1001;
    private String selectedImagePath = "";

    @Override
    protected ActivityCustomStickerBinding getViewBinding() {
        return ActivityCustomStickerBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.custom_sticker_title);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
    }

    @Override
    protected void initListener() {
        SingleClickUtil.onSingleClick(wkVBinding.selectImgBtn, v -> {
            Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
            intent.addCategory(Intent.CATEGORY_OPENABLE);
            intent.setType("image/*");
            startActivityForResult(intent, REQUEST_PICK_IMAGE);
        });

        SingleClickUtil.onSingleClick(wkVBinding.addButton, v -> {
            if (TextUtils.isEmpty(selectedImagePath)) {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.no_image_selected));
                return;
            }
            String name = wkVBinding.nameEt.getText().toString().trim();
            if (TextUtils.isEmpty(name)) {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.hint_sticker_name));
                return;
            }

            StickerEntity sticker = new StickerEntity();
            sticker.stickerID = "custom_" + System.currentTimeMillis();
            sticker.categoryID = "custom";
            sticker.url = selectedImagePath;
            sticker.name = name;
            sticker.sort = 0;
            sticker.type = 2;
            sticker.isCustom = true;

            boolean success = StickerService.getInstance().addSticker(sticker);
            if (success) {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.sticker_added));
                finish();
            } else {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.sticker_already_added));
            }
        });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_PICK_IMAGE && resultCode == Activity.RESULT_OK && data != null) {
            Uri uri = data.getData();
            if (uri != null) {
                selectedImagePath = uri.toString();
                Glide.with(this).load(uri).into(wkVBinding.previewIv);
                wkVBinding.previewIv.setVisibility(View.VISIBLE);
                wkVBinding.placeholderTv.setVisibility(View.GONE);
            }
        }
    }
}
