package com.chat.uikit.chat.manager;

import android.text.TextUtils;

import com.chat.base.endpoint.EndpointManager;
import com.chat.base.endpoint.EndpointSID;
import com.chat.base.endpoint.entity.WKSendMsgMenu;
import com.chat.base.glide.GlideUtils;
import com.chat.base.msgitem.WKContentType;
import com.chat.base.net.ud.WKUploader;
import com.chat.base.utils.WKMediaFileUtils;
import com.chat.base.utils.WKFileUtils;
import com.chat.base.utils.MP4FastStart;
import com.chat.uikit.chat.msgmodel.WKNoteContent;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannel;
import com.xinbida.wukongim.entity.WKMsg;
import com.xinbida.wukongim.entity.WKSendOptions;
import com.xinbida.wukongim.interfaces.IUploadAttacResultListener;
import com.xinbida.wukongim.message.type.WKSendMsgResult;
import com.xinbida.wukongim.msgmodel.WKImageContent;
import com.xinbida.wukongim.msgmodel.WKMediaMessageContent;
import com.xinbida.wukongim.msgmodel.WKVideoContent;

import java.io.File;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
import java.util.Timer;
import java.util.TimerTask;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import android.graphics.BitmapFactory;
import android.os.Handler;
import android.os.Looper;

import com.chat.base.config.WKApiConfig;
import com.chat.base.config.WKConfig;
import com.chat.base.utils.HlsTranscodeUtil;
import com.chat.base.utils.WKTimeUtils;

/**
 * 2019-11-20 13:20
 * 发送消息管理
 */
public class WKSendMsgUtils {
    private WKSendMsgUtils() {

    }

    private static class SendMsgUtilsBinder {
        private static final WKSendMsgUtils utils = new WKSendMsgUtils();
    }

    public static WKSendMsgUtils getInstance() {
        return SendMsgUtilsBinder.utils;
    }

    /**
     * 获取上传基础URL
     * 直传WuKongIM服务器（8090端口），避免后端中转导致双重上传
     */
    private String getUploadBaseUrl() {
        return WKApiConfig.baseUrl;
    }

    private final Set<String> uploadedMsgNos = ConcurrentHashMap.newKeySet();
    // 跟踪所有待发送消息的 clientMsgNO，连接恢复后重试 syncMsg 状态下被丢弃的消息
    private final Set<String> pendingMsgNos = ConcurrentHashMap.newKeySet();
    private final Handler retryHandler = new Handler(Looper.getMainLooper());

    private void trackUploadedMsg(String clientMsgNO) {
        if (clientMsgNO != null && !clientMsgNO.isEmpty()) {
            uploadedMsgNos.add(clientMsgNO);
            pendingMsgNos.add(clientMsgNO);
        }
    }

    /**
     * 跟踪所有待发送消息（包括不需要上传附件的消息，如笔记、文本等）
     * 确保在 syncMsg 状态下被丢弃的消息能在连接恢复后重试
     */
    private void trackPendingMsg(String clientMsgNO) {
        if (clientMsgNO != null && !clientMsgNO.isEmpty()) {
            pendingMsgNos.add(clientMsgNO);
        }
    }

    /**
     * 重发上传完成但卡在send_loading状态的消息
     * 在连接同步完成后调用，确保消息能被发送出去
     */
    void retryStuckMessages() {
        if (uploadedMsgNos.isEmpty() && pendingMsgNos.isEmpty()) return;
        android.util.Log.i("WKSendMsgUtils", "retryStuckMessages: checking uploaded=" + uploadedMsgNos.size() + ", pending=" + pendingMsgNos.size());

        // 重试上传相关的卡住消息
        Iterator<String> it = uploadedMsgNos.iterator();
        while (it.hasNext()) {
            String clientMsgNO = it.next();
            try {
                WKMsg msg = WKIM.getInstance().getMsgManager().getWithClientMsgNO(clientMsgNO);
                if (msg == null || msg.status == WKSendMsgResult.send_success) {
                    it.remove();
                    continue;
                }
                if (msg.status == WKSendMsgResult.send_loading) {
                    android.util.Log.i("WKSendMsgUtils", "retryStuckMessages: resending uploaded msg " + clientMsgNO);
                    WKIM.getInstance().getMsgManager().sendMessage(msg);
                    it.remove();
                }
            } catch (Exception e) {
                android.util.Log.e("WKSendMsgUtils", "retryStuckMessages error: " + e.getMessage());
                it.remove();
            }
        }

        // 重试所有待发送消息（包括笔记、文本等不需要上传的消息）
        Iterator<String> pit = pendingMsgNos.iterator();
        while (pit.hasNext()) {
            String clientMsgNO = pit.next();
            try {
                WKMsg msg = WKIM.getInstance().getMsgManager().getWithClientMsgNO(clientMsgNO);
                if (msg == null || msg.status == WKSendMsgResult.send_success) {
                    pit.remove();
                    continue;
                }
                if (msg.status == WKSendMsgResult.send_loading || msg.status == WKSendMsgResult.send_fail) {
                    android.util.Log.i("WKSendMsgUtils", "retryStuckMessages: resending pending msg " + clientMsgNO + ", status=" + msg.status);
                    WKIM.getInstance().getMsgManager().sendMessage(msg);
                    pit.remove();
                }
            } catch (Exception e) {
                android.util.Log.e("WKSendMsgUtils", "retryStuckMessages pending error: " + e.getMessage());
                pit.remove();
            }
        }
    }

