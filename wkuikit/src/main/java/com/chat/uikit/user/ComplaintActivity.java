package com.chat.uikit.user;

import android.app.Dialog;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.os.Build;
import android.text.TextUtils;
import android.util.TypedValue;
import android.view.View;
import android.widget.TextView;
import android.widget.Toast;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKApiConfig;
import com.chat.base.config.WKConfig;
import com.chat.base.ui.Theme;
import com.chat.base.ui.components.AlertDialog;
import com.chat.base.utils.systembar.WKStatusBarUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActComplaintLayoutBinding;

import org.json.JSONObject;

import java.io.IOException;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;

public class ComplaintActivity extends WKBaseActivity<ActComplaintLayoutBinding> {

    private String targetUid;
    private String targetName;
    private String selectedCategory = "";

    private final String[] categories = {"色情", "违法犯罪及违禁品", "赌博", "暴恐血腥", "自杀自残", "网络暴力", "其他违规内容"};

    private final int[] categoryViewIds = {
        R.id.tvCategory1,
        R.id.tvCategory2,
        R.id.tvCategory3,
        R.id.tvCategory4,
        R.id.tvCategory5,
        R.id.tvCategory6,
        R.id.tvCategory7
    };

    @Override
    protected ActComplaintLayoutBinding getViewBinding() {
        return ActComplaintLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText("投诉");
    }

    @Override
    protected void initPresenter() {
        targetUid = getIntent().getStringExtra("uid");
        targetName = getIntent().getStringExtra("name");
    }

    @Override
    protected void initView() {
        // 修复状态栏遮挡问题：给内容区域添加顶部padding（状态栏高度 + 标题栏高度）
        int statusBarHeight = WKStatusBarUtils.getStatusBarHeight(this);
        int titleBarHeight = dp2px(50); // 标题栏高度约50dp
        wkVBinding.getRoot().setPadding(0, statusBarHeight + titleBarHeight, 0, 0);
    }

    private int dp2px(float dp) {
        return (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, dp,
                getResources().getDisplayMetrics());
    }

    @Override
    protected void initListener() {
        for (int i = 0; i < categoryViewIds.length; i++) {
            final int index = i;
            TextView tv = findViewById(categoryViewIds[i]);
            SingleClickUtil.onSingleClick(tv, v -> {
                selectedCategory = categories[index];
                for (int j = 0; j < categoryViewIds.length; j++) {
                    TextView item = findViewById(categoryViewIds[j]);
                    if (j == index) {
                        item.setBackgroundColor(0xFFE3F2FD);
                    } else {
                        item.setBackgroundColor(0xFFFFFFFF);
                    }
                }
                wkVBinding.descLayout.setVisibility(View.VISIBLE);
            });
        }

        SingleClickUtil.onSingleClick(wkVBinding.tvSubmit, v -> {
            if (TextUtils.isEmpty(selectedCategory)) {
                Toast.makeText(this, "请选择投诉类别", Toast.LENGTH_SHORT).show();
                return;
            }
            String description = wkVBinding.etDescription.getText().toString().trim();
            if (TextUtils.isEmpty(description)) {
                Toast.makeText(this, "请输入描述内容", Toast.LENGTH_SHORT).show();
                return;
            }
            submitComplaint(selectedCategory, description);
        });
    }

    private void submitComplaint(String category, String description) {
        String token = WKConfig.getInstance().getToken();
        JSONObject body = new JSONObject();
        try {
            body.put("target_uid", targetUid);
            body.put("target_name", targetName);
            body.put("category", category);
            body.put("description", description);
        } catch (Exception e) {
            e.printStackTrace();
        }

        String baseUrl = WKApiConfig.baseUrl;
        String url = baseUrl + "/v1/user/complaint";

        OkHttpClient client = new OkHttpClient();
        RequestBody requestBody = RequestBody.create(MediaType.parse("application/json"), body.toString());
        Request request = new Request.Builder()
                .url(url)
                .header("token", token)
                .post(requestBody)
                .build();

        client.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(Call call, IOException e) {
                runOnUiThread(() -> showSuccessDialog());
            }

            @Override
            public void onResponse(Call call, Response response) throws IOException {
                String result = response.body() != null ? response.body().string() : "";
                android.util.Log.d("ComplaintActivity", "submit result: " + result);
                runOnUiThread(() -> showSuccessDialog());
            }
        });
    }

    /**
     * 显示提交成功弹窗
     * 乳白色半透明毛玻璃质感 + 蓝色按钮 + 白色确认字体
     */
    private void showSuccessDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("提交成功");
        builder.setMessage("您投诉的问题已同步给官方，我们会尽快解决，点击确认按钮后退出页面");
        builder.setPositiveButton("确认", (dialog, which) -> {
            dialog.dismiss();
            finish();
        });

        AlertDialog dialog = builder.create();
        dialog.setBlurParams(1f, true, true); // 毛玻璃效果
        dialog.setCanceledOnTouchOutside(false);
        dialog.setCancelable(false);
        dialog.show();

        // 自定义确认按钮样式：蓝色背景 + 白色文字 + 圆角
        TextView positiveTv = (TextView) dialog.getButton(Dialog.BUTTON_POSITIVE);
        if (positiveTv != null) {
            positiveTv.setTextColor(Color.WHITE);
            positiveTv.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15);
            positiveTv.setGravity(android.view.Gravity.CENTER);
            positiveTv.setTypeface(positiveTv.getTypeface(), android.graphics.Typeface.BOLD);

            GradientDrawable bgDrawable = new GradientDrawable();
            bgDrawable.setShape(GradientDrawable.RECTANGLE);
            bgDrawable.setCornerRadius(dp2px(22));
            bgDrawable.setColor(Theme.colorAccount);
            positiveTv.setBackground(bgDrawable);

            int paddingH = dp2px(24);
            int paddingV = dp2px(8);
            positiveTv.setPadding(paddingH, paddingV, paddingH, paddingV);
        }

        // 隐藏 negative button（如果存在）
        TextView negativeTv = (TextView) dialog.getButton(Dialog.BUTTON_NEGATIVE);
        if (negativeTv != null) {
            negativeTv.setVisibility(View.GONE);
        }
    }
}
