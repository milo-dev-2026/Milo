package com.chat.uikit.favorite;

import android.Manifest;
import android.content.ContentValues;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;
import android.widget.Toast;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.target.CustomTarget;
import com.bumptech.glide.request.transition.Transition;
import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKApiConfig;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityDetailImgBinding;

import java.io.File;
import java.io.OutputStream;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.core.content.PermissionChecker;

public class DetailImgActivity extends WKBaseActivity<ActivityDetailImgBinding> {

    public static final String KEY_IMG_URL = "img_url";
    public static final String KEY_SENDER = "sender";
    public static final String KEY_TIME = "time";

    private static final int REQUEST_WRITE_STORAGE = 1001;

    private String imgUrl;
    private String resolvedImgUrl; // 转换后的可加载URL

    @Override
    protected ActivityDetailImgBinding getViewBinding() {
        return ActivityDetailImgBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.detail_image);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        Intent intent = getIntent();
        imgUrl = intent.getStringExtra(KEY_IMG_URL);
        String sender = intent.getStringExtra(KEY_SENDER);
        String time = intent.getStringExtra(KEY_TIME);

        // 解析URL为可加载的完整地址
        resolvedImgUrl = resolveImageUrl(imgUrl);

        String info = "";
        if (sender != null && !sender.isEmpty()) {
            info = sender;
        }
        if (time != null && !time.isEmpty()) {
            info = info.isEmpty() ? time : info + "  " + time;
        }
        wkVBinding.senderInfoTv.setText(info);