    /**
     * 上传成功后延迟检查消息是否已发送
     * 如果5秒后仍处于send_loading状态，自动重发
     */
    private void scheduleRetryCheck(final String clientMsgNO) {
        if (clientMsgNO == null || clientMsgNO.isEmpty()) return;
        retryHandler.postDelayed(() -> {
            try {
                WKMsg msg = WKIM.getInstance().getMsgManager().getWithClientMsgNO(clientMsgNO);
                if (msg != null && (msg.status == WKSendMsgResult.send_loading || msg.status == WKSendMsgResult.send_fail)) {
                    android.util.Log.i("WKSendMsgUtils", "scheduleRetryCheck: message " + clientMsgNO + " status=" + msg.status + ", resending");
                    WKIM.getInstance().getMsgManager().sendMessage(msg);
                }
                uploadedMsgNos.remove(clientMsgNO);
                pendingMsgNos.remove(clientMsgNO);
            } catch (Exception e) {
                android.util.Log.e("WKSendMsgUtils", "scheduleRetryCheck error: " + e.getMessage());
                uploadedMsgNos.remove(clientMsgNO);
                pendingMsgNos.remove(clientMsgNO);
            }
        }, 5000);
    }

    /**
     * 判断路径是否为本地媒体文件（包括文件路径和content URI）
     */
    private boolean isLocalMediaPath(String path) {
        if (TextUtils.isEmpty(path)) return false;
        if (path.startsWith("http://") || path.startsWith("https://")) return false;
        if (path.startsWith("content://")) return true;
        File file = new File(path);
        return file.exists() && file.length() > 0;
    }

    /**
     * 从content URI获取真实文件路径
     */
    private String getRealPathFromContentUri(String uriString) {
        if (TextUtils.isEmpty(uriString) || !uriString.startsWith("content://")) {
            return uriString;
        }
        try {
            android.net.Uri uri = android.net.Uri.parse(uriString);
            String[] projection = { android.provider.MediaStore.Images.Media.DATA };
            android.database.Cursor cursor = com.chat.base.WKBaseApplication.getInstance().application
                    .getContentResolver().query(uri, projection, null, null, null);
            if (cursor != null && cursor.moveToFirst()) {
                String path = cursor.getString(cursor.getColumnIndexOrThrow(
                        android.provider.MediaStore.Images.Media.DATA));
                cursor.close();
                return path;
            }
            if (cursor != null) cursor.close();
        } catch (Exception e) {
            android.util.Log.e("WKSendMsgUtils", "getRealPathFromContentUri error: " + e.getMessage());
        }
        return null;
    }

    public void sendMessage(WKMsg wkMsg) {
        if (wkMsg == null || wkMsg.baseContentMsgModel == null) return;
        // 笔记消息：SDK的上传附件监听器不会触发自定义消息类型，需主动上传后再发送
        if (wkMsg.type == WKContentType.noteMsg && wkMsg.baseContentMsgModel instanceof WKNoteContent) {
            final WKNoteContent noteContent = (WKNoteContent) wkMsg.baseContentMsgModel;
            final String blockListJson = noteContent.blockListJson;
            android.util.Log.d("WKSendMsgUtils", "sendMessage noteMsg, blockListJson empty=" + TextUtils.isEmpty(blockListJson));

            // 计算摘要、containVideo、containLocation
            if (TextUtils.isEmpty(noteContent.summary)) {
                noteContent.summary = extractNoteSummary(blockListJson);
            }
            noteContent.containLocation = hasLocationBlock(blockListJson) ? 1 : 0;

            // 检查是否有本地图片/视频需要上传
            boolean hasLocalImage = false;
            boolean hasLocalVideo = false;
            boolean hasNetworkImage = false;
            String firstImageUrl = null;
            String firstVideoCoverUrl = null;
            if (!TextUtils.isEmpty(blockListJson)) {
                try {
                    org.json.JSONArray array = new org.json.JSONArray(blockListJson);
                    for (int i = 0; i < array.length(); i++) {
                        org.json.JSONObject obj = array.optJSONObject(i);
                        if (obj == null) continue;
                        int blockType = obj.optInt("type", -1);
                        if (blockType == 3) { // 图片块
                            String imgPath = obj.optString("imagePath", "");
                            if (TextUtils.isEmpty(imgPath)) imgPath = obj.optString("path", "");
                            if (!TextUtils.isEmpty(imgPath)) {
                                boolean isNetwork = imgPath.startsWith("http://") || imgPath.startsWith("https://");
                                if (isNetwork) {
                                    hasNetworkImage = true;
                                    if (firstImageUrl == null) firstImageUrl = imgPath;
                                } else if (isLocalMediaPath(imgPath)) {
                                    hasLocalImage = true;
                                    // 对于content URI，先尝试获取真实路径作为封面（上传后会替换成网络URL）
                                    String realPath = getRealPathFromContentUri(imgPath);
                                    if (firstImageUrl == null) {
                                        firstImageUrl = (realPath != null) ? realPath : imgPath;
                                    }
                                }
                            }
                        } else if (blockType == 4) { // 视频块
                            noteContent.containVideo = 1;
                            String vPath = obj.optString("videoPath", "");
                            if (!TextUtils.isEmpty(vPath) && isLocalMediaPath(vPath)) {
                                hasLocalVideo = true;
                            }
                            String cover = obj.optString("videoCover", "");
                            if (!TextUtils.isEmpty(cover)) {
                                boolean isNetwork = cover.startsWith("http://") || cover.startsWith("https://");
                                if (isNetwork) {
                                    if (firstVideoCoverUrl == null) firstVideoCoverUrl = cover;
                                } else if (isLocalMediaPath(cover)) {
                                    hasLocalVideo = true; // 封面也要上传
                                    String realPath = getRealPathFromContentUri(cover);
                                    if (firstVideoCoverUrl == null) {
                                        firstVideoCoverUrl = (realPath != null) ? realPath : cover;
                                    }
                                }
                            }
                        }
                    }
                } catch (Exception e) {
                    android.util.Log.e("WKSendMsgUtils", "parse note block error: " + e.getMessage());
                }
            }

            // 如果coverUrl为空但有图片，尝试设置封面
            if (TextUtils.isEmpty(noteContent.coverUrl)) {
                if (firstImageUrl != null) {
                    noteContent.coverUrl = firstImageUrl;
                    noteContent.resource = firstImageUrl;
                    noteContent.resourceType = "image";
                    android.util.Log.d("WKSendMsgUtils", "set coverUrl from first image: " + firstImageUrl);
                } else if (firstVideoCoverUrl != null) {
                    noteContent.coverUrl = firstVideoCoverUrl;
                    noteContent.resource = firstVideoCoverUrl;
                    noteContent.resourceType = "video";
                    android.util.Log.d("WKSendMsgUtils", "set coverUrl from first video cover: " + firstVideoCoverUrl);
                }
            }

            // 有本地媒体需要上传
            if (hasLocalImage || hasLocalVideo) {
                android.util.Log.d("WKSendMsgUtils", "has local media, uploading... image=" + hasLocalImage + ", video=" + hasLocalVideo);
                doUploadNoteAndSend(wkMsg, noteContent, blockListJson);
                return;
            }
            // 没有本地媒体，直接发送（coverUrl可能已从网络图片设置）
            android.util.Log.d("WKSendMsgUtils", "no local media, send directly, coverUrl=" + noteContent.coverUrl);
        }
        doSendMessage(wkMsg);
    }

