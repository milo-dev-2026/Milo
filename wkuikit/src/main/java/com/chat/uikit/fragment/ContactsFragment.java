package com.chat.uikit.fragment;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.os.Build;
import android.text.TextUtils;
import android.view.Gravity;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.core.app.ActivityOptionsCompat;
import androidx.core.content.ContextCompat;
import androidx.core.util.Pair;
import androidx.recyclerview.widget.RecyclerView;

import com.chat.base.base.WKBaseFragment;
import com.chat.base.config.WKConfig;
import com.chat.base.config.WKConstants;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.config.WKSystemAccount;
import com.chat.base.endpoint.EndpointCategory;
import com.chat.base.endpoint.EndpointManager;
import com.chat.base.endpoint.entity.ContactsMenu;
import com.chat.base.entity.PopupMenuItem;
import com.chat.base.ui.Theme;
import com.chat.base.utils.AndroidUtilities;
import com.chat.base.utils.HanziToPinyin;
import com.chat.base.utils.LayoutHelper;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.WKReader;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.base.views.sidebar.listener.OnQuickSideBarTouchListener;
import com.chat.uikit.R;
import com.chat.uikit.contacts.FriendAdapter;
import com.chat.uikit.contacts.FriendUIEntity;
import com.chat.uikit.databinding.FragContactsLayoutBinding;
import com.chat.uikit.group.JoinedGroupsActivity;
import com.chat.uikit.search.SearchAllActivity;
import com.chat.uikit.user.UserDetailActivity;
import com.chat.uikit.utils.CharacterParser;
import com.chat.uikit.utils.PyingUtils;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannel;
import com.xinbida.wukongim.entity.WKChannelType;

import org.jetbrains.annotations.NotNull;

import java.util.ArrayList;
import java.util.List;

import io.reactivex.rxjava3.android.schedulers.AndroidSchedulers;
import io.reactivex.rxjava3.core.Observable;
import io.reactivex.rxjava3.core.ObservableOnSubscribe;
import io.reactivex.rxjava3.core.Observer;
import io.reactivex.rxjava3.disposables.Disposable;
import io.reactivex.rxjava3.schedulers.Schedulers;

/**
 * 2019-11-12 14:57
 * 联系人
 */
public class ContactsFragment extends WKBaseFragment<FragContactsLayoutBinding> implements OnQuickSideBarTouchListener {

    private ContactsHeaderAdapter contactsHeaderAdapter;
    private FriendAdapter friendAdapter;
    private TextView allContactsCountTv;


    @Override
    protected boolean isShowBackLayout() {
        return false;
    }

