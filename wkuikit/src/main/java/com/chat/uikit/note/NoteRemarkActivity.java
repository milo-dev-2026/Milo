package com.chat.uikit.note;

import android.content.Intent;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActNoteRemarkLayoutBinding;

public class NoteRemarkActivity extends WKBaseActivity<ActNoteRemarkLayoutBinding> {

    public static final String KEY_NOTE_ID = "note_id";
    public static final String KEY_NOTE_REMARK = "note_remark";

    private String noteId;

    @Override
    protected ActNoteRemarkLayoutBinding getViewBinding() {
        return ActNoteRemarkLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.setting_remark);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        Intent intent = getIntent();
        noteId = intent.getStringExtra(KEY_NOTE_ID);
        String remark = intent.getStringExtra(KEY_NOTE_REMARK);
        if (remark != null && !remark.isEmpty()) {
            wkVBinding.remarkEt.setText(remark);
            wkVBinding.remarkEt.setSelection(remark.length());
            updateCharCount(remark.length());
        }
    }

    @Override
    protected void initListener() {
        wkVBinding.remarkEt.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
            }

            @Override
            public void afterTextChanged(Editable s) {
                updateCharCount(s.length());
            }
        });

        SingleClickUtil.onSingleClick(wkVBinding.saveBtn, v -> {
            String remark = wkVBinding.remarkEt.getText().toString().trim();
            Intent resultIntent = new Intent();
            resultIntent.putExtra(KEY_NOTE_ID, noteId);
            resultIntent.putExtra(KEY_NOTE_REMARK, remark);
            setResult(RESULT_OK, resultIntent);
            WKToastUtils.getInstance().showToastNormal("保存成功");
            finish();
        });
    }

    private void updateCharCount(int length) {
        wkVBinding.charCountTv.setText(length + "/200");
    }
}