    private void doSendMessage(WKMsg wkMsg) {
        WKSendOptions options = new WKSendOptions();
        options.robotID = wkMsg.robotID;
        WKChannel channel = wkMsg.getChannelInfo();
        if (channel == null) {
            channel = new WKChannel(wkMsg.channelID, wkMsg.channelType);
        }
        channel.receipt = 1;
        options.setting.receipt = 1;
        if (wkMsg.setting == null) {
            wkMsg.setting = options.setting;
        } else {
            wkMsg.setting.receipt = 1;
        }
        try {
            EndpointManager.getInstance().invokes(EndpointSID.sendMessage, new WKSendMsgMenu(channel, options));
        } catch (Exception ignored) {
        }
        if (wkMsg.clientMsgNO == null || wkMsg.clientMsgNO.isEmpty()) {
            wkMsg.clientMsgNO = UUID.randomUUID().toString().replace("-", "");
        }
        if (wkMsg.fromUID == null || wkMsg.fromUID.isEmpty()) {
            wkMsg.fromUID = WKConfig.getInstance().getUid();
        }
        if (wkMsg.timestamp == 0) {
            wkMsg.timestamp = System.currentTimeMillis() / 1000;
        }
        wkMsg.status = WKSendMsgResult.send_loading;
        WKIM.getInstance().getMsgManager().sendMessage(wkMsg);
    }