        if (!TextUtils.isEmpty(resolvedImgUrl)) {
            wkVBinding.loadingPb.setVisibility(View.VISIBLE);
            Glide.with(this)
                    .load(resolvedImgUrl)
                    .listener(new com.bumptech.glide.request.RequestListener<Drawable>() {
                        @Override
                        public boolean onLoadFailed(@Nullable com.bumptech.glide.load.engine.GlideException e,
                                                    Object model,
                                                    com.bumptech.glide.request.target.Target<Drawable> target,
                                                    boolean isFirstResource) {
                            wkVBinding.loadingPb.setVisibility(View.GONE);
                            WKToastUtils.getInstance().showToastNormal("图片加载失败");
                            return false;
                        }

                        @Override
                        public boolean onResourceReady(Drawable resource, Object model,
                                                       com.bumptech.glide.request.target.Target<Drawable> target,
                                                       com.bumptech.glide.load.DataSource dataSource,
                                                       boolean isFirstResource) {
                            wkVBinding.loadingPb.setVisibility(View.GONE);
                            return false;
                        }
                    })
                    .into(wkVBinding.photoView);
        } else {
            wkVBinding.loadingPb.setVisibility(View.GONE);
            WKToastUtils.getInstance().showToastNormal("图片地址无效");
        }
    }

    @Override
    protected void initListener() {
        SingleClickUtil.onSingleClick(wkVBinding.saveBtn, v -> {
            checkPermissionAndSave();
        });
    }

    /**
     * 将图片路径转换为可加载的完整URL
     */
    private String resolveImageUrl(String imagePath) {
        if (TextUtils.isEmpty(imagePath)) return "";

        String lower = imagePath.toLowerCase();
        // 已经是完整的网络URL
        if (lower.startsWith("http://") || lower.startsWith("https://")) {
            return imagePath;
        }

        // 本地绝对路径
        if (imagePath.startsWith("/") && !imagePath.startsWith("//") && imagePath.contains(".")) {
            File file = new File(imagePath);
            if (file.exists() && file.length() > 0) {
                return imagePath;
            }
        }

        // content URI
        if (imagePath.startsWith("content://")) {
            return imagePath;
        }

        // 相对路径：通过 getShowUrl 转换
        return WKApiConfig.getShowUrl(imagePath.replace("\\/", "/"));
    }

    private void checkPermissionAndSave() {
        if (TextUtils.isEmpty(resolvedImgUrl)) {
            WKToastUtils.getInstance().showToastNormal(getString(R.string.save_failed));
            return;
        }

        // Android 10+ 使用MediaStore，不需要存储权限
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveImageToGallery();
        } else {
            // Android 9及以下需要检查存储权限
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE)
                    == PermissionChecker.PERMISSION_GRANTED) {
                saveImageToGallery();
            } else {
                ActivityCompat.requestPermissions(this,
                        new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE},
                        REQUEST_WRITE_STORAGE);
            }
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_WRITE_STORAGE) {
            if (grantResults.length > 0 && grantResults[0] == PermissionChecker.PERMISSION_GRANTED) {
                saveImageToGallery();
            } else {
                WKToastUtils.getInstance().showToastNormal("需要存储权限才能保存图片");
            }
        }
    }

    private void saveImageToGallery() {
        if (TextUtils.isEmpty(resolvedImgUrl)) {
            WKToastUtils.getInstance().showToastNormal(getString(R.string.save_failed));
            return;
        }

        wkVBinding.loadingPb.setVisibility(View.VISIBLE);

        // 使用Glide获取Bitmap，支持网络URL、本地文件、content URI等所有类型
        Glide.with(this)
                .asBitmap()
                .load(resolvedImgUrl)
                .into(new CustomTarget<Bitmap>() {
                    @Override
                    public void onResourceReady(@NonNull Bitmap resource,
                                                @Nullable Transition<? super Bitmap> transition) {
                        boolean saved = saveBitmapToGallery(resource);
                        wkVBinding.loadingPb.setVisibility(View.GONE);
                        if (saved) {
                            WKToastUtils.getInstance().showToastNormal(getString(R.string.image_saved));
                        } else {
                            WKToastUtils.getInstance().showToastNormal(getString(R.string.save_failed));
                        }
                    }

                    @Override
                    public void onLoadCleared(@Nullable Drawable placeholder) {
                    }

                    @Override
                    public void onLoadFailed(@Nullable Drawable errorDrawable) {
                        wkVBinding.loadingPb.setVisibility(View.GONE);
                        WKToastUtils.getInstance().showToastNormal(getString(R.string.save_failed));
                    }
                });
    }

    private boolean saveBitmapToGallery(Bitmap bitmap) {
        if (bitmap == null) return false;
        try {
            String fileName = "IMG_" + System.currentTimeMillis() + ".jpg";
            OutputStream fos = null;

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10+ 使用 MediaStore 方式保存
                ContentValues values = new ContentValues();
                values.put(MediaStore.Images.Media.DISPLAY_NAME, fileName);
                values.put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg");
                values.put(MediaStore.Images.Media.RELATIVE_PATH,
                        Environment.DIRECTORY_PICTURES + "/xianleihuhu");
                values.put(MediaStore.Images.Media.IS_PENDING, 1);

                Uri contentUri = getContentResolver().insert(
                        MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
                if (contentUri == null) return false;

                fos = getContentResolver().openOutputStream(contentUri);
                if (fos == null) return false;

                bitmap.compress(Bitmap.CompressFormat.JPEG, 90, fos);
                fos.flush();
                fos.close();

                values.clear();
                values.put(MediaStore.Images.Media.IS_PENDING, 0);
                getContentResolver().update(contentUri, values, null, null);

                // 通知相册更新
                sendBroadcast(new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, contentUri));
                return true;
            } else {
                // Android 9 及以下使用文件方式
                File dir = new File(Environment.getExternalStoragePublicDirectory(
                        Environment.DIRECTORY_PICTURES), "xianleihuhu");
                if (!dir.exists()) {
                    dir.mkdirs();
                }
                File file = new File(dir, fileName);
                java.io.FileOutputStream out = new java.io.FileOutputStream(file);
                bitmap.compress(Bitmap.CompressFormat.JPEG, 90, out);
                out.flush();
                out.close();

                // 通知相册更新
                sendBroadcast(new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, Uri.fromFile(file)));
                return true;
            }
        } catch (Exception e) {
            android.util.Log.e("DetailImgActivity", "saveBitmapToGallery error: " + e.getMessage());
            return false;
        }
    }
}
