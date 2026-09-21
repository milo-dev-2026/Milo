package com.chat.uikit.search;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.view.KeyEvent;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.widget.TextView;

import androidx.recyclerview.widget.LinearLayoutManager;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKReader;
import com.chat.base.utils.systembar.WKStatusBarUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActSearchAllLayoutBinding;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannel;
import com.xinbida.wukongim.entity.WKChannelType;
import com.xinbida.wukongim.entity.WKUIConversationMsg;

import java.util.ArrayList;
import java.util.List;

/**
 * 全局搜索页面
 * 实时搜索联系人、群组、聊天记录
 */
public class SearchAllActivity extends WKBaseActivity<ActSearchAllLayoutBinding> {

    private String searchKeyword = "";
    private final Handler searchHandler = new Handler(Looper.getMainLooper());
    private Runnable searchRunnable;
    private TextView emptyTv;

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
        int statusBarHeight = WKStatusBarUtils.getStatusBarHeight(this);
        android.view.ViewGroup.MarginLayoutParams params = (android.view.ViewGroup.MarginLayoutParams) wkVBinding.searchLayout.getLayoutParams();
        if (params != null) {
            params.topMargin = statusBarHeight + params.topMargin;
            wkVBinding.searchLayout.setLayoutParams(params);
        }

        wkVBinding.userRecyclerView.setLayoutManager(new LinearLayoutManager(this));
        wkVBinding.groupRecyclerView.setLayoutManager(new LinearLayoutManager(this));
        wkVBinding.msgRecyclerView.setLayoutManager(new LinearLayoutManager(this));
        wkVBinding.noteRecyclerView.setLayoutManager(new LinearLayoutManager(this));

