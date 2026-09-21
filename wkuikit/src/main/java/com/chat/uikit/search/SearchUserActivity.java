package com.chat.uikit.search;

import android.content.Context;
import android.content.Intent;
import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.view.KeyEvent;
import android.view.inputmethod.EditorInfo;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.ui.Theme;
import com.chat.base.utils.SoftKeyboardUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActSearchUserLayoutBinding;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannel;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class SearchUserActivity extends WKBaseActivity<ActSearchUserLayoutBinding> implements SearchContract.SearchUserView {

    private static final String KEY_KEYWORD = "keyword";
    private SearchUserAdapter searchUserAdapter;
    private SearchUserPresenter presenter;

    public static void startSearchUser(Context context, String keyword) {
        Intent intent = new Intent(context, SearchUserActivity.class);
        intent.putExtra(KEY_KEYWORD, keyword);
        context.startActivity(intent);
    }

    @Override
    protected ActSearchUserLayoutBinding getViewBinding() {
        return ActSearchUserLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.add_friends);
    }

    @Override
    protected void initPresenter() {
        presenter = new SearchUserPresenter(this);
    }

    @Override
    protected void initView() {
        wkVBinding.searchBtn.setTextColor(Theme.colorAccount);
        searchUserAdapter = new SearchUserAdapter(new ArrayList<>());
        initAdapter(wkVBinding.recyclerView, searchUserAdapter);
        SoftKeyboardUtils.getInstance().showSoftKeyBoard(SearchUserActivity.this, wkVBinding.searchEt);
        String phone = getIntent().getStringExtra("phone");
        if (!TextUtils.isEmpty(phone)) {
            wkVBinding.searchEt.setText(phone);
            wkVBinding.searchEt.setSelection(phone.length());
            wkVBinding.searchBtn.setEnabled(true);
            wkVBinding.searchBtn.setAlpha(1f);
        }
    }

    @Override
    protected void initListener() {
        wkVBinding.searchEt.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
            }

            @Override
            public void afterTextChanged(Editable s) {
                String content = s.toString();
                if (!TextUtils.isEmpty(content)) {
                    wkVBinding.searchBtn.setEnabled(true);
                    wkVBinding.searchBtn.setAlpha(1f);
                } else {
                    wkVBinding.searchBtn.setEnabled(false);
                    wkVBinding.searchBtn.setAlpha(0.2f);
                }
            }
        });
        searchUserAdapter.setOnItemClickListener((adapter, view1, position) -> {
            SearchUserEntity searchUserEntity = (SearchUserEntity) adapter.getItem(position);
            if (searchUserEntity != null && searchUserEntity.itemType == 0 && searchUserEntity.data != null) {
                SoftKeyboardUtils.getInstance().hideSoftKeyboard(SearchUserActivity.this);
                Intent intent = new Intent(this, com.chat.uikit.user.UserDetailActivity.class);
                intent.putExtra("uid", searchUserEntity.data.uid);
                intent.putExtra("vercode", searchUserEntity.data.vercode);
                startActivity(intent);
            }
        });
        SingleClickUtil.onSingleClick(wkVBinding.searchBtn, v -> {
            String keyword = Objects.requireNonNull(wkVBinding.searchEt.getText()).toString();
            searchUserAdapter.setSearchKey(keyword);
            presenter.searchUser(keyword);
        });
        // 键盘搜索按钮触发搜索
        wkVBinding.searchEt.setOnEditorActionListener((v, actionId, event) -> {
            if (actionId == EditorInfo.IME_ACTION_SEARCH
                    || (event != null && event.getKeyCode() == KeyEvent.KEYCODE_ENTER && event.getAction() == KeyEvent.ACTION_DOWN)) {
                String keyword = Objects.requireNonNull(wkVBinding.searchEt.getText()).toString();
                if (!TextUtils.isEmpty(keyword) && wkVBinding.searchBtn.isEnabled()) {
                    searchUserAdapter.setSearchKey(keyword);
                    presenter.searchUser(keyword);
                    SoftKeyboardUtils.getInstance().hideSoftKeyboard(SearchUserActivity.this);
                }
                return true;
            }
            return false;
        });
    }

    public void setSearchUser(SearchUserEntity searchUser) {
        List<SearchUserEntity> list = new ArrayList<>();
        if (searchUser != null && searchUser.exist == 1) {
            WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(searchUser.data.uid, WKChannelType.PERSONAL);
            if (channel != null && channel.follow == 1 && channel.isDeleted == 0) {
                searchUser.showApply = false;
            }
            list.add(searchUser);
        } else {
            SearchUserEntity searchUserEntity = new SearchUserEntity();
            searchUserEntity.itemType = 1;
            list.add(searchUserEntity);
        }
        searchUserAdapter.setList(list);
    }

    @Override
    protected void initData() {
        super.initData();
        if (getIntent().hasExtra(KEY_KEYWORD)) {
            String searchKey = getIntent().getStringExtra(KEY_KEYWORD);
            if (!TextUtils.isEmpty(searchKey)) {
                wkVBinding.searchEt.setText(searchKey);
                wkVBinding.searchEt.setSelection(searchKey.length());
                searchUserAdapter.setSearchKey(searchKey);
                presenter.searchUser(searchKey);
            }
        }
    }

    @Override
    public void finish() {
        super.finish();
        SoftKeyboardUtils.getInstance().hideInput(this, wkVBinding.searchEt);
    }

    @Override
    public void showError(String msg) {
    }

    @Override
    public void hideLoading() {
    }
}
