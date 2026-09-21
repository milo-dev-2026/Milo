package com.chat.uikit.chat;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import androidx.activity.result.ActivityResult;
import androidx.activity.result.ActivityResultCallback;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.chad.library.adapter.base.BaseQuickAdapter;
import com.chad.library.adapter.base.viewholder.BaseViewHolder;
import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKApiConfig;
import com.chat.base.msgitem.WKContentType;
import com.chat.base.utils.WKFileUtils;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.chat.msgmodel.WKFileContent;
import com.chat.uikit.databinding.ActChooseFileLayoutBinding;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKMsg;
import com.xinbida.wukongim.interfaces.IGetOrSyncHistoryMsgBack;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

public class ChooseFileActivity extends WKBaseActivity<ActChooseFileLayoutBinding> {

    private String channelId;
    private int channelType;
    private FileAdapter adapter;
    private final List<WKMsg> fileMsgs = new ArrayList<>();

    private final ActivityResultLauncher<Intent> filePickerLauncher =
            registerForActivityResult(new ActivityResultContracts.StartActivityForResult(),
                    new ActivityResultCallback<ActivityResult>() {
                        @Override
                        public void onActivityResult(ActivityResult result) {
                            if (result.getResultCode() == RESULT_OK && result.getData() != null) {
                                handlePickResult(result.getData());
                            }
                        }
                    });

    public static void start(Context context, String channelId, int channelType) {
        Intent intent = new Intent(context, ChooseFileActivity.class);
        intent.putExtra("channel_id", channelId);
        intent.putExtra("channel_type", channelType);
        context.startActivity(intent);
    }

    @Override
    protected ActChooseFileLayoutBinding getViewBinding() {
        return ActChooseFileLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.choose_file);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        channelId = getIntent().getStringExtra("channel_id");
        channelType = getIntent().getIntExtra("channel_type", 1);

        adapter = new FileAdapter();
        wkVBinding.fileRecyclerView.setLayoutManager(new LinearLayoutManager(this));
        wkVBinding.fileRecyclerView.setAdapter(adapter);

        loadRecentFiles();
    }

    @Override
    protected void initListener() {
        wkVBinding.systemFileLayout.setOnClickListener(v -> openSystemFilePicker());
        adapter.setOnItemClickListener((a, view, position) -> {
            if (position < fileMsgs.size()) {
                ChatFileActivity.start(this, fileMsgs.get(position).clientMsgNO);
            }
        });
    }

    private void openSystemFilePicker() {
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("*/*");
        try {
            filePickerLauncher.launch(intent);
        } catch (Exception e) {
            WKToastUtils.getInstance().showToastNormal("无法打开文件选择器");
        }
    }

    private void handlePickResult(Intent data) {
        Uri uri = data.getData();
        if (uri == null) return;

        String filePath = WKFileUtils.getInstance().getChooseFileResultPath(this, uri);
        if (TextUtils.isEmpty(filePath)) {
            WKToastUtils.getInstance().showToastNormal("无法获取文件路径");
            return;
        }

        File file = new File(filePath);
        if (!file.exists()) {
            WKToastUtils.getInstance().showToastNormal("文件不存在");
            return;
        }

        String fileName = WKFileUtils.getInstance().getFileName(this, uri);
        if (TextUtils.isEmpty(fileName)) {
            fileName = file.getName();
        }

        long fileSize = file.length();

        if (WKFileUtils.getInstance().isFileOverSize(this, filePath)) {
            WKToastUtils.getInstance().showToastNormal("文件过大，无法发送");
            return;
        }

        WKFileContent fileContent = new WKFileContent(filePath, fileName, fileSize);
        if (!TextUtils.isEmpty(channelId)) {
            WKIM.getInstance().getMsgManager().sendMessage(fileContent, channelId, (byte) channelType);
        }
        finish();
    }

    private void loadRecentFiles() {
        if (TextUtils.isEmpty(channelId)) {
            wkVBinding.emptyView.setVisibility(View.VISIBLE);
            return;
        }

        WKIM.getInstance().getMsgManager().getOrSyncHistoryMessages(
                channelId,
                (byte) channelType,
                0,
                false,
                0,
                500,
                0,
                new IGetOrSyncHistoryMsgBack() {
                    @Override
                    public void onSyncing() {
                    }

                    @Override
                    public void onResult(List<WKMsg> list) {
                        runOnUiThread(() -> {
                            fileMsgs.clear();
                            if (list != null) {
                                for (WKMsg msg : list) {
                                    if (msg.type == WKContentType.WK_FILE) {
                                        fileMsgs.add(msg);
                                    }
                                }
                            }
                            adapter.setList(fileMsgs);
                            wkVBinding.emptyView.setVisibility(fileMsgs.isEmpty() ? View.VISIBLE : View.GONE);
                        });
                    }
                }
        );
    }

    private static class FileAdapter extends BaseQuickAdapter<WKMsg, BaseViewHolder> {

        public FileAdapter() {
            super(R.layout.item_choose_file_layout);
        }

        @Override
        protected void convert(@NonNull BaseViewHolder helper, WKMsg item) {
            WKFileContent content = (WKFileContent) item.baseContentMsgModel;

            helper.setText(R.id.nameTv, content.name != null ? content.name : "未知文件");
            helper.setText(R.id.sizeTv, formatSize(content.size));
            helper.setText(R.id.typeTv, content.getFileExtension());
        }

        private String formatSize(long size) {
            if (size < 1024) return size + " B";
            if (size < 1024 * 1024) return String.format("%.1f KB", size / 1024.0);
            if (size < 1024 * 1024 * 1024) return String.format("%.1f MB", size / (1024.0 * 1024));
            return String.format("%.1f GB", size / (1024.0 * 1024 * 1024));
        }
    }
}
