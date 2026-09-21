package com.chat.uikit.note;

import android.content.Intent;
import android.net.Uri;
import android.text.TextUtils;
import android.view.View;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.contacts.ChooseContactsActivity;
import com.chat.uikit.favorite.DetailImgActivity;
import com.chat.uikit.databinding.ActNotePreviewLayoutBinding;
import com.chat.uikit.chat.msgmodel.WKNoteContent;
import com.chat.uikit.chat.manager.WKSendMsgUtils;
import com.chat.uikit.chat.manager.SendMsgEntity;
import com.xinbida.wukongim.entity.WKChannel;
import com.xinbida.wukongim.entity.WKSendOptions;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.ArrayList;
import java.util.List;

import androidx.recyclerview.widget.LinearLayoutManager;

/**
 * 笔记详情页面
 */
public class NotePreviewActivity extends WKBaseActivity<ActNotePreviewLayoutBinding> {

    public static final String KEY_NOTE_ID = "note_id";
    public static final String KEY_NOTE_TITLE = "note_title";
    public static final String KEY_NOTE_CONTENT = "note_content";
    public static final String KEY_NOTE_GROUP = "note_group";
    public static final String KEY_NOTE_TIME = "note_time";
    public static final String KEY_NOTE_REMARK = "note_remark";
    public static final String KEY_BLOCK_LIST_JSON = "block_list_json";
    public static final int REQUEST_CODE_EDIT = 2001;
    public static final int REQUEST_CODE_SHARE = 2002;

    private String noteId;
    private String currentGroup;
    private String currentTime;
    private String currentTitle;
    private String currentContent;
    private String currentBlockListJson;
    private List<NoteBlock> blockList = new ArrayList<>();
    private NotePreviewBlockAdapter blockAdapter;
    private boolean isSending = false;
    private boolean isReceivedNote = false;