    /**
     * 上传笔记中的图片/视频，完成后再发送消息
     */
    private void doUploadNoteAndSend(final WKMsg msg, final WKNoteContent noteContent, final String blockListJson) {
        // 收集所有本地图片和视频路径，同时记录第一张图（封面）
        // key: 原始路径（可能是content URI，用于替换blockListJson）value: 真实文件路径（用于上传）
        final java.util.Map<String, String> originalToRealPathMap = new java.util.HashMap<>();
        final java.util.List<String> localImagePaths = new java.util.ArrayList<>(); // 原始路径列表
        final java.util.List<String> localVideoPaths = new java.util.ArrayList<>();
        final java.util.List<String> localVideoCoverPaths = new java.util.ArrayList<>();
        final String[] firstImageOriginalPath = {null};
        final String[] firstVideoCoverOriginalPath = {null};
        try {
            org.json.JSONArray array = new org.json.JSONArray(blockListJson);
            for (int i = 0; i < array.length(); i++) {
                org.json.JSONObject obj = array.optJSONObject(i);
                if (obj == null) continue;
                int blockType = obj.optInt("type", -1);
                if (blockType == 3) { // 图片块
                    String imgPath = obj.optString("imagePath", "");
                    if (TextUtils.isEmpty(imgPath)) imgPath = obj.optString("path", "");
                    if (!TextUtils.isEmpty(imgPath) && isLocalMediaPath(imgPath)) {
                        String realPath = getRealPathFromContentUri(imgPath);
                        if (realPath != null) {
                            originalToRealPathMap.put(imgPath, realPath);
                            localImagePaths.add(imgPath);
                            if (firstImageOriginalPath[0] == null) firstImageOriginalPath[0] = imgPath;
                        } else {
                            android.util.Log.w("WKSendMsgUtils", "cannot get real path for: " + imgPath);
                        }
                    }
                } else if (blockType == 4) { // 视频块
                    String vPath = obj.optString("videoPath", "");
                    if (!TextUtils.isEmpty(vPath) && isLocalMediaPath(vPath)) {
                        String realPath = getRealPathFromContentUri(vPath);
                        if (realPath != null) {
                            originalToRealPathMap.put(vPath, realPath);
                            localVideoPaths.add(vPath);
                        }
                    }
                    String cover = obj.optString("videoCover", "");
                    if (!TextUtils.isEmpty(cover) && isLocalMediaPath(cover)) {
                        String realPath = getRealPathFromContentUri(cover);
                        if (realPath != null) {
                            originalToRealPathMap.put(cover, realPath);
                            localVideoCoverPaths.add(cover);
                            if (firstVideoCoverOriginalPath[0] == null) firstVideoCoverOriginalPath[0] = cover;
                        }
                    }
                }
            }
        } catch (Exception e) {
            android.util.Log.e("WKSendMsgUtils", "parse note block error: " + e.getMessage());
        }

        // 计算摘要
        if (TextUtils.isEmpty(noteContent.summary)) {
            noteContent.summary = extractNoteSummary(blockListJson);
        }
        noteContent.containVideo = localVideoPaths.size() > 0 ? 1 : 0;
        noteContent.containLocation = hasLocationBlock(blockListJson) ? 1 : 0;

        int totalMedia = localImagePaths.size() + localVideoPaths.size() + localVideoCoverPaths.size();
        android.util.Log.d("WKSendMsgUtils", "note upload media count: " + totalMedia + ", images=" + localImagePaths.size() + ", videos=" + localVideoPaths.size());
        if (totalMedia == 0) {
            doSendMessage(msg);
            return;
        }

        final java.util.Map<String, String> pathMap = new java.util.concurrent.ConcurrentHashMap<>();
        final int[] completedCount = {0};
        final boolean[] hasError = {false};
        final int total = totalMedia;

        java.lang.Runnable checkDone = () -> {
            synchronized (completedCount) {
                completedCount[0]++;
                if (completedCount[0] == total) {
                    // 所有上传完成，替换路径
                    String newJson = replaceNoteMediaPaths(blockListJson, pathMap);
                    noteContent.blockListJson = newJson;
                    // 设置封面URL（同时设置coverUrl和resource，保持一致）
                    if (firstImageOriginalPath[0] != null && pathMap.containsKey(firstImageOriginalPath[0])) {
                        String coverUrl = pathMap.get(firstImageOriginalPath[0]);
                        noteContent.coverUrl = coverUrl;
                        noteContent.resource = coverUrl;
                        noteContent.resourceType = "image";
                    } else if (firstVideoCoverOriginalPath[0] != null && pathMap.containsKey(firstVideoCoverOriginalPath[0])) {
                        String coverUrl = pathMap.get(firstVideoCoverOriginalPath[0]);
                        noteContent.coverUrl = coverUrl;
                        noteContent.resource = coverUrl;
                        noteContent.resourceType = "video";
                    }
                    android.util.Log.d("WKSendMsgUtils", "note upload done, coverUrl=" + noteContent.coverUrl + ", sending...");
                    doSendMessage(msg);
                }
            }
        };

        // 上传图片（先压缩再上传）
        for (final String originalPath : localImagePaths) {
            final String realPath = originalToRealPathMap.get(originalPath);
            if (realPath == null) continue;
            final File imgFile = new File(realPath);
            if (imgFile.exists() && imgFile.length() > 500 * 1024) {
                java.util.List<String> single = new java.util.ArrayList<>();
                single.add(realPath);
                GlideUtils.getInstance().compressImg(
                        com.chat.base.WKBaseApplication.getInstance().application,
                        single, files -> {
                            String uploadPath = realPath;
                            if (files != null && !files.isEmpty() && files.get(0) != null
                                    && files.get(0).exists() && files.get(0).length() > 0) {
                                uploadPath = files.get(0).getAbsolutePath();
                            }
                            uploadNoteMedia(msg.channelID, msg.channelType, uploadPath, originalPath, pathMap, checkDone, hasError);
                        });
            } else {
                uploadNoteMedia(msg.channelID, msg.channelType, realPath, originalPath, pathMap, checkDone, hasError);
            }
        }

        // 上传视频封面
        for (final String originalPath : localVideoCoverPaths) {
            String realPath = originalToRealPathMap.get(originalPath);
            if (realPath == null) realPath = originalPath;
            uploadNoteMedia(msg.channelID, msg.channelType, realPath, originalPath, pathMap, checkDone, hasError);
        }

        // 上传视频
        for (final String originalPath : localVideoPaths) {
            String realPath = originalToRealPathMap.get(originalPath);
            if (realPath == null) realPath = originalPath;
            uploadNoteMedia(msg.channelID, msg.channelType, realPath, originalPath, pathMap, checkDone, hasError);
        }
    }

    public void sendMessages(List<SendMsgEntity> list) {
        for (int i = 0; i < list.size(); i++) {
            WKMsg wkMsg = new WKMsg();
            wkMsg.channelID = list.get(i).wkChannel.channelID;
            wkMsg.channelType = list.get(i).wkChannel.channelType;
            wkMsg.type = list.get(i).messageContent.type;
            wkMsg.baseContentMsgModel = list.get(i).messageContent;
            wkMsg.setChannelInfo(list.get(i).wkChannel);
            sendMessage(wkMsg);
        }
    }

