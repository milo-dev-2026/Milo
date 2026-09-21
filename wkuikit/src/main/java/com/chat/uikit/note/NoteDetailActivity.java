package com.chat.uikit.note;

import android.content.Intent;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActNoteDetailLayoutBinding;

/**
 * 笔记详情页面
 */
public class NoteDetailActivity extends WKBaseActivity<ActNoteDetailLayoutBinding> {

    public static final String KEY_NOTE_ID = "note_id";
    public static final String KEY_NOTE_TITLE = "note_title";
    public static final String KEY_NOTE_CONTENT = "note_content";
    public static final String KEY_NOTE_GROUP = "note_group";
    public static final String KEY_NOTE_TIME = "note_time";

    public static final int REQUEST_CODE_EDIT = 2001;

    private String noteId;
    private String noteTitle;
    private String noteContent;
    private String noteGroup;
    private String noteTime;

    @Override
    protected ActNoteDetailLayoutBinding getViewBinding() {
        return ActNoteDetailLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.note_detail);
    }

    @Override
    protected void initPresenter() {
        if (getIntent() != null) {
            noteId = getIntent().getStringExtra(KEY_NOTE_ID);
            noteTitle = getIntent().getStringExtra(KEY_NOTE_TITLE);
            noteContent = getIntent().getStringExtra(KEY_NOTE_CONTENT);
            noteGroup = getIntent().getStringExtra(KEY_NOTE_GROUP);
            noteTime = getIntent().getStringExtra(KEY_NOTE_TIME);
        }
    }

    @Override
    protected void initView() {
        if (!TextUtils.isEmpty(noteTitle)) {
            wkVBinding.titleTv.setText(noteTitle);
        } else {
            wkVBinding.titleTv.setText("无标题");
        }

        wkVBinding.contentTv.setText(noteContent != null ? noteContent : "");
        wkVBinding.groupTv.setText(!TextUtils.isEmpty(noteGroup) ? noteGroup : "未分组");
        wkVBinding.timeTv.setText(noteTime != null ? noteTime : "");
    }

    @Override
    protected void initListener() {
        // 编辑
        SingleClickUtil.onSingleClick(wkVBinding.editBtn, v -> {
            Intent intent = new Intent(NoteDetailActivity.this, NoteEditActivity.class);
            intent.putExtra(NoteEditActivity.KEY_NOTE_ID, noteId);
            intent.putExtra(NoteEditActivity.KEY_NOTE_TITLE, noteTitle);
            intent.putExtra(NoteEditActivity.KEY_NOTE_CONTENT, noteContent);
            intent.putExtra(NoteEditActivity.KEY_GROUP_NAME, noteGroup);
            startActivityForResult(intent, REQUEST_CODE_EDIT);
        });

        // 分享
        SingleClickUtil.onSingleClick(wkVBinding.shareBtn, v -> {
            WKToastUtils.getInstance().showToastNormal("分享笔记");
        });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_CODE_EDIT && resultCode == RESULT_OK && data != null) {
            noteTitle = data.getStringExtra(NoteEditActivity.KEY_NOTE_TITLE);
            noteContent = data.getStringExtra(NoteEditActivity.KEY_NOTE_CONTENT);
            noteGroup = data.getStringExtra(NoteEditActivity.KEY_GROUP_NAME);

            if (!TextUtils.isEmpty(noteTitle)) {
                wkVBinding.titleTv.setText(noteTitle);
            }
            wkVBinding.contentTv.setText(noteContent != null ? noteContent : "");
            wkVBinding.groupTv.setText(!TextUtils.isEmpty(noteGroup) ? noteGroup : "未分组");

            setResult(RESULT_OK, data);
        }
    }
}
