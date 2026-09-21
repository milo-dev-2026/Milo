package com.chat.uikit.contacts.service;

import java.util.List;

public class SearchUserResult {
    public List<UserItem> list;
    public int page;
    public int page_size;
    public int total;

    public static class UserItem {
        public String uid;
        public String username;
        public String nickname;
        public String avatar;
        public String sign;
    }
}
