package com.chat.uikit.search;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
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
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivitySearchMoreBinding;

/**
 * 更多搜索结果页面
 * 展示某一类别的完整搜索结果列表
 */
public class SearchMoreActivity extends WKBaseActivity<ActivitySearchMoreBinding> {

    private static final String KEY_KEYWORD = "keyword";
    private static final String KEY_TYPE = "type";

    private String searchKeyword = "";
    private int searchType = SearchMoreType.TYPE_USER;

    public static void startSearchMore(Context context, String keyword, int type) {
        Intent intent = new Intent(context, SearchMoreActivity.class);
        intent.putExtra(KEY_KEYWORD, keyword);
        intent.putExtra(KEY_TYPE, type);
        context.startActivity(intent);
    }

    @Override
    protected ActivitySearchMoreBinding getViewBinding() {
        return ActivitySearchMoreBinding.inflate(getLayoutInflater());
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
            searchType = getIntent().getIntExtra(KEY_TYPE, SearchMoreType.TYPE_USER);
        }

        wkVBinding.moreRecyclerView.setLayoutManager(new LinearLayoutManager(this));

        if (!TextUtils.isEmpty(searchKeyword)) {
            wkVBinding.searchEt.setText(searchKeyword);
            wkVBinding.searchEt.setSelection(searchKeyword.length());
            wkVBinding.searchCloseImg.setVisibility(View.VISIBLE);
        }

        updateTitleByType();
    }

    private void updateTitleByType() {
        String hint = "";
        switch (searchType) {
            case SearchMoreType.TYPE_USER:
                hint = "搜索联系人";
                break;
            case SearchMoreType.TYPE_GROUP:
                hint = "搜索群组";
                break;
            case SearchMoreType.TYPE_MESSAGE:
                hint = "搜索消息";
                break;
            case SearchMoreType.TYPE_NOTE:
                hint = "搜索笔记";
                break;
            case SearchMoreType.TYPE_CHANNEL:
                hint = "搜索频道";
                break;
            default:
                break;
        }
        wkVBinding.searchEt.setHint(hint);
    }

    @SuppressLint("ClickableViewAccessibility")
    @Override
    protected void initListener() {
        wkVBinding.cancelTv.setOnClickListener(v -> finish());

        wkVBinding.searchCloseImg.setOnClickListener(v -> {
            wkVBinding.searchEt.setText("");
            wkVBinding.searchCloseImg.setVisibility(View.GONE);
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

        wkVBinding.refreshLayout.setOnLoadMoreListener(refreshLayout -> {
            refreshLayout.finishLoadMoreWithNoMoreData();
        });
    }

    private void doSearch() {
        if (TextUtils.isEmpty(searchKeyword)) {
            return;
        }
        WKToastUtils.getInstance().showToastNormal("搜索: " + searchKeyword);
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
