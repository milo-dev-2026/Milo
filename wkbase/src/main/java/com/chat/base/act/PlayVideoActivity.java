package com.chat.base.act;

import android.Manifest;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.ImageView;

import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.core.view.ViewCompat;

import com.chat.base.R;
import com.chat.base.WKBaseApplication;
import com.chat.base.endpoint.EndpointManager;
import com.chat.base.endpoint.EndpointSID;
import com.chat.base.endpoint.entity.ChatChooseContacts;
import com.chat.base.endpoint.entity.ChooseChatMenu;
import com.chat.base.entity.BottomSheetItem;
import com.chat.base.glide.GlideUtils;
import com.chat.base.net.ud.WKDownloader;
import com.chat.base.net.ud.WKProgressManager;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.WKFileUtils;
import com.chat.base.utils.WKPermissions;
import com.chat.base.utils.WKReader;
import com.chat.base.utils.WKTimeUtils;
import com.chat.base.utils.VideoPreDownloader;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.systembar.WKStatusBarUtils;
import com.google.android.material.snackbar.Snackbar;
import com.shuyu.gsyvideoplayer.builder.GSYVideoOptionBuilder;
import com.shuyu.gsyvideoplayer.model.VideoOptionModel;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannel;
import com.xinbida.wukongim.entity.WKMsg;
import com.xinbida.wukongim.entity.WKSendOptions;
import com.xinbida.wukongim.msgmodel.WKMessageContent;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

import tv.danmaku.ijk.media.player.IjkMediaPlayer;

/**
 * 2020-03-11 11:54
 * 播放视频
 */
public class PlayVideoActivity extends GSYBaseActivityDetail<VideoPlayer> {

    VideoPlayer detailPlayer;
    String playUrl;
    String coverImg;
    private String clientMsgNo;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
        setContentView(R.layout.act_play_video_layout);