    @Override
    protected FragContactsLayoutBinding getViewBinding() {
        return FragContactsLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void initView() {
        wkVBinding.quickSideBarView.setTextChooseColor(Theme.colorAccount);
        wkVBinding.quickSideBarTipsView.setBackgroundColor(Theme.colorAccount);
        wkVBinding.refreshLayout.setEnableOverScrollDrag(true);
        wkVBinding.refreshLayout.setEnableLoadMore(false);
        wkVBinding.refreshLayout.setEnableRefresh(false);
        Theme.setPressedBackground(wkVBinding.searchIv);
        Theme.setPressedBackground(wkVBinding.rightIv);
    }

    @SuppressLint("ClickableViewAccessibility")
    @Override
    protected void initListener() {
        Object orgViewObject = EndpointManager.getInstance().invoke("org_contacts_view", requireContext());
        friendAdapter = new FriendAdapter();
        RecyclerView headerRecyclerView = new RecyclerView(requireContext());
        friendAdapter.addHeaderView(headerRecyclerView);
        if (orgViewObject != null) {
            View orgView = (View) orgViewObject;
            friendAdapter.addHeaderView(orgView);
        }
        friendAdapter.addFooterView(getFooterView());
        initAdapter(wkVBinding.recyclerView, friendAdapter);
        headerRecyclerView.setNestedScrollingEnabled(false);
        contactsHeaderAdapter = new ContactsHeaderAdapter();
        initAdapter(headerRecyclerView, contactsHeaderAdapter);
        wkVBinding.quickSideBarView.setOnQuickSideBarTouchListener(this);
        friendAdapter.addChildClickViewIds(R.id.contentLayout);
        friendAdapter.setOnItemChildClickListener((adapter, view, position) -> SingleClickUtil.determineTriggerSingleClick(view, view1 -> {
            FriendUIEntity friendEntity = (FriendUIEntity) adapter.getItem(position);
            if (friendEntity != null && friendEntity.channel != null
                    && getActivity() != null && !getActivity().isFinishing()) {
                Intent intent = new Intent(getActivity(), UserDetailActivity.class);
                intent.putExtra("uid", friendEntity.channel.channelID);
                startActivity(intent);
            }
        }));
        contactsHeaderAdapter.setOnItemClickListener((adapter, view, position) -> SingleClickUtil.determineTriggerSingleClick(view, view1 -> {
            ContactsMenu item = (ContactsMenu) adapter.getItem(position);
            if (item != null && item.iMenuClick != null) {
                item.iMenuClick.onClick();
            }
        }));
        wkVBinding.rightIv.setOnClickListener(view -> {
            List<PopupMenuItem> list = EndpointManager.getInstance().invokes(EndpointCategory.tabMenus, null);
            WKDialogUtils.getInstance().showScreenPopup(view, list);
        });
        //成员刷新监听
        WKIM.getInstance().getChannelManager().addOnRefreshChannelInfo("contacts_fragment_refresh_channel", (channel, isEnd) -> {
            if (channel != null) {
                Observable.create((ObservableOnSubscribe<Integer>) e -> {
                    for (int i = 0, size = friendAdapter.getData().size(); i < size; i++) {
                        if (friendAdapter.getData().get(i).channel != null
                                && friendAdapter.getData().get(i).channel.channelID.equals(channel.channelID)
                                && friendAdapter.getData().get(i).channel.channelType == channel.channelType) {
                            friendAdapter.getData().get(i).channel.channelName = channel.channelName;
                            friendAdapter.getData().get(i).channel.channelRemark = channel.channelRemark;
                            friendAdapter.getData().get(i).channel.mute = channel.mute;
                            friendAdapter.getData().get(i).channel.top = channel.top;
                            friendAdapter.getData().get(i).channel.avatar = channel.avatar;
                            friendAdapter.getData().get(i).channel.remoteExtraMap = channel.remoteExtraMap;
                            friendAdapter.getData().get(i).channel.online = channel.online;
                            friendAdapter.getData().get(i).channel.lastOffline = channel.lastOffline;
                            friendAdapter.getData().get(i).channel.deviceFlag = channel.deviceFlag;
                            e.onNext(i);
                            break;
                        }
                    }
                }).observeOn(AndroidSchedulers.mainThread()).subscribeOn(Schedulers.io()).subscribe(new Observer<>() {
                    @Override
                    public void onSubscribe(@NotNull Disposable d) {

                    }

                    @Override
                    public void onNext(@NotNull Integer index) {
                        friendAdapter.notifyItemChanged(index + friendAdapter.getHeaderLayoutCount());
                    }

                    @Override
                    public void onError(@NotNull Throwable e) {

                    }

                    @Override
                    public void onComplete() {

                    }
                });

            }
        });
        wkVBinding.searchIv.setOnClickListener(view -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                @SuppressWarnings("unchecked") ActivityOptionsCompat activityOptions = ActivityOptionsCompat.makeSceneTransitionAnimation(requireActivity(), new Pair<>(wkVBinding.searchIv, "searchView"));
                startActivity(new Intent(getActivity(), SearchAllActivity.class), activityOptions.toBundle());
            } else {
                startActivity(new Intent(getActivity(), SearchAllActivity.class));
            }
        });
        //监听刷新通讯录
        EndpointManager.getInstance().setMethod("", EndpointCategory.wkRefreshMailList, object -> {
            resetHeaderData();
            return null;
        });

