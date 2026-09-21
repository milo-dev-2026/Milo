package com.chat.base.utils;

import android.content.Context;
import android.media.MediaMetadataRetriever;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;

import com.arthenica.ffmpegkit.FFmpegKit;
import com.arthenica.ffmpegkit.FFmpegSession;
import com.arthenica.ffmpegkit.FFmpegSessionCompleteCallback;
import com.arthenica.ffmpegkit.ReturnCode;
import com.chat.base.WKBaseApplication;
import com.chat.base.utils.WKLogUtils;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * 使用FFmpeg将视频转码为HLS(m3u8 + ts分片)，实现秒发秒收。
 * <p>
 * 接收方拿到m3u8 URL后，播放器按需加载ts分片，边下边播，
 * 不需要等待完整视频下载完毕。
 */
public class HlsTranscodeUtil {

    private static final String TAG = "HlsTranscode";
    private static final String CACHE_FOLDER = "transcode_m3u8";
    private static final int HLS_SEGMENT_DURATION = 2;

    private static volatile HlsTranscodeUtil instance;
    private final ExecutorService executor = Executors.newSingleThreadExecutor();

    public static HlsTranscodeUtil getInstance() {
        if (instance == null) {
            synchronized (HlsTranscodeUtil.class) {
                if (instance == null) {
                    instance = new HlsTranscodeUtil();
                }
            }
        }
        return instance;
    }

    private HlsTranscodeUtil() {
    }

    public interface TranscodeCallback {
        void onStart();
        void onProgress(int percent);
        void onSuccess(File outputDir, String m3u8FileName);
        void onError(Exception e);
    }