    /**
     * 上传聊天附件
     *
     * @param msg      消息
     * @param listener 上传返回
     */
    void uploadChatAttachment(WKMsg msg, IUploadAttacResultListener listener) {
        android.util.Log.d("WKSendMsgUtils", "uploadChatAttachment called, msg.type=" + msg.type + ", noteMsg=" + WKContentType.noteMsg + ", baseContent=" + (msg.baseContentMsgModel != null ? msg.baseContentMsgModel.getClass().getSimpleName() : "null"));
        //存在附件待上传
        if (msg.type == WKContentType.WK_IMAGE || msg.type == WKContentType.WK_GIF || msg.type == WKContentType.WK_VOICE || msg.type == WKContentType.WK_FILE || msg.type == WKContentType.WK_LOCATION) {
            WKMediaMessageContent contentMsgModel = (WKMediaMessageContent) msg.baseContentMsgModel;
            //已经有网络地址无需再上传
            if (!TextUtils.isEmpty(contentMsgModel.url)) {
                trackUploadedMsg(msg.clientMsgNO);
                scheduleRetryCheck(msg.clientMsgNO);
                listener.onUploadResult(true, contentMsgModel);
            } else if (!TextUtils.isEmpty(contentMsgModel.localPath)) {
                // 图片发送前先压缩，减小体积、加快上传
                if (msg.type == WKContentType.WK_IMAGE && contentMsgModel instanceof WKImageContent) {
                    File imgFile = new File(contentMsgModel.localPath);
                    if (imgFile.exists() && imgFile.length() > 500 * 1024) {
                        List<String> pathList = new ArrayList<>();
                        pathList.add(contentMsgModel.localPath);
                        GlideUtils.getInstance().compressImg(com.chat.base.WKBaseApplication.getInstance().application, pathList, files -> {
                            if (files != null && !files.isEmpty()) {
                                File compressedFile = files.get(0);
                                if (compressedFile != null && compressedFile.exists() && compressedFile.length() > 0) {
                                    contentMsgModel.localPath = compressedFile.getAbsolutePath();
                                    try {
                                        BitmapFactory.Options options = new BitmapFactory.Options();
                                        options.inJustDecodeBounds = true;
                                        BitmapFactory.decodeFile(compressedFile.getAbsolutePath(), options);
                                        if (options.outWidth > 0 && options.outHeight > 0) {
                                            ((WKImageContent) contentMsgModel).width = options.outWidth;
                                            ((WKImageContent) contentMsgModel).height = options.outHeight;
                                        }
                                    } catch (Exception ignored) {
                                    }
                                }
                            }
                            doUploadFile(msg, contentMsgModel.localPath, contentMsgModel, listener);
                        });
                        return;
                    }
                }
                doUploadFile(msg, contentMsgModel.localPath, contentMsgModel, listener);
            } else {
                listener.onUploadResult(false, msg.baseContentMsgModel);
            }
        } else if (msg.type == WKContentType.WK_VIDEO) {
            //视频：封面和视频本体并行上传，提升速度
            WKVideoContent videoMsgModel = (WKVideoContent) msg.baseContentMsgModel;

            // 如果封面还未提取（从相册选择后立即发送的情况），在上传线程提取
            if (TextUtils.isEmpty(videoMsgModel.coverLocalPath) && !TextUtils.isEmpty(videoMsgModel.localPath)) {
                WKMediaFileUtils.VideoMeta meta = WKMediaFileUtils.getInstance().getVideoMeta(videoMsgModel.localPath);
                videoMsgModel.coverLocalPath = meta.coverPath;
                videoMsgModel.second = meta.seconds;
                if (videoMsgModel.width == 0 || videoMsgModel.height == 0) {
                    videoMsgModel.width = meta.width;
                    videoMsgModel.height = meta.height;
                }
                // 刷新UI显示封面
                WKIM.getInstance().getMsgManager().updateContentAndRefresh(msg.clientMsgNO, videoMsgModel, true);
            }

            if (!TextUtils.isEmpty(videoMsgModel.cover) && !TextUtils.isEmpty(videoMsgModel.url)) {
                trackUploadedMsg(msg.clientMsgNO);
                scheduleRetryCheck(msg.clientMsgNO);
                listener.onUploadResult(true, msg.baseContentMsgModel);
            } else {
                // 并行上传封面和视频
                final String clientMsgNO = msg.clientMsgNO;
                final boolean[] coverDone = {false};
                final boolean[] videoDone = {false};
                final boolean[] coverFailed = {false};
                final boolean[] videoFailed = {false};

                // 上传封面（使用预签名直传，避免multipart中转）
                if (!TextUtils.isEmpty(videoMsgModel.coverLocalPath) && TextUtils.isEmpty(videoMsgModel.cover)) {
                    WKUploader.getInstance().uploadPresign(msg.channelID, msg.channelType, videoMsgModel.coverLocalPath,
                            UUID.randomUUID().toString().replace("-", ""), new WKUploader.IUploadBack() {
                                @Override
                                public void onSuccess(String returnedPath) {
                                    if (!TextUtils.isEmpty(returnedPath)) {
                                        videoMsgModel.cover = returnedPath;
                                    } else {
                                        coverFailed[0] = true;
                                    }
                                    coverDone[0] = true;
                                    checkParallelUploadDone(coverDone, videoDone, coverFailed, videoFailed, clientMsgNO, videoMsgModel, listener);
                                }

                                @Override
                                public void onError() {
                                    coverFailed[0] = true;
                                    coverDone[0] = true;
                                    checkParallelUploadDone(coverDone, videoDone, coverFailed, videoFailed, clientMsgNO, videoMsgModel, listener);
                                }
                            });
                } else {
                    coverDone[0] = true;
                }

                // 视频上传：HLS转码 + COS直传（实现秒发秒收）
                // 接收方拿到m3u8 URL后按需加载ts分片，边下边播
                if (!TextUtils.isEmpty(videoMsgModel.localPath) && TextUtils.isEmpty(videoMsgModel.url)) {
                    final String originalVideoPath = videoMsgModel.localPath;
                    final Object uploadTag = msg.clientSeq;

                    File vf = new File(originalVideoPath);

                    // 小视频(<10MB)跳过HLS转码，直接预签名上传，大幅提升速度
                    if (vf.exists() && vf.length() > 0 && vf.length() < 10 * 1024 * 1024) {
                        android.util.Log.d("WKSendMsgUtils", "small video (" + vf.length() / 1024 + "KB), skip HLS, use presign");
                        fallbackToMinioPresign(msg, originalVideoPath, uploadTag, videoMsgModel,
                                coverDone, videoDone, coverFailed, videoFailed, clientMsgNO, listener);
                    } else {
                    // 大视频：MP4 faststart + HLS转码 + COS直传
                    String transcodePath = originalVideoPath;
                    boolean needCleanup = false;

                    if (vf.exists() && vf.length() > 0 && !MP4FastStart.isFastStart(originalVideoPath)) {
                        String tmpPath = originalVideoPath + ".fs.mp4";
                        if (MP4FastStart.convert(originalVideoPath, tmpPath)) {
                            transcodePath = tmpPath;
                            needCleanup = true;
                        }
                    }

                    final String finalTranscodePath = transcodePath;
                    final boolean finalNeedCleanup = needCleanup;

                    String basePath = "video/" + msg.channelType + "/" + msg.channelID + "/" +
                            WKTimeUtils.getInstance().getCurrentMills() + "_" +
                            UUID.randomUUID().toString().replace("-", "").substring(0, 8) + "/";

                    HlsTranscodeUtil.getInstance().transcodeToHls(finalTranscodePath,
                            new HlsTranscodeUtil.TranscodeCallback() {
                                @Override
                                public void onStart() {
                                    android.util.Log.d("WKSendMsgUtils", "HLS transcode started");
                                }

                                @Override
                                public void onProgress(int percent) {
                                }

                                @Override
                                public void onSuccess(File outputDir, String m3u8FileName) {
                                    if (finalNeedCleanup) {
                                        new File(finalTranscodePath).delete();
                                    }

                                    List<File> hlsFiles = HlsTranscodeUtil.getHlsFiles(outputDir);
                                    if (hlsFiles.isEmpty()) {
                                        android.util.Log.e("WKSendMsgUtils", "HLS transcode: no output files");
                                        HlsTranscodeUtil.cleanupOutputDir(outputDir);
                                        fallbackToMinioPresign(msg, originalVideoPath, uploadTag, videoMsgModel,
                                                coverDone, videoDone, coverFailed, videoFailed, clientMsgNO, listener);
                                        return;
                                    }

                                    WKUploader.getInstance().uploadCosBatch(msg.channelID, msg.channelType,
                                            hlsFiles, basePath, uploadTag,
                                            new WKUploader.CosBatchUploadCallback() {
                                                @Override
                                                public void onSuccess(String accessUrl, List<String> cosPaths) {
                                                    videoMsgModel.url = accessUrl;
                                                    videoDone[0] = true;
                                                    HlsTranscodeUtil.cleanupOutputDir(outputDir);
                                                    checkParallelUploadDone(coverDone, videoDone, coverFailed, videoFailed, clientMsgNO, videoMsgModel, listener);
                                                }

                                                @Override
                                                public void onError(Throwable e) {
                                                    android.util.Log.e("WKSendMsgUtils", "COS upload failed, fallback to MinIO: " + e.getMessage());
                                                    HlsTranscodeUtil.cleanupOutputDir(outputDir);
                                                    fallbackToMinioPresign(msg, originalVideoPath, uploadTag, videoMsgModel,
                                                            coverDone, videoDone, coverFailed, videoFailed, clientMsgNO, listener);
                                                }
                                            });
                                }

                                @Override
                                public void onError(Exception e) {
                                    android.util.Log.e("WKSendMsgUtils", "HLS transcode failed, fallback to MinIO: " + e.getMessage());
                                    if (finalNeedCleanup) {
                                        new File(finalTranscodePath).delete();
                                    }
                                    fallbackToMinioPresign(msg, originalVideoPath, uploadTag, videoMsgModel,
                                            coverDone, videoDone, coverFailed, videoFailed, clientMsgNO, listener);
                                }
                            });
                    } // end else (大视频HLS)
                } else {
                    videoDone[0] = true;
                }

                // 如果封面和视频都没有需要上传的
                if (coverDone[0] && videoDone[0]) {
                    checkParallelUploadDone(coverDone, videoDone, coverFailed, videoFailed, clientMsgNO, videoMsgModel, listener);
                }
            }
        } else if (msg.type == WKContentType.noteMsg) {
            // 笔记消息：上传所有图片和视频，替换为网络URL后再发送
            // 同时提取第一张图片作为封面coverUrl，接收方直接加载，无需解析blockListJson
            final WKNoteContent noteContent = (WKNoteContent) msg.baseContentMsgModel;
            final String blockListJson = noteContent.blockListJson;
            if (TextUtils.isEmpty(blockListJson)) {
                trackUploadedMsg(msg.clientMsgNO);
                scheduleRetryCheck(msg.clientMsgNO);
                listener.onUploadResult(true, noteContent);
                return;
            }

            // 收集所有本地图片和视频路径，同时记录第一张图（封面）
            final java.util.List<String> localImagePaths = new java.util.ArrayList<>();
            final java.util.List<String> localVideoPaths = new java.util.ArrayList<>();
            final java.util.List<String> localVideoCoverPaths = new java.util.ArrayList<>();
            final String[] firstImagePath = {null};  // 第一张图片路径，作为封面
            final String[] firstVideoCoverPath = {null}; // 第一个视频封面，无图片时作为封面
            try {
                org.json.JSONArray array = new org.json.JSONArray(blockListJson);
                for (int i = 0; i < array.length(); i++) {
                    org.json.JSONObject obj = array.optJSONObject(i);
                    if (obj == null) continue;
                    int blockType = obj.optInt("type", -1);
                    if (blockType == 3) { // 图片块
                        String imgPath = obj.optString("imagePath", "");
                        if (TextUtils.isEmpty(imgPath)) imgPath = obj.optString("path", "");
                        if (!TextUtils.isEmpty(imgPath) && !imgPath.startsWith("http")
                                && new File(imgPath).exists()) {
                            localImagePaths.add(imgPath);
                            if (firstImagePath[0] == null) firstImagePath[0] = imgPath;
                        }
                    } else if (blockType == 4) { // 视频块
                        String vPath = obj.optString("videoPath", "");
                        if (!TextUtils.isEmpty(vPath) && !vPath.startsWith("http")
                                && new File(vPath).exists()) {
                            localVideoPaths.add(vPath);
                        }
                        String cover = obj.optString("videoCover", "");
                        if (!TextUtils.isEmpty(cover) && !cover.startsWith("http")
                                && new File(cover).exists()) {
                            localVideoCoverPaths.add(cover);
                            if (firstVideoCoverPath[0] == null) firstVideoCoverPath[0] = cover;
                        }
                    }
                }
            } catch (Exception e) {
                android.util.Log.e("WKSendMsgUtils", "parse note block error: " + e.getMessage());
            }

            // 计算摘要（取第一个文字块内容）
            if (TextUtils.isEmpty(noteContent.summary)) {
                noteContent.summary = extractNoteSummary(blockListJson);
            }
            // 是否包含视频
            noteContent.containVideo = localVideoPaths.size() > 0 ? 1 : 0;
            // 是否包含位置
            noteContent.containLocation = hasLocationBlock(blockListJson) ? 1 : 0;

            int totalMedia = localImagePaths.size() + localVideoPaths.size() + localVideoCoverPaths.size();
            if (totalMedia == 0) {
                // 没有需要上传的媒体，直接发送
                trackUploadedMsg(msg.clientMsgNO);
                scheduleRetryCheck(msg.clientMsgNO);
                listener.onUploadResult(true, noteContent);
                return;
            }

            // 并行上传所有图片和视频
            final java.util.Map<String, String> pathMap = new java.util.concurrent.ConcurrentHashMap<>();
            final int[] completedCount = {0};
            final boolean[] hasError = {false};
            final int total = totalMedia;

            java.lang.Runnable checkDone = () -> {
                synchronized (completedCount) {
                    completedCount[0]++;
                    if (completedCount[0] == total) {
                        // 所有上传完成，替换路径
                        String newJson = replaceNoteMediaPaths(blockListJson, pathMap);
                        noteContent.blockListJson = newJson;
                        // 设置封面URL：优先第一张图片，其次第一个视频封面
                        if (firstImagePath[0] != null && pathMap.containsKey(firstImagePath[0])) {
                            noteContent.coverUrl = pathMap.get(firstImagePath[0]);
                        } else if (firstVideoCoverPath[0] != null && pathMap.containsKey(firstVideoCoverPath[0])) {
                            noteContent.coverUrl = pathMap.get(firstVideoCoverPath[0]);
                        }
                        android.util.Log.d("WKSendMsgUtils", "note upload done: coverUrl=" + noteContent.coverUrl + ", firstImagePath=" + firstImagePath[0] + ", pathMap size=" + pathMap.size());
                        trackUploadedMsg(msg.clientMsgNO);
                        scheduleRetryCheck(msg.clientMsgNO);
                        listener.onUploadResult(!hasError[0], noteContent);
                    }
                }
            };

            // 上传图片（先压缩再上传）
            for (final String imgPath : localImagePaths) {
                final File imgFile = new File(imgPath);
                if (imgFile.exists() && imgFile.length() > 500 * 1024) {
                    // 大于500KB先压缩
                    java.util.List<String> single = new java.util.ArrayList<>();
                    single.add(imgPath);
                    GlideUtils.getInstance().compressImg(
                            com.chat.base.WKBaseApplication.getInstance().application,
                            single, files -> {
                                String uploadPath = imgPath;
                                if (files != null && !files.isEmpty() && files.get(0) != null
                                        && files.get(0).exists() && files.get(0).length() > 0) {
                                    uploadPath = files.get(0).getAbsolutePath();
                                }
                                uploadNoteMedia(msg.channelID, msg.channelType, uploadPath, imgPath, pathMap, checkDone, hasError);
                            });
                } else {
                    uploadNoteMedia(msg.channelID, msg.channelType, imgPath, imgPath, pathMap, checkDone, hasError);
                }
            }

            // 上传视频封面
            for (final String coverPath : localVideoCoverPaths) {
                uploadNoteMedia(msg.channelID, msg.channelType, coverPath, coverPath, pathMap, checkDone, hasError);
            }

            // 上传视频
            for (final String videoPath : localVideoPaths) {
                uploadNoteMedia(msg.channelID, msg.channelType, videoPath, videoPath, pathMap, checkDone, hasError);
            }

        } else {
            //其他不需要上传附件的消息类型，直接回调成功
            trackUploadedMsg(msg.clientMsgNO);
            scheduleRetryCheck(msg.clientMsgNO);
            listener.onUploadResult(true, msg.baseContentMsgModel);
        }
    }

