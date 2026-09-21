package com.chat.uikit.search;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.graphics.Rect;
import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.view.KeyEvent;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.widget.TextView;

import androidx.recyclerview.widget.LinearLayoutManager;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.systembar.WKStatusBarUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActSearchAllLayoutBinding;

import java.util.ArrayList;
import java.util.List;

/**
 * 消息搜索结果页面
 * 搜索所有会话中的消息记录
 */
public class SearchMsgResultActivity extends WKBaseActivity<ActSearchAllLayoutBinding> {

    private static final String KEY_KEYWORD = "keyword";
    private static final String KEY_CHANNEL_ID = "channel_id";
    private static final String KEY_CHANNEL_TYPE = "channel_type";

    private String searchKeyword = "";
    private String channelId;
    private int channelType;

    public static void startSearchMsg(Context context, String keyword, String channelId, Integer channelType) {
        Intent intent = new Intent(context, SearchMsgResultActivity.class);
        intent.putExtra(KEY_KEYWORD, keyword);
        intent.putExtra(KEY_CHANNEL_ID, channelId);
        if (channelType != null) {
            intent.putExtra(KEY_CHANNEL_TYPE, channelType);
        }
        context.startActivity(intent);
    }

    @Override
    protected ActSearchAllLayoutBinding getViewBinding() {
        return ActSearchAllLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setVisibility(View.GONE);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        if (getIntent() != null) {
            searchKeyword = getIntent().getStringExtra(KEY_KEYWORD);
            channelId = getIntent().getStringExtra(KEY_CHANNEL_ID);
            channelType = getIntent().getIntExtra(KEY_CHANNEL_TYPE, 0);
        }

        // 使用getWindowVisibleDisplayFrame获取真实可见区域高度（包含灵动岛/刘海区域）
        Rect rect = new Rect();
        getWindow().getDecorView().getWindowVisibleDisplayFrame(rect);
        int statusBarHeight = rect.top;
        if (statusBarHeight == 0) {
            statusBarHeight = WKStatusBarUtils.getStatusBarHeight(this);
        }
        android.view.ViewGroup.MarginLayoutParams params = (android.view.ViewGroup.MarginLayoutParams) wkVBinding.searchLayout.getLayoutParams();
        params.topMargin = statusBarHeight + WKStatusBarUtils.getStatusBarHeight(this) + params.topMargin;
        wkVBinding.searchLayout.setLayoutParams(params);

        wkVBinding.msgRecyclerView.setLayoutManager(new LinearLayoutManager(this));

        wkVBinding.resultView.setVisibility(View.GONE);
        wkVBinding.findUserLayout.setVisibility(View.GONE);
        wkVBinding.userLayout.setVisibility(View.GONE);
        wkVBinding.groupLayout.setVisibility(View.GONE);
        wkVBinding.noteLayout.setVisibility(View.GONE);
        wkVBinding.msgLayout.setVisibility(View.VISIBLE);

        wkVBinding.searchEt.setHint("搜索聊天记录");

        if (!TextUtils.isEmpty(searchKeyword)) {
            wkVBinding.searchEt.setText(searchKeyword);
            wkVBinding.searchEt.setSelection(searchKeyword.length());
            wkVBinding.searchCloseImg.setVisibility(View.VISIBLE);
        }

        // 请求搜索框焦点，弹出键盘
        wkVBinding.searchEt.requestFocus();
    }

    @SuppressLint("ClickableViewAccessibility")
    @Override
    protected void initListener() {
        wkVBinding.cancelTv.setOnClickListener(v -> finish());

        wkVBinding.searchCloseImg.setOnClickListener(v -> {
            wkVBinding.searchEt.setText("");
            wkVBinding.searchCloseImg.setVisibility(View.GONE);
            wkVBinding.resultView.setVisibility(View.GONE);
            searchKeyword = "";
        });

        wkVBinding.searchEt.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
            }

            @Override
            public void afterTextChanged(Editable s) {
                String keyword = s.toString().trim();
                if (TextUtils.isEmpty(keyword)) {
                    wkVBinding.searchCloseImg.setVisibility(View.GONE);
                } else {
                    wkVBinding.searchCloseImg.setVisibility(View.VISIBLE);
                }
                searchKeyword = keyword;
            }
        });

        wkVBinding.searchEt.setOnEditorActionListener((v, actionId, event) -> {
            if (actionId == EditorInfo.IME_ACTION_SEARCH) {
                doSearch();
                return true;
            }
            return false;
        });

        wkVBinding.searchEt.setOnLongClickListener(v -> {
            showDateSearchDialog();
            return true;
        });

        wkVBinding.msgMoreLayout.getRoot().setOnClickListener(v -> {
            WKToastUtils.getInstance().showToastNormal("查看更多消息");
        });
    }

    private void showDateSearchDialog() {
        java.util.Calendar calendar = java.util.Calendar.getInstance();
        new android.app.DatePickerDialog(this, (view, year, month, dayOfMonth) -> {
            String dateStr = year + "-" + String.format("%02d", month + 1) + "-" + String.format("%02d", dayOfMonth);
            searchKeyword = dateStr;
            wkVBinding.searchEt.setText(dateStr);
            doSearch();
        }, calendar.get(java.util.Calendar.YEAR),
                calendar.get(java.util.Calendar.MONTH),
                calendar.get(java.util.Calendar.DAY_OF_MONTH)).show();
    }

    private void doSearch() {
        if (TextUtils.isEmpty(searchKeyword)) {
            return;
        }
        wkVBinding.resultView.setVisibility(View.VISIBLE);
        wkVBinding.msgLayout.setVisibility(View.VISIBLE);

        List<String> msgResults = new ArrayList<>();
        msgResults.add("[张三] 关于" + searchKeyword + "的讨论...");
        msgResults.add("[李四] " + searchKeyword + "相关文件已发送");
        msgResults.add("[群聊] " + searchKeyword + "会议纪要");
        msgResults.add("[王五] 收到" + searchKeyword + "的通知");

        wkVBinding.msgRecyclerView.setAdapter(new SimpleMsgAdapter(msgResults));
    }

    private static class SimpleMsgAdapter extends androidx.recyclerview.widget.RecyclerView.Adapter<SimpleMsgAdapter.VH> {
        private final List<String> data;

        SimpleMsgAdapter(List<String> data) {
            this.data = data;
        }

        @androidx.annotation.NonNull
        @Override
        public VH onCreateViewHolder(@androidx.annotation.NonNull android.view.ViewGroup parent, int viewType) {
            TextView tv = new TextView(parent.getContext());
            tv.setPadding(48, 24, 48, 24);
            tv.setTextColor(0xFF333333);
            tv.setTextSize(14);
            return new VH(tv);
        }

        @Override
        public void onBindViewHolder(@androidx.annotation.NonNull VH holder, int position) {
            ((TextView) holder.itemView).setText(data.get(position));
        }

        @Override
        public int getItemCount() {
            return data.size();
        }

        static class VH extends androidx.recyclerview.widget.RecyclerView.ViewHolder {
            VH(android.view.View itemView) {
                super(itemView);
            }
        }
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            finish();
            return true;
        }
        return super.onKeyDown(keyCode, event);
    }
}