        wkVBinding.resultView.setVisibility(View.GONE);

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
                    wkVBinding.resultView.setVisibility(View.GONE);
                    searchKeyword = "";
                    return;
                }
                wkVBinding.searchCloseImg.setVisibility(View.VISIBLE);
                searchKeyword = keyword;

                // 防抖搜索：200ms后执行
                if (searchRunnable != null) {
                    searchHandler.removeCallbacks(searchRunnable);
                }
                searchRunnable = () -> doSearch(keyword);
                searchHandler.postDelayed(searchRunnable, 200);
            }
        });

        wkVBinding.searchEt.setOnEditorActionListener((v, actionId, event) -> {
            if (actionId == EditorInfo.IME_ACTION_SEARCH) {
                if (!TextUtils.isEmpty(searchKeyword)) {
                    if (searchRunnable != null) {
                        searchHandler.removeCallbacks(searchRunnable);
                    }
                    doSearch(searchKeyword);
                }
                return true;
            }
            return false;
        });

        wkVBinding.findUserLayout.setOnClickListener(v -> {
            if (!TextUtils.isEmpty(searchKeyword)) {
                SearchUserActivity.startSearchUser(this, searchKeyword);
            }
        });

        wkVBinding.userMoreLayout.getRoot().setOnClickListener(v -> {
            if (!TextUtils.isEmpty(searchKeyword)) {
                SearchMoreActivity.startSearchMore(this, searchKeyword, SearchMoreType.TYPE_USER);
            }
        });

        wkVBinding.groupMoreLayout.getRoot().setOnClickListener(v -> {
            if (!TextUtils.isEmpty(searchKeyword)) {
                SearchMoreActivity.startSearchMore(this, searchKeyword, SearchMoreType.TYPE_GROUP);
            }
        });

        wkVBinding.msgMoreLayout.getRoot().setOnClickListener(v -> {
            if (!TextUtils.isEmpty(searchKeyword)) {
                SearchMsgResultActivity.startSearchMsg(this, searchKeyword, null, null);
            }
        });

        wkVBinding.noteMoreLayout.getRoot().setOnClickListener(v -> {
            if (!TextUtils.isEmpty(searchKeyword)) {
                SearchMoreActivity.startSearchMore(this, searchKeyword, SearchMoreType.TYPE_NOTE);
            }
        });
    }

    private void doSearch(String keyword) {
        if (TextUtils.isEmpty(keyword)) {
            return;
        }

        // 搜索联系人
        List<WKChannel> friendList = new ArrayList<>();
        try {
            List<WKChannel> allFriends = WKIM.getInstance().getChannelManager()
                    .getWithFollowAndStatus(WKChannelType.PERSONAL, 1, 1);
            if (WKReader.isNotEmpty(allFriends)) {
                for (WKChannel channel : allFriends) {
                    if (matchesKeyword(channel, keyword)) {
                        friendList.add(channel);
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        // 搜索群聊
        List<WKChannel> groupList = new ArrayList<>();
        try {
            List<WKChannel> allGroups = WKIM.getInstance().getChannelManager()
                    .getWithFollowAndStatus(WKChannelType.GROUP, 0, 1);
            if (WKReader.isNotEmpty(allGroups)) {
                for (WKChannel channel : allGroups) {
                    if (matchesKeyword(channel, keyword)) {
                        groupList.add(channel);
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        // 搜索聊天记录（从会话列表中匹配）
        List<WKUIConversationMsg> msgList = new ArrayList<>();
        try {
            List<WKUIConversationMsg> allConversations = WKIM.getInstance().getConversationManager().getAll();
            if (WKReader.isNotEmpty(allConversations)) {
                for (WKUIConversationMsg conv : allConversations) {
                    if (conv.getWkMsg() != null && conv.getWkMsg().baseContentMsgModel != null) {
                        String content = conv.getWkMsg().baseContentMsgModel.getSearchableWord();
                        if (content != null && content.toLowerCase().contains(keyword.toLowerCase())) {
                            msgList.add(conv);
                        }
                    }
                    // 也匹配频道名
                    if (conv.getWkChannel() != null) {
                        String name = conv.getWkChannel().channelName;
                        if (name != null && name.toLowerCase().contains(keyword.toLowerCase())) {
                            if (!msgList.contains(conv)) {
                                msgList.add(conv);
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        // 更新UI
        runOnUiThread(() -> updateSearchResults(friendList, groupList, msgList, keyword));
    }

    private boolean matchesKeyword(WKChannel channel, String keyword) {
        if (channel == null) return false;
        String name = channel.channelName;
        String remark = channel.channelRemark;
        String id = channel.channelID;
        String lowerKey = keyword.toLowerCase();
        if (name != null && name.toLowerCase().contains(lowerKey)) return true;
        if (remark != null && remark.toLowerCase().contains(lowerKey)) return true;
        if (id != null && id.toLowerCase().contains(lowerKey)) return true;
        return false;
    }

    private void updateSearchResults(List<WKChannel> friendList, List<WKChannel> groupList,
                                     List<WKUIConversationMsg> msgList, String keyword) {
        wkVBinding.resultView.setVisibility(View.VISIBLE);
        wkVBinding.findUserLayout.setVisibility(View.GONE);

        boolean hasUser = WKReader.isNotEmpty(friendList);
        boolean hasGroup = WKReader.isNotEmpty(groupList);
        boolean hasMsg = WKReader.isNotEmpty(msgList);

        // 如果全部为空，显示空状态
        if (!hasUser && !hasGroup && !hasMsg) {
            wkVBinding.userLayout.setVisibility(View.GONE);
            wkVBinding.groupLayout.setVisibility(View.GONE);
            wkVBinding.msgLayout.setVisibility(View.GONE);
            wkVBinding.noteLayout.setVisibility(View.GONE);
            showEmptyState();
            return;
        }

        hideEmptyState();

        // 联系人
        if (hasUser) {
            wkVBinding.userLayout.setVisibility(View.VISIBLE);
            int showCount = Math.min(friendList.size(), 3);
            wkVBinding.userRecyclerView.setAdapter(new SearchChannelAdapter(
                    friendList.subList(0, showCount), keyword, this::openUserDetail));
            wkVBinding.userMoreLayout.getRoot().setVisibility(friendList.size() > 3 ? View.VISIBLE : View.GONE);
        } else {
            wkVBinding.userLayout.setVisibility(View.GONE);
        }

        // 群聊
        if (hasGroup) {
            wkVBinding.groupLayout.setVisibility(View.VISIBLE);
            int showCount = Math.min(groupList.size(), 3);
            wkVBinding.groupRecyclerView.setAdapter(new SearchChannelAdapter(
                    groupList.subList(0, showCount), keyword, this::openGroupChat));
            wkVBinding.groupMoreLayout.getRoot().setVisibility(groupList.size() > 3 ? View.VISIBLE : View.GONE);
        } else {
            wkVBinding.groupLayout.setVisibility(View.GONE);
        }

        // 聊天记录
        if (hasMsg) {
            wkVBinding.msgLayout.setVisibility(View.VISIBLE);
            int showCount = Math.min(msgList.size(), 3);
            wkVBinding.msgRecyclerView.setAdapter(new SearchMsgAdapter(
                    msgList.subList(0, showCount), keyword, this::openChatRecord));
            wkVBinding.msgMoreLayout.getRoot().setVisibility(msgList.size() > 3 ? View.VISIBLE : View.GONE);
        } else {
            wkVBinding.msgLayout.setVisibility(View.GONE);
        }

        // 笔记暂不搜索
        wkVBinding.noteLayout.setVisibility(View.GONE);
    }

    private void showEmptyState() {
        wkVBinding.resultView.setVisibility(View.GONE);
        // 简单的空状态：直接在 pageState 中添加一个 TextView
        if (emptyTv == null) {
            emptyTv = new TextView(this);
            emptyTv.setText("没有更多了");
            emptyTv.setTextSize(14);
            emptyTv.setTextColor(0xFF999999);
            emptyTv.setGravity(android.view.Gravity.CENTER);
            emptyTv.setPadding(0, 120, 0, 120);
            emptyTv.setLayoutParams(new android.widget.FrameLayout.LayoutParams(
                    android.widget.FrameLayout.LayoutParams.MATCH_PARENT,
                    android.widget.FrameLayout.LayoutParams.WRAP_CONTENT));
            wkVBinding.pageState.addView(emptyTv);
        }
        emptyTv.setVisibility(View.VISIBLE);
    }

    private void hideEmptyState() {
        if (emptyTv != null) {
            emptyTv.setVisibility(View.GONE);
        }
    }

    private void openUserDetail(WKChannel channel) {
        if (channel != null) {
            Intent intent = new Intent(this, com.chat.uikit.user.UserDetailActivity.class);
            intent.putExtra("uid", channel.channelID);
            startActivity(intent);
        }
    }

    private void openGroupChat(WKChannel channel) {
        if (channel != null) {
            com.chat.uikit.chat.manager.WKIMUtils.getInstance()
                    .startChatActivity(new com.chat.base.endpoint.entity.ChatViewMenu(
                            this, channel.channelID, WKChannelType.GROUP, 0, false));
        }
    }

    private void openChatRecord(WKUIConversationMsg conv) {
        if (conv != null) {
            com.chat.uikit.chat.manager.WKIMUtils.getInstance()
                    .startChatActivity(new com.chat.base.endpoint.entity.ChatViewMenu(
                            this, conv.channelID, conv.channelType, 0, false));
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

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (searchRunnable != null) {
            searchHandler.removeCallbacks(searchRunnable);
        }
    }
}
