package com.chat.uikit.label;

import android.content.Intent;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActLabelLayoutBinding;

import java.util.ArrayList;
import java.util.List;

import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

/**
 * 标签列表页面
 */
public class LabelActivity extends WKBaseActivity<ActLabelLayoutBinding> {

    public static final int REQUEST_CODE_DETAIL = 1001;

    private List<LabelEntity> labelList = new ArrayList<>();
    private LabelAdapter adapter;

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
    }

    @Override
    protected void initView() {
        LinearLayoutManager layoutManager = new LinearLayoutManager(this);
        wkVBinding.recyclerView.setLayoutManager(layoutManager);
        adapter = new LabelAdapter(labelList);
        wkVBinding.recyclerView.setAdapter(adapter);

        loadLabels();
    }

    @Override
    protected void initListener() {
        adapter.setOnItemClickListener(position -> {
            LabelEntity label = labelList.get(position);
            Intent intent = new Intent(LabelActivity.this, LabelDetailActivity.class);
            intent.putExtra(LabelDetailActivity.KEY_LABEL_ID, label.id);
            intent.putExtra(LabelDetailActivity.KEY_LABEL_NAME, label.name);
            startActivityForResult(intent, REQUEST_CODE_DETAIL);
        });
    }

    /**
     * 加载标签数据
     */
    private void loadLabels() {
        labelList.clear();
        labelList.addAll(LabelStorageManager.getInstance(this).getAllLabels());

        if (labelList.isEmpty()) {
            String[] names = {"家人", "朋友", "同事", "同学", "客户", "重要联系人"};
            int[] counts = {5, 12, 25, 8, 30, 3};
            for (int i = 0; i < names.length; i++) {
                LabelEntity label = new LabelEntity();
                label.id = "label_" + (i + 1);
                label.name = names[i];
                label.memberCount = counts[i];
                for (int j = 0; j < Math.min(counts[i], 5); j++) {
                    LabelEntity.LabelMember member = new LabelEntity.LabelMember();
                    member.uid = "user_" + i + "_" + j;
                    member.name = getMockName(i, j);
                    label.members.add(member);
                }
                LabelStorageManager.getInstance(this).saveLabel(label);
                labelList.add(label);
            }
        }

        updateEmptyView();
        adapter.notifyDataSetChanged();
    }

    private String getMockName(int labelIndex, int memberIndex) {
        String[][] names = {
                {"爸爸", "妈妈", "哥哥", "姐姐", "爷爷"},
                {"张三", "李四", "王五", "赵六", "钱七", "孙八", "周九", "吴十", "郑十一", "王十二", "冯十三", "陈十四"},
                {"产品经理", "设计师", "前端开发", "后端开发", "测试工程师", "运维工程师", "项目经理", "HR", "财务", "行政",
                        "销售1", "销售2", "销售3", "市场1", "市场2", "运营1", "运营2", "技术总监", "CTO", "CEO",
                        "实习生1", "实习生2", "实习生3", "实习生4", "实习生5"},
                {"小明", "小红", "小刚", "小丽", "小华", "小强", "小芳", "小军"},
                {"客户A", "客户B", "客户C", "客户D", "客户E", "客户F", "客户G", "客户H", "客户I", "客户J",
                        "客户K", "客户L", "客户M", "客户N", "客户O", "客户P", "客户Q", "客户R", "客户S", "客户T",
                        "客户U", "客户V", "客户W", "客户X", "客户Y", "客户Z", "客户AA", "客户AB", "客户AC", "客户AD"},
                {"老板", "秘书", "合伙人"}
        };
        if (labelIndex < names.length && memberIndex < names[labelIndex].length) {
            return names[labelIndex][memberIndex];
        }
        return "成员" + (memberIndex + 1);
    }

    private void updateEmptyView() {
        if (labelList.isEmpty()) {
            wkVBinding.noDataView.setVisibility(View.VISIBLE);
            wkVBinding.recyclerView.setVisibility(View.GONE);
        } else {
            wkVBinding.noDataView.setVisibility(View.GONE);
            wkVBinding.recyclerView.setVisibility(View.VISIBLE);
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_CODE_DETAIL && resultCode == RESULT_OK) {
            loadLabels();
        }
    }
}
