package com.chat.base.glide;

import android.content.Context;

import com.bumptech.glide.Glide;
import com.bumptech.glide.GlideBuilder;
import com.bumptech.glide.Registry;
import com.bumptech.glide.load.engine.cache.LruResourceCache;
import com.bumptech.glide.load.engine.cache.DiskLruCacheFactory;
import com.bumptech.glide.load.model.GlideUrl;
import com.bumptech.glide.module.AppGlideModule;

import java.io.File;
import java.io.InputStream;

public class WKGlideModule extends AppGlideModule {

    @Override
    public void registerComponents(Context context, Glide glide, Registry registry) {
        registry.replace(GlideUrl.class, InputStream.class,
                new OkHttpUrlLoader.Factory(UnsafeOkHttpClient.getUnsafeOkHttpClient()));
    }

    @Override
    public void applyOptions(Context context, GlideBuilder builder) {
        long maxMemory = Runtime.getRuntime().maxMemory();
        int memoryCacheSize = (int) (maxMemory / 8);
        builder.setMemoryCache(new LruResourceCache(memoryCacheSize));

        builder.setDiskCache(new DiskLruCacheFactory(
                new DiskLruCacheFactory.CacheDirectoryGetter() {
                    @Override
                    public File getCacheDirectory() {
                        return new File(context.getCacheDir(), "glide_img");
                    }
                }, 512 * 1024 * 1024));
    }

    @Override
    public boolean isManifestParsingEnabled() {
        return false;
    }
}
