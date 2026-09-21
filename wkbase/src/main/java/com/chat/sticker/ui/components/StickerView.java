package com.chat.sticker.ui.components;

import android.content.Context;
import android.graphics.Bitmap;
import android.text.TextUtils;
import android.util.AttributeSet;
import android.widget.FrameLayout;
import android.widget.ImageView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;

import com.chat.base.R;
import com.chat.base.net.ud.WKDownloader;
import com.chat.base.net.ud.WKProgressManager;
import com.chat.base.utils.AndroidUtilities;
import com.chat.base.utils.LayoutHelper;
import com.chat.base.utils.SvgHelper;
import com.chat.base.utils.WKFileUtils;

import java.io.File;

import org.telegram.ui.Components.RLottieDrawable;
import org.telegram.ui.Components.RLottieImageView;

public class StickerView extends FrameLayout implements WKProgressManager.IProgress {
    private RLottieImageView lottieImageView;
    private boolean isLoopPlay;
    private boolean isPlay;
    private int size;
    private String tag;

    public StickerView(@NonNull Context context) {
        super(context);
        init(context);
    }

    public StickerView(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init(context);
    }

    private void init(Context context) {
        lottieImageView = new RLottieImageView(context);
        lottieImageView.setScaleType(ImageView.ScaleType.CENTER_CROP);
        addView(lottieImageView, LayoutHelper.createFrame(-2, -2, 17));
    }

    public void loadSticker(String url, String svg, int size, boolean loop, boolean play) {
        loadStickerInternal(url, svg, size, loop, play, true);
    }

    public synchronized void loadStickerInternal(final String url, String svg, final int size, final boolean loop, final boolean play, final boolean autoPlay) {
        lottieImageView.getLayoutParams().height = size;
        lottieImageView.getLayoutParams().width = size;
        this.isLoopPlay = loop;
        this.isPlay = autoPlay;
        this.size = size;

        if (!TextUtils.isEmpty(svg)) {
            try {
                if (svg.startsWith("<")) {
                    Bitmap bitmap = SvgHelper.getBitmapByPathOnly(
                        svg.replaceAll("<svg version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" viewBox=\"0 0 512 512\" xml:space=\"preserve\"><path fill-opacity=\"0.1\" d=\"", "")
                            .replaceAll(" /></svg>", ""),
                        ContextCompat.getColor(getContext(), R.color.sticker_placeholder),
                        512, 512, 512, 512
                    );
                    if (bitmap != null) {
                        lottieImageView.setImageBitmap(bitmap);
                    }
                }
            } catch (Throwable e) {
                e.printStackTrace();
            }
        }

        if (TextUtils.isEmpty(url)) return;

        lottieImageView.setTag(url);
        new Thread(() -> loadStickerFile(url, loop, size, autoPlay)).start();
    }

    private void loadStickerFile(String url, boolean loop, int size, boolean play) {
        String fileName = url.replaceAll("/", "_");
        File stickerDir = getContext().getExternalFilesDir("stickers");
        if (stickerDir == null) return;
        String dirPath = stickerDir.getAbsolutePath() + "/";
        File file = new File(dirPath + fileName);
        if (file.exists()) {
            playStickerFile(lottieImageView, loop, file, size, play);
            return;
        }
        File altFile = new File(dirPath + url.replaceAll("/", "_"));
        if (altFile.exists()) {
            playStickerFile(lottieImageView, loop, altFile, size, play);
        } else {
            this.tag = url;
            WKDownloader.Companion.getInstance().download(url, altFile.getAbsolutePath(), this);
        }
    }

    public void clearSticker() {
        this.tag = null;
        this.isPlay = false;
        if (lottieImageView != null) {
            lottieImageView.stopAnimation();
            lottieImageView.setImageDrawable(null);
            lottieImageView.setTag(null);
        }
    }

    public RLottieImageView getImageView() {
        return lottieImageView;
    }

    public void playOnce() {
        if (lottieImageView != null && lottieImageView.getAnimatedDrawable() != null) {
            lottieImageView.setAutoRepeat(false);
            lottieImageView.playAnimation();
            lottieImageView.getAnimatedDrawable().setOnFinishCallback(() ->
                lottieImageView.stopAnimation()
            , lottieImageView.getAnimatedDrawable().getFramesCount() - 1);
        }
    }

    private void playStickerFile(final RLottieImageView imageView, boolean loop, File file, int size, final boolean play) {
        String nameWithoutExt = file.getName().replace(".lim", "");
        File decompressed = new File(nameWithoutExt);
        if (!decompressed.exists()) {
            String result = WKFileUtils.getInstance().uncompressSticker(
                WKFileUtils.getInstance().file2byte(file), nameWithoutExt);
            if (!TextUtils.isEmpty(result)) {
                decompressed = new File(result);
            }
        }
        File finalFile = decompressed;
        Object tag = imageView.getTag();
        if (tag instanceof String) {
            String tagStr = (String) tag;
            if (!TextUtils.isEmpty(tagStr)) {
                String expectedPath = tagStr.replace(".lim", "").replaceAll("/", "_");
                if (!finalFile.getAbsolutePath().endsWith(expectedPath)) {
                    return;
                }
            }
        }
        final RLottieDrawable drawable = new RLottieDrawable(finalFile, size, size, false, false);
        AndroidUtilities.runOnUIThread(() -> {
            imageView.setAutoRepeat(loop);
            imageView.setAnimation(drawable);
            if (play) {
                imageView.playAnimation();
            }
        });
    }

    @Override
    public void onAttachedToWindow() {
        super.onAttachedToWindow();
        if (lottieImageView != null && isPlay && lottieImageView.getAnimatedDrawable() != null) {
            lottieImageView.playAnimation();
        }
    }

    @Override
    public void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        if (lottieImageView != null) {
            lottieImageView.stopAnimation();
        }
    }

    @Override
    public void onSuccess(@Nullable Object obj, @Nullable String path) {
        if (!TextUtils.isEmpty(path)) {
            playStickerFile(lottieImageView, isLoopPlay, new File(path), size, isPlay);
        }
    }

    @Override
    public void onFail(@Nullable Object obj, @Nullable String msg) {
    }

    @Override
    public void onProgress(@Nullable Object obj, int progress) {
    }
}
