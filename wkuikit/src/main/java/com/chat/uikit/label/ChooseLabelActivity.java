package com.chat.uikit.label;

import android.content.Intent;
import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActLabelLayoutBinding;

import java.util.ArrayList;
import java.util.List;

import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

/**
 * 选择标签页面
 */
public class ChooseLabelActivity extends WKBaseActivity<ActLabelLayoutBinding> {

    public static final String KEY_SELECTED_LABELS = "selected_labels";

    private List<LabelEntity> labelList = new ArrayList<>();
    private ChooseLabelAdapter adapter;
    private List<String> selectedLabelIds = new ArrayList<>();

    @Override
    protected ActLabelLayoutBinding getViewBinding() {
        return ActLabelLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.str_label);
    }

    @Override
    protected void initPresenter() {
        if (getIntent() != null) {
            ArrayList<String> selected = getIntent().getStringArrayListExtra(KEY_SELECTED_LABELS);
            if (selected != null) {
                selectedLabelIds.addAll(selected);
            }
        }
    }

    @Override
    protected void initView() {
        LinearLayoutManager layoutManager = new LinearLayoutManager(this);
        wkVBinding.recyclerView.setLayoutManager(layoutManager);
        adapter = new ChooseLabelAdapter(labelList);
        wkVBinding.recyclerView.setAdapter(adapter);

        // 加载模拟数据
        loadMockLabels();
    }

    @Override
    protected void initListener() {
        adapter.setOnLabelCheckListener((position, isChecked) -> {
            LabelEntity label = labelList.get(position);
            if (isChecked) {
                if (!selectedLabelIds.contains(label.id)) {
                    selectedLabelIds.add(label.id);
                }
            } else {
                selectedLabelIds.remove(label.id);
            }
        });
    }

    /**
     * 加载模拟标签数据
     */
    private void loadMockLabels() {
        labelList.clear();

        String[] names = {"家人", "朋友", "同事", "同学", "客户", "重要联系人"};
        int[] counts = {5, 12, 25, 8, 30, 3};

        for (int i = 0; i < names.length; i++) {
            LabelEntity label = new LabelEntity();
            label.id = "label_" + (i + 1);
            label.name = names[i];
            label.memberCount = counts[i];

            // 根据传入的已选标签设置选中状态
            if (selectedLabelIds.contains(label.id)) {
                LabelEntity.LabelMember member = new LabelEntity.LabelMember();
                member.isSelected = true;
                label.members.add(member);
            }

            labelList.add(label);
        }

        adapter.notifyDataSetChanged();
    }

    @Override
    public void onBackPressed() {
        // 返回时传递选中的标签
        Intent resultIntent = new Intent();
        resultIntent.putStringArrayListExtra(KEY_SELECTED_LABELS, new ArrayList<>(selectedLabelIds));
        setResult(RESULT_OK, resultIntent);
        super.onBackPressed();
    }
}