    /**
     * 上传笔记中的单个媒体文件
     */
    private void uploadNoteMedia(String channelID, byte channelType, String uploadPath,
                                 final String originalPath,
                                 final java.util.Map<String, String> pathMap,
                                 final java.lang.Runnable onDone,
                                 final boolean[] hasError) {
        WKUploader.getInstance().uploadPresign(channelID, channelType, uploadPath, originalPath, new WKUploader.IUploadBack() {
            @Override
            public void onSuccess(String returnedPath) {
                if (!TextUtils.isEmpty(returnedPath)) {
                    pathMap.put(originalPath, returnedPath);
                } else {
                    hasError[0] = true;
                }
                onDone.run();
            }

            @Override
            public void onError() {
                hasError[0] = true;
                onDone.run();
            }
        });
    }

    /**
     * 从笔记blockListJson提取摘要（第一个文字/标题块内容）
     */
    private String extractNoteSummary(String blockListJson) {
        try {
            org.json.JSONArray array = new org.json.JSONArray(blockListJson);
            for (int i = 0; i < array.length(); i++) {
                org.json.JSONObject obj = array.optJSONObject(i);
                if (obj == null) continue;
                int blockType = obj.optInt("type", -1);
                if (blockType == 2) { // 文字块
                    String content = obj.optString("content", "");
                    if (!TextUtils.isEmpty(content)) {
                        return content.length() > 50 ? content.substring(0, 50) : content;
                    }
                }
            }
        } catch (Exception ignored) {
        }
        return "";
    }

