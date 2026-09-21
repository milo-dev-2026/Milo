package com.chat.uikit.chat;

import android.content.Context;
import android.content.Intent;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKApiConfig;
import com.chat.base.config.WKConstants;
import com.chat.base.net.ud.WKDownloader;
import com.chat.base.net.ud.WKProgressManager;
import com.chat.base.utils.WKFileUtils;
import com.chat.base.utils.WKTimeUtils;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.chat.msgmodel.WKFileContent;
import com.chat.uikit.databinding.ActChatFileLayoutBinding;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKMsg;

import java.io.File;

public class ChatFileActivity extends WKBaseActivity<ActChatFileLayoutBinding> {

    private String clientMsgNo;
    private WKFileContent fileContent;
    private WKMsg wkMsg;
    private String downloadSavePath;

    public static void start(Context context, String clientMsgNo) {
        Intent intent = new Intent(context, ChatFileActivity.class);
        intent.putExtra("client_msg_no", clientMsgNo);
        context.startActivity(intent);
    }

    @Override
    protected ActChatFileLayoutBinding getViewBinding() {
        return ActChatFileLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.file_detail);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        clientMsgNo = getIntent().getStringExtra("client_msg_no");
        if (TextUtils.isEmpty(clientMsgNo)) {
            WKToastUtils.getInstance().showToastNormal("参数错误");
            finish();
            return;
        }

        wkMsg = WKIM.getInstance().getMsgManager().getWithClientMsgNO(clientMsgNo);
        if (wkMsg == null || !(wkMsg.baseContentMsgModel instanceof WKFileContent)) {
            WKToastUtils.getInstance().showToastNormal("文件不存在");
            finish();
            return;
        }

        fileContent = (WKFileContent) wkMsg.baseContentMsgModel;

        wkVBinding.fileNameTv.setText(fileContent.name != null ? fileContent.name : "未知文件");
        wkVBinding.fileSizeTv.setText(formatSize(fileContent.size));
        wkVBinding.fileTypeTv.setText(fileContent.getFileExtension());
        wkVBinding.senderTv.setText(wkMsg.fromUID != null ? wkMsg.fromUID : "");
        wkVBinding.timeTv.setText(WKTimeUtils.getInstance().getTimeString(wkMsg.timestamp));

        updateActionState();
    }

    @Override
    protected void initListener() {
        wkVBinding.actionBtn.setOnClickListener(v -> onActionClick());
    }

    private void updateActionState() {
        boolean localExists = !TextUtils.isEmpty(fileContent.localPath)
                && new File(fileContent.localPath).exists();
        if (localExists) {
            wkVBinding.actionBtn.setText(R.string.open_file);
            wkVBinding.downloadProgress.setVisibility(View.GONE);
            wkVBinding.downloadPercentTv.setVisibility(View.GONE);
        } else {
            wkVBinding.actionBtn.setText(R.string.download_file);
        }
    }

    private void onActionClick() {
        if (fileContent == null) return;

        boolean localExists = !TextUtils.isEmpty(fileContent.localPath)
                && new File(fileContent.localPath).exists();

        if (localExists) {
            openFile(fileContent.localPath);
        } else {
            downloadFile();
        }
    }

    private void downloadFile() {
        if (fileContent == null || TextUtils.isEmpty(fileContent.url)) {
            String url = WKApiConfig.getShowUrl(fileContent.url);
            if (TextUtils.isEmpty(url)) {
                WKToastUtils.getInstance().showToastNormal("文件下载地址无效");
                return;
            }
        }

        String downloadUrl = WKApiConfig.getShowUrl(fileContent.url);
        if (TextUtils.isEmpty(downloadUrl)) {
            WKToastUtils.getInstance().showToastNormal("文件下载地址无效");
            return;
        }

        String fileName = fileContent.name != null ? fileContent.name : "download_" + System.currentTimeMillis();
        downloadSavePath = WKConstants.chatDownloadFileDir + fileName;

        wkVBinding.actionBtn.setText(R.string.downloading);
        wkVBinding.actionBtn.setEnabled(false);
        wkVBinding.downloadProgress.setVisibility(View.VISIBLE);
        wkVBinding.downloadProgress.setProgress(0);
        wkVBinding.downloadPercentTv.setVisibility(View.VISIBLE);
        wkVBinding.downloadPercentTv.setText("0%");

        WKDownloader.Companion.getInstance().download(downloadUrl, downloadSavePath,
                new WKProgressManager.IProgress() {
                    @Override
                    public void onProgress(Object tag, int progress) {
                        runOnUiThread(() -> {
                            wkVBinding.downloadProgress.setProgress(progress);
                            wkVBinding.downloadPercentTv.setText(progress + "%");
                        });
                    }

                    @Override
                    public void onSuccess(Object tag, String path) {
                        runOnUiThread(() -> {
                            fileContent.localPath = path;
                            wkVBinding.actionBtn.setEnabled(true);
                            updateActionState();
                            WKToastUtils.getInstance().showToastNormal("下载完成");
                            openFile(path);
                        });
                    }

                    @Override
                    public void onFail(Object tag, String msg) {
                        runOnUiThread(() -> {
                            wkVBinding.actionBtn.setEnabled(true);
                            updateActionState();
                            WKToastUtils.getInstance().showToastNormal("下载失败: " + msg);
                        });
                    }
                });
    }

    private void openFile(String path) {
        if (TextUtils.isEmpty(path) || !new File(path).exists()) {
            WKToastUtils.getInstance().showToastNormal("文件不存在");
            return;
        }
        WKFileUtils.getInstance().openFileByPath(this, path);
    }

    private String formatSize(long size) {
        if (size < 1024) return size + " B";
        if (size < 1024 * 1024) return String.format("%.1f KB", size / 1024.0);
        if (size < 1024 * 1024 * 1024) return String.format("%.1f MB", size / (1024.0 * 1024));
        return String.format("%.1f GB", size / (1024.0 * 1024 * 1024));
    }
}
