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
import com.chat.uikit.databinding.ActAddCustomStickerLayoutBinding;

public class AddCustomStickerActivity extends WKBaseActivity<ActAddCustomStickerLayoutBinding> {

    private static final int REQUEST_PICK_IMAGE = 1001;
    private String selectedImagePath = "";

    @Override
    protected ActAddCustomStickerLayoutBinding getViewBinding() {
        return ActAddCustomStickerLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText("添加自定义表情");
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
    }

    @Override
    protected void initListener() {
        SingleClickUtil.onSingleClick(wkVBinding.selectImgLayout, v -> {
            Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
            intent.addCategory(Intent.CATEGORY_OPENABLE);
            intent.setType("image/*");
            startActivityForResult(intent, REQUEST_PICK_IMAGE);
        });

        SingleClickUtil.onSingleClick(wkVBinding.addButton, v -> {
            if (TextUtils.isEmpty(selectedImagePath)) {
                WKToastUtils.getInstance().showToastNormal("请先选择图片");
                return;
            }
            String name = wkVBinding.nameEt.getText().toString().trim();
            if (TextUtils.isEmpty(name)) {
                WKToastUtils.getInstance().showToastNormal("请输入表情名称");
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

            StickerService.getInstance().addSticker(sticker);
            WKToastUtils.getInstance().showToastNormal("添加成功");
            finish();
        });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @androidx.annotation.Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_PICK_IMAGE && resultCode == Activity.RESULT_OK && data != null) {
            Uri uri = data.getData();
            if (uri != null) {
                selectedImagePath = uri.toString();
                Glide.with(this).load(uri).into(wkVBinding.previewIv);
                wkVBinding.previewIv.setVisibility(View.VISIBLE);
            }
        }
    }
}
