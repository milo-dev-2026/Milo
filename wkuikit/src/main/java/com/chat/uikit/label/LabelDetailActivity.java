package com.chat.uikit.label;

import android.content.Intent;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActLabelDetailLayoutBinding;
import com.chat.uikit.label.LabelStorageManager;

import java.util.ArrayList;
import java.util.List;

import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

/**
 * 标签详情页面
 */
public class LabelDetailActivity extends WKBaseActivity<ActLabelDetailLayoutBinding> {

    public static final String KEY_LABEL_ID = "label_id";
    public static final String KEY_LABEL_NAME = "label_name";

    private String labelId;
    private String labelName;
    private boolean isEdit = false;
    private List<LabelEntity.LabelMember> memberList = new ArrayList<>();
    private LabelMemberAdapter adapter;

    @Override
    protected ActLabelDetailLayoutBinding getViewBinding() {
        return ActLabelDetailLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(isEdit ? R.string.str_label_create_title : R.string.str_label);
    }

    @Override
    protected void initPresenter() {
        if (getIntent() != null) {
            labelId = getIntent().getStringExtra(KEY_LABEL_ID);
            labelName = getIntent().getStringExtra(KEY_LABEL_NAME);
            isEdit = !TextUtils.isEmpty(labelId);
        }
    }

    @Override
    protected void initView() {
        if (isEdit) {
            wkVBinding.nameEt.setText(labelName);
            wkVBinding.deleteBtn.setVisibility(View.VISIBLE);
        } else {
            wkVBinding.deleteBtn.setVisibility(View.GONE);
        }

        GridLayoutManager layoutManager = new GridLayoutManager(this, 5);
        wkVBinding.recyclerView.setLayoutManager(layoutManager);
        adapter = new LabelMemberAdapter(memberList);
        adapter.setShowAddButton(true);
        wkVBinding.recyclerView.setAdapter(adapter);

        // 加载模拟成员数据
        loadMockMembers();
    }

    @Override
    protected void initListener() {
        // 删除成员
        adapter.setOnMemberDeleteListener(position -> {
            memberList.remove(position);
            adapter.notifyItemRemoved(position);
            WKToastUtils.getInstance().showToastNormal("已移除成员");
        });

        // 添加成员
        adapter.setOnAddMemberListener(() -> {
            WKToastUtils.getInstance().showToastNormal("添加联系人");
        });

        // 删除标签
        SingleClickUtil.onSingleClick(wkVBinding.deleteBtn, v -> {
            if (!TextUtils.isEmpty(labelId)) {
                LabelStorageManager.getInstance(this).deleteLabel(labelId);
            }
            WKToastUtils.getInstance().showToastNormal("标签已删除");
            setResult(RESULT_OK);
            finish();
        });
    }

    /**
     * 加载成员数据
     */
    private void loadMockMembers() {
        memberList.clear();

        if (isEdit && !TextUtils.isEmpty(labelId)) {
            LabelEntity label = LabelStorageManager.getInstance(this).getLabel(labelId);
            if (label != null && label.members != null) {
                memberList.addAll(label.members);
            }
        }

        adapter.notifyDataSetChanged();
    }

    private String[] getMemberNamesByLabel(String labelName) {
        switch (labelName) {
            case "家人":
                return new String[]{"爸爸", "妈妈", "哥哥", "姐姐", "爷爷"};
            case "朋友":
                return new String[]{"张三", "李四", "王五", "赵六", "钱七", "孙八", "周九", "吴十"};
            case "同事":
                return new String[]{"产品经理", "设计师", "前端开发", "后端开发", "测试工程师", "运维工程师", "项目经理", "HR", "财务", "行政"};
            case "同学":
                return new String[]{"小明", "小红", "小刚", "小丽", "小华", "小强", "小芳", "小军"};
            case "客户":
                return new String[]{"客户A", "客户B", "客户C", "客户D", "客户E", "客户F", "客户G", "客户H", "客户I", "客户J"};
            case "重要联系人":
                return new String[]{"老板", "秘书", "合伙人"};
            default:
                return new String[]{};
        }
    }
}