        detailPlayer = findViewById(R.id.player);
        //增加title
        detailPlayer.getTitleTextView().setVisibility(View.GONE);
        detailPlayer.getBackButton().setVisibility(View.GONE);
        initView();
        initVideoBuilderMode();
        // 设置 IJKPlayer 优化选项：减少缓冲、加快启动、允许丢帧避免卡顿
        setupIjkPlayerOptions();
        detailPlayer.startPlayLogic();
    }

    /**
     * 设置 IJKPlayer 全局优化选项
     */
    private void setupIjkPlayerOptions() {
        try {
            ArrayList<VideoOptionModel> optionModels = new ArrayList<>();
            boolean isHls = playUrl != null && playUrl.toLowerCase().endsWith(".m3u8");
            if (isHls) {
                // HLS流需要更大的探测空间来解析m3u8播放列表和ts分片
                optionModels.add(new VideoOptionModel(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "analyzemaxduration", 200));
                optionModels.add(new VideoOptionModel(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "probesize", 2 * 1024 * 1024));
                optionModels.add(new VideoOptionModel(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "fflags", "nobuffer"));
                optionModels.add(new VideoOptionModel(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "flush_packets", 1));
            } else {
                // 普通视频文件：减少分析时长和探测大小，加快首帧
                optionModels.add(new VideoOptionModel(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "analyzemaxduration", 100));
                optionModels.add(new VideoOptionModel(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "probesize", 512 * 1024));
                optionModels.add(new VideoOptionModel(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "fflags", "nobuffer"));
                optionModels.add(new VideoOptionModel(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "flush_packets", 1));
            }
            // 播放器选项：准备后自动播放、允许丢帧、关闭 packet 缓冲减少延迟
            optionModels.add(new VideoOptionModel(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "start-on-prepared", 1));
            optionModels.add(new VideoOptionModel(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "framedrop", 5));
            optionModels.add(new VideoOptionModel(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "packet-buffering", 0));
            optionModels.add(new VideoOptionModel(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "enable-accurate-seek", 0));
            // HLS流不能用mediacodec硬件解码（不兼容ts分片切换）
            if (!isHls) {
                optionModels.add(new VideoOptionModel(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "mediacodec", 1));
                optionModels.add(new VideoOptionModel(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "mediacodec-auto-rotate", 1));
                optionModels.add(new VideoOptionModel(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "mediacodec-handle-resolution-change", 1));
            }
            // 缓冲区：适中即可，太大反而增加启动延迟
            optionModels.add(new VideoOptionModel(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "max-buffer-size", 10 * 1024 * 1024));
            optionModels.add(new VideoOptionModel(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "high-water-mark", 5 * 1024 * 1024));
            optionModels.add(new VideoOptionModel(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "low-water-mark", 2 * 1024 * 1024));

            com.shuyu.gsyvideoplayer.player.IPlayerManager playerManager = com.shuyu.gsyvideoplayer.player.PlayerFactory.getPlayManager();
            if (playerManager instanceof com.shuyu.gsyvideoplayer.player.IjkPlayerManager) {
                ((com.shuyu.gsyvideoplayer.player.IjkPlayerManager) playerManager).setOptionModelList(optionModels);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void initView() {
        if (getIntent().hasExtra("clientMsgNo"))
            clientMsgNo = getIntent().getStringExtra("clientMsgNo");
        coverImg = getIntent().getStringExtra("coverImg");
        String url = getIntent().getStringExtra("url");
        if (TextUtils.isEmpty(url)) {
            WKToastUtils.getInstance().showToast(getString(R.string.video_deleted));
            finish();
            return;
        }
        // HLS流不能查本地缓存：m3u8是播放列表文本，不是视频文件
        boolean isHls = url.toLowerCase().endsWith(".m3u8");
        if (!isHls) {
            String cachedPath = getCachedVideoPath(url);
            if (cachedPath == null) {
                cachedPath = VideoPreDownloader.getInstance().getCachedPath(url);
            }
            if (cachedPath != null) {
                playUrl = "file:///" + cachedPath;
            } else {
                playUrl = url;
                if (!url.startsWith("HTTP") && !url.startsWith("http")) {
                    playUrl = "file:///" + url;
                }
            }
        } else {
            playUrl = url;
        }
        detailPlayer.setLongClick(() -> {
            if (!TextUtils.isEmpty(clientMsgNo)) {
                WKMsg msg = WKIM.getInstance().getMsgManager().getWithClientMsgNO(clientMsgNo);
                if (msg.flame == 1) return;
            }
            showSaveDialog(playUrl);
        });


        Window window = getWindow();
        if (window == null) return;
        WKStatusBarUtils.transparentStatusBar(window);
//        WKStatusBarUtils.setDarkMode(window);
        WKStatusBarUtils.setStatusBarColor(window, ContextCompat.getColor(this, R.color.black), 0);
        WKStatusBarUtils.setLightMode(window);

        if (!TextUtils.isEmpty(clientMsgNo)) {
            WKIM.getInstance().getMsgManager().addOnRefreshMsgListener("play_video", (msg, b) -> {
                if (msg != null && !TextUtils.isEmpty(msg.clientMsgNO) && msg.clientMsgNO.equals(clientMsgNo)) {
                    if (msg.remoteExtra.revoke == 1) {
                        WKToastUtils.getInstance().showToast(getString(R.string.can_not_play_video_with_revoke));
                        finish();
                    }
                }
            });
        }
    }

    @Override
    public VideoPlayer getGSYVideoPlayer() {
        return detailPlayer;
    }

    @Override
    public GSYVideoOptionBuilder getGSYVideoOptionBuilder() {
        //内置封面可参考SampleCoverVideo
        ImageView imageView = new ImageView(this);
        ViewCompat.setTransitionName(detailPlayer, "coverIv");
        GlideUtils.getInstance().showImg(this, coverImg, imageView);
        boolean isHls = playUrl != null && playUrl.toLowerCase().endsWith(".m3u8");
        return new GSYVideoOptionBuilder()
                .setThumbImageView(imageView)
                .setUrl(playUrl)
                // HLS(m3u8)流不能用本地代理缓存，否则会破坏ts分片相对路径解析
                .setCacheWithPlay(!isHls)
                .setVideoTitle("")
                .setIsTouchWiget(true)
                //.setAutoFullWithSize(true)
                .setRotateViewAuto(false)
                .setLockLand(false)
                .setShowFullAnimation(false)//打开动画
                .setNeedLockFull(true)
                .setSeekRatio(1)
                .setStartAfterPrepared(true);
    }

    @Override
    public void clickForFullScreen() {

    }


    /**
     * 是否启动旋转横屏，true表示启动
     */
    @Override
    public boolean getDetailOrientationRotateAuto() {
        return true;
    }

    private void showSaveDialog(String url) {
        List<BottomSheetItem> list = new ArrayList<>();
        list.add(new BottomSheetItem(getString(R.string.save_img), R.mipmap.msg_download, () -> {
            checkPermissions(url);
        }));
        if (!TextUtils.isEmpty(clientMsgNo)) {
            list.add(new BottomSheetItem(getString(R.string.forward), R.mipmap.msg_forward, () -> {

                if (!TextUtils.isEmpty(clientMsgNo)) {
                    WKMsg msg = WKIM.getInstance().getMsgManager().getWithClientMsgNO(clientMsgNo);
                    if (msg != null && msg.baseContentMsgModel != null) {
                        EndpointManager.getInstance().invoke(EndpointSID.showChooseChatView, new ChooseChatMenu(new ChatChooseContacts(list1 -> {
                            WKMessageContent msgContent = msg.baseContentMsgModel;
                            if (WKReader.isNotEmpty(list1)) {
                                for (WKChannel channel : list1) {
                                    msgContent.mentionAll = 0;
                                    msgContent.mentionInfo = null;
                                    WKSendOptions options = new WKSendOptions();
                                    options.setting.receipt = 1;
//                                    setting.signal = 0;
                                    WKIM.getInstance().getMsgManager().sendWithOptions(
                                            msgContent,
                                            channel, options
                                    );
                                }
                                View viewGroup = findViewById(android.R.id.content);
                                Snackbar.make(viewGroup, getString(R.string.str_forward), 1000).setAction("", view -> {
                                }).show();
                            }
                        }), msg.baseContentMsgModel));
                    }
                }

            }));
        }
        WKDialogUtils.getInstance().showBottomSheet(this, getString(R.string.wk_video), false, list);
    }

    @Override
    public void finish() {
        super.finish();
        if (!TextUtils.isEmpty(clientMsgNo)) {
            WKIM.getInstance().getMsgManager().removeRefreshMsgListener("play_video");
            WKMsg msg = WKIM.getInstance().getMsgManager().getWithClientMsgNO(clientMsgNo);
            if (msg != null && msg.flame == 1 && msg.viewed == 0) {
                WKIM.getInstance().getMsgManager().updateViewedAt(1, WKTimeUtils.getInstance().getCurrentMills(), clientMsgNo);
                EndpointManager.getInstance().invoke("video_viewed", clientMsgNo);
            }
        }
    }

    private static final String VIDEO_CACHE_PREF = "video_cache";
    private static final String CACHE_KEY_PREFIX = "url_";

    private String getCachedVideoPath(String url) {
        if (url == null || (!url.startsWith("http"))) return null;
        SharedPreferences prefs = getSharedPreferences(VIDEO_CACHE_PREF, MODE_PRIVATE);
        String path = prefs.getString(CACHE_KEY_PREFIX + url, null);
        if (path != null) {
            File f = new File(path);
            if (f.exists() && f.length() > 0) return path;
        }
        return null;
    }

    private void setCachedVideoPath(String url, String path) {
        if (url == null || path == null) return;
        SharedPreferences prefs = getSharedPreferences(VIDEO_CACHE_PREF, MODE_PRIVATE);
        prefs.edit().putString(CACHE_KEY_PREFIX + url, path).apply();
    }

    private void saveToAlbum(String url) {

        // 保存视频
        if (!url.startsWith("http") && !url.startsWith("HTTP")) {
            File file = new File(url.replaceAll("file:///", ""));
            save(file);
        } else {
            String fileDir = Objects.requireNonNull(getExternalFilesDir("video")).getAbsolutePath() + WKBaseApplication.getInstance().getFileDir() + "/";
            WKFileUtils.getInstance().createFileDir(fileDir);
            String filePath = fileDir + WKTimeUtils.getInstance().getCurrentMills() + ".mp4";
            WKDownloader.Companion.getInstance().download(url, filePath, new WKProgressManager.IProgress() {
                @Override
                public void onProgress(@Nullable Object tag, int progress) {

                }

                @Override
                public void onSuccess(@Nullable Object tag, @Nullable String path) {
                    setCachedVideoPath(url, filePath);
                    VideoPreDownloader.getInstance().preDownload(url);
                    File file = new File(filePath.replaceAll("file:///", ""));
                    save(file);
                }

                @Override
                public void onFail(@Nullable Object tag, @Nullable String msg) {
                    WKToastUtils.getInstance().showToastNormal(getString((R.string.download_err)));
                }
            });
        }

    }

    private void save(File file) {
        boolean result = WKFileUtils.getInstance().saveVideoToAlbum(PlayVideoActivity.this, file.getAbsolutePath());
        if (result) {
            WKToastUtils.getInstance().showToastNormal(getString(R.string.saved_album));
        }
    }

    private void checkPermissions(String url) {
        String desc = String.format(
                getString(R.string.file_permissions_des),
                getString(R.string.app_name)
        );
        if (Build.VERSION.SDK_INT < 33) {
            WKPermissions.getInstance().checkPermissions(new WKPermissions.IPermissionResult() {
                                                             @Override
                                                             public void onResult(boolean result) {
                                                                 if (result) {
                                                                     saveToAlbum(url);
                                                                 }
                                                             }

                                                             @Override
                                                             public void clickResult(boolean isCancel) {

                                                             }
                                                         },
                    this,
                    desc,
                    Manifest.permission.READ_EXTERNAL_STORAGE,
                    Manifest.permission.WRITE_EXTERNAL_STORAGE
            );
        } else {
            WKPermissions.getInstance().checkPermissions(
                    new WKPermissions.IPermissionResult() {
                        @Override
                        public void onResult(boolean result) {
                            if (result) {
                                saveToAlbum(url);
                            }
                        }

                        @Override
                        public void clickResult(boolean isCancel) {

                        }
                    },
                    this,
                    desc,
                    Manifest.permission.READ_MEDIA_AUDIO,
                    Manifest.permission.READ_MEDIA_VIDEO,
                    Manifest.permission.READ_MEDIA_IMAGES
            );
        }
    }
}
