package com.chat.richeditor.ui;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;

import com.chat.base.base.WKBaseActivity;
import com.chat.richeditor.component.wmview.WMTextEditor;
import com.chat.richeditor.msg.RichTextContent;
import com.chat.uikit.R;
import com.chat.uikit.databinding.EditLayoutBinding;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.msgmodel.WKMsgEntity;

import java.util.List;

/**
 * 富文本编辑器页面
 */
public class EditActivity extends WKBaseActivity<EditLayoutBinding> {

    public static final String KEY_CHANNEL_ID = "channel_id";
    public static final String KEY_CHANNEL_TYPE = "channel_type";
    public static final String KEY_RESULT_CONTENT = "rich_content";
    public static final String KEY_RESULT_ENTITIES = "rich_entities";

    private String channelID;
    private byte channelType;
    private WMTextEditor textEditor;

    private final ActivityResultLauncher<Intent> chooseMemberLauncher = registerForActivityResult(
            new ActivityResultContracts.StartActivityForResult(),
            result -> {
                if (result.getResultCode() == Activity.RESULT_OK && result.getData() != null) {
                    String uid = result.getData().getStringExtra("member_uid");
                    String name = result.getData().getStringExtra("member_name");
                    if (!TextUtils.isEmpty(uid) && !TextUtils.isEmpty(name) && textEditor != null) {
                        textEditor.insertMention(uid, name);
                    }
                }
            }
    );

    @Override
    protected EditLayoutBinding getViewBinding() {
        return EditLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.rich_text_editor);
    }

    @Override
    protected void initPresenter() {
        channelID = getIntent().getStringExtra(KEY_CHANNEL_ID);
        channelType = getIntent().getByteExtra(KEY_CHANNEL_TYPE, (byte) 1);
    }

    @Override
    protected void initView() {
        textEditor = wkVBinding.textEditor;
        textEditor.setOnChooseGroupMemberListener(() -> {
            if (channelType == 2) { // 群聊
                Intent intent = new Intent(EditActivity.this, ChooseGroupMemberActivity.class);
                intent.putExtra(ChooseGroupMemberActivity.KEY_CHANNEL_ID, channelID);
                intent.putExtra(ChooseGroupMemberActivity.KEY_CHANNEL_TYPE, channelType);
                chooseMemberLauncher.launch(intent);
            }
        });
        // 自动弹出软键盘
        textEditor.getEditText().postDelayed(() -> {
            textEditor.getEditText().requestFocus();
            android.view.inputmethod.InputMethodManager imm =
                    (android.view.inputmethod.InputMethodManager) getSystemService(INPUT_METHOD_SERVICE);
            if (imm != null) {
                imm.showSoftInput(textEditor.getEditText(), 0);
            }
        }, 200);
    }

    @Override
    protected String getRightTvText(TextView textView) {
        return getString(R.string.send);
    }

    private void sendRichMessage() {
        if (textEditor == null) return;
        String content = textEditor.getContentText();
        if (TextUtils.isEmpty(content)) {
            return;
        }

        List<WKMsgEntity> entities = textEditor.getContentEntities();
        List<String> mentionUids = textEditor.getMentionUids();

        RichTextContent richContent = new RichTextContent(content);
        richContent.entities = entities;

        // 发送消息
        WKIM.getInstance().getMsgManager().sendMessage(richContent, channelID, channelType);

        finish();
    }

    @Override
    public void rightLayoutClick() {
        super.rightLayoutClick();
        sendRichMessage();
    }
}
