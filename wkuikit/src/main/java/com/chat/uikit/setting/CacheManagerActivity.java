package com.chat.uikit.setting;

import android.os.AsyncTask;
import android.os.Handler;
import android.os.Looper;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.DataCleanManager;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityCacheManagerBinding;

import java.io.File;

public class CacheManagerActivity extends WKBaseActivity<ActivityCacheManagerBinding> {

    private File cacheDir;
    private File extCacheDir;

    @Override
    protected ActivityCacheManagerBinding getViewBinding() {
        return ActivityCacheManagerBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.cache_management);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        cacheDir = getCacheDir();
        extCacheDir = getExternalCacheDir();
        loadCacheSizes();
    }

    private void loadCacheSizes() {
        AsyncTask.execute(() -> {
            String totalSize = DataCleanManager.getTotalCacheSize(this);
            String imageSize = getCategorySize("image");
            String videoSize = getCategorySize("video");
            String voiceSize = getCategorySize("voice");
            String fileSize = getCategorySize("file");
            String otherSize = getCategorySize("other");

            runOnUiThread(() -> {
                wkVBinding.totalCacheSizeTv.setText(totalSize);
                wkVBinding.imageCacheSizeTv.setText(imageSize);
                wkVBinding.videoCacheSizeTv.setText(videoSize);
                wkVBinding.voiceCacheSizeTv.setText(voiceSize);
                wkVBinding.fileCacheSizeTv.setText(fileSize);
                wkVBinding.otherCacheSizeTv.setText(otherSize);
            });
        });
    }

    private String getCategorySize(String category) {
        long size = 0;
        File[] dirs = {cacheDir, extCacheDir};
        for (File dir : dirs) {
            if (dir == null) continue;
            File catDir = new File(dir, category);
            if (catDir.exists()) {
                size += DataCleanManager.getFolderSize(catDir);
            }
        }
        if (size == 0) {
            File[] files = cacheDir != null ? cacheDir.listFiles() : null;
            if (files != null) {
                for (File f : files) {
                    if (!f.getName().equals("image") && !f.getName().equals("video")
                            && !f.getName().equals("voice") && !f.getName().equals("file")) {
                        size += DataCleanManager.getFolderSize(f);
                    }
                }
            }
        }
        return DataCleanManager.getFormatSize(size);
    }

    private void clearCategory(String category) {
        File[] dirs = {cacheDir, extCacheDir};
        for (File dir : dirs) {
            if (dir == null) continue;
            File catDir = new File(dir, category);
            if (catDir.exists()) {
                deleteDir(catDir);
            }
        }
    }

    private void deleteDir(File dir) {
        if (dir != null && dir.isDirectory()) {
            File[] children = dir.listFiles();
            if (children != null) {
                for (File child : children) {
                    deleteDir(child);
                }
            }
        }
        if (dir != null) {
            dir.delete();
        }
    }

    @Override
    protected void initListener() {
        SingleClickUtil.onSingleClick(wkVBinding.imageCacheLayout, v -> {
            clearCategory("image");
            WKToastUtils.getInstance().showToastNormal(getString(R.string.cache_cleared));
            loadCacheSizes();
        });

        SingleClickUtil.onSingleClick(wkVBinding.videoCacheLayout, v -> {
            clearCategory("video");
            WKToastUtils.getInstance().showToastNormal(getString(R.string.cache_cleared));
            loadCacheSizes();
        });

        SingleClickUtil.onSingleClick(wkVBinding.voiceCacheLayout, v -> {
            clearCategory("voice");
            WKToastUtils.getInstance().showToastNormal(getString(R.string.cache_cleared));
            loadCacheSizes();
        });

        SingleClickUtil.onSingleClick(wkVBinding.fileCacheLayout, v -> {
            clearCategory("file");
            WKToastUtils.getInstance().showToastNormal(getString(R.string.cache_cleared));
            loadCacheSizes();
        });

        SingleClickUtil.onSingleClick(wkVBinding.otherCacheLayout, v -> {
            WKToastUtils.getInstance().showToastNormal(getString(R.string.cache_cleared));
            loadCacheSizes();
        });

        SingleClickUtil.onSingleClick(wkVBinding.clearAllBtn, v -> {
            WKDialogUtils.getInstance().showDialog(this, getString(R.string.clear_all_cache),
                    getString(R.string.clear_all_cache_tips), true, "", getString(R.string.confirm), 0, 0, index -> {
                        if (index == 1) {
                            DataCleanManager.clearAllCache(this);
                            WKToastUtils.getInstance().showToastNormal(getString(R.string.cache_cleared));
                            loadCacheSizes();
                        }
                    });
        });
    }
}
