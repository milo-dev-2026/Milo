package com.chat.uikit.note;

import android.content.Intent;
import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.kotlin.view.CustomTitleBar;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActNoteListLayoutBinding;

import java.util.ArrayList;
import java.util.List;

import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

/**
 * 笔记列表页面
 */
public class NoteListActivity extends WKBaseActivity<ActNoteListLayoutBinding> {

    public static final int REQUEST_CODE_EDIT = 1001;
    public static final int REQUEST_CODE_DETAIL = 1002;
    private static final String SP_KEY_FOLDERS = "note_folders";

    private List<String> tabList = new ArrayList<>();
    private List<NoteEntity> noteList = new ArrayList<>();
    private NoteTabAdapter tabAdapter;
    private NoteListAdapter noteAdapter;
    private NoteTabItemTouchHelperCallback tabTouchHelperCallback;
    private int currentTab = 0;
    private boolean isSelectAll = false;
    private boolean isTabSortMode = false;
    private boolean ignoreNextClick = false;
    private String channelId;
    private byte channelType;
    private boolean isShareMode = false;

    @Override
    protected ActNoteListLayoutBinding getViewBinding() {
        return ActNoteListLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        // 使用 CustomTitleBar，这里不使用默认标题栏
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        // 适配状态栏高度（灵动岛/刘海屏）
        initStatusBarPadding();

        // 检查是否从聊天工具栏启动
        Intent intent = getIntent();
        channelId = intent.getStringExtra("channelId");
        channelType = intent.getByteExtra("channelType", (byte) 0);
        isShareMode = channelId != null && !channelId.isEmpty();

        // 初始化CustomTitleBar
        CustomTitleBar titleBar = wkVBinding.titleBar;
        titleBar.setTitleText(getString(R.string.note_share));
        // 设置右侧按钮文字大小
        titleBar.getRightBtn3Tv().setTextSize(20f);
        titleBar.setBackClickListener(v -> {
            if (noteAdapter != null && noteAdapter.isSelectMode()) {
                noteAdapter.setSelectMode(false);
                wkVBinding.titleBar.setRightBtn3Text("分享");
            } else {
                finish();
                overridePendingTransition(R.anim.in_left, R.anim.out_right);
            }
        });

        if (isShareMode) {
            // 聊天工具栏启动：显示"分享"按钮
            titleBar.setRightBtn3Text("分享");
            titleBar.setRightBtn3ClickListener(v -> toggleShareMode());
        } else {
            // 个人中心启动：显示"全选"按钮
            titleBar.setRightBtn3Text(getString(R.string.select_all));
            titleBar.setRightBtn3ClickListener(v -> toggleSelectAll());
        }

        // 初始化Tab
        initTabList();
        LinearLayoutManager tabLayoutManager = new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false);
        wkVBinding.tabRecyclerView.setLayoutManager(tabLayoutManager);
        tabAdapter = new NoteTabAdapter(tabList);
        wkVBinding.tabRecyclerView.setAdapter(tabAdapter);

        // 初始化笔记列表
        LinearLayoutManager noteLayoutManager = new LinearLayoutManager(this);
        wkVBinding.noteRecyclerView.setLayoutManager(noteLayoutManager);
        noteAdapter = new NoteListAdapter(noteList);
        wkVBinding.noteRecyclerView.setAdapter(noteAdapter);

