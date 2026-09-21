package com.chat.uikit.group;

import android.annotation.SuppressLint;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.text.InputFilter;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKConfig;
import com.chat.base.entity.PopupMenuItem;
import com.chat.base.msgitem.WKChannelMemberRole;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.utils.SoftKeyboardUtils;
import com.chat.base.utils.StringUtils;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActGroupNoticeLayoutBinding;
import com.chat.uikit.group.service.GroupModel;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannelMember;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.ArrayList;
import java.util.List;

/**
 * 2020-01-26 16:03
 * 群公告
 */
public class GroupNoticeActivity extends WKBaseActivity<ActGroupNoticeLayoutBinding> {

    private String groupNo, oldNotice;
    private TextView titleRightTv;

    @Override
    protected ActGroupNoticeLayoutBinding getViewBinding() {
        return ActGroupNoticeLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.group_announcement);
    }

    @Override
    protected String getRightTvText(TextView textView) {
        titleRightTv = textView;
        return getString(R.string.save);
    }

    @Override
    protected boolean hideStatusBar() {
        return false;
    }

    @Override
    protected void rightLayoutClick() {
        super.rightLayoutClick();
        if (TextUtils.isEmpty(groupNo)) return;
        String content = wkVBinding.contentEt.getText() != null ? wkVBinding.contentEt.getText().toString() : "";
//        content = StringUtils.replaceBlank(content);
        if ((!TextUtils.isEmpty(oldNotice) && content.equals(oldNotice))) {
            return;
        }
        showTitleRightLoading();
        GroupModel.getInstance().updateGroupInfo(groupNo, "notice", content, (code, msg) -> {
            hideTitleRightLoading();
            if (code == HttpResponseCode.success) {
                finish();
            } else {
                showToast(msg);
            }
        });
    }

    @SuppressLint("ClickableViewAccessibility")
    @Override
    protected void initView() {
        List<PopupMenuItem> list = new ArrayList<>();
        list.add(new PopupMenuItem(getString(R.string.copy), R.mipmap.msg_copy, () -> {
            ClipboardManager cm = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
            String content = wkVBinding.contentEt.getText() != null ? wkVBinding.contentEt.getText().toString() : "";
            if (cm != null && !TextUtils.isEmpty(content)) {
                ClipData mClipData = ClipData.newPlainText("Label", content);
                cm.setPrimaryClip(mClipData);
                WKToastUtils.getInstance().showToastNormal(getString(R.string.copyed));
            }
        }));
        WKDialogUtils.getInstance().setViewLongClickPopup(wkVBinding.contentEt,list);
    }

    @Override
    protected void initListener() {
        wkVBinding.contentEt.addTextChangedListener(new android.text.TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                String content = s != null ? s.toString() : "";
                // 内容为空时隐藏保存按钮，有内容且有权限时显示
                if (titleRightTv != null && wkVBinding.contentEt.isEnabled()) {
                    titleRightTv.setVisibility(TextUtils.isEmpty(content) ? View.GONE : View.VISIBLE);
                }
            }

            @Override
            public void afterTextChanged(android.text.Editable s) {
            }
        });
    }

    @Override
    protected void initData() {
        super.initData();

        groupNo = getIntent().getStringExtra("groupNo");
        if (TextUtils.isEmpty(groupNo)) {
            finish();
            return;
        }
        oldNotice = getIntent().getStringExtra("oldNotice");

        WKChannelMember member = WKIM.getInstance().getChannelMembersManager().getMember(groupNo, WKChannelType.GROUP, WKConfig.getInstance().getUid());
        wkVBinding.contentEt.setText(oldNotice);
        if (!TextUtils.isEmpty(oldNotice))
            wkVBinding.contentEt.setSelection(oldNotice.length());

        if (member != null && member.role != WKChannelMemberRole.normal) {
            wkVBinding.contentEt.setEnabled(true);
            titleRightTv.setVisibility(View.VISIBLE);
            wkVBinding.contentEt.requestFocus();
            SoftKeyboardUtils.getInstance().showSoftKeyBoard(this, wkVBinding.contentEt);
        } else {
            wkVBinding.contentEt.setFocusableInTouchMode(false);
            wkVBinding.contentEt.setEnabled(true);
            titleRightTv.setVisibility(View.GONE);
        }
        if (member != null) {
            wkVBinding.bottomView.setVisibility(member.role == WKChannelMemberRole.normal ? View.VISIBLE : View.GONE);
        }
        wkVBinding.contentEt.setFilters(new InputFilter[]{StringUtils.getInputFilter(300)});
    }

    @Override
    public void finish() {
        super.finish();
        SoftKeyboardUtils.getInstance().hideSoftKeyboard(this);
    }
}