    /**
     * 检查笔记是否包含位置块
     */
    private boolean hasLocationBlock(String blockListJson) {
        try {
            org.json.JSONArray array = new org.json.JSONArray(blockListJson);
            for (int i = 0; i < array.length(); i++) {
                org.json.JSONObject obj = array.optJSONObject(i);
                if (obj != null && obj.optInt("type", -1) == 5) {
                    return true;
                }
            }
        } catch (Exception ignored) {
        }
        return false;
    }

    /**
     * 替换笔记 blockListJson 中的本地路径为网络URL
     */
    private String replaceNoteMediaPaths(String blockListJson, java.util.Map<String, String> pathMap) {
        try {
            org.json.JSONArray array = new org.json.JSONArray(blockListJson);
            for (int i = 0; i < array.length(); i++) {
                org.json.JSONObject obj = array.optJSONObject(i);
                if (obj == null) continue;
                int blockType = obj.optInt("type", -1);
                if (blockType == 3) { // 图片块
                    String imgPath = obj.optString("imagePath", "");
                    if (TextUtils.isEmpty(imgPath)) imgPath = obj.optString("path", "");
                    if (!TextUtils.isEmpty(imgPath) && pathMap.containsKey(imgPath)) {
                        String url = pathMap.get(imgPath);
                        if (!TextUtils.isEmpty(url)) {
                            obj.put("imagePath", url);
                            obj.put("path", url);
                        }
                    }
                } else if (blockType == 4) { // 视频块
                    String vPath = obj.optString("videoPath", "");
                    if (!TextUtils.isEmpty(vPath) && pathMap.containsKey(vPath)) {
                        String url = pathMap.get(vPath);
                        if (!TextUtils.isEmpty(url)) obj.put("videoPath", url);
                    }
                    String cover = obj.optString("videoCover", "");
                    if (!TextUtils.isEmpty(cover) && pathMap.containsKey(cover)) {
                        String url = pathMap.get(cover);
                        if (!TextUtils.isEmpty(url)) obj.put("videoCover", url);
                    }
                }
            }
            return array.toString();
        } catch (Exception e) {
            android.util.Log.e("WKSendMsgUtils", "replaceNoteMediaPaths error: " + e.getMessage());
            return blockListJson;
        }
    }

