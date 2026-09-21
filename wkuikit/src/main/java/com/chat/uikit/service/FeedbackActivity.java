package com.chat.uikit.service;

import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.entity.BottomSheetItem;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityFeedbackBinding;

import java.util.ArrayList;
import java.util.List;

/**
 * 意见反馈页面
 */
public class FeedbackActivity extends WKBaseActivity<ActivityFeedbackBinding> {

    private static final int MAX_CONTENT_LENGTH = 500;
    private String feedbackType = "功能建议";
    private int selectedTypeIndex = 0;

    private final String[] typeOptions = {
            "功能建议",
            "Bug反馈",
            "体验问题",
            "其他问题"
    };

    @Override
    protected ActivityFeedbackBinding getViewBinding() {
        return ActivityFeedbackBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText("意见反馈");
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        wkVBinding.typeTv.setText(feedbackType);
        updateSubmitButton();
    }

    @Override
    protected void initListener() {
        // 选择反馈类型
        SingleClickUtil.onSingleClick(wkVBinding.typeLayout, v -> showTypeSelector());

        // 内容输入监听
        wkVBinding.contentEt.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
            }

            @Override
            public void afterTextChanged(Editable s) {
                int length = s.length();
                if (length > MAX_CONTENT_LENGTH) {
                    wkVBinding.contentEt.setText(s.subSequence(0, MAX_CONTENT_LENGTH));
                    wkVBinding.contentEt.setSelection(MAX_CONTENT_LENGTH);
                    length = MAX_CONTENT_LENGTH;
                }
                wkVBinding.countTv.setText(length + "/" + MAX_CONTENT_LENGTH);
                updateSubmitButton();
            }
        });

        // 提交按钮
        SingleClickUtil.onSingleClick(wkVBinding.submitBtn, v -> submitFeedback());
    }

    /**
     * 显示类型选择器
     */
    private void showTypeSelector() {
        List<BottomSheetItem> itemList = new ArrayList<>();
        for (int i = 0; i < typeOptions.length; i++) {
            final int index = i;
            BottomSheetItem item = new BottomSheetItem(typeOptions[i], 0, () -> {
                selectedTypeIndex = index;
                feedbackType = typeOptions[index];
                wkVBinding.typeTv.setText(feedbackType);
            });
            itemList.add(item);
        }
        WKDialogUtils.getInstance().showBottomSheet(this, "选择反馈类型", false, itemList);
    }

    /**
     * 更新提交按钮状态
     */
    private void updateSubmitButton() {
        String content = wkVBinding.contentEt.getText().toString().trim();
        boolean enabled = !TextUtils.isEmpty(content);
        wkVBinding.submitBtn.setEnabled(enabled);
        wkVBinding.submitBtn.setAlpha(enabled ? 1.0f : 0.2f);
    }

    /**
     * 提交反馈
     */
    private void submitFeedback() {
        String content = wkVBinding.contentEt.getText().toString().trim();
        String contact = wkVBinding.contactEt.getText().toString().trim();

        if (TextUtils.isEmpty(content)) {
            WKToastUtils.getInstance().showToastNormal("请输入反馈内容");
            return;
        }

        // 模拟提交反馈
        WKToastUtils.getInstance().showToastNormal("反馈提交成功，感谢您的宝贵意见！");
        finish();
    }
}
