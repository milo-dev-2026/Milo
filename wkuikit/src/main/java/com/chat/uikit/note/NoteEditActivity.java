package com.chat.uikit.note;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.media.ThumbnailUtils;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.WKPermissions;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActNoteEditLayoutBinding;

import java.io.File;
import java.io.FileOutputStream;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;

import androidx.core.content.FileProvider;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

/**
 * 笔记编辑页面 - 模块化块结构
 */
public class NoteEditActivity extends WKBaseActivity<ActNoteEditLayoutBinding> {

    public static final String KEY_NOTE_ID = "note_id";
    public static final String KEY_NOTE_TITLE = "note_title";
    public static final String KEY_NOTE_CONTENT = "note_content";
    public static final String KEY_GROUP_NAME = "group_name";

    private static final int REQUEST_CODE_IMAGE = 1001;
    private static final int REQUEST_CODE_VIDEO = 1002;
    private static final int REQUEST_CODE_LOCATION = 1003;
    private static final int REQUEST_CODE_CAMERA = 1004;
    private static final int REQUEST_CODE_REMARK = 1005;

    private String noteId;
    private String groupName = "未分组";
    private boolean isEdit = false;
    private NoteToolAdapter toolAdapter;
    private NoteBlockAdapter blockAdapter;
    private List<NoteBlock> blockList = new ArrayList<>();
    private NoteItemTouchHelperCallback touchHelperCallback;
    private boolean isSortMode = false;
    private boolean isKeyboardVisible = false;
    private Uri cameraImageUri;

    @Override
    protected ActNoteEditLayoutBinding getViewBinding() {
        return ActNoteEditLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        // 使用自定义标题栏
    }

    @Override
    protected void initPresenter() {
        if (getIntent() != null) {
            noteId = getIntent().getStringExtra(KEY_NOTE_ID);
            groupName = getIntent().getStringExtra(KEY_GROUP_NAME);
            isEdit = !TextUtils.isEmpty(noteId);
        }
        if (TextUtils.isEmpty(groupName)) {
            groupName = "未分组";
        }
    }

    @Override
    protected void initView() {
        // 适配状态栏高度（灵动岛/刘海屏）
        initStatusBarPadding();

        // 设置标题
        wkVBinding.titleTv.setText(isEdit ? R.string.note_edit : R.string.note_create);

        // 分组名称
        wkVBinding.groupTv.setText(groupName);
        wkVBinding.groupLayout.setOnClickListener(v -> showGroupSelectDialog());

        // 初始化笔记块列表
        initBlockList();

        // 初始化工具栏
        initToolBar();

        // 初始化键盘监听和底部安全区域适配
        initKeyboardListener();
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
        // 至少 24dp 的安全间距
        if (statusBarHeight < dp2px(24)) {
            statusBarHeight = dp2px(24);
        }
        // 设置标题栏的顶部 margin = 状态栏高度
        androidx.constraintlayout.widget.ConstraintLayout.LayoutParams params =
                (androidx.constraintlayout.widget.ConstraintLayout.LayoutParams) wkVBinding.titleLayout.getLayoutParams();
        params.topMargin = statusBarHeight;
        wkVBinding.titleLayout.setLayoutParams(params);
    }

    private int dp2px(float dp) {
        return (int) (dp * getResources().getDisplayMetrics().density + 0.5f);
    }