        EndpointManager.getInstance().setMethod(WKConstants.refreshContacts, object -> {
            getContacts();
            return null;
        });
    }

    @Override
    protected void initData() {
        wkVBinding.quickSideBarView.setLetters(CharacterParser.getInstance().getList());
        List<ContactsMenu> headerList = buildHeaderList();
        contactsHeaderAdapter.setList(headerList);
        getContacts();
    }

    @Override
    public void onResume() {
        super.onResume();
        resetHeaderData();
        getContacts();
    }

    private void getContacts() {
        List<WKChannel> allList = WKIM.getInstance().getChannelManager().getWithFollowAndStatus(WKChannelType.PERSONAL, 1, 1);
        List<FriendUIEntity> list = new ArrayList<>();
        for (int i = 0, size = allList.size(); i < size; i++) {
            String channelID = allList.get(i).channelID;
            // 过滤系统账号（文件助手、系统通知），不计入好友列表
            if (channelID.equals(WKSystemAccount.system_file_helper)
                    || channelID.equals(WKSystemAccount.system_team)) {
                continue;
            }
            list.add(new FriendUIEntity(allList.get(i)));
        }
        List<FriendUIEntity> otherList = new ArrayList<>();
        List<FriendUIEntity> letterList = new ArrayList<>();
        List<FriendUIEntity> numList = new ArrayList<>();
        for (int i = 0, size = list.size(); i < size; i++) {
            String showName = list.get(i).channel.channelRemark;
            if (TextUtils.isEmpty(showName))
                showName = list.get(i).channel.channelName;
            if (!TextUtils.isEmpty(showName)) {
                if (PyingUtils.getInstance().isStartNum(showName)) {
                    list.get(i).pying = "#";
                } else
                    list.get(i).pying = HanziToPinyin.getInstance().getPY(showName);
            } else list.get(i).pying = "#";
        }
        PyingUtils.getInstance().sortListBasic(list);

        for (int i = 0, size = list.size(); i < size; i++) {
            if (PyingUtils.getInstance().isStartLetter(list.get(i).pying)) {
                //字母
                letterList.add(list.get(i));
            } else if (PyingUtils.getInstance().isStartNum(list.get(i).pying)) {
                //数字
                numList.add(list.get(i));
            } else otherList.add(list.get(i));
        }
        List<FriendUIEntity> tempList = new ArrayList<>();
        tempList.addAll(letterList);
        tempList.addAll(numList);
        tempList.addAll(otherList);
        friendAdapter.setList(tempList);
        if (isAdded())
            allContactsCountTv.setText(String.format(getString(R.string.contacts_num), tempList.size()));
    }

    private View getFooterView() {
        allContactsCountTv = new TextView(requireContext());
        allContactsCountTv.setGravity(Gravity.CENTER);
        allContactsCountTv.setTextSize(16);
        allContactsCountTv.setTextColor(ContextCompat.getColor(requireContext(), R.color.colorDark));
        LinearLayout linearLayout = new LinearLayout(requireContext());
        linearLayout.setOrientation(LinearLayout.HORIZONTAL);
        linearLayout.setLayoutParams(new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, LayoutHelper.WRAP_CONTENT));

        linearLayout.setBackgroundColor(ContextCompat.getColor(requireContext(), R.color.white));
        linearLayout.addView(allContactsCountTv, LayoutHelper.createLinear(LayoutHelper.MATCH_PARENT, LayoutHelper.WRAP_CONTENT, Gravity.CENTER));
        LinearLayout.LayoutParams layoutParams = (LinearLayout.LayoutParams) allContactsCountTv.getLayoutParams();
        layoutParams.topMargin = AndroidUtilities.dp(15);
        layoutParams.bottomMargin = AndroidUtilities.dp(15);
        return linearLayout;
    }

    @Override
    public void onLetterChanged(String letter, int position, float y) {
        wkVBinding.quickSideBarTipsView.setText(letter, position, y);
        //有此key则获取位置并滚动到该位置
        List<FriendUIEntity> list = friendAdapter.getData();
        if (WKReader.isNotEmpty(list)) {
            for (int i = 0, size = list.size(); i < size; i++) {
                if (list.get(i).pying.startsWith(letter)) {
                    wkVBinding.recyclerView.scrollToPosition(i + friendAdapter.getHeaderLayoutCount());
                    break;
                }
            }
        }
    }

    @Override
    public void onLetterTouching(boolean touching) {
        wkVBinding.quickSideBarTipsView.setVisibility(touching ? View.VISIBLE : View.INVISIBLE);
    }

    /**
     * 构建通讯录头部菜单列表
     * 只保留指定的入口：新的朋友、保存的群聊、加入的群聊、系统通知
     */
    private List<ContactsMenu> buildHeaderList() {
        List<ContactsMenu> result = new ArrayList<>();
        List<ContactsMenu> originalList = EndpointManager.getInstance().invokes(EndpointCategory.mailList, getActivity());
        if (originalList == null) originalList = new ArrayList<>();

        // 保留：新的朋友
        ContactsMenu friendMenu = findMenuBySid(originalList, "friend");
        if (friendMenu != null) {
            result.add(friendMenu);
        }

        // 保留：保存的群聊
        ContactsMenu groupMenu = findMenuBySid(originalList, "group");
        if (groupMenu != null) {
            result.add(groupMenu);
        }

        // 添加：加入的群聊
        result.add(new ContactsMenu("joined_group", R.mipmap.icon_joined_groups,
                getString(R.string.joined_groups), () -> {
            if (getActivity() != null) {
                Intent intent = new Intent(getActivity(), JoinedGroupsActivity.class);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(intent);
            }
        }));

        // 添加：文件传输助手
        result.add(new ContactsMenu("file_helper", com.chat.base.R.mipmap.icon_func_file,
                getString(R.string.wk_file_helper), () -> {
            if (getActivity() != null) {
                Intent intent = new Intent(getActivity(), com.chat.uikit.user.WKFileHelperActivity.class);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(intent);
            }
        }));

        // 添加：系统通知
        result.add(new ContactsMenu("system_notice", com.chat.base.R.drawable.ic_system_avatar,
                getString(R.string.wk_system_notice), () -> {
            if (getActivity() != null) {
                Intent intent = new Intent(getActivity(), com.chat.uikit.user.WKSystemTeamActivity.class);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(intent);
            }
        }));

        // 更新新朋友的红点数量
        for (ContactsMenu menu : result) {
            if (!TextUtils.isEmpty(menu.sid) && menu.sid.equals("friend")) {
                menu.badgeNum = WKSharedPreferencesUtil.getInstance().getInt(WKConfig.getInstance().getUid() + "_new_friend_count");
                break;
            }
        }

        return result;
    }

    private ContactsMenu findMenuBySid(List<ContactsMenu> list, String sid) {
        if (list == null || TextUtils.isEmpty(sid)) return null;
        for (ContactsMenu menu : list) {
            if (sid.equals(menu.sid)) {
                return menu;
            }
        }
        return null;
    }

    private void resetHeaderData() {
        if (isAdded()) {
            List<ContactsMenu> list = buildHeaderList();
            contactsHeaderAdapter.setList(list);
        }
    }

}
