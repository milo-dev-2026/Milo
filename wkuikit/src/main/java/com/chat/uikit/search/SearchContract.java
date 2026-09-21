package com.chat.uikit.search;

import com.chat.base.base.WKBasePresenter;
import com.chat.base.base.WKBaseView;

public class SearchContract {
    public interface SearchUserPresenter extends WKBasePresenter {
        void searchUser(String keyword);
    }

    public interface SearchUserView extends WKBaseView {
        void setSearchUser(SearchUserEntity searchUser);
    }
}