    /**
     * 初始化键盘监听和底部安全区域适配
     */
    private void initKeyboardListener() {
        // 获取底部安全区域高度（导航栏高度）
        final int[] bottomNavBarHeight = {0};
        int resourceId = getResources().getIdentifier("navigation_bar_height", "dimen", "android");
        if (resourceId > 0) {
            bottomNavBarHeight[0] = getResources().getDimensionPixelSize(resourceId);
        }

        // 给底部按钮区域添加底部 padding，适配全面屏导航栏
        final int finalBottomPadding = bottomNavBarHeight[0];
        wkVBinding.bottomButtonLayout.post(() -> {
            int currentPaddingBottom = wkVBinding.bottomButtonLayout.getPaddingBottom();
            wkVBinding.bottomButtonLayout.setPadding(
                    wkVBinding.bottomButtonLayout.getPaddingLeft(),
                    wkVBinding.bottomButtonLayout.getPaddingTop(),
                    wkVBinding.bottomButtonLayout.getPaddingRight(),
                    currentPaddingBottom + finalBottomPadding
            );
        });

        // 监听键盘弹出/收起（adjustResize 模式下用 translationY 精确移动工具栏）
        wkVBinding.getRoot().getViewTreeObserver().addOnGlobalLayoutListener(() -> {
            android.graphics.Rect rect = new android.graphics.Rect();
            wkVBinding.getRoot().getWindowVisibleDisplayFrame(rect);
            int screenHeight = wkVBinding.getRoot().getRootView().getHeight();
            int keypadHeight = screenHeight - rect.bottom;

            android.util.Log.d("NoteEditKeyboard", "onGlobalLayout: screenHeight=" + screenHeight
                    + ", rect.bottom=" + rect.bottom + ", keypadHeight=" + keypadHeight
                    + ", threshold=" + (screenHeight * 0.25));

            boolean keyboardNowVisible = keypadHeight > screenHeight * 0.25;
            android.util.Log.d("NoteEditKeyboard", "keyboardNowVisible=" + keyboardNowVisible
                    + ", isKeyboardVisible=" + isKeyboardVisible
                    + ", changed=" + (keyboardNowVisible != isKeyboardVisible));

            // 状态变化时才处理
            if (keyboardNowVisible != isKeyboardVisible) {
                isKeyboardVisible = keyboardNowVisible;
                if (keyboardNowVisible) {
                    // 键盘弹出：
                    // 1. 底部按钮下移到屏幕底部（键盘后面）
                    int[] btnLocation = new int[2];
                    wkVBinding.bottomButtonLayout.getLocationOnScreen(btnLocation);
                    int btnBottomY = btnLocation[1] + wkVBinding.bottomButtonLayout.getHeight();
                    float btnTranslationY = screenHeight - btnBottomY;
                    android.util.Log.d("NoteEditKeyboard", "键盘弹出: btnBottomY=" + btnBottomY
                            + ", screenHeight=" + screenHeight
                            + ", btnTranslationY=" + btnTranslationY);
                    wkVBinding.bottomButtonLayout.setTranslationY(btnTranslationY);

                    // 2. 计算工具栏需要上移的距离，让工具栏底部贴在键盘顶部
                    int[] toolsLocation = new int[2];
                    wkVBinding.toolsRecyclerView.getLocationOnScreen(toolsLocation);
                    int toolsBottomY = toolsLocation[1] + wkVBinding.toolsRecyclerView.getHeight();
                    float translationY = rect.bottom - toolsBottomY;
                    android.util.Log.d("NoteEditKeyboard", "键盘弹出: toolsBottomY=" + toolsBottomY
                            + ", rect.bottom(keyboardTop)=" + rect.bottom
                            + ", toolsTranslationY=" + translationY);
                    wkVBinding.toolsRecyclerView.setTranslationY(translationY);

                    // 3. 调整 RecyclerView 底部 padding，避免内容被键盘挡住
                    int oldPaddingBottom = wkVBinding.recyclerView.getPaddingBottom();
                    wkVBinding.recyclerView.setPadding(
                            wkVBinding.recyclerView.getPaddingLeft(),
                            wkVBinding.recyclerView.getPaddingTop(),
                            wkVBinding.recyclerView.getPaddingRight(),
                            oldPaddingBottom + keypadHeight
                    );
                } else {
                    // 键盘收起：
                    // 1. 底部按钮恢复原位
                    wkVBinding.bottomButtonLayout.setTranslationY(0);
                    // 2. 工具栏恢复原位
                    wkVBinding.toolsRecyclerView.setTranslationY(0);
                    // 3. 恢复 RecyclerView 底部 padding
                    wkVBinding.recyclerView.setPadding(
                            wkVBinding.recyclerView.getPaddingLeft(),
                            wkVBinding.recyclerView.getPaddingTop(),
                            wkVBinding.recyclerView.getPaddingRight(),
                            12 // 恢复原始 padding
                    );
                }
            }
        });
    }

