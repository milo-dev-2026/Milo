package com.chat.uikit.search;

import com.chat.base.net.HttpResponseCode;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.search.service.SearchModel;

import java.lang.ref.WeakReference;

public class SearchUserPresenter implements SearchContract.SearchUserPresenter {
    private final WeakReference<SearchContract.SearchUserView> userViewWeakReference;

    public SearchUserPresenter(SearchContract.SearchUserView searchUserView) {
        userViewWeakReference = new WeakReference<>(searchUserView);
    }

    @Override
    public void searchUser(String keyword) {
        SearchModel.getInstance().searchUser(keyword, (code, msg, searchUserEntity) -> {
            if (code == HttpResponseCode.success) {
                if (userViewWeakReference.get() != null)
                    userViewWeakReference.get().setSearchUser(searchUserEntity);
            } else WKToastUtils.getInstance().showToastFail(msg);
        });
    }

    @Override
    public void showLoading() {
    }
}