        // 加载笔记数据
        loadNotes();
    }

    @Override
    protected void onResume() {
        super.onResume();
        // 刷新分组标签列表（分组管理页修改后同步）
        refreshTabList();
        loadNotes();
    }

    @Override
    protected void initListener() {
        // Tab切换
        tabAdapter.setOnTabClickListener(position -> {
            currentTab = position;
            tabAdapter.setSelectPosition(position);
            filterNotesByGroup(tabList.get(position));
        });

        // Tab拖拽开始回调
        tabAdapter.setOnDragStartListener(viewHolder -> {
            if (tabTouchHelperCallback != null) {
                tabTouchHelperCallback.startDrag(viewHolder);
            }
        });

        // 笔记点击
        noteAdapter.setOnItemClickListener(position -> {
            NoteEntity note = noteList.get(position);
            Intent intent = new Intent(NoteListActivity.this, NotePreviewActivity.class);
            intent.putExtra(NotePreviewActivity.KEY_NOTE_ID, note.id);
            intent.putExtra(NotePreviewActivity.KEY_NOTE_TITLE, note.title);
            intent.putExtra(NotePreviewActivity.KEY_NOTE_CONTENT, note.content);
            intent.putExtra(NotePreviewActivity.KEY_NOTE_GROUP, note.groupName);
            intent.putExtra(NotePreviewActivity.KEY_NOTE_TIME, note.time);
            intent.putExtra(NotePreviewActivity.KEY_NOTE_REMARK, note.remark);
            startActivityForResult(intent, REQUEST_CODE_DETAIL);
            overridePendingTransition(R.anim.in_right, R.anim.out_left);
        });

        // 更多操作
        noteAdapter.setOnItemMoreClickListener(position -> {
            NoteEntity note = noteList.get(position);
            showNoteMoreDialog(note, position);
        });

        // 搜索 - 实时搜索
        wkVBinding.searchEditText.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                searchNotes(s != null ? s.toString().trim() : "");
            }

            @Override
            public void afterTextChanged(Editable s) {
            }
        });

        // 搜索按钮
        wkVBinding.searchBtn.setOnClickListener(v -> {
            String keyword = wkVBinding.searchEditText.getText().toString().trim();
            searchNotes(keyword);
        });

        // 分组管理按钮
        wkVBinding.moreIv.setOnClickListener(v -> {
            android.util.Log.d("NoteListTabSort", "moreIv onClick, isTabSortMode=" + isTabSortMode + ", ignoreNextClick=" + ignoreNextClick);
            if (ignoreNextClick) {
                ignoreNextClick = false;
                android.util.Log.d("NoteListTabSort", "忽略本次点击");
                return;
            }
            if (isTabSortMode) {
                // 排序模式下点击退出排序
                toggleTabSortMode();
            } else {
                startActivity(new Intent(NoteListActivity.this, NoteFolderManagerActivity.class));
                overridePendingTransition(R.anim.in_right, R.anim.out_left);
            }
        });

        // 长按三横按钮进入标签排序模式
        wkVBinding.moreIv.setOnLongClickListener(v -> {
            android.util.Log.d("NoteListTabSort", "moreIv onLongClick, isTabSortMode=" + isTabSortMode);
            if (!isTabSortMode) {
                toggleTabSortMode();
                ignoreNextClick = true; // 标记忽略下一次点击（长按抬起会触发click）
            }
            return true;
        });

        // 新建笔记按钮
        wkVBinding.fabCreate.setOnClickListener(v -> {
            Intent intent = new Intent(NoteListActivity.this, NoteEditActivity.class);
            intent.putExtra(NoteEditActivity.KEY_GROUP_NAME, tabList.get(currentTab));
            startActivityForResult(intent, REQUEST_CODE_EDIT);
            overridePendingTransition(R.anim.in_right, R.anim.out_left);
        });

        // 长按新建按钮也可进入分组管理（保留原交互）
        wkVBinding.fabCreate.setOnLongClickListener(v -> {
            startActivity(new Intent(NoteListActivity.this, NoteFolderManagerActivity.class));
            overridePendingTransition(R.anim.in_right, R.anim.out_left);
            return true;
        });
    }

    /**
     * 切换分享模式
     * 第一次点击"分享"进入选择模式，按钮变为"确定"
     * 点击"确定"发送选中的笔记到聊天会话
     */
    private boolean isSending = false;

    private void toggleShareMode() {
        android.util.Log.e("NoteListActivity", "toggleShareMode called, isSelectMode=" + noteAdapter.isSelectMode());
        if (!noteAdapter.isSelectMode()) {
            // 进入选择模式
            noteAdapter.setSelectMode(true);
            wkVBinding.titleBar.setRightBtn3Text("确定");
        } else {
            if (isSending) return;
            isSending = true;
            // 点击确定，发送选中的笔记
            List<Integer> selectedPositions = noteAdapter.getSelectedPositions();
            if (selectedPositions.isEmpty()) {
                WKToastUtils.getInstance().showToastNormal("请选择要分享的笔记");
                isSending = false;
                return;
            }
            // 发送选中的笔记到聊天会话
            for (int pos : selectedPositions) {
                if (pos >= 0 && pos < noteList.size()) {
                    NoteEntity note = noteList.get(pos);
                    sendNoteToChat(note);
                }
            }
            WKToastUtils.getInstance().showToastNormal("已分享" + selectedPositions.size() + "条笔记");
            finish();
            overridePendingTransition(R.anim.in_left, R.anim.out_right);
        }
    }

    /**
     * 发送笔记到聊天会话
     * 发送前先上传笔记中的所有本地图片，替换为网络 URL 后再发送
     */
    private void sendNoteToChat(NoteEntity note) {
        try {
            android.util.Log.e("NoteListActivity", "sendNoteToChat: noteId=" + note.id + ", title=" + note.title);
            String blockListJson = note.blockListJson != null ? note.blockListJson : "";
            // 直接发送笔记消息，不等待图片压缩上传
            // 参考utalk逻辑：先保存消息到数据库并显示，附件异步处理
            doSendNote(note, blockListJson);
        } catch (Exception e) {
            android.util.Log.e("NoteListActivity", "sendNoteToChat: exception: " + e.getMessage(), e);
        }
    }

    /**
     * 先压缩所有本地图片，再上传图片和视频并发送
     */
    private void compressNoteImagesAndSend(final NoteEntity note, final String blockListJson,
                                           final java.util.List<String> localImagePaths,
                                           final java.util.List<String> localVideoPaths,
                                           final java.util.List<String> localVideoCoverPaths) {
        final java.util.Map<String, String> compressMap = new java.util.concurrent.ConcurrentHashMap<>();
        final int totalCount = localImagePaths.size();
        final int[] completedCount = {0};

        if (totalCount == 0) {
            // 没有图片需要压缩，直接上传视频
            uploadNoteMediaAndSend(note, blockListJson, localImagePaths, compressMap, localVideoPaths, localVideoCoverPaths);
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
                        if (completedCount[0] == totalCount) {
                            uploadNoteMediaAndSend(note, blockListJson, localImagePaths, compressMap, localVideoPaths, localVideoCoverPaths);
                        }
                    }
                }
            });
        }
    }

    /**
     * 上传笔记中的所有本地图片和视频，完成后发送消息
     */
    private void uploadNoteMediaAndSend(final NoteEntity note, final String blockListJson,
                                        java.util.List<String> localImagePaths, final java.util.Map<String, String> compressMap,
                                        java.util.List<String> localVideoPaths, java.util.List<String> localVideoCoverPaths) {
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
                            checkAndSend();
                        }
                        @Override
                        public void onError() { checkAndSend(); }
                        private void checkAndSend() {
                            synchronized (completedCount) {
                                completedCount[0]++;
                                if (completedCount[0] == totalCount) {
                                    String newJson = replaceMediaPathsInBlockList(blockListJson, pathMap);
                                    doSendNote(note, newJson);
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
                            checkAndSend();
                        }
                        @Override
                        public void onError() { checkAndSend(); }
                        private void checkAndSend() {
                            synchronized (completedCount) {
                                completedCount[0]++;
                                if (completedCount[0] == totalCount) {
                                    String newJson = replaceMediaPathsInBlockList(blockListJson, pathMap);
                                    doSendNote(note, newJson);
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
                            checkAndSend();
                        }
                        @Override
                        public void onError() { checkAndSend(); }
                        private void checkAndSend() {
                            synchronized (completedCount) {
                                completedCount[0]++;
                                if (completedCount[0] == totalCount) {
                                    String newJson = replaceMediaPathsInBlockList(blockListJson, pathMap);
                                    doSendNote(note, newJson);
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
                        if (android.text.TextUtils.isEmpty(imagePath)) {
                            imagePath = obj.optString("path", "");
                        }
                        if (!android.text.TextUtils.isEmpty(imagePath) && pathMap.containsKey(imagePath)) {
                            String remoteUrl = pathMap.get(imagePath);
                            if (!android.text.TextUtils.isEmpty(remoteUrl)) {
                                obj.put("imagePath", remoteUrl);
                                obj.put("path", remoteUrl);
                            }
                        }
                    } else if (blockType == 4) { // 视频块
                        String videoPath = obj.optString("videoPath", "");
                        if (!android.text.TextUtils.isEmpty(videoPath) && pathMap.containsKey(videoPath)) {
                            String remoteUrl = pathMap.get(videoPath);
                            if (!android.text.TextUtils.isEmpty(remoteUrl)) {
                                obj.put("videoPath", remoteUrl);
                            }
                        }
                        String coverPath = obj.optString("videoCover", "");
                        if (!android.text.TextUtils.isEmpty(coverPath) && pathMap.containsKey(coverPath)) {
                            String remoteUrl = pathMap.get(coverPath);
                            if (!android.text.TextUtils.isEmpty(remoteUrl)) {
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
     * 实际执行发送笔记消息
     */
    private void doSendNote(NoteEntity note, String blockListJson) {
        try {
            android.util.Log.e("NoteListActivity", "doSendNote: noteId=" + note.id + ", title=" + note.title
                    + ", channelId=" + channelId + ", channelType=" + channelType
                    + ", blockListJson length=" + (blockListJson != null ? blockListJson.length() : 0));
            com.chat.uikit.chat.msgmodel.WKNoteContent noteContent =
                    new com.chat.uikit.chat.msgmodel.WKNoteContent(
                            note.id != null ? note.id : "",
                            note.title != null ? note.title : "",
                            note.content != null ? note.content : "",
                            note.groupName != null ? note.groupName : "",
                            note.time != null ? note.time : "",
                            blockListJson);

            com.xinbida.wukongim.entity.WKChannel channel =
                    new com.xinbida.wukongim.entity.WKChannel(channelId, channelType);

            com.chat.uikit.chat.manager.SendMsgEntity sendEntity =
                    new com.chat.uikit.chat.manager.SendMsgEntity(noteContent, channel, new com.xinbida.wukongim.entity.WKSendOptions());
            java.util.List<com.chat.uikit.chat.manager.SendMsgEntity> list = new java.util.ArrayList<>();
            list.add(sendEntity);
            android.util.Log.e("NoteListActivity", "doSendNote: calling sendMessages, list size=" + list.size());
            com.chat.uikit.chat.manager.WKSendMsgUtils.getInstance().sendMessages(list);
            android.util.Log.e("NoteListActivity", "doSendNote: sendMessages returned");
        } catch (Exception e) {
            android.util.Log.e("NoteListActivity", "doSendNote: exception: " + e.getMessage(), e);
            e.printStackTrace();
        }
    }

    /**
     * 切换全选状态
     */
    private void toggleSelectAll() {
        isSelectAll = !isSelectAll;
        if (isSelectAll) {
            wkVBinding.titleBar.setRightBtn3Text("取消全选");
            WKToastUtils.getInstance().showToastNormal("已全选 " + noteList.size() + " 条笔记");
        } else {
            wkVBinding.titleBar.setRightBtn3Text(getString(R.string.note_select_all));
            WKToastUtils.getInstance().showToastNormal("已取消全选");
        }
        noteAdapter.setAllSelected(isSelectAll);
    }

    private void showNoteMoreDialog(NoteEntity note, int position) {
        String[] items = {"预览", "编辑", "添加备注", "移动到分组", note.isTop ? "取消置顶" : "置顶", "删除"};
        new androidx.appcompat.app.AlertDialog.Builder(this)
                .setTitle(note.title)
                .setItems(items, (dialog, which) -> {
                    Intent intent;
                    switch (which) {
                        case 0:
                            intent = new Intent(NoteListActivity.this, NotePreviewActivity.class);
                            intent.putExtra(NotePreviewActivity.KEY_NOTE_ID, note.id);
                            intent.putExtra(NotePreviewActivity.KEY_NOTE_TITLE, note.title);
                            intent.putExtra(NotePreviewActivity.KEY_NOTE_CONTENT, note.content);
                            intent.putExtra(NotePreviewActivity.KEY_NOTE_GROUP, note.groupName);
                            intent.putExtra(NotePreviewActivity.KEY_NOTE_TIME, note.time);
                            intent.putExtra(NotePreviewActivity.KEY_NOTE_REMARK, note.remark);
                            startActivityForResult(intent, 1003);
                            overridePendingTransition(R.anim.in_right, R.anim.out_left);
                            break;
                        case 1:
                            intent = new Intent(NoteListActivity.this, NoteEditActivity.class);
                            intent.putExtra(NoteEditActivity.KEY_NOTE_ID, note.id);
                            intent.putExtra(NoteEditActivity.KEY_NOTE_TITLE, note.title);
                            intent.putExtra(NoteEditActivity.KEY_NOTE_CONTENT, note.content);
                            startActivityForResult(intent, REQUEST_CODE_EDIT);
                            overridePendingTransition(R.anim.in_right, R.anim.out_left);
                            break;
                        case 2:
                            intent = new Intent(NoteListActivity.this, NoteRemarkActivity.class);
                            intent.putExtra(NoteRemarkActivity.KEY_NOTE_ID, note.id);
                            intent.putExtra(NoteRemarkActivity.KEY_NOTE_REMARK, note.remark);
                            startActivityForResult(intent, 1004);
                            overridePendingTransition(R.anim.in_right, R.anim.out_left);
                            break;
                        case 3:
                            // 移动到分组
                            showMoveGroupDialog(note, position);
                            break;
                        case 4:
                            note.isTop = !note.isTop;
                            NoteStorageManager.getInstance(NoteListActivity.this).toggleTop(note.id);
                            noteAdapter.notifyItemChanged(position);
                            WKToastUtils.getInstance().showToastNormal(note.isTop ? "已置顶" : "已取消置顶");
                            break;
                        case 5:
                            NoteStorageManager.getInstance(NoteListActivity.this).deleteNote(note.id);
                            noteList.remove(position);
                            noteAdapter.notifyItemRemoved(position);
                            WKToastUtils.getInstance().showToastNormal("已删除");
                            break;
                    }
                })
                .show();
    }

    /**
     * 初始化Tab分组
     */
    private void initTabList() {
        loadTabListFromStorage();
    }

    /**
     * 从存储加载分组列表
     */
    private void loadTabListFromStorage() {
        tabList.clear();
        tabList.add("全部");
        tabList.add("未分组");

        String json = com.chat.base.config.WKSharedPreferencesUtil.getInstance().getSP(SP_KEY_FOLDERS);
        if (json != null && !json.isEmpty()) {
            try {
                org.json.JSONArray array = new org.json.JSONArray(json);
                for (int i = 0; i < array.length(); i++) {
                    String name = array.getString(i);
                    if (!tabList.contains(name)) {
                        tabList.add(name);
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        // 默认分组
        if (tabList.size() <= 2) {
            tabList.add("工作");
            tabList.add("生活");
            tabList.add("学习");
            tabList.add("旅行");
            saveTabListToStorage();
        }
    }

    /**
     * 刷新分组标签列表
     */
    private void refreshTabList() {
        String currentTabName = currentTab < tabList.size() ? tabList.get(currentTab) : "全部";
        loadTabListFromStorage();
        tabAdapter.notifyDataSetChanged();

        // 恢复选中位置
        int newPosition = 0;
        for (int i = 0; i < tabList.size(); i++) {
            if (TextUtils.equals(tabList.get(i), currentTabName)) {
                newPosition = i;
                break;
            }
        }
        currentTab = newPosition;
        tabAdapter.setSelectPosition(newPosition);

        // 更新拖拽数据引用
        if (tabTouchHelperCallback != null) {
            tabTouchHelperCallback.setTabList(tabList);
        }
    }

    /**
     * 保存分组顺序到存储
     */
    private void saveTabListToStorage() {
        org.json.JSONArray array = new org.json.JSONArray();
        for (int i = 2; i < tabList.size(); i++) {
            array.put(tabList.get(i));
        }
        com.chat.base.config.WKSharedPreferencesUtil.getInstance().putSP(SP_KEY_FOLDERS, array.toString());
    }

    /**
     * 切换Tab排序模式
     */
    private void toggleTabSortMode() {
        isTabSortMode = !isTabSortMode;
        android.util.Log.d("NoteListTabSort", "toggleTabSortMode -> isTabSortMode=" + isTabSortMode);
        tabAdapter.setSortMode(isTabSortMode);
        if (isTabSortMode) {
            // 进入排序模式，绑定拖拽
            if (tabTouchHelperCallback == null) {
                tabTouchHelperCallback = new NoteTabItemTouchHelperCallback(tabAdapter, tabList);
                tabTouchHelperCallback.setOnTabSortListener(this::saveTabListToStorage);
            }
            tabTouchHelperCallback.attachToRecyclerView(wkVBinding.tabRecyclerView);
            // 排序模式下切换图标为完成文字
            wkVBinding.moreIv.setImageResource(android.R.drawable.ic_menu_save);
            WKToastUtils.getInstance().showToastNormal("长按标签可拖拽排序");
        } else {
            // 退出排序模式，解绑拖拽
            if (tabTouchHelperCallback != null) {
                tabTouchHelperCallback.detachFromRecyclerView();
            }
            // 恢复三横图标
            wkVBinding.moreIv.setImageResource(R.mipmap.ic_manager);
        }
    }

    /**
     * 从NoteStorageManager加载笔记数据
     */
    private void loadNotes() {
        noteList.clear();
        List<NoteEntity> stored = NoteStorageManager.getInstance(this).getAllNotes();
        // 排序：置顶优先，然后按时间倒序
        List<NoteEntity> topList = new ArrayList<>();
        List<NoteEntity> normalList = new ArrayList<>();
        for (NoteEntity note : stored) {
            if (note.isTop) {
                topList.add(note);
            } else {
                normalList.add(note);
            }
        }
        noteList.addAll(topList);
        noteList.addAll(normalList);
        noteAdapter.notifyDataSetChanged();
    }

    /**
     * 按分组筛选笔记
     */
    private void filterNotesByGroup(String group) {
        List<NoteEntity> allNotes = NoteStorageManager.getInstance(this).getAllNotes();
        noteList.clear();
        if (TextUtils.equals(group, "全部")) {
            List<NoteEntity> topList = new ArrayList<>();
            List<NoteEntity> normalList = new ArrayList<>();
            for (NoteEntity note : allNotes) {
                if (note.isTop) topList.add(note);
                else normalList.add(note);
            }
            noteList.addAll(topList);
            noteList.addAll(normalList);
        } else if (TextUtils.equals(group, "未分组")) {
            for (NoteEntity note : allNotes) {
                if (TextUtils.isEmpty(note.groupName) || TextUtils.equals(note.groupName, "未分组")) {
                    noteList.add(note);
                }
            }
        } else {
            for (NoteEntity note : allNotes) {
                if (TextUtils.equals(note.groupName, group)) {
                    noteList.add(note);
                }
            }
        }
        noteAdapter.notifyDataSetChanged();
    }

    /**
     * 搜索笔记
     */
    private void searchNotes(String keyword) {
        if (TextUtils.isEmpty(keyword)) {
            filterNotesByGroup(tabList.get(currentTab));
            return;
        }
        List<NoteEntity> allNotes = NoteStorageManager.getInstance(this).getAllNotes();
        List<NoteEntity> searchResult = new ArrayList<>();
        for (NoteEntity note : allNotes) {
            if ((note.title != null && note.title.contains(keyword)) ||
                    (note.content != null && note.content.contains(keyword)) ||
                    (note.remark != null && note.remark.contains(keyword))) {
                searchResult.add(note);
            }
        }
        noteList.clear();
        noteList.addAll(searchResult);
        noteAdapter.notifyDataSetChanged();
    }

    /**
     * 移动到分组对话框
     */
    private void showMoveGroupDialog(NoteEntity note, int position) {
        String[] groups = {"未分组", "工作", "生活", "学习", "旅行"};
        new androidx.appcompat.app.AlertDialog.Builder(this)
                .setTitle("移动到分组")
                .setItems(groups, (dialog, which) -> {
                    note.groupName = groups[which];
                    NoteStorageManager.getInstance(this).updateNoteGroup(note.id, groups[which]);
                    noteAdapter.notifyItemChanged(position);
                    WKToastUtils.getInstance().showToastNormal("已移动到" + groups[which]);
                })
                .show();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (resultCode == RESULT_OK && data != null) {
            // 处理编辑结果
            if (requestCode == REQUEST_CODE_EDIT) {
                String noteId = data.getStringExtra(NoteEditActivity.KEY_NOTE_ID);
                // 直接从存储刷新，确保块列表等完整数据同步
                if (noteId != null) {
                    NoteEntity note = NoteStorageManager.getInstance(this).getNote(noteId);
                    if (note != null) {
                        // 确保列表中有这条笔记
                        boolean found = false;
                        for (NoteEntity n : noteList) {
                            if (TextUtils.equals(n.id, noteId)) {
                                found = true;
                                break;
                            }
                        }
                        if (!found) {
                            // 新建的笔记，添加到列表
                            noteList.add(0, note);
                        }
                    }
                }
            }
            // 处理备注结果
            if (requestCode == 1004 && data != null) {
                String noteId = data.getStringExtra(NoteRemarkActivity.KEY_NOTE_ID);
                String remark = data.getStringExtra(NoteRemarkActivity.KEY_NOTE_REMARK);
                if (noteId != null) {
                    NoteStorageManager.getInstance(this).updateNoteRemark(noteId, remark);
                }
            }
            // 重新加载列表
            filterNotesByGroup(tabList.get(currentTab));
        }
    }

    /**
     * 适配状态栏高度，避免标题栏被灵动岛/刘海遮挡
     */
    private void initStatusBarPadding() {
        int statusBarHeight = 0;
        int resourceId = getResources().getIdentifier("status_bar_height", "dimen", "android");
        if (resourceId > 0) {
            statusBarHeight = getResources().getDimensionPixelSize(resourceId);
        }
        if (statusBarHeight < dp2px(24)) {
            statusBarHeight = dp2px(24);
        }
        wkVBinding.getRoot().setPadding(
                wkVBinding.getRoot().getPaddingLeft(),
                statusBarHeight,
                wkVBinding.getRoot().getPaddingRight(),
                wkVBinding.getRoot().getPaddingBottom()
        );
    }

    private int dp2px(float dp) {
        return (int) (dp * getResources().getDisplayMetrics().density + 0.5f);
    }
}