    /**
     * 以 multipart POST 方式把附件上传到业务服务（服务端再写入 MinIO）。
     * 上传成功后服务端返回存储相对路径（file/preview/chat/...），写入消息 url；
     * 接收端通过 WKApiConfig.getShowUrl() 直连对象存储加载。
     */
    private void doUploadFile(WKMsg msg, String localPath, WKMediaMessageContent contentModel, IUploadAttacResultListener listener) {
        WKUploader.getInstance().uploadPresign(msg.channelID, msg.channelType, localPath, msg.clientSeq, new WKUploader.IUploadBack() {
            @Override
            public void onSuccess(String returnedPath) {
                if (TextUtils.isEmpty(returnedPath)) {
                    listener.onUploadResult(false, contentModel);
                    return;
                }
                contentModel.url = returnedPath;
                trackUploadedMsg(msg.clientMsgNO);
                scheduleRetryCheck(msg.clientMsgNO);
                listener.onUploadResult(true, contentModel);
            }

            @Override
            public void onError() {
                listener.onUploadResult(false, contentModel);
            }
        });
    }

    /**
     * 上传视频本体（封面已上传完成后调用）
     */
    private void uploadVideoBody(WKMsg msg, WKVideoContent videoMsgModel, IUploadAttacResultListener listener) {
        if (TextUtils.isEmpty(videoMsgModel.localPath)) {
            listener.onUploadResult(false, videoMsgModel);
            return;
        }
        WKUploader.getInstance().getUploadFileUrl(msg.channelID, msg.channelType, videoMsgModel.localPath, (uploadUrl, requestPath) -> {
            if (TextUtils.isEmpty(uploadUrl)) {
                listener.onUploadResult(false, videoMsgModel);
                return;
            }
            WKUploader.getInstance().upload(uploadUrl, videoMsgModel.localPath, msg.clientSeq, new WKUploader.IUploadBack() {
                @Override
                public void onSuccess(String returnedPath) {
                    if (TextUtils.isEmpty(returnedPath)) {
                        listener.onUploadResult(false, videoMsgModel);
                        return;
                    }
                    videoMsgModel.url = returnedPath;
                    trackUploadedMsg(msg.clientMsgNO);
                    scheduleRetryCheck(msg.clientMsgNO);
                    listener.onUploadResult(true, videoMsgModel);
                }

                @Override
                public void onError() {
                    listener.onUploadResult(false, videoMsgModel);
                }
            });
        });
    }

    /**
     * HLS/COS上传失败时，回退到MinIO预签名直传单个MP4文件
     */
    private void fallbackToMinioPresign(WKMsg msg, String videoPath, Object uploadTag,
                                        WKVideoContent videoMsgModel,
                                        boolean[] coverDone, boolean[] videoDone,
                                        boolean[] coverFailed, boolean[] videoFailed,
                                        String clientMsgNO,
                                        IUploadAttacResultListener listener) {
        WKUploader.getInstance().uploadPresign(msg.channelID, msg.channelType,
                videoPath, uploadTag, new WKUploader.IUploadBack() {
                    @Override
                    public void onSuccess(String returnedPath) {
                        if (!TextUtils.isEmpty(returnedPath)) {
                            videoMsgModel.url = returnedPath;
                        } else {
                            videoFailed[0] = true;
                        }
                        videoDone[0] = true;
                        checkParallelUploadDone(coverDone, videoDone, coverFailed, videoFailed, clientMsgNO, videoMsgModel, listener);
                    }

                    @Override
                    public void onError() {
                        videoFailed[0] = true;
                        videoDone[0] = true;
                        checkParallelUploadDone(coverDone, videoDone, coverFailed, videoFailed, clientMsgNO, videoMsgModel, listener);
                    }
                });
    }

    private void checkParallelUploadDone(boolean[] coverDone, boolean[] videoDone,
                                         boolean[] coverFailed, boolean[] videoFailed,
                                         String clientMsgNO,
                                         WKVideoContent videoMsgModel,
                                         IUploadAttacResultListener listener) {
        if (coverDone[0] && videoDone[0]) {
            boolean success = !coverFailed[0] && !videoFailed[0];
            if (success) {
                trackUploadedMsg(clientMsgNO);
                scheduleRetryCheck(clientMsgNO);
            }
            listener.onUploadResult(success, videoMsgModel);
        }
    }
}
