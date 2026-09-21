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
import com.chat.uikit.databinding.ActSearchAllLayoutBinding;

/**
 * 会话搜索页面
 * 搜索会话列表
 */
public class SearchConversationActivity extends WKBaseActivity<ActSearchAllLayoutBinding> {

    private static final String KEY_KEYWORD = "keyword";
    private String searchKeyword = "";

    public static void startSearchConversation(Context context, String keyword) {
        Intent intent = new Intent(context, SearchConversationActivity.class);
        intent.putExtra(KEY_KEYWORD, keyword);
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
        }

        wkVBinding.userRecyclerView.setLayoutManager(new LinearLayoutManager(this));

        wkVBinding.resultView.setVisibility(View.GONE);
        wkVBinding.findUserLayout.setVisibility(View.GONE);
        wkVBinding.userLayout.setVisibility(View.GONE);
        wkVBinding.groupLayout.setVisibility(View.GONE);
        wkVBinding.noteLayout.setVisibility(View.GONE);
        wkVBinding.msgLayout.setVisibility(View.GONE);

        wkVBinding.searchEt.setHint("搜索会话");

        if (!TextUtils.isEmpty(searchKeyword)) {
            wkVBinding.searchEt.setText(searchKeyword);
            wkVBinding.searchEt.setSelection(searchKeyword.length());
            wkVBinding.searchCloseImg.setVisibility(View.VISIBLE);
        }
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
    }

    private void doSearch() {
        if (TextUtils.isEmpty(searchKeyword)) {
            return;
        }
        wkVBinding.resultView.setVisibility(View.VISIBLE);
        wkVBinding.userLayout.setVisibility(View.VISIBLE);
        WKToastUtils.getInstance().showToastNormal("搜索会话: " + searchKeyword);
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