    @Override
    protected ActNotePreviewLayoutBinding getViewBinding() {
        return ActNotePreviewLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(android.widget.TextView titleTv) {
    }

    @Override
    protected void initPresenter() {
        Intent intent = getIntent();
        noteId = intent.getStringExtra(KEY_NOTE_ID);
        currentGroup = intent.getStringExtra(KEY_NOTE_GROUP);
        currentTime = intent.getStringExtra(KEY_NOTE_TIME);
        currentTitle = intent.getStringExtra(KEY_NOTE_TITLE);
        currentContent = intent.getStringExtra(KEY_NOTE_CONTENT);
        String blockListJson = intent.getStringExtra(KEY_BLOCK_LIST_JSON);

        if (TextUtils.isEmpty(currentGroup)) {
            currentGroup = "未分组";
        }

        if (!TextUtils.isEmpty(noteId)) {
            NoteEntity note = NoteStorageManager.getInstance(this).getNote(noteId);
            if (note != null) {
                currentGroup = note.groupName;
                currentTime = note.time;
                currentTitle = note.title;
                currentContent = note.content;
                if (!TextUtils.isEmpty(note.blockListJson)) {
                    blockListJson = note.blockListJson;
                }
            } else {
                isReceivedNote = true;
            }
        } else {
            isReceivedNote = true;
        }

        currentBlockListJson = blockListJson;

        if (!TextUtils.isEmpty(blockListJson)) {
            blockList = parseBlockListFromJson(blockListJson);
        }
        if (blockList.isEmpty()) {
            if (!TextUtils.isEmpty(currentTitle)) {
                NoteBlock titleBlock = NoteBlock.createTitle();
                titleBlock.content = currentTitle;
                blockList.add(titleBlock);
            }
            if (!TextUtils.isEmpty(currentContent)) {
                NoteBlock textBlock = NoteBlock.createText();
                textBlock.content = currentContent;
                blockList.add(textBlock);
            }
        }
    }

    @Override
    protected void initView() {
        initStatusBarPadding();
        LinearLayoutManager layoutManager = new LinearLayoutManager(this);
        wkVBinding.blockRecyclerView.setLayoutManager(layoutManager);
        blockAdapter = new NotePreviewBlockAdapter(blockList);
        wkVBinding.blockRecyclerView.setAdapter(blockAdapter);

        if (isReceivedNote) {
            wkVBinding.saveIv.setVisibility(View.VISIBLE);
        }
    }

    private void initStatusBarPadding() {
        int statusBarHeight = 0;
        int resourceId = getResources().getIdentifier("status_bar_height", "dimen", "android");
        if (resourceId > 0) {
            statusBarHeight = getResources().getDimensionPixelSize(resourceId);
        }
        if (statusBarHeight < dp2px(24)) {
            statusBarHeight = dp2px(24);
        }
        androidx.constraintlayout.widget.ConstraintLayout.LayoutParams params =
                (androidx.constraintlayout.widget.ConstraintLayout.LayoutParams) wkVBinding.titleLayout.getLayoutParams();
        params.topMargin = statusBarHeight;
        wkVBinding.titleLayout.setLayoutParams(params);
    }

    private int dp2px(float dp) {
        return (int) (dp * getResources().getDisplayMetrics().density + 0.5f);
    }

    @Override
    protected void initListener() {
        wkVBinding.backIv.setOnClickListener(v -> {
            finish();
            overridePendingTransition(R.anim.in_left, R.anim.out_right);
        });

        // 分享按钮 - 跳转到联系人选择页面，选中后直接发送
        wkVBinding.shareIv.setOnClickListener(v -> {
            Intent intent = new Intent(NotePreviewActivity.this, ChooseContactsActivity.class);
            intent.putExtra("type", 2);
            intent.putExtra("chooseBack", true);
            startActivityForResult(intent, REQUEST_CODE_SHARE);
            overridePendingTransition(R.anim.in_right, R.anim.out_left);
        });

        // 保存到我的笔记按钮
        wkVBinding.saveIv.setOnClickListener(v -> {
            saveToMyNotes();
        });

        blockAdapter.setOnBlockClickListener(new NotePreviewBlockAdapter.OnBlockClickListener() {
            @Override
            public void onImageClick(String imagePath) {
                if (!TextUtils.isEmpty(imagePath)) {
                    viewImage(imagePath);
                }
            }

            @Override
            public void onVideoClick(String videoPath, String videoCover) {
                if (!TextUtils.isEmpty(videoPath)) {
                    playVideo(videoPath);
                }
            }

            @Override
            public void onLocationClick(NoteBlock block) {
                openLocationDetail(block);
            }
        });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (resultCode == RESULT_OK && data != null) {
            if (requestCode == REQUEST_CODE_SHARE) {
                if (isSending) return;
                isSending = true;
                final ArrayList<String> channelIds = data.getStringArrayListExtra("selectedChannelIds");
                final ArrayList<Integer> channelTypeInts = data.getIntegerArrayListExtra("selectedChannelTypes");
                if (channelIds != null && !channelIds.isEmpty() && channelTypeInts != null) {
                    final String blockListJson = currentBlockListJson != null ? currentBlockListJson : "";

                    // 收集所有本地图片、视频、视频封面路径
                    final List<String> localImagePaths = new ArrayList<>();
                    final List<String> localVideoPaths = new ArrayList<>();
                    final List<String> localVideoCoverPaths = new ArrayList<>();
                    try {
                        org.json.JSONArray array = new org.json.JSONArray(blockListJson);
                        for (int i = 0; i < array.length(); i++) {
                            org.json.JSONObject obj = array.optJSONObject(i);
                            if (obj != null) {
                                int blockType = obj.optInt("type", -1);
                                if (blockType == 3) { // 图片块
                                    String imagePath = obj.optString("imagePath", "");
                                    if (TextUtils.isEmpty(imagePath)) {
                                        imagePath = obj.optString("path", "");
                                    }
                                    if (!TextUtils.isEmpty(imagePath)
                                            && !imagePath.startsWith("http://")
                                            && !imagePath.startsWith("https://")) {
                                        localImagePaths.add(imagePath);
                                    }
                                } else if (blockType == 4) { // 视频块
                                    String videoPath = obj.optString("videoPath", "");
                                    if (!TextUtils.isEmpty(videoPath)
                                            && !videoPath.startsWith("http://")
                                            && !videoPath.startsWith("https://")) {
                                        localVideoPaths.add(videoPath);
                                    }
                                    String coverPath = obj.optString("videoCover", "");
                                    if (!TextUtils.isEmpty(coverPath)
                                            && !coverPath.startsWith("http://")
                                            && !coverPath.startsWith("https://")) {
                                        localVideoCoverPaths.add(coverPath);
                                    }
                                }
                            }
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }

                    // 如果没有本地媒体需要上传，直接发送
                    if (localImagePaths.isEmpty() && localVideoPaths.isEmpty() && localVideoCoverPaths.isEmpty()) {
                        doShareNote(channelIds, channelTypeInts, blockListJson);
                        return;
                    }

                    // 先压缩图片，再上传所有媒体文件后发送
                    compressAndUploadMediaForShare(blockListJson, localImagePaths, localVideoPaths, localVideoCoverPaths,
                            new IUploadNoteImagesCallback() {
                                @Override
                                public void onComplete(String newBlockListJson) {
                                    doShareNote(channelIds, channelTypeInts, newBlockListJson);
                                }
                            });
                }
            } else if (requestCode == REQUEST_CODE_EDIT) {
                if (!TextUtils.isEmpty(noteId)) {
                    NoteEntity note = NoteStorageManager.getInstance(this).getNote(noteId);
                    if (note != null) {
                        currentGroup = note.groupName;
                        currentTime = note.time;
                        currentTitle = note.title;
                        currentContent = note.content;
                        if (!TextUtils.isEmpty(note.blockListJson)) {
                            currentBlockListJson = note.blockListJson;
                            blockList.clear();
                            blockList.addAll(parseBlockListFromJson(note.blockListJson));
                        }
                        blockAdapter.notifyDataSetChanged();
                    }
                }
            }
        }
    }

    private void viewImage(String imagePath) {
        if (TextUtils.isEmpty(imagePath)) {
            WKToastUtils.getInstance().showToastNormal("图片路径为空");
            return;
        }
        Intent intent = new Intent(this, com.chat.uikit.favorite.DetailImgActivity.class);
        intent.putExtra(DetailImgActivity.KEY_IMG_URL, imagePath);
        startActivity(intent);
        overridePendingTransition(R.anim.in_right, R.anim.out_left);
    }

    private void playVideo(String videoPath) {
        if (TextUtils.isEmpty(videoPath)) {
            WKToastUtils.getInstance().showToastNormal("视频路径为空");
            return;
        }
        Intent intent = new Intent(this, com.chat.base.act.PlayVideoActivity.class);
        intent.putExtra("url", videoPath);
        startActivity(intent);
        overridePendingTransition(R.anim.in_right, R.anim.out_left);
    }

    private void openLocationDetail(NoteBlock block) {
        if (block == null || block.latitude == 0 || block.longitude == 0) {
            return;
        }
        Intent intent = new Intent(this, com.chat.uikit.location.LocationDetailActivity.class);
        intent.putExtra(com.chat.uikit.location.LocationDetailActivity.EXTRA_LATITUDE, block.latitude);
        intent.putExtra(com.chat.uikit.location.LocationDetailActivity.EXTRA_LONGITUDE, block.longitude);
        intent.putExtra(com.chat.uikit.location.LocationDetailActivity.EXTRA_TITLE, block.locationName);
        intent.putExtra(com.chat.uikit.location.LocationDetailActivity.EXTRA_ADDRESS, block.locationAddress);
        startActivity(intent);
        overridePendingTransition(R.anim.in_right, R.anim.out_left);
    }

    private List<NoteBlock> parseBlockListFromJson(String json) {
        List<NoteBlock> blocks = new ArrayList<>();
        if (TextUtils.isEmpty(json)) {
            return blocks;
        }
        try {
            org.json.JSONArray array = new org.json.JSONArray(json);
            for (int i = 0; i < array.length(); i++) {
                org.json.JSONObject obj = array.getJSONObject(i);
                int type = obj.optInt("type", NoteBlock.TYPE_TEXT);
                NoteBlock block = new NoteBlock(type);
                block.content = obj.optString("content", "");
                block.imagePath = obj.optString("imagePath", "");
                block.videoPath = obj.optString("videoPath", "");
                block.videoCover = obj.optString("videoCover", "");
                block.locationName = obj.optString("locationName", "");
                block.locationAddress = obj.optString("locationAddress", "");
                block.latitude = obj.optDouble("latitude", 0);
                block.longitude = obj.optDouble("longitude", 0);
                blocks.add(block);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return blocks;
    }

    /**
     * 先压缩所有本地图片，再上传所有媒体文件（图片、视频、视频封面）
     */
    private void compressAndUploadMediaForShare(final String blockListJson,
                                                final List<String> localImagePaths,
                                                final List<String> localVideoPaths,
                                                final List<String> localVideoCoverPaths,
                                                final IUploadNoteImagesCallback callback) {
        final java.util.Map<String, String> compressMap = new java.util.concurrent.ConcurrentHashMap<>();
        final int totalImageCount = localImagePaths.size();
        final int[] completedCount = {0};

        if (totalImageCount == 0) {
            // 没有图片需要压缩，直接上传所有媒体
            uploadAllMediaForShare(blockListJson, localImagePaths, compressMap, localVideoPaths, localVideoCoverPaths, callback);
            return;
        }

        for (final String originalPath : localImagePaths) {
            java.util.List<String> singlePath = new java.util.ArrayList<>();
            singlePath.add(originalPath);
            com.chat.base.glide.GlideUtils.getInstance().compressImg(this, singlePath, new com.chat.base.glide.GlideUtils.ICompressListener() {
                @Override
                public void onResult(java.util.List<java.io.File> files) {
                    if (files != null && files.size() > 0 && files.get(0) != null
                            && files.get(0).exists() && files.get(0).length() > 0) {
                        compressMap.put(originalPath, files.get(0).getAbsolutePath());
                    } else {
                        compressMap.put(originalPath, originalPath);
                    }
                    synchronized (completedCount) {
                        completedCount[0]++;
                        if (completedCount[0] == totalImageCount) {
                            uploadAllMediaForShare(blockListJson, localImagePaths, compressMap, localVideoPaths, localVideoCoverPaths, callback);
                        }
                    }
                }
            });
        }
    }

    /**
     * 上传所有本地媒体文件（图片、视频、视频封面），完成后回调
     */
    private void uploadAllMediaForShare(final String blockListJson,
                                        List<String> localImagePaths, final java.util.Map<String, String> compressMap,
                                        List<String> localVideoPaths, List<String> localVideoCoverPaths,
                                        final IUploadNoteImagesCallback callback) {
        final java.util.Map<String, String> pathMap = new java.util.concurrent.ConcurrentHashMap<>();
        final int imageCount = localImagePaths.size();
        final int videoCount = localVideoPaths.size();
        final int coverCount = localVideoCoverPaths.size();
        final int totalCount = imageCount + videoCount + coverCount;
        final int[] completedCount = {0};

        String cosImageUrl = com.chat.base.config.WKApiConfig.baseUrl + "upload/image";
        String cosFileUrl = com.chat.base.config.WKApiConfig.baseUrl + "upload/file";

        // 上传图片（走图片压缩接口）
        for (final String originalPath : localImagePaths) {
            final String uploadPath = compressMap.containsKey(originalPath) ? compressMap.get(originalPath) : originalPath;
            com.chat.base.net.ud.WKUploader.getInstance().upload(
                    cosImageUrl, uploadPath, uploadPath,
                    new com.chat.base.net.ud.WKUploader.IUploadBack() {
                        @Override
                        public void onSuccess(String remoteUrl) {
                            pathMap.put(originalPath, remoteUrl);
                            checkAndCallback();
                        }
                        @Override
                        public void onError() { checkAndCallback(); }
                        private void checkAndCallback() {
                            synchronized (completedCount) {
                                completedCount[0]++;
                                if (completedCount[0] == totalCount) {
                                    String newJson = replaceMediaPathsInBlockList(blockListJson, pathMap);
                                    callback.onComplete(newJson);
                                }
                            }
                        }
                    });
        }

        // 上传视频封面图（走图片接口）
        for (final String coverPath : localVideoCoverPaths) {
            com.chat.base.net.ud.WKUploader.getInstance().upload(
                    cosImageUrl, coverPath, coverPath,
                    new com.chat.base.net.ud.WKUploader.IUploadBack() {
                        @Override
                        public void onSuccess(String remoteUrl) {
                            pathMap.put(coverPath, remoteUrl);
                            checkAndCallback();
                        }
                        @Override
                        public void onError() { checkAndCallback(); }
                        private void checkAndCallback() {
                            synchronized (completedCount) {
                                completedCount[0]++;
                                if (completedCount[0] == totalCount) {
                                    String newJson = replaceMediaPathsInBlockList(blockListJson, pathMap);
                                    callback.onComplete(newJson);
                                }
                            }
                        }
                    });
        }

        // 上传视频文件（走通用文件接口）
        for (final String videoPath : localVideoPaths) {
            com.chat.base.net.ud.WKUploader.getInstance().upload(
                    cosFileUrl, videoPath, videoPath,
                    new com.chat.base.net.ud.WKUploader.IUploadBack() {
                        @Override
                        public void onSuccess(String remoteUrl) {
                            pathMap.put(videoPath, remoteUrl);
                            checkAndCallback();
                        }
                        @Override
                        public void onError() { checkAndCallback(); }
                        private void checkAndCallback() {
                            synchronized (completedCount) {
                                completedCount[0]++;
                                if (completedCount[0] == totalCount) {
                                    String newJson = replaceMediaPathsInBlockList(blockListJson, pathMap);
                                    callback.onComplete(newJson);
                                }
                            }
                        }
                    });
        }
    }

    /**
     * 替换 blockListJson 中的本地图片和视频路径为网络 URL
     */
    private String replaceMediaPathsInBlockList(String blockListJson, java.util.Map<String, String> pathMap) {
        try {
            org.json.JSONArray array = new org.json.JSONArray(blockListJson);
            for (int i = 0; i < array.length(); i++) {
                org.json.JSONObject obj = array.optJSONObject(i);
                if (obj != null) {
                    int blockType = obj.optInt("type", -1);
                    if (blockType == 3) { // 图片块
                        String imagePath = obj.optString("imagePath", "");
                        if (TextUtils.isEmpty(imagePath)) {
                            imagePath = obj.optString("path", "");
                        }
                        if (!TextUtils.isEmpty(imagePath) && pathMap.containsKey(imagePath)) {
                            String remoteUrl = pathMap.get(imagePath);
                            if (!TextUtils.isEmpty(remoteUrl)) {
                                obj.put("imagePath", remoteUrl);
                                obj.put("path", remoteUrl);
                            }
                        }
                    } else if (blockType == 4) { // 视频块
                        String videoPath = obj.optString("videoPath", "");
                        if (!TextUtils.isEmpty(videoPath) && pathMap.containsKey(videoPath)) {
                            String remoteUrl = pathMap.get(videoPath);
                            if (!TextUtils.isEmpty(remoteUrl)) {
                                obj.put("videoPath", remoteUrl);
                            }
                        }
                        String coverPath = obj.optString("videoCover", "");
                        if (!TextUtils.isEmpty(coverPath) && pathMap.containsKey(coverPath)) {
                            String remoteUrl = pathMap.get(coverPath);
                            if (!TextUtils.isEmpty(remoteUrl)) {
                                obj.put("videoCover", remoteUrl);
                            }
                        }
                    }
                }
            }
            return array.toString();
        } catch (Exception e) {
            e.printStackTrace();
            return blockListJson;
        }
    }

    /**
     * 保存收到的笔记到自己的笔记列表
     */
    private void saveToMyNotes() {
        NoteEntity note = new NoteEntity();
        note.id = "note_" + System.currentTimeMillis();
        note.title = currentTitle != null ? currentTitle : "未命名笔记";
        note.content = currentContent != null ? currentContent : "";
        note.groupName = "未分组";
        note.time = getCurrentTime();
        note.blockListJson = currentBlockListJson != null ? currentBlockListJson : "";
        NoteStorageManager.getInstance(this).saveNote(note);

        noteId = note.id;
        isReceivedNote = false;
        wkVBinding.saveIv.setVisibility(View.GONE);

        WKToastUtils.getInstance().showToastNormal("已保存到我的笔记");
    }

    private String getCurrentTime() {
        java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm", java.util.Locale.getDefault());
        return sdf.format(new java.util.Date());
    }

    /**
     * 实际执行分享笔记到多个联系人
     */
    private void doShareNote(ArrayList<String> channelIds, ArrayList<Integer> channelTypeInts, String blockListJson) {
        // 构造笔记消息内容
        WKNoteContent noteContent = new WKNoteContent(
                noteId != null ? noteId : "",
                currentTitle != null ? currentTitle : "",
                currentContent != null ? currentContent : "",
                currentGroup != null ? currentGroup : "",
                currentTime != null ? currentTime : "",
                blockListJson);

        // 发送到每个选中的联系人
        List<SendMsgEntity> msgList = new ArrayList<>();
        for (int i = 0; i < channelIds.size(); i++) {
            byte chType = (byte) (int) channelTypeInts.get(i);
            WKChannel channel = new WKChannel(channelIds.get(i), chType);
            WKSendOptions options = new WKSendOptions();
            msgList.add(new SendMsgEntity(noteContent, channel, options));
        }
        WKSendMsgUtils.getInstance().sendMessages(msgList);

        // 跳转到最后一个联系人的聊天窗口
        String lastChannelId = channelIds.get(channelIds.size() - 1);
        byte lastChannelType = (byte) (int) channelTypeInts.get(channelTypeInts.size() - 1);
        Intent chatIntent = new Intent(this, com.chat.uikit.chat.ChatActivity.class);
        chatIntent.putExtra("channelId", lastChannelId);
        chatIntent.putExtra("channelType", lastChannelType);
        chatIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        startActivity(chatIntent);
        WKToastUtils.getInstance().showToastNormal("已分享给" + channelIds.size() + "位联系人");
        finish();
    }

    /**
     * 笔记图片上传回调接口
     */
    private interface IUploadNoteImagesCallback {
        void onComplete(String newBlockListJson);
    }
}