    private void initBlockList() {
        // 编辑模式下加载已保存的块数据
        if (isEdit && !TextUtils.isEmpty(noteId)) {
            NoteEntity note = NoteStorageManager.getInstance(this).getNote(noteId);
            if (note != null && !TextUtils.isEmpty(note.blockListJson)) {
                List<NoteBlock> savedBlocks = parseBlockListFromJson(note.blockListJson);
                if (savedBlocks != null && !savedBlocks.isEmpty()) {
                    blockList.clear();
                    blockList.addAll(savedBlocks);
                }
            }
        }

        blockAdapter = new NoteBlockAdapter(blockList);
        LinearLayoutManager layoutManager = new LinearLayoutManager(this);
        wkVBinding.recyclerView.setLayoutManager(layoutManager);
        wkVBinding.recyclerView.setAdapter(blockAdapter);

        // 删除块
        blockAdapter.setOnBlockDeleteListener(position -> {
            blockList.remove(position);
            blockAdapter.notifyItemRemoved(position);
            blockAdapter.notifyItemRangeChanged(position, blockList.size());
        });

        // 块点击
        blockAdapter.setOnBlockClickListener((position, block) -> {
            if (block.type == NoteBlock.TYPE_VIDEO && !TextUtils.isEmpty(block.videoPath)) {
                // 使用内置播放器播放视频
                currentVideoCover = block.videoCover;
                playVideo(block.videoPath);
            } else if (block.type == NoteBlock.TYPE_IMAGE && !TextUtils.isEmpty(block.imagePath)) {
                viewImage(block.imagePath);
            } else if (block.type == NoteBlock.TYPE_LOCATION) {
                openLocationDetail(block);
            }
        });

        // 初始化长按拖拽排序（默认开启，长按键块即可拖拽）
        touchHelperCallback = new NoteItemTouchHelperCallback(blockAdapter, blockList);
        touchHelperCallback.attachToRecyclerView(wkVBinding.recyclerView);
    }