    /**
     * 获取视频宽高和旋转
     */
    private int[] getVideoInfo(String videoPath) {
        int width = 0, height = 0, rotation = 0;
        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        try {
            retriever.setDataSource(videoPath);
            String w = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH);
            String h = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT);
            String r = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION);
            if (w != null) width = Integer.parseInt(w);
            if (h != null) height = Integer.parseInt(h);
            if (r != null) rotation = Integer.parseInt(r);
            if (rotation == 90 || rotation == 270) {
                int tmp = width;
                width = height;
                height = tmp;
            }
        } catch (Exception e) {
            WKLogUtils.e(TAG, "getVideoInfo error: " + e.getMessage());
        } finally {
            try { retriever.release(); } catch (Exception ignored) {}
        }
        return new int[]{width, height, rotation};
    }

    /**
     * 计算智能缩放滤镜
     */
    private String buildScaleFilter(int width, int height) {
        int maxWidth = 720;
        int targetWidth = Math.min(width, maxWidth);
        if (targetWidth % 2 != 0) targetWidth--;
        if (width > 0 && height > 0) {
            int targetHeight = (int) ((double) targetWidth * height / width);
            if (targetHeight % 2 != 0) targetHeight--;
            return "scale=" + targetWidth + ":" + targetHeight + ":flags=lanczos";
        }
        return "scale=720:-2:flags=lanczos";
    }

    /**
     * 创建输出目录
     */
    private File createOutputDir() {
        Context ctx = WKBaseApplication.getInstance().application;
        File cacheDir = ctx.getExternalCacheDir();
        if (cacheDir == null) cacheDir = ctx.getCacheDir();
        String dirName = CACHE_FOLDER + "/" + System.currentTimeMillis() + "_" +
                UUID.randomUUID().toString().replace("-", "").substring(0, 8);
        File outputDir = new File(cacheDir, dirName);
        if (!outputDir.exists()) outputDir.mkdirs();
        return outputDir;
    }

    /**
     * 转码视频为HLS格式
     *
     * @param videoPath 原始视频路径
     * @param callback  转码回调
     */
    public void transcodeToHls(String videoPath, TranscodeCallback callback) {
        if (TextUtils.isEmpty(videoPath)) {
            if (callback != null) callback.onError(new IllegalArgumentException("videoPath is empty"));
            return;
        }
        File videoFile = new File(videoPath);
        if (!videoFile.exists() || videoFile.length() <= 0) {
            if (callback != null) callback.onError(new IllegalArgumentException("video file not exists"));
            return;
        }

        executor.execute(() -> {
            Handler mainHandler = new Handler(Looper.getMainLooper());
            if (callback != null) mainHandler.post(callback::onStart);

            try {
                File outputDir = createOutputDir();
                String m3u8Name = "master.m3u8";
                String m3u8Path = new File(outputDir, m3u8Name).getAbsolutePath();
                String tsPattern = new File(outputDir, "segment_%03d.ts").getAbsolutePath();

                int[] info = getVideoInfo(videoPath);
                int width = info[0], height = info[1];
                String scaleFilter = buildScaleFilter(width, height);

                String[] cmd = new String[]{
                    "-i", videoPath,
                    "-c:v", "libx264",
                    "-preset", "veryfast",
                    "-crf", "23",
                    "-b:v", "2000k",
                    "-maxrate", "3000k",
                    "-bufsize", "4000k",
                    "-vf", scaleFilter,
                    "-c:a", "aac",
                    "-b:a", "128k",
                    "-ac", "2",
                    "-ar", "44100",
                    "-profile:v", "baseline",
                    "-level", "3.0",
                    "-pix_fmt", "yuv420p",
                    "-f", "hls",
                    "-hls_time", String.valueOf(HLS_SEGMENT_DURATION),
                    "-hls_list_size", "0",
                    "-hls_segment_filename", tsPattern,
                    "-hls_playlist_type", "vod",
                    "-movflags", "+faststart",
                    m3u8Path
                };

                StringBuilder cmdBuilder = new StringBuilder();
                for (String s : cmd) {
                    if (cmdBuilder.length() > 0) cmdBuilder.append(" ");
                    cmdBuilder.append(s);
                }
                WKLogUtils.d(TAG, "FFmpeg command: " + cmdBuilder.toString());

                FFmpegKit.executeAsync(cmdBuilder.toString(), new FFmpegSessionCompleteCallback() {
                    @Override
                    public void apply(FFmpegSession completedSession) {
                        ReturnCode rc = completedSession.getReturnCode();
                        WKLogUtils.d(TAG, "FFmpeg done: rc=" + rc.getValue() + " outputDir=" + outputDir.getAbsolutePath());

                        if (ReturnCode.isSuccess(rc)) {
                            File[] files = outputDir.listFiles();
                            if (files == null || files.length == 0) {
                                if (callback != null)
                                    mainHandler.post(() -> callback.onError(new RuntimeException("No output files generated")));
                                return;
                            }
                            if (callback != null)
                                mainHandler.post(() -> callback.onSuccess(outputDir, m3u8Name));
                        } else {
                            String log = completedSession.getLogsAsString();
                            WKLogUtils.e(TAG, "FFmpeg failed: " + log);
                            if (callback != null)
                                mainHandler.post(() -> callback.onError(new RuntimeException("Transcode failed: " + rc.getValue())));
                        }
                    }
                });

            } catch (Exception e) {
                WKLogUtils.e(TAG, "transcodeToHls error: " + e.getMessage());
                if (callback != null)
                    mainHandler.post(() -> callback.onError(e));
            }
        });
    }

    /**
     * 获取转码输出目录中的所有需要上传的文件
     */
    public static List<File> getHlsFiles(File outputDir) {
        List<File> files = new ArrayList<>();
        if (outputDir == null || !outputDir.isDirectory()) return files;
        File[] allFiles = outputDir.listFiles();
        if (allFiles == null) return files;
        for (File f : allFiles) {
            String name = f.getName().toLowerCase();
            if (name.endsWith(".m3u8") || name.endsWith(".ts") || name.endsWith(".key") || name.endsWith(".keyinfo")) {
                files.add(f);
            }
        }
        return files;
    }

    /**
     * 获取转码输出目录中的m3u8文件
     */
    public static File getM3u8File(File outputDir, String m3u8Name) {
        if (outputDir == null || m3u8Name == null) return null;
        File f = new File(outputDir, m3u8Name);
        return f.exists() ? f : null;
    }

    /**
     * 清理转码输出目录
     */
    public static void cleanupOutputDir(File outputDir) {
        if (outputDir == null || !outputDir.exists()) return;
        try {
            File[] files = outputDir.listFiles();
            if (files != null) {
                for (File f : files) f.delete();
            }
            outputDir.delete();
        } catch (Exception e) {
            WKLogUtils.e(TAG, "cleanup error: " + e.getMessage());
        }
    }
}