    private void initToolBar() {
        List<NoteToolAdapter.ToolItem> toolList = new ArrayList<>();
        toolList.add(new NoteToolAdapter.ToolItem("title", R.mipmap.ic_note_title, "标题"));
        toolList.add(new NoteToolAdapter.ToolItem("text", R.mipmap.ic_note_text, "文字"));
        toolList.add(new NoteToolAdapter.ToolItem("image", R.mipmap.ic_note_image, "图片"));
        toolList.add(new NoteToolAdapter.ToolItem("video", R.mipmap.ic_note_video, "视频"));
        toolList.add(new NoteToolAdapter.ToolItem("location", R.mipmap.ic_note_location, "位置"));
        toolList.add(new NoteToolAdapter.ToolItem("group", R.mipmap.ic_note_folder, "笔记分组"));

        toolAdapter = new NoteToolAdapter(toolList);
        LinearLayoutManager layoutManager = new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false);
        wkVBinding.toolsRecyclerView.setLayoutManager(layoutManager);
        wkVBinding.toolsRecyclerView.setAdapter(toolAdapter);
    }

    /**
     * 切换排序模式
     */
    private void toggleSortMode() {
        isSortMode = !isSortMode;
        if (isSortMode) {
            // 进入排序模式
            wkVBinding.titleTv.setText(R.string.note_sort_note);
            wkVBinding.completeBtn.setVisibility(View.GONE);
            wkVBinding.toolsRecyclerView.setVisibility(View.GONE);
            wkVBinding.normalBottomLayout.setVisibility(View.GONE);
            wkVBinding.llSortFinish.setVisibility(View.VISIBLE);
            // 更新拖拽数据引用
            if (touchHelperCallback != null) {
                touchHelperCallback.setBlockList(blockList);
            }
        } else {
            // 退出排序模式
            wkVBinding.titleTv.setText(isEdit ? R.string.note_edit : R.string.note_create);
            wkVBinding.completeBtn.setVisibility(View.VISIBLE);
            wkVBinding.toolsRecyclerView.setVisibility(View.VISIBLE);
            wkVBinding.normalBottomLayout.setVisibility(View.VISIBLE);
            wkVBinding.llSortFinish.setVisibility(View.GONE);
        }
    }

    @Override
    protected void initListener() {
        // 返回按钮
        wkVBinding.backIv.setOnClickListener(v -> {
            checkUnsavedAndFinish();
        });

        // 完成按钮
        wkVBinding.completeBtn.setOnClickListener(v -> saveNote());

        // 工具栏点击
        toolAdapter.setOnToolClickListener(toolId -> {
            switch (toolId) {
                case "title":
                    addTitleBlock();
                    break;
                case "text":
                    addTextBlock();
                    break;
                case "image":
                    pickImage();
                    break;
                case "video":
                    pickVideo();
                    break;
                case "location":
                    pickLocation();
                    break;
                case "group":
                    showGroupSelectDialog();
                    break;
                default:
                    break;
            }
        });

        // 排序按钮
        wkVBinding.llSort.setOnClickListener(v -> toggleSortMode());

        // 排序完成按钮
        wkVBinding.llSortFinish.setOnClickListener(v -> toggleSortMode());

        // 预览按钮
        wkVBinding.llView.setOnClickListener(v -> {
            Intent intent = new Intent(NoteEditActivity.this, NotePreviewActivity.class);
            intent.putExtra(NotePreviewActivity.KEY_NOTE_GROUP, groupName);
            intent.putExtra(NotePreviewActivity.KEY_NOTE_TIME, getCurrentTime());
            // 传递完整块列表 JSON
            intent.putExtra(NotePreviewActivity.KEY_BLOCK_LIST_JSON, serializeBlockListToJson(blockList));
            // 兼容旧字段
            StringBuilder titleSb = new StringBuilder();
            StringBuilder contentSb = new StringBuilder();
            for (NoteBlock block : blockList) {
                if (block.type == NoteBlock.TYPE_TITLE && !TextUtils.isEmpty(block.content)) {
                    if (titleSb.length() == 0) {
                        titleSb.append(block.content);
                    }
                } else if (block.type == NoteBlock.TYPE_TEXT && !TextUtils.isEmpty(block.content)) {
                    if (contentSb.length() > 0) contentSb.append("\n");
                    contentSb.append(block.content);
                }
            }
            intent.putExtra(NotePreviewActivity.KEY_NOTE_TITLE, titleSb.toString());
            intent.putExtra(NotePreviewActivity.KEY_NOTE_CONTENT, contentSb.toString());
            startActivity(intent);
            overridePendingTransition(R.anim.in_right, R.anim.out_left);
        });
    }

    private void addTitleBlock() {
        blockList.add(NoteBlock.createTitle());
        int position = blockList.size() - 1;
        blockAdapter.notifyItemInserted(position);
        wkVBinding.recyclerView.scrollToPosition(position);
        // 延迟弹出键盘并聚焦
        wkVBinding.recyclerView.postDelayed(() -> {
            RecyclerView.ViewHolder holder = wkVBinding.recyclerView.findViewHolderForAdapterPosition(position);
            if (holder instanceof NoteBlockAdapter.TitleViewHolder) {
                ((NoteBlockAdapter.TitleViewHolder) holder).etTitle.requestFocus();
                com.chat.base.utils.SoftKeyboardUtils.getInstance().showSoftKeyBoard(this, ((NoteBlockAdapter.TitleViewHolder) holder).etTitle);
            }
        }, 200);
    }

    private void addTextBlock() {
        blockList.add(NoteBlock.createText());
        int position = blockList.size() - 1;
        blockAdapter.notifyItemInserted(position);
        wkVBinding.recyclerView.scrollToPosition(position);
        // 延迟弹出键盘并聚焦
        wkVBinding.recyclerView.postDelayed(() -> {
            RecyclerView.ViewHolder holder = wkVBinding.recyclerView.findViewHolderForAdapterPosition(position);
            if (holder instanceof NoteBlockAdapter.TextViewHolder) {
                ((NoteBlockAdapter.TextViewHolder) holder).etText.requestFocus();
                com.chat.base.utils.SoftKeyboardUtils.getInstance().showSoftKeyBoard(this, ((NoteBlockAdapter.TextViewHolder) holder).etText);
            }
        }, 200);
    }

    /**
     * 直接打开图片选择
     */
    private void pickImage() {
        Intent intent = new Intent(Intent.ACTION_PICK);
        intent.setType("image/*");
        startActivityForResult(intent, REQUEST_CODE_IMAGE);
    }

    /**
     * 直接打开视频选择
     */
    private void pickVideo() {
        Intent intent = new Intent(Intent.ACTION_PICK);
        intent.setType("video/*");
        startActivityForResult(intent, REQUEST_CODE_VIDEO);
    }

    /**
     * 位置选择
     */
    private void pickLocation() {
        String[] permissions = new String[]{
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
        };
        String desc = String.format(getString(R.string.location_permission_desc), getString(R.string.app_name));
        WKPermissions.getInstance().checkPermissions(new WKPermissions.IPermissionResult() {
            @Override
            public void onResult(boolean result) {
                if (result) {
                    try {
                        Intent intent = new Intent(NoteEditActivity.this, com.chat.uikit.location.LocationPickerActivity.class);
                        intent.putExtra(com.chat.uikit.location.LocationPickerActivity.KEY_IS_PICK_MODE, true);
                        startActivityForResult(intent, REQUEST_CODE_LOCATION);
                    } catch (Exception e) {
                        e.printStackTrace();
                        WKToastUtils.getInstance().showToastNormal("无法打开位置选择: " + e.getMessage());
                    }
                }
            }

            @Override
            public void clickResult(boolean isCancel) {
            }
        }, this, desc, permissions);
    }

    /**
     * 分组选择
     */
    private void showGroupSelectDialog() {
        // 从存储加载分组列表
        final java.util.List<String> groups = new java.util.ArrayList<>();
        groups.add("未分组");
        String json = com.chat.base.config.WKSharedPreferencesUtil.getInstance().getSP("note_folders");
        if (json != null && !json.isEmpty()) {
            try {
                org.json.JSONArray array = new org.json.JSONArray(json);
                for (int i = 0; i < array.length(); i++) {
                    groups.add(array.getString(i));
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        if (groups.size() <= 1) {
            groups.add("工作");
            groups.add("生活");
            groups.add("学习");
            groups.add("旅行");
        }

        int currentIndex = 0;
        for (int i = 0; i < groups.size(); i++) {
            if (TextUtils.equals(groups.get(i), groupName)) {
                currentIndex = i;
                break;
            }
        }
        new androidx.appcompat.app.AlertDialog.Builder(this)
                .setTitle("选择分组")
                .setSingleChoiceItems(groups.toArray(new String[0]), currentIndex, (dialog, which) -> {
                    groupName = groups.get(which);
                    wkVBinding.groupTv.setText(groupName);
                    dialog.dismiss();
                })
                .show();
    }

    /**
     * 保存笔记
     */
    private void saveNote() {
        // 提取标题和正文
        StringBuilder titleSb = new StringBuilder();
        StringBuilder contentSb = new StringBuilder();
        for (NoteBlock block : blockList) {
            if (block.type == NoteBlock.TYPE_TITLE) {
                if (!TextUtils.isEmpty(block.content)) {
                    if (titleSb.length() > 0) titleSb.append(" ");
                    titleSb.append(block.content);
                }
            } else if (block.type == NoteBlock.TYPE_TEXT) {
                if (!TextUtils.isEmpty(block.content)) {
                    if (contentSb.length() > 0) contentSb.append("\n");
                    contentSb.append(block.content);
                }
            }
        }

        String title = titleSb.toString();
        String content = contentSb.toString();

        if (TextUtils.isEmpty(title) && TextUtils.isEmpty(content) && blockList.isEmpty()) {
            WKToastUtils.getInstance().showToastNormal("笔记内容不能为空");
            return;
        }

        // 如果没有标题但有内容，用内容前30字作为标题
        if (TextUtils.isEmpty(title) && !TextUtils.isEmpty(content)) {
            title = content.length() > 30 ? content.substring(0, 30) : content;
        }

        // 如果完全没有文字但有图片/视频/位置，也可以保存
        if (TextUtils.isEmpty(title) && blockList.size() > 0) {
            title = "笔记 " + getCurrentTime();
        }

        NoteEntity note;
        if (isEdit && !TextUtils.isEmpty(noteId)) {
            note = NoteStorageManager.getInstance(this).getNote(noteId);
            if (note == null) {
                note = new NoteEntity();
                note.id = noteId;
            }
        } else {
            note = new NoteEntity();
            note.id = "note_" + System.currentTimeMillis();
            note.time = getCurrentTime();
        }
        note.title = title;
        note.content = content;
        note.groupName = groupName;
        note.blockListJson = serializeBlockListToJson(blockList);
        NoteStorageManager.getInstance(this).saveNote(note);

        WKToastUtils.getInstance().showToastNormal(isEdit ? "已保存" : "创建成功");

        Intent resultIntent = new Intent();
        resultIntent.putExtra(KEY_NOTE_ID, note.id);
        resultIntent.putExtra(KEY_NOTE_TITLE, title);
        resultIntent.putExtra(KEY_NOTE_CONTENT, content);
        resultIntent.putExtra(KEY_GROUP_NAME, groupName);
        setResult(RESULT_OK, resultIntent);
        finish();
        overridePendingTransition(R.anim.in_left, R.anim.out_right);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (resultCode == Activity.RESULT_OK) {
            switch (requestCode) {
                case REQUEST_CODE_IMAGE:
                    if (data != null && data.getData() != null) {
                        Uri imageUri = data.getData();
                        addImageBlock(imageUri.toString());
                    }
                    break;
                case REQUEST_CODE_VIDEO:
                    if (data != null && data.getData() != null) {
                        Uri videoUri = data.getData();
                        addVideoBlock(videoUri.toString());
                    }
                    break;
                case REQUEST_CODE_LOCATION:
                    if (data != null) {
                        String name = data.getStringExtra(com.chat.uikit.location.LocationPickerActivity.KEY_LOCATION_NAME);
                        String address = data.getStringExtra(com.chat.uikit.location.LocationPickerActivity.KEY_LOCATION_ADDRESS);
                        double lat = data.getDoubleExtra(com.chat.uikit.location.LocationPickerActivity.KEY_LOCATION_LAT, 0);
                        double lng = data.getDoubleExtra(com.chat.uikit.location.LocationPickerActivity.KEY_LOCATION_LNG, 0);
                        addLocationBlock(name, address, lat, lng);
                    }
                    break;
                default:
                    break;
            }
        }
    }

    private void addImageBlock(String imagePath) {
        // 如果是 content URI，转换为真实路径
        String realPath = getImageRealPathFromUri(imagePath);
        if (!TextUtils.isEmpty(realPath)) {
            imagePath = realPath;
        }
        blockList.add(NoteBlock.createImage(imagePath));
        blockAdapter.notifyItemInserted(blockList.size() - 1);
        wkVBinding.recyclerView.scrollToPosition(blockList.size() - 1);
    }

    private void addLocationBlock(String name, String address, double lat, double lng) {
        blockList.add(NoteBlock.createLocation(name, address, lat, lng));
        blockAdapter.notifyItemInserted(blockList.size() - 1);
        wkVBinding.recyclerView.scrollToPosition(blockList.size() - 1);
    }

    /**
     * 打开位置详情页
     */
    private void openLocationDetail(NoteBlock block) {
        if (block == null) return;
        Intent intent = new Intent(this, com.chat.uikit.location.LocationDetailActivity.class);
        intent.putExtra(com.chat.uikit.location.LocationDetailActivity.EXTRA_TITLE, block.locationName);
        intent.putExtra(com.chat.uikit.location.LocationDetailActivity.EXTRA_ADDRESS, block.locationAddress);
        intent.putExtra(com.chat.uikit.location.LocationDetailActivity.EXTRA_LATITUDE, block.latitude);
        intent.putExtra(com.chat.uikit.location.LocationDetailActivity.EXTRA_LONGITUDE, block.longitude);
        startActivity(intent);
        overridePendingTransition(R.anim.in_right, R.anim.out_left);
    }

    /**
     * 从 content URI 获取图片真实文件路径
     */
    private String getImageRealPathFromUri(String uriString) {
        if (TextUtils.isEmpty(uriString) || !uriString.startsWith("content://")) {
            return uriString;
        }
        try {
            Uri uri = Uri.parse(uriString);
            String[] projection = { MediaStore.Images.Media.DATA };
            android.database.Cursor cursor = getContentResolver().query(uri, projection, null, null, null);
            if (cursor != null && cursor.moveToFirst()) {
                String path = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA));
                cursor.close();
                return path;
            }
            if (cursor != null) cursor.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * 播放视频（使用内置播放器）
     */
    private void playVideo(String videoPath) {
        try {
            Intent intent = new Intent(this, com.chat.base.act.PlayVideoActivity.class);
            intent.putExtra("url", videoPath);
            if (!TextUtils.isEmpty(currentVideoCover)) {
                intent.putExtra("coverImg", currentVideoCover);
            }
            startActivity(intent);
        } catch (Exception e) {
            e.printStackTrace();
            WKToastUtils.getInstance().showToastNormal("视频播放失败");
        }
    }

    private String currentVideoCover = "";

    /**
     * 查看图片
     */
    private void viewImage(String imagePath) {
        try {
            Intent intent = new Intent(Intent.ACTION_VIEW);
            Uri uri;
            if (imagePath.startsWith("content://")) {
                uri = Uri.parse(imagePath);
            } else {
                File imageFile = new File(imagePath);
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    uri = FileProvider.getUriForFile(this,
                            getPackageName() + ".fileprovider", imageFile);
                } else {
                    uri = Uri.fromFile(imageFile);
                }
            }
            intent.setDataAndType(uri, "image/*");
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            startActivity(intent);
        } catch (Exception e) {
            e.printStackTrace();
            WKToastUtils.getInstance().showToastNormal("图片查看失败");
        }
    }

    private void addVideoBlock(String videoPath) {
        // 如果是 content URI，转换为真实路径
        String realPath = getRealPathFromUri(videoPath);
        if (!TextUtils.isEmpty(realPath)) {
            videoPath = realPath;
        }
        // 生成视频缩略图
        String coverPath = getVideoThumbnailPath(videoPath);
        if (TextUtils.isEmpty(coverPath)) {
            coverPath = videoPath;
        }
        final String finalVideoPath = videoPath;
        final String finalCoverPath = coverPath;
        blockList.add(NoteBlock.createVideo(finalVideoPath, finalCoverPath));
        blockAdapter.notifyItemInserted(blockList.size() - 1);
        wkVBinding.recyclerView.scrollToPosition(blockList.size() - 1);
    }

    /**
     * 从 content URI 获取真实文件路径
     */
    private String getRealPathFromUri(String uriString) {
        if (TextUtils.isEmpty(uriString) || !uriString.startsWith("content://")) {
            return uriString;
        }
        try {
            Uri uri = Uri.parse(uriString);
            String[] projection = { MediaStore.Video.Media.DATA };
            android.database.Cursor cursor = getContentResolver().query(uri, projection, null, null, null);
            if (cursor != null && cursor.moveToFirst()) {
                String path = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DATA));
                cursor.close();
                return path;
            }
            if (cursor != null) cursor.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private String getVideoThumbnailPath(String videoPath) {
        try {
            Bitmap bitmap = null;
            if (videoPath.startsWith("content://")) {
                // 从 content URI 获取缩略图
                Uri uri = Uri.parse(videoPath);
                String[] proj = { MediaStore.Video.Media._ID };
                android.database.Cursor cursor = getContentResolver().query(uri, proj, null, null, null);
                if (cursor != null && cursor.moveToFirst()) {
                    long videoId = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Video.Media._ID));
                    cursor.close();
                    bitmap = MediaStore.Video.Thumbnails.getThumbnail(
                            getContentResolver(), videoId,
                            MediaStore.Video.Thumbnails.MINI_KIND, null);
                }
                if (cursor != null) cursor.close();
            } else {
                bitmap = ThumbnailUtils.createVideoThumbnail(videoPath,
                        MediaStore.Video.Thumbnails.MINI_KIND);
            }
            if (bitmap != null) {
                File file = new File(getExternalFilesDir(Environment.DIRECTORY_PICTURES),
                        "video_thumb_" + System.currentTimeMillis() + ".jpg");
                FileOutputStream fos = new FileOutputStream(file);
                bitmap.compress(Bitmap.CompressFormat.JPEG, 80, fos);
                fos.flush();
                fos.close();
                return file.getAbsolutePath();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private String getCurrentTime() {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.getDefault());
        return sdf.format(new Date());
    }

    /**
     * 检查是否有未保存的更改，有则弹窗确认
     */
    private void checkUnsavedAndFinish() {
        if (hasUnsavedChanges()) {
            WKDialogUtils.getInstance().showDialog(this,
                    getString(R.string.note_unsaved_title),
                    getString(R.string.note_unsaved_message),
                    false,
                    getString(R.string.note_cancel),
                    getString(R.string.note_confirm_leave),
                    R.color.colorDark,
                    R.color.color_main,
                    index -> {
                        if (index == 1) {
                            // 确定离开
                            finish();
                            overridePendingTransition(R.anim.in_left, R.anim.out_right);
                        }
                    });
        } else {
            finish();
            overridePendingTransition(R.anim.in_left, R.anim.out_right);
        }
    }

    /**
     * 判断是否有未保存的更改
     */
    private boolean hasUnsavedChanges() {
        // 新建笔记且有内容（标题或任意块）
        if (!isEdit) {
            // 检查是否有非空块
            for (NoteBlock block : blockList) {
                if (block.type == NoteBlock.TYPE_TITLE
                        || block.type == NoteBlock.TYPE_TEXT) {
                    if (!TextUtils.isEmpty(block.content)) {
                        return true;
                    }
                } else if (block.type == NoteBlock.TYPE_IMAGE
                        || block.type == NoteBlock.TYPE_VIDEO
                        || block.type == NoteBlock.TYPE_LOCATION) {
                    // 图片、视频、位置块只要存在就是有内容
                    return true;
                }
            }
            return false;
        }
        // 编辑模式：简单判断为有更改（可以对比原始数据）
        return true;
    }

    @Override
    public void onBackPressed() {
        checkUnsavedAndFinish();
    }

    /**
     * 将笔记块列表序列化为 JSON 字符串
     */
    private String serializeBlockListToJson(List<NoteBlock> blocks) {
        if (blocks == null || blocks.isEmpty()) {
            return "";
        }
        try {
            org.json.JSONArray array = new org.json.JSONArray();
            for (NoteBlock block : blocks) {
                org.json.JSONObject obj = new org.json.JSONObject();
                obj.put("type", block.type);
                obj.put("content", block.content != null ? block.content : "");
                obj.put("imagePath", block.imagePath != null ? block.imagePath : "");
                obj.put("videoPath", block.videoPath != null ? block.videoPath : "");
                obj.put("videoCover", block.videoCover != null ? block.videoCover : "");
                obj.put("locationName", block.locationName != null ? block.locationName : "");
                obj.put("locationAddress", block.locationAddress != null ? block.locationAddress : "");
                obj.put("latitude", block.latitude);
                obj.put("longitude", block.longitude);
                array.put(obj);
            }
            return array.toString();
        } catch (Exception e) {
            e.printStackTrace();
            return "";
        }
    }

    /**
     * 从 JSON 字符串解析笔记块列表
     */
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
}
