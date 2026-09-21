package com.chat.uikit.chat;

import static androidx.recyclerview.widget.RecyclerView.SCROLL_STATE_IDLE;

import android.Manifest;
import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.ObjectAnimator;
import android.app.Activity;
import android.content.Intent;
import android.content.res.Configuration;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffColorFilter;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.SpannableString;
import android.text.TextUtils;
import android.util.Log;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import android.view.Window;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.ImageView;
import android.widget.RelativeLayout;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.AppCompatImageView;
import android.widget.TextView;
import androidx.core.content.ContextCompat;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;
import androidx.databinding.DataBindingUtil;
import androidx.recyclerview.widget.DefaultItemAnimator;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.chat.base.common.WKCommonModel;
import com.chat.base.config.WKBinder;
import com.chat.base.config.WKConfig;
import com.chat.base.config.WKConstants;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.config.WKSystemAccount;
import com.chat.base.emoji.MoonUtil;
import com.chat.base.endpoint.EndpointCategory;
import com.chat.base.endpoint.EndpointManager;
import com.chat.base.endpoint.EndpointSID;
import com.chat.base.endpoint.entity.AvatarOtherViewMenu;
import com.chat.base.endpoint.entity.RTCMenu;
import com.chat.base.endpoint.entity.ReadMsgMenu;
import com.chat.base.endpoint.entity.SetChatBgMenu;
import com.chat.base.entity.PopupMenuItem;
import com.chat.base.entity.UserOnlineStatus;
import com.chat.base.entity.WKChannelCustomerExtras;
import com.chat.base.entity.WKGroupType;
import com.chat.base.msg.ChatAdapter;
import com.chat.base.msg.ChatContentSpanType;
import com.chat.base.msg.IConversationContext;
import com.chat.base.msgitem.WKChannelMemberRole;
import com.chat.base.msgitem.WKContentType;
import com.chat.base.msgitem.WKUIChatMsgItemEntity;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.ui.Theme;
import com.chat.base.ui.components.NumberTextView;
import com.chat.base.ui.components.SystemMsgBackgroundColorSpan;
import com.chat.base.utils.ActManagerUtils;
import com.chat.base.utils.AndroidUtilities;
import com.chat.base.utils.LayoutHelper;
import com.chat.base.utils.SoftKeyboardUtils;
import com.chat.base.utils.UserUtils;
import com.chat.base.utils.WKChannelUtils;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.WKPermissions;
import com.chat.base.utils.WKPlaySound;
import com.chat.base.utils.WKReader;
import com.chat.base.utils.WKTimeUtils;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.VideoPreDownloader;
import com.chat.base.config.WKApiConfig;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.base.utils.systembar.WKStatusBarUtils;
import com.chat.base.views.CommonAnim;
import com.chat.base.views.swipeback.SwipeBackActivity;
import com.chat.base.views.swipeback.SwipeBackLayout;
import com.chat.uikit.R;
import com.chat.uikit.WKUIKitApplication;
import com.chat.uikit.chat.manager.SendMsgEntity;
import com.chat.uikit.chat.manager.WKIMUtils;
import com.chat.uikit.chat.manager.WKSendMsgUtils;
import com.chat.uikit.chat.msgmodel.WKCardContent;
import com.chat.uikit.contacts.ChooseContactsActivity;
import com.chat.uikit.databinding.ActChatLayoutBinding;
import com.chat.uikit.group.ChooseVideoCallMembersActivity;
import com.chat.uikit.group.GroupDetailActivity;
import com.chat.uikit.group.service.GroupModel;
import com.chat.uikit.message.MsgModel;
import com.chat.uikit.robot.service.WKRobotModel;
import com.chat.uikit.view.WKPlayVoiceUtils;
import com.chat.uikit.user.UserDetailActivity;
import com.effective.android.panel.PanelSwitchHelper;
import com.effective.android.panel.interfaces.ContentScrollMeasurer;
import com.effective.android.panel.interfaces.listener.OnPanelChangeListener;
import com.effective.android.panel.view.panel.IPanelView;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKCMD;
import com.xinbida.wukongim.entity.WKCMDKeys;
import com.xinbida.wukongim.entity.WKChannel;
import com.xinbida.wukongim.entity.WKChannelExtras;
import com.xinbida.wukongim.entity.WKChannelMember;
import com.xinbida.wukongim.entity.WKChannelStatus;
import com.xinbida.wukongim.entity.WKChannelType;
import com.xinbida.wukongim.entity.WKConversationMsgExtra;
import com.xinbida.wukongim.entity.WKMentionType;
import com.xinbida.wukongim.entity.WKMsg;
import com.xinbida.wukongim.entity.WKMsgExtra;
import com.xinbida.wukongim.entity.WKMsgReaction;
import com.xinbida.wukongim.entity.WKReminder;
import com.xinbida.wukongim.entity.WKSendOptions;
import com.xinbida.wukongim.interfaces.IGetOrSyncHistoryMsgBack;
import com.xinbida.wukongim.message.type.WKConnectStatus;
import com.xinbida.wukongim.message.type.WKSendMsgResult;
import com.xinbida.wukongim.msgmodel.WKImageContent;
import com.xinbida.wukongim.msgmodel.WKMessageContent;
import com.xinbida.wukongim.msgmodel.WKMsgEntity;
import com.xinbida.wukongim.msgmodel.WKReply;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.TimeUnit;

import io.reactivex.rxjava3.android.schedulers.AndroidSchedulers;
import io.reactivex.rxjava3.core.Observable;
import io.reactivex.rxjava3.core.Observer;
import io.reactivex.rxjava3.disposables.Disposable;
import io.reactivex.rxjava3.schedulers.Schedulers;

public class ChatActivity extends SwipeBackActivity implements IConversationContext {
    private String channelId = "";
    private byte channelType = WKChannelType.PERSONAL;
    private ChatAdapter chatAdapter;
    //是否在查看历史消息
    private boolean isShowHistory;
    private boolean isSyncLastMsg = false;
    private boolean isToEnd = true;
    private boolean isViewingPicture = false;
    private final boolean showNickName = true; // 是否显示聊天昵称
    private long lastPreviewMsgOrderSeq = 0; //上次浏览消息
    private long unreadStartMsgOrderSeq = 0; //新消息开始位置
    private long tipsOrderSeq = 0; //需要强提示的msg
    private int keepOffsetY = 0; // 上次浏览消息的偏移量
    private int redDot = 0; // 未读消息数量
    private int lastVisibleMsgSeq = 0; // 最后可见消息序号
    private int maxMsgSeq = 0;
    private long maxMsgOrderSeq = 0;
    //回复的消息对象
    private WKMsg replyWKMsg;
    // 编辑对象
    private WKMsg editMsg;
    // 群成员数量
    private int count;
    private int groupType = WKGroupType.normalGroup;
    //已读消息
    private final List<com.chat.base.endpoint.entity.ReadedMessageReq> readMsgList = new ArrayList<>();
    private Disposable disposable;
    private boolean isUploadReadMsg = true;
    //    boolean isUpdateCoverMsg = false;
    private boolean isCanLoadMore;
    // 自动全量同步历史消息相关 - 已优化：移除进入页面自动全量同步，改为按需加载
    private boolean isAutoSyncingHistory = false;  // 是否正在自动同步历史消息
    private int autoSyncedMsgCount = 0;            // 已自动同步的消息数量
    private boolean isFirstDataLoad = true;        // 是否首次加载数据
    private static final int MAX_AUTO_SYNC_MSG = 500; // 最大自动同步消息数（进入页面预加载数量）
    boolean isRefreshLoading = false;
    boolean isMoreLoading = false;
    boolean isCanRefresh = true;
    private boolean isShowChatActivity = true;
    LinearLayoutManager linearLayoutManager;
    private final List<WKReminder> reminderList = new ArrayList<>();
    private final List<WKReminder> groupApproveList = new ArrayList<>();
    private final List<Long> reminderIds = new ArrayList<>();
    private long browseTo = 0;
    private boolean isUpdateRedDot = true;
    //查询聊天数据偏移量 - 增大首次加载数量，避免频繁分页加载
    private final int limit = 200;
    private boolean isShowPinnedView = false;
    private boolean isMultipleChoiceMode = false;
    private boolean isTipMessage = false;
    private int hideChannelAllPinnedMessage = 0;
    // 新成员查看历史消息控制
    private boolean isAllowViewHistoryMsg = true; // 是否允许查看历史消息（群设置）
    private long memberJoinTimestamp = 0; // 当前用户入群时间戳（秒级）
    private PanelSwitchHelper mHelper; // nullable, PanelSwitchLayout may not be available
    private ChatPanelManager chatPanelManager;
    private ActChatLayoutBinding wkVBinding;
    private int unfilledHeight = 0;
    private int keyboardHeight = 0;
    private boolean isKeyboardVisible = false;
    private ViewTreeObserver.OnGlobalLayoutListener keyboardLayoutListener;
    private com.chat.uikit.chat.utils.KeyboardHeightProvider keyboardHeightProvider;
    // 对方输入中显示控制
    private final Handler typingHandler = new Handler(Looper.getMainLooper());
    private final Runnable hideTypingRunnable = () -> hideTypingInTitle();
    private boolean isTypingShowing = false;
    // 连接状态显示控制
    private boolean isShowingConnectionStatus = false;
    private int currentConnectionStatus = WKConnectStatus.success;
    private CharSequence savedSubtitleText = "";
    private int savedSubtitleVisibility = View.GONE;

    private void p2pCall(int callType) {
        EndpointManager.getInstance().invoke("wk_p2p_call", new RTCMenu(this, callType));
    }

    private void toggleStatusBarMode() {
        Window window = getWindow();
        if (window == null) return;
        // adjustResize 模式：窗口自动调整大小，标题栏保持不动，内容区域自适应
        window.setBackgroundDrawableResource(R.color.color_chat);
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE
                | WindowManager.LayoutParams.SOFT_INPUT_STATE_HIDDEN);
        // 使用 WindowInsets 方式处理沉浸式状态栏
        // 替代旧的 SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN 方式，避免与 adjustResize 冲突导致键盘弹起时布局异常
        WindowCompat.setDecorFitsSystemWindows(window, false);
        window.setStatusBarColor(android.graphics.Color.TRANSPARENT);
        // 设置状态栏文字颜色
        WindowInsetsControllerCompat controller = WindowCompat.getInsetsController(window, window.getDecorView());
        if (controller != null) {
            controller.setAppearanceLightStatusBars(!Theme.getDarkModeStatus(this));
        }
        // 监听窗口 insets 变化，手动处理键盘弹起时的布局调整
        // 由于使用了 setDecorFitsSystemWindows(false)，adjustResize 可能不会自动调整内容区域
        // 因此需要手动根据 IME insets 调整底部 padding，确保消息不会上移覆盖标题
        ViewCompat.setOnApplyWindowInsetsListener(wkVBinding.viewGroupLayout, (v, insets) -> {
            int statusBarHeight = insets.getInsets(WindowInsetsCompat.Type.statusBars()).top;
            int imeHeight = insets.getInsets(WindowInsetsCompat.Type.ime()).bottom;
            int navBarHeight = insets.getInsets(WindowInsetsCompat.Type.navigationBars()).bottom;
            // 顶部：将状态栏高度应用到标题栏
            wkVBinding.topLayout.titleView.setPadding(0, statusBarHeight, 0, 0);
            // 底部：键盘弹出时用键盘高度，否则用导航栏高度
            int bottomPadding = Math.max(imeHeight, navBarHeight);
            if (v.getPaddingBottom() != bottomPadding) {
                v.setPadding(v.getPaddingLeft(), 0,
                        v.getPaddingRight(), bottomPadding);
            }
            // 键盘高度检测（替代KeyboardHeightProvider PopupWindow，避免可见弹窗）
            boolean kbVisible = imeHeight > 0;
            if (kbVisible) {
                if (!isKeyboardVisible) {
                    isKeyboardVisible = true;
                }
                keyboardHeight = imeHeight;
                com.chat.base.config.WKConstants.setKeyboardHeight(imeHeight);
                ViewGroup.LayoutParams lp = wkVBinding.morePanel.getLayoutParams();
                if (lp != null && lp.height != imeHeight) {
                    lp.height = imeHeight;
                    wkVBinding.morePanel.setLayoutParams(lp);
                }
                chatRecyclerViewScrollToEnd();
            } else {
                if (isKeyboardVisible) {
                    isKeyboardVisible = false;
                }
            }
            return insets;
        });
    }

    private void initParam() {
        toggleStatusBarMode();
        //频道ID
        channelId = getIntent().getStringExtra("channelId");
        if (TextUtils.isEmpty(channelId)) {
            finish();
            return;
        }
        //频道类型
        channelType = getIntent().getByteExtra("channelType", WKChannelType.PERSONAL);
        maxMsgOrderSeq = WKIM.getInstance().getMsgManager().getMaxOrderSeqWithChannel(channelId, channelType);
        maxMsgSeq = WKIM.getInstance().getMsgManager().getMaxMessageSeqWithChannel(channelId, channelType);
        resetHideChannelAllPinnedMessage();
        // 是否含有带转发的消息
        if (getIntent().hasExtra("msgContentList")) {
            List<WKMessageContent> msgContentList = getIntent().getParcelableArrayListExtra("msgContentList");
            if (WKReader.isNotEmpty(msgContentList)) {
                List<WKChannel> list = new ArrayList<>();
                WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(channelId, channelType);
                if (channel != null) {
                    list.add(channel);
                }
                WKUIKitApplication.getInstance().showChatConfirmDialog(this, list, msgContentList, (list1, messageContentList) -> {
                    List<SendMsgEntity> msgList = new ArrayList<>();
                    WKSendOptions options = new WKSendOptions();
                    options.setting.receipt = 1;
                    for (int i = 0, size = msgContentList.size(); i < size; i++) {
                        msgList.add(new SendMsgEntity(msgContentList.get(i), channel, options));
                    }
                    WKSendMsgUtils.getInstance().sendMessages(msgList);
                });

            }
        }

    }

    private void initSwipeBackFinish() {
        SwipeBackLayout mSwipeBackLayout = getSwipeBackLayout();
        mSwipeBackLayout.setEdgeTrackingEnabled(SwipeBackLayout.EDGE_LEFT);
        mSwipeBackLayout.setEnableGesture(true);
    }

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        initSwipeBackFinish();
        wkVBinding = DataBindingUtil.setContentView(this, R.layout.act_chat_layout);
//        setContentView(R.layout.act_chat_layout1);
        initParam();
        if (TextUtils.isEmpty(channelId)) {
            return;
        }
        // 好友关系校验：非好友状态不允许发起聊天
        if (!checkFriendPermission()) {
            WKToastUtils.getInstance().showToast("需要添加对方为好友后才可聊天");
            finish();
            return;
        }
        initView();
        initListener();
        initData();
        ActManagerUtils.getInstance().addActivity(this);
    }

    /**
     * 检查好友权限
     * @return true 允许聊天 false 不允许聊天
     */
    private boolean checkFriendPermission() {
        // 群聊、客服、系统账号不需要校验
        if (channelType != WKChannelType.PERSONAL) {
            return true;
        }
        if (WKSystemAccount.isSystemAccount(channelId)) {
            return true;
        }
        // 判断是否为好友：follow == 1 表示好友
        WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(channelId, channelType);
        return channel != null && channel.follow == 1;
    }

    @Override
    protected void onResume() {
        super.onResume();
        isShowChatActivity = true;
        WKUIKitApplication.getInstance().chattingChannelID = channelId;
        WKUIKitApplication.getInstance().chattingChannelType = channelType;
        isUploadReadMsg = true;
        chatPanelManager.initRefreshListener();
        EndpointManager.getInstance().invoke("start_screen_shot", this);
        MsgModel.getInstance().syncExtraMsg(channelId, channelType, () -> restorePinnedBanner());
        restorePinnedBanner();
    }

    @Override
    protected void onStart() {
        super.onStart();
        if (mHelper == null) {
            try {
                mHelper = new PanelSwitchHelper.Builder(this)
                        .addKeyboardStateListener((visible, height) -> {
                            if (visible && height > 0) {
                                WKConstants.setKeyboardHeight(height);
                            }
                        })
                        .addPanelChangeListener(new OnPanelChangeListener() {
                            @Override
                            public void onKeyboard() {
                                if (chatPanelManager != null) {
                                    chatPanelManager.resetToolBar();
                                }
                                SoftKeyboardUtils.getInstance().requestFocus(findViewById(R.id.editText));
                            }

                            @Override
                            public void onNone() {
                            }

                            @Override
                            public void onPanel(IPanelView view) {
                            }

                            @Override
                            public void onPanelSizeChange(IPanelView panelView, boolean portrait, int oldWidth, int oldHeight, int width, int height) {
                            }
                        }).addContentScrollMeasurer(new ContentScrollMeasurer() {
                            @Override
                            public int getScrollDistance(int i) {
                                View bottomView = findViewById(R.id.chat_input_panel);
                                View followView = findViewById(R.id.recyclerViewContentLayout);
                                if (bottomView == null || followView == null) return 0;
                                return i - (bottomView.getTop() - followView.getBottom());
                            }

                            @Override
                            public int getScrollViewId() {
                                return R.id.recyclerViewLayout;
                            }
                        }).addContentScrollMeasurer(new ContentScrollMeasurer() {
                            @Override
                            public int getScrollDistance(int i) {
                                return 0;
                            }

                            @Override
                            public int getScrollViewId() {
                                return R.id.pinnedLayout;
                            }
                        }).addContentScrollMeasurer(new ContentScrollMeasurer() {
                            @Override
                            public int getScrollDistance(int i) {
                                return 0;
                            }

                            @Override
                            public int getScrollViewId() {
                                return R.id.timeTv;
                            }
                        }).addContentScrollMeasurer(new ContentScrollMeasurer() {
                            @Override
                            public int getScrollDistance(int i) {
                                return 0;
                            }

                            @Override
                            public int getScrollViewId() {
                                return R.id.imageView;
                            }
                        }).addContentScrollMeasurer(new ContentScrollMeasurer() {
                            @Override
                            public int getScrollDistance(int i) {
                                return i - unfilledHeight;
                            }

                            @Override
                            public int getScrollViewId() {
                                return R.id.recyclerView;
                            }
                        })
                        .logTrack(WKBinder.isDebug)
                        .build(false);
            } catch (Throwable e) {
                Log.e("ChatActivity", "PanelSwitchHelper init failed: " + e.getMessage());
                mHelper = null;
            }
        }
        if (chatPanelManager == null) {
            try {
                FrameLayout moreView = findViewById(R.id.more_panel);
                chatPanelManager = new ChatPanelManager(mHelper, findViewById(R.id.chat_input_panel), moreView, findViewById(R.id.recyclerViewContentLayout), this, () -> {
                    CommonAnim.getInstance().rotateImage(wkVBinding.topLayout.backIv, 180f, 360f, R.mipmap.ic_ab_back);
                    return null;
                }, path -> {
                    if (previewNewImgResultLac != null) {
                        Intent intent = new Intent(ChatActivity.this, PreviewNewImgActivity.class);
                        intent.putExtra("path", path);
                        previewNewImgResultLac.launch(intent);
                    }
                    return null;
                });
                initData();
            } catch (Throwable e) {
                Log.e("ChatActivity", "ChatPanelManager init failed: " + e.getMessage(), e);
            }
        }
    }

    protected void initView() {
        EndpointManager.getInstance().invoke("set_chat_bg", new SetChatBgMenu(channelId, channelType, wkVBinding.imageView, wkVBinding.rootView, wkVBinding.blurView));
        initPinnedMessageBanner();
        wkVBinding.timeTv.setShadowLayer(AndroidUtilities.dp(5f), 0f, 0f, 0);
        CommonAnim.getInstance().showOrHide(wkVBinding.timeTv, false, true);
        Theme.setPressedBackground(wkVBinding.topLayout.backIv);
        wkVBinding.topLayout.backIv.setColorFilter(new PorterDuffColorFilter(ContextCompat.getColor(this, R.color.titleBarIcon), PorterDuff.Mode.MULTIPLY));
        wkVBinding.topLayout.avatarView.setSize(40);
        wkVBinding.chatUnreadLayout.progress.setSize(40);
        wkVBinding.chatUnreadLayout.progress.setStrokeWidth(1.5f);
        wkVBinding.chatUnreadLayout.progress.setProgressColor(ContextCompat.getColor(this, R.color.popupTextColor));

        wkVBinding.chatUnreadLayout.msgCountTv.setColors(R.color.white, R.color.reminderColor);
        wkVBinding.chatUnreadLayout.remindCountTv.setColors(R.color.white, R.color.reminderColor);
        wkVBinding.chatUnreadLayout.approveCountTv.setColors(R.color.white, R.color.reminderColor);
        // Set initial tag to 1 (hidden state) so CommonAnim.showOrHide can show it for the first time
        wkVBinding.chatUnreadLayout.newMsgLayout.setTag(1);

        //去除刷新条目闪动动画
        RecyclerView.ItemAnimator animator = wkVBinding.recyclerView.getItemAnimator();
        if (animator instanceof DefaultItemAnimator) {
            ((DefaultItemAnimator) animator).setSupportsChangeAnimations(false);
        }
        chatAdapter = new ChatAdapter(this, ChatAdapter.AdapterType.normalMessage);
        linearLayoutManager = new LinearLayoutManager(this, LinearLayoutManager.VERTICAL, false);
        wkVBinding.recyclerView.setLayoutManager(linearLayoutManager);
        wkVBinding.recyclerView.setAdapter(chatAdapter);
        wkVBinding.recyclerView.setItemAnimator(new MyItemAnimator());
        chatAdapter.setAnimationFirstOnly(true);
        chatAdapter.setAnimationEnable(false);
        initKeyboardListener();
    }

    private void initKeyboardListener() {
        // 键盘高度检测已通过 WindowInsets 实现，不再使用 PopupWindow 避免可见弹窗
    }

    private void initListener() {
        ItemTouchHelper helper = new ItemTouchHelper(new MessageSwipeController(this, new SwipeControllerActions() {
            @Override
            public void showReplyUI(int position) {
                if (chatAdapter.getData() == null || position < 0 || position >= chatAdapter.getData().size()) return;
                showReply(chatAdapter.getData().get(position).wkMsg);
            }

            @Override
            public void hideSoft() {
                SoftKeyboardUtils.getInstance().hideSoftKeyboard(ChatActivity.this);
            }
        }));
        helper.attachToRecyclerView(wkVBinding.recyclerView);
        wkVBinding.topLayout.backIv.setOnClickListener(v -> setBackListener());
        // 通话按钮点击事件：直接发起语音通话
        wkVBinding.topLayout.callView.setOnClickListener(v -> {
            if (channelType == WKChannelType.PERSONAL) {
                p2pCall(0); // 0=语音通话
            }
        });
        // 更多按钮点击事件：跳转到聊天信息页面
        wkVBinding.topLayout.moreView.setOnClickListener(v -> {
            WKChannelMember member = WKIM.getInstance().getChannelMembersManager().getMember(channelId, channelType, WKConfig.getInstance().getUid());
            if ((member != null && member.isDeleted == 1) || channelType == WKChannelType.CUSTOMER_SERVICE)
                return;
            Intent intent = new Intent(ChatActivity.this, channelType == WKChannelType.GROUP ? GroupDetailActivity.class : ChatPersonalActivity.class);
            intent.putExtra("channelId", channelId);
            startActivity(intent);
        });

        WKDialogUtils.getInstance().setViewLongClickPopup(wkVBinding.chatUnreadLayout.groupApproveLayout, getGroupApprovePopupItems());
        wkVBinding.chatUnreadLayout.groupApproveLayout.setOnClickListener(view -> {
            if (WKReader.isNotEmpty(groupApproveList)) {
                WKMsg msg = WKIM.getInstance().getMsgManager().getWithMessageID(groupApproveList.get(0).messageID);
                if (msg != null && !TextUtils.isEmpty(msg.clientMsgNO)) {
                    tipsMsg(msg.clientMsgNO);
                }
            }
        });
        WKDialogUtils.getInstance().setViewLongClickPopup(wkVBinding.chatUnreadLayout.remindLayout, getRemindPopupItems());
        wkVBinding.chatUnreadLayout.remindLayout.setOnClickListener(view -> {

            if (WKReader.isNotEmpty(reminderList)) {
                reminderIds.add(reminderList.get(0).reminderID);
                WKMsg msg = WKIM.getInstance().getMsgManager().getWithMessageID(reminderList.get(0).messageID);
                if (msg != null && !TextUtils.isEmpty(msg.clientMsgNO)) {
                    tipsMsg(msg.clientMsgNO);
                } else {
                    long orderSeq = WKIM.getInstance().getMsgManager().getMessageOrderSeq(reminderList.get(0).messageSeq, channelId, channelType);
                    unreadStartMsgOrderSeq = 0;
                    tipsOrderSeq = orderSeq;
                    getData(1, true, orderSeq, false);
                    isCanLoadMore = true;
                }
            }
        });

        SingleClickUtil.onSingleClick(wkVBinding.topLayout.titleView, view -> {
            WKChannelMember member = WKIM.getInstance().getChannelMembersManager().getMember(channelId, channelType, WKConfig.getInstance().getUid());

            if ((member != null && member.isDeleted == 1) || channelType == WKChannelType.CUSTOMER_SERVICE)
                return;
//              SoftKeyboardUtils.getInstance().hideInput(this, wkVBinding.toolbarView.editText);
            Intent intent;
            if (channelType == WKChannelType.GROUP) {
                intent = new Intent(ChatActivity.this, GroupDetailActivity.class);
                intent.putExtra("channelId", channelId);
            } else {
                intent = new Intent(ChatActivity.this, UserDetailActivity.class);
                intent.putExtra("uid", channelId);
            }
            startActivity(intent);
        });

        wkVBinding.recyclerView.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrolled(@NonNull RecyclerView recyclerView, int dx, int dy) {
                super.onScrolled(recyclerView, dx, dy);
                if (chatAdapter.getData().size() <= 1) return;
                setShowTime();
                int lastItemPosition = linearLayoutManager.findLastVisibleItemPosition();
                if (lastItemPosition < chatAdapter.getItemCount() - 1) {
                    wkVBinding.chatUnreadLayout.newMsgLayout.post(() -> CommonAnim.getInstance().showOrHide(wkVBinding.chatUnreadLayout.newMsgLayout, true, true, false));
                } else {
                    wkVBinding.chatUnreadLayout.newMsgLayout.post(() -> CommonAnim.getInstance().showOrHide(wkVBinding.chatUnreadLayout.newMsgLayout, false, true, false));
                }
                resetRemindView();
                resetGroupApproveView();

                View lastChildView = linearLayoutManager.findViewByPosition(lastItemPosition);
                if (lastChildView != null) {
                    int bottom = lastChildView.getBottom();
                    int listHeight = wkVBinding.recyclerView.getHeight() - wkVBinding.recyclerView.getPaddingBottom();
                    unfilledHeight = listHeight - bottom;
                }
            }

            @Override
            public void onScrollStateChanged(@NonNull RecyclerView recyclerView, int newState) {
                super.onScrollStateChanged(recyclerView, newState);
                int lastItemPosition = linearLayoutManager.findLastVisibleItemPosition();
                isShowHistory = lastItemPosition < chatAdapter.getItemCount() - 1;
                if (newState == SCROLL_STATE_IDLE) {
                    isTipMessage = false;
                    CommonAnim.getInstance().showOrHide(wkVBinding.timeTv, false, true);
                    EndpointManager.getInstance().invoke("stop_reaction_animation", null);
                    if (!wkVBinding.recyclerView.canScrollVertically(1)) { // 到达底部
                        showMoreLoading();
                    } else if (!wkVBinding.recyclerView.canScrollVertically(-1)) { // 到达顶部
                        showRefreshLoading();
                    }
                } else {
                    MsgModel.getInstance().doneReminder(reminderIds);
                    if (!isUpdateRedDot) return;
                    MsgModel.getInstance().clearUnread(channelId, channelType, redDot, (code, msg) -> {
                        if (code == HttpResponseCode.success && redDot == 0) {
                            isUpdateRedDot = false;
                        }
                    });
                }
            }
        });

        wkVBinding.chatUnreadLayout.newMsgLayout.setOnClickListener(v -> {
            redDot = 0;
            MsgModel.getInstance().clearUnread(channelId, channelType, redDot, (code, msg) -> {
                if (code == HttpResponseCode.success && redDot == 0) {
                    isUpdateRedDot = false;
                }
            });
            if (isCanLoadMore) {
                isSyncLastMsg = true;
                // chatAdapter.setList(new ArrayList<>());
                wkVBinding.chatUnreadLayout.progress.setVisibility(View.VISIBLE);
                wkVBinding.chatUnreadLayout.msgDownIv.setVisibility(View.GONE);
                unreadStartMsgOrderSeq = 0;
                lastPreviewMsgOrderSeq = 0;
                long maxSeq = WKIM.getInstance().getMsgManager().getMaxOrderSeqWithChannel(channelId, channelType);
                new Handler().postDelayed(() -> {
                    getData(0, true, maxSeq, true);
                    showUnReadCountView();
                }, 500);
            } else {
                scrollToPosition(chatAdapter.getItemCount() - 1);
                showUnReadCountView();
            }

            isShowHistory = false;
            isCanLoadMore = false;
        });

        //监听频道改变通知
        WKIM.getInstance().getChannelManager().addOnRefreshChannelInfo(channelId, (channel, isEnd) -> {
            if (channel == null) return;
            if (channel.channelID.equals(channelId) && channel.channelType == channelType) { //同一个会话
                showChannelName(channel);
                wkVBinding.topLayout.avatarView.showAvatar(channel);
                EndpointManager.getInstance().invoke("show_avatar_other_info", new AvatarOtherViewMenu(wkVBinding.topLayout.otherLayout, channel, wkVBinding.topLayout.avatarView, true));
                //用户在线状态
                if (channel.channelType == WKChannelType.PERSONAL) {
                    setOnlineView(channel);
                } else {
                    if (channel.remoteExtraMap != null) {
                        Object memberCountObject = channel.remoteExtraMap.get(WKChannelCustomerExtras.memberCount);
                        if (memberCountObject instanceof Integer) {
                            int count = (int) memberCountObject;
                            wkVBinding.topLayout.subtitleTv.setText(String.format(getString(R.string.group_member), count));
                        }
                        Object onlineCountObject = channel.remoteExtraMap.get(WKChannelCustomerExtras.onlineCount);
                        if (onlineCountObject instanceof Integer) {
                            int onlineCount = (int) onlineCountObject;
                            if (onlineCount > 0) {
                                wkVBinding.topLayout.subtitleCountTv.setVisibility(View.VISIBLE);
                                wkVBinding.topLayout.subtitleCountTv.setText(String.format(getString(R.string.online_count), onlineCount));
                            }
                        }
                    }
                }
                EndpointManager.getInstance().invoke("set_chat_bg", new SetChatBgMenu(channelId, channelType, wkVBinding.imageView, wkVBinding.rootView, wkVBinding.blurView));
            } else {
                for (int i = 0, size = chatAdapter.getData().size(); i < size; i++) {
                    if (TextUtils.isEmpty(chatAdapter.getData().get(i).wkMsg.fromUID)) continue;
                    boolean isRefresh = false;
                    if (chatAdapter.getData().get(i).wkMsg.fromUID.equals(channel.channelID) && channel.channelType == WKChannelType.PERSONAL) {
                        chatAdapter.getData().get(i).wkMsg.setFrom(channel);
                        isRefresh = true;
                    }
                    if (chatAdapter.getData().get(i).wkMsg.getMemberOfFrom() != null && chatAdapter.getData().get(i).wkMsg.getMemberOfFrom().memberUID.equals(channel.channelID) && channel.channelType == WKChannelType.PERSONAL) {
                        chatAdapter.getData().get(i).wkMsg.getMemberOfFrom().memberRemark = channel.channelRemark;
                        chatAdapter.getData().get(i).wkMsg.getMemberOfFrom().memberName = channel.channelName;
                        chatAdapter.getData().get(i).wkMsg.getMemberOfFrom().memberAvatar = channel.avatar;
                        chatAdapter.getData().get(i).wkMsg.getMemberOfFrom().memberAvatarCacheKey = channel.avatarCacheKey;
                        isRefresh = true;
                    }
                    if (chatAdapter.getData().get(i).wkMsg.baseContentMsgModel != null && WKReader.isNotEmpty(chatAdapter.getData().get(i).wkMsg.baseContentMsgModel.entities)) {
                        for (WKMsgEntity entity : chatAdapter.getData().get(i).wkMsg.baseContentMsgModel.entities) {
                            if (entity.type.equals(ChatContentSpanType.mention) && !TextUtils.isEmpty(entity.value) && entity.value.equals(channel.channelID)) {
                                isRefresh = true;
                                chatAdapter.getData().get(i).formatSpans(ChatActivity.this, chatAdapter.getData().get(i).wkMsg);
                                break;
                            }
                        }
                    }
                    if (isRefresh) {
                        chatAdapter.getData().get(i).isRefreshAvatarAndName = true;
                        chatAdapter.notifyItemChanged(i, chatAdapter.getData().get(i));
                    }
                }
            }
        });

        //监听频道成员信息改变通知
        WKIM.getInstance().getChannelMembersManager().addOnRefreshChannelMemberInfo(channelId, (channelMember, isEnd) -> {
            if (channelMember != null && !TextUtils.isEmpty(channelMember.channelID)) {
                if (channelMember.channelID.equals(channelId) && channelMember.channelType == channelType) {
                    if (channelMember.channelType == WKChannelType.PERSONAL) {
                        String name = channelMember.memberRemark;
                        if (TextUtils.isEmpty(name)) name = channelMember.memberName;
                        wkVBinding.topLayout.titleCenterTv.setText(name);
                    } else {
                        //成员名字改变
                        for (int i = 0, size = chatAdapter.getData().size(); i < size; i++) {
                            if (chatAdapter.getData().get(i).wkMsg != null && chatAdapter.getData().get(i).wkMsg.getMemberOfFrom() != null && !TextUtils.isEmpty(chatAdapter.getData().get(i).wkMsg.getMemberOfFrom().memberUID) && chatAdapter.getData().get(i).wkMsg.getMemberOfFrom().memberUID.equals(channelMember.memberUID)) {
                                chatAdapter.getData().get(i).wkMsg.getMemberOfFrom().memberName = channelMember.memberName;
                                chatAdapter.getData().get(i).wkMsg.getMemberOfFrom().memberRemark = channelMember.memberRemark;
                                chatAdapter.getData().get(i).wkMsg.getMemberOfFrom().memberAvatar = channelMember.memberAvatar;
                                chatAdapter.getData().get(i).isRefreshAvatarAndName = true;
                                chatAdapter.notifyItemChanged(i, chatAdapter.getData().get(i));
                            }
                        }
                    }
                }
            }
            if (isEnd) {
                checkLoginUserInGroupStatus();
            }
        });

        //监听移除频道成员
        WKIM.getInstance().getChannelMembersManager().addOnRemoveChannelMemberListener(channelId, list -> {
            if (WKReader.isNotEmpty(list) && !TextUtils.isEmpty(list.get(0).channelID) && list.get(0).channelID.equals(channelId) && list.get(0).channelType == channelType) {
                if (groupType == WKGroupType.normalGroup) {
                    count = WKIM.getInstance().getChannelMembersManager().getMemberCount(channelId, channelType);
                    wkVBinding.topLayout.subtitleTv.setText(String.format(getString(R.string.group_member), count));
                }
                //查询登录用户是否在本群
                checkLoginUserInGroupStatus();
                WKRobotModel.getInstance().syncRobotData(getChatChannelInfo());
            }
        });
        //监听添加频道成员
        WKIM.getInstance().getChannelMembersManager().addOnAddChannelMemberListener(channelId, list -> {
            if (WKReader.isNotEmpty(list) && !TextUtils.isEmpty(list.get(0).channelID) && list.get(0).channelID.equals(channelId) && list.get(0).channelType == channelType && groupType == WKGroupType.normalGroup) {
                count = WKIM.getInstance().getChannelMembersManager().getMemberCount(channelId, channelType);
                wkVBinding.topLayout.subtitleTv.setText(String.format(getString(R.string.group_member), count));
                WKRobotModel.getInstance().syncRobotData(getChatChannelInfo());
                checkLoginUserInGroupStatus();
            }
        });
        //监听删除消息
        WKIM.getInstance().getMsgManager().addOnDeleteMsgListener(channelId, msg -> {
            if (msg != null) {
                removeMsg(msg);
            }
        });
        // 命令消息监听
        WKIM.getInstance().getCMDManager().addCmdListener(channelId, wkCmd -> {
            if (wkCmd == null || TextUtils.isEmpty(wkCmd.cmdKey)) return;
            // 监听正在输入
            if (wkCmd.cmdKey.equals(WKCMDKeys.wk_typing)) {
                typing(wkCmd);
            }
        });

        //监听消息刷新
        WKIM.getInstance().getMsgManager().addOnRefreshMsgListener(channelId, (wkMsg, left) -> {
            if (wkMsg.remoteExtra.isMutualDeleted == 1) {
                removeMsg(wkMsg);
                return;
            }
            refreshMsg(wkMsg);
        });
        //监听发送消息返回
        WKIM.getInstance().getMsgManager().addOnSendMsgCallback(channelId, this::sendMsgInserted);

        //监听新消息
        WKIM.getInstance().getMsgManager().addOnNewMsgListener(channelId, this::receivedMessages);
        //监听清空聊天记录
        WKIM.getInstance().getMsgManager().addOnClearMsgListener(channelId, (channelID, channelType, fromUID) -> {
            if (!TextUtils.isEmpty(channelID) && ChatActivity.this.channelId.equals(channelID) && ChatActivity.this.channelType == channelType) {
                if (TextUtils.isEmpty(fromUID)) {
                    chatAdapter = new ChatAdapter(ChatActivity.this, ChatAdapter.AdapterType.normalMessage);
                    wkVBinding.recyclerView.setAdapter(chatAdapter);
                } else {
                    for (int i = 0; i < chatAdapter.getData().size(); i++) {
                        if (chatAdapter.getData().get(i).wkMsg != null && !TextUtils.isEmpty(chatAdapter.getData().get(i).wkMsg.fromUID) && chatAdapter.getData().get(i).wkMsg.fromUID.equals(fromUID)) {
                            chatAdapter.removeAt(i);
                            i--;
                        }
                    }
                }
            }

        });
        WKIM.getInstance().getReminderManager().addOnNewReminderListener(channelId, this::resetReminder);
        EndpointManager.getInstance().setMethod(channelId, EndpointCategory.wkExitChat, object -> {
            if (object != null) {
                WKChannel channel = (WKChannel) object;
                if (channelId.equals(channel.channelID) && channel.channelType == channelType) {
                    finish();
                }
            }
            return null;
        });
        WKIM.getInstance().getConnectionManager().addOnConnectionStatusListener(channelId, (i, s) -> {
            if (i == WKConnectStatus.syncCompleted && WKUIKitApplication.getInstance().isRefreshChatActivityMessage) {
                WKUIKitApplication.getInstance().isRefreshChatActivityMessage = false;
                int firstItemPosition = linearLayoutManager.findFirstVisibleItemPosition();
                if (firstItemPosition == -1) return;
                if (WKReader.isNotEmpty(chatAdapter.getData())) {
                    WKMsg msg = chatAdapter.getFirstVisibleItem(firstItemPosition);
                    if (msg != null) {
//                            keepMsgSeq = msg.messageSeq;
                        lastPreviewMsgOrderSeq = msg.orderSeq;
                        int index = chatAdapter.getFirstVisibleItemIndex(firstItemPosition);
                        View view = linearLayoutManager.findViewByPosition(index);
                        if (view != null) {
                            keepOffsetY = view.getTop();
                        }
                    }
                }
                getData(1, false, lastPreviewMsgOrderSeq, false);
            }
            // 更新标题栏连接状态显示
            runOnUiThread(() -> updateConnectionStatusInTitle(i));
        });
        EndpointManager.getInstance().setMethod(channelId, EndpointCategory.refreshProhibitWord, object -> {
            if (WKReader.isEmpty(chatAdapter.getData())) {
                return 1;
            }
            for (int i = 0, size = chatAdapter.getData().size(); i < size; i++) {
                if (chatAdapter.getData().get(i).wkMsg != null && chatAdapter.getData().get(i).wkMsg.type == WKContentType.WK_TEXT) {
                    WKIMUtils.getInstance().resetMsgProhibitWord(chatAdapter.getData().get(i).wkMsg);
                    chatAdapter.getData().get(i).formatSpans(ChatActivity.this, chatAdapter.getData().get(i).wkMsg);
                    chatAdapter.notifyItemChanged(i);
                }
            }
            return 1;
        });
        EndpointManager.getInstance().setMethod("hide_pinned_view", object -> {
            if (!isShowPinnedView) return null;
            isShowPinnedView = false;
            RelativeLayout.LayoutParams lp = (RelativeLayout.LayoutParams) wkVBinding.timeTv.getLayoutParams();
            lp.topMargin = AndroidUtilities.dp(10);
            wkVBinding.timeTv.setVisibility(View.GONE);
            ObjectAnimator animator = ObjectAnimator.ofFloat(wkVBinding.pinnedLayout, "translationY", 0, -AndroidUtilities.dp(53));
            animator.setDuration(200);
            animator.addListener(new AnimatorListenerAdapter() {
                @Override
                public void onAnimationEnd(Animator animation) {
                    wkVBinding.pinnedLayout.clearAnimation();
                    wkVBinding.pinnedLayout.setVisibility(View.GONE);
                    if (WKReader.isNotEmpty(chatAdapter.getData()) && chatAdapter.getData().get(0).wkMsg != null && chatAdapter.getData().get(0).wkMsg.type == WKContentType.spanEmptyView) {
                        chatAdapter.getData().remove(0);
                        chatAdapter.notifyItemRemoved(0);
                        //chatAdapter.notifyDataSetChanged();
                    }
                }

                public void onAnimationStart(Animator animation) {
                    wkVBinding.pinnedLayout.setVisibility(View.VISIBLE);
                }
            });
            wkVBinding.pinnedLayout.setVisibility(View.VISIBLE);
            animator.start();
            return null;
        });
        EndpointManager.getInstance().setMethod("show_pinned_view", object -> {
            if (isShowPinnedView) {
                return null;
            }
            isShowPinnedView = true;
            if (WKReader.isNotEmpty(chatAdapter.getData()) && chatAdapter.getData().get(0).wkMsg != null && chatAdapter.getData().get(0).wkMsg.type != WKContentType.spanEmptyView) {
                WKMsg msg = new WKMsg();
                msg.timestamp = 0;
                msg.type = WKContentType.spanEmptyView;
                chatAdapter.addData(0, new WKUIChatMsgItemEntity(this, msg, null));
            }
            RelativeLayout.LayoutParams lp = (RelativeLayout.LayoutParams) wkVBinding.timeTv.getLayoutParams();
            lp.topMargin = AndroidUtilities.dp(60);
            wkVBinding.timeTv.setVisibility(View.GONE);
            ObjectAnimator animator = ObjectAnimator.ofFloat(wkVBinding.pinnedLayout, "translationY", -wkVBinding.pinnedLayout.getHeight(), 0);
            animator.setDuration(200);
            animator.addListener(new AnimatorListenerAdapter() {
                @Override
                public void onAnimationEnd(Animator animation) {
                    // wkVBinding.pinnedLayout.clearAnimation();
                    wkVBinding.pinnedLayout.setVisibility(View.VISIBLE);
                }
            });
            animator.start();
            wkVBinding.pinnedLayout.setVisibility(View.VISIBLE);
            return null;
        });
        EndpointManager.getInstance().setMethod("tip_msg_in_chat", object -> {
            tipsMsg((String) object);
            return null;
        });
        EndpointManager.getInstance().setMethod("reset_channel_all_pinned_msg", object -> {
            resetHideChannelAllPinnedMessage();
            for (int i = 0, size = chatAdapter.getData().size(); i < size; i++) {
                if (hideChannelAllPinnedMessage == 1) {
                    if (chatAdapter.getData().get(i).isPinned == 1) {
                        chatAdapter.getData().get(i).isPinned = 0;
                        chatAdapter.notifyStatus(i);
                    }
                } else {
                    if (chatAdapter.getData().get(i).isPinned == 0) {
                        if (chatAdapter.getData().get(i).wkMsg.remoteExtra != null && chatAdapter.getData().get(i).wkMsg.remoteExtra.isPinned == 1) {
                            chatAdapter.getData().get(i).isPinned = 1;
                            chatAdapter.notifyStatus(i);
                        }
                    }
                }
            }
            return null;
        });
    }

    @Override
    protected void onNewIntent(@NonNull Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        initParam();
        initData();
    }

    private void initData() {
        startTimer();
        EndpointManager.getInstance().invoke(EndpointSID.openChatPage, getChatChannelInfo());
        //获取网络频道信息
        WKIM.getInstance().getChannelManager().fetchChannelInfo(channelId, channelType);
        MsgModel.getInstance().syncExtraMsg(channelId, channelType);
        WKRobotModel.getInstance().syncRobotData(getChatChannelInfo());
        WKCommonModel.getInstance().getChannelState(channelId, channelType, channelState -> {
            if (channelState != null) {
                if (channelType == WKChannelType.GROUP && channelState.online_count > 0) {
                    wkVBinding.topLayout.subtitleCountTv.setVisibility(View.VISIBLE);
                    wkVBinding.topLayout.subtitleCountTv.setText(String.format(getString(R.string.online_count), channelState.online_count));
                }
            }
        });

        // Do NOT clear chatAdapter data here - causes messages to disappear during onNewIntent.
        // getData() with isSetNewData=true will atomically replace data via setNewInstance().
        WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(channelId, channelType);

        String avatarKey = "";
        if (channel != null) {
            wkVBinding.topLayout.categoryLayout.removeAllViews();
            avatarKey = channel.avatarCacheKey;
            if (channel.remoteExtraMap != null && channel.remoteExtraMap.containsKey(WKChannelExtras.groupType)) {
                Object object = channel.remoteExtraMap.get(WKChannelExtras.groupType);
                if (object instanceof Integer) {
                    groupType = (int) object;
                }
            }
            if (!TextUtils.isEmpty(channel.category)) {
                if (channel.category.equals(WKSystemAccount.accountCategorySystem)) {
                    wkVBinding.topLayout.categoryLayout.addView(Theme.getChannelCategoryTV(this, getString(R.string.official), ContextCompat.getColor(this, R.color.transparent), ContextCompat.getColor(this, R.color.reminderColor), ContextCompat.getColor(this, R.color.reminderColor)), LayoutHelper.createLinear(LayoutHelper.WRAP_CONTENT, LayoutHelper.WRAP_CONTENT, Gravity.CENTER, 5, 1, 0, 0));
                }
                if (channel.category.equals(WKSystemAccount.accountCategoryCustomerService)) {
                    wkVBinding.topLayout.categoryLayout.addView(Theme.getChannelCategoryTV(this, getString(R.string.customer_service), Theme.colorAccount, ContextCompat.getColor(this, R.color.white), Theme.colorAccount), LayoutHelper.createLinear(LayoutHelper.WRAP_CONTENT, LayoutHelper.WRAP_CONTENT, Gravity.CENTER, 5, 1, 0, 0));
                }
                if (channel.category.equals(WKSystemAccount.accountCategoryVisitor)) {
                    wkVBinding.topLayout.categoryLayout.addView(Theme.getChannelCategoryTV(this, getString(R.string.visitor), ContextCompat.getColor(this, R.color.transparent), ContextCompat.getColor(this, R.color.colorFFC107), ContextCompat.getColor(this, R.color.colorFFC107)), LayoutHelper.createLinear(LayoutHelper.WRAP_CONTENT, LayoutHelper.WRAP_CONTENT, Gravity.CENTER, 5, 1, 0, 0));
                }
                if (channel.category.equals(WKSystemAccount.channelCategoryOrganization)) {
                    wkVBinding.topLayout.categoryLayout.addView(Theme.getChannelCategoryTV(this, getString(R.string.all_staff), ContextCompat.getColor(this, R.color.category_org_bg), ContextCompat.getColor(this, R.color.category_org_text), ContextCompat.getColor(this, R.color.transparent)), LayoutHelper.createLinear(LayoutHelper.WRAP_CONTENT, LayoutHelper.WRAP_CONTENT, Gravity.CENTER, 5, 1, 0, 0));
                }
                if (channel.category.equals(WKSystemAccount.channelCategoryDepartment)) {
                    wkVBinding.topLayout.categoryLayout.addView(Theme.getChannelCategoryTV(this, getString(R.string.department), ContextCompat.getColor(this, R.color.category_org_bg), ContextCompat.getColor(this, R.color.category_org_text), ContextCompat.getColor(this, R.color.transparent)), LayoutHelper.createLinear(LayoutHelper.WRAP_CONTENT, LayoutHelper.WRAP_CONTENT, Gravity.CENTER, 5, 1, 0, 0));
                }
            }
            showChannelName(channel);
            if (channel.robot == 1) {
                wkVBinding.topLayout.categoryLayout.addView(Theme.getChannelCategoryTV(this, getString(R.string.bot), ContextCompat.getColor(this, R.color.color_main), ContextCompat.getColor(this, R.color.white), ContextCompat.getColor(this, R.color.color_main)), LayoutHelper.createLinear(LayoutHelper.WRAP_CONTENT, LayoutHelper.WRAP_CONTENT, Gravity.CENTER, 5, 1, 1, 0));
            }
            EndpointManager.getInstance().invoke("show_avatar_other_info", new AvatarOtherViewMenu(wkVBinding.topLayout.otherLayout, channel, wkVBinding.topLayout.avatarView, true));
        } else {
            // 本地没有频道信息时，默认显示channelId作为名字
            wkVBinding.topLayout.titleCenterTv.setText(channelId);
        }
        wkVBinding.topLayout.avatarView.showAvatar(channelId, channelType, avatarKey);

        //如果是群聊就同步群成员信息
        if (channelType == WKChannelType.GROUP) {
            if (groupType == WKGroupType.normalGroup) {
                GroupModel.getInstance().groupMembersSync(channelId, (code, msg) -> {
                    if (code == HttpResponseCode.success) {
                        WKChannelMember member = WKIM.getInstance().getChannelMembersManager().getMember(channelId, channelType, WKConfig.getInstance().getUid());
                        hideOrShowRightView(member == null || member.isDeleted != 1);
                        // 更新入群时间
                        if (member != null && !TextUtils.isEmpty(member.createdAt)) {
                            memberJoinTimestamp = WKTimeUtils.getInstance().date2TimeStamp(member.createdAt, "yyyy-MM-dd HH:mm:ss");
                        }
                        WKRobotModel.getInstance().syncRobotData(getChatChannelInfo());
                        if (chatPanelManager != null) {
                            chatPanelManager.showOrHideForbiddenView();
                        }
                    }
                });
            }
            //获取sdk频道信息
            if (channel != null) {
                count = WKIM.getInstance().getChannelMembersManager().getMemberCount(channelId, channelType);
                showChannelName(channel);
                // showNickName = channel.showNick == 1;
                // 读取新成员查看历史消息设置
                if (channel.remoteExtraMap != null && channel.remoteExtraMap.containsKey("allow_view_history_msg")) {
                    Object val = channel.remoteExtraMap.get("allow_view_history_msg");
                    if (val instanceof Integer) {
                        isAllowViewHistoryMsg = (int) val == 1;
                    }
                }
                if (chatPanelManager != null) {
                    if (WKChannelUtils.getInstance().isGroupForbidden(channel)) {
                        chatPanelManager.showOrHideForbiddenView();
                    }
                    if (channel.status == WKChannelStatus.statusDisabled) {
                        chatPanelManager.showBan();
                    } else {
                        chatPanelManager.hideBan();
                    }
                }
            }

            WKChannelMember member = WKIM.getInstance().getChannelMembersManager().getMember(channelId, channelType, WKConfig.getInstance().getUid());
            hideOrShowRightView(member == null || member.isDeleted == 0);
            // 读取当前用户入群时间
            if (member != null && !TextUtils.isEmpty(member.createdAt)) {
                memberJoinTimestamp = WKTimeUtils.getInstance().date2TimeStamp(member.createdAt, "yyyy-MM-dd HH:mm:ss");
            }
            if (groupType == WKGroupType.normalGroup) {
                wkVBinding.topLayout.subtitleTv.setText(String.format(getString(R.string.group_member), count));
            }
            wkVBinding.topLayout.subtitleView.setVisibility(View.VISIBLE);
            if (chatPanelManager != null) {
                chatPanelManager.showOrHideForbiddenView();
            }
        } else {
            hideOrShowRightView(true);
            wkVBinding.topLayout.subtitleCountTv.setVisibility(View.GONE);
            if (channel != null) {
                setOnlineView(channel);
                showChannelName(channel);
            }
        }


        //定位消息
        if (getIntent().hasExtra("lastPreviewMsgOrderSeq")) {
            lastPreviewMsgOrderSeq = getIntent().getLongExtra("lastPreviewMsgOrderSeq", 0L);
            isCanLoadMore = lastPreviewMsgOrderSeq > 0;
        }
        if (getIntent().hasExtra("keepOffsetY")) {
            keepOffsetY = getIntent().getIntExtra("keepOffsetY", 0);
        }
        if (getIntent().hasExtra("redDot")) redDot = getIntent().getIntExtra("redDot", 0);
        if (getIntent().hasExtra("tipsOrderSeq")) {
            tipsOrderSeq = getIntent().getLongExtra("tipsOrderSeq", 0);
        }
        if (getIntent().hasExtra("unreadStartMsgOrderSeq")) {
            unreadStartMsgOrderSeq = getIntent().getLongExtra("unreadStartMsgOrderSeq", 0);
        }

        List<WKReminder> allReminder = WKIM.getInstance().getReminderManager().getReminders(channelId, channelType);
        if (WKReader.isNotEmpty(allReminder)) {
            String loginUID = WKConfig.getInstance().getUid();
            for (WKReminder reminder : allReminder) {

                boolean isPublisher = !TextUtils.isEmpty(reminder.publisher) && reminder.publisher.equals(loginUID);
                if (reminder.type == WKMentionType.WKReminderTypeMentionMe && reminder.done == 0 && !isPublisher) {
                    reminderList.add(reminder);
                }
                if (reminder.type == WKMentionType.WKApplyJoinGroupApprove && reminder.done == 0) {
                    groupApproveList.add(reminder);
                }
            }
        }
        // 先获取聊天数据
        boolean isScrollToEnd = unreadStartMsgOrderSeq == 0 && lastPreviewMsgOrderSeq == 0;
        long aroundMsgSeq = 0;
        // 默认允许加载更多历史消息，确保能全量同步历史记录
        isCanLoadMore = true;
        if (unreadStartMsgOrderSeq != 0) {
            aroundMsgSeq = unreadStartMsgOrderSeq;
        }
        isUpdateRedDot = unreadStartMsgOrderSeq > 0;
        if (lastPreviewMsgOrderSeq != 0) aroundMsgSeq = lastPreviewMsgOrderSeq;
        if (tipsOrderSeq != 0) {
            aroundMsgSeq = tipsOrderSeq;
        }
        if (aroundMsgSeq == 0 && getIntent().hasExtra("aroundMsgSeq")) {
            aroundMsgSeq = getIntent().getLongExtra("aroundMsgSeq", 0);
        }
        getData(lastPreviewMsgOrderSeq == 0 ? 0 : 1, unreadStartMsgOrderSeq > 0, aroundMsgSeq, isScrollToEnd);

        //查询高光内容
        WKConversationMsgExtra extra = WKIM.getInstance().getConversationManager().getMsgExtraWithChannel(channelId, channelType);
        if (extra != null) {
            if (!TextUtils.isEmpty(extra.draft)) {
                if (chatPanelManager != null) {
                    chatPanelManager.setEditContent(extra.draft);
                }
            }
            browseTo = extra.browseTo;
        }
        new Handler().postDelayed(() -> {
            resetRemindView();
            resetGroupApproveView();
        }, 150);

    }


    // 获取聊天记录
    private void getData(int pullMode, boolean isSetNewData, long aroundMsgOrderSeq, boolean isScrollToEnd) {
        boolean contain = false;
        long oldestOrderSeq;
        if (pullMode == 1) {
            oldestOrderSeq = chatAdapter.getEndMsgOrderSeq();
        } else {
            oldestOrderSeq = chatAdapter.getFirstMsgOrderSeq();
        }
        if (isSyncLastMsg) {
            oldestOrderSeq = 0;
        }
        //定位消息
        if (lastPreviewMsgOrderSeq != 0) {
            contain = true;
            oldestOrderSeq = lastPreviewMsgOrderSeq;
        }
        if (unreadStartMsgOrderSeq != 0) contain = true;
        android.util.Log.d("ChatHistoryFix", "getData: channel=" + channelId + " pullMode=" + pullMode + " limit=" + limit + " oldestOrderSeq=" + oldestOrderSeq + " isFirstDataLoad=" + isFirstDataLoad + " isAutoSyncingHistory=" + isAutoSyncingHistory + " autoSyncedMsgCount=" + autoSyncedMsgCount);
        WKIM.getInstance().getMsgManager().getOrSyncHistoryMessages(channelId, channelType, oldestOrderSeq, contain, pullMode, limit, aroundMsgOrderSeq, new IGetOrSyncHistoryMsgBack() {
            @Override
            public void onSyncing() {
                android.util.Log.d("ChatHistoryFix", "getData.onSyncing: channel=" + channelId);
                if (isShowPinnedView && !isRefreshLoading && !isMoreLoading && !isSyncLastMsg) {
                    EndpointManager.getInstance().invoke("is_syncing_message", 1);
                } else {
                    if (WKReader.isEmpty(chatAdapter.getData())) {
                        WKMsg wkMsg = new WKMsg();
                        wkMsg.type = WKContentType.loading;
                        chatAdapter.addData(new WKUIChatMsgItemEntity(ChatActivity.this, wkMsg, null));
                    }
                }
            }

            @Override
            public void onResult(List<WKMsg> list) {
                android.util.Log.d("ChatHistoryFix", "getData.onResult: pullMode=" + pullMode + " listSize=" + (list == null ? 0 : list.size()) + " isFirstDataLoad=" + isFirstDataLoad);
                if (isShowPinnedView) {
                    EndpointManager.getInstance().invoke("is_syncing_message", 0);
                }
                if (pullMode == 0) {
                    if (WKReader.isEmpty(list))
                        isCanRefresh = false;
                } else {
                    if (WKReader.isEmpty(list)) {
                        isCanLoadMore = false;
                        // 自动同步历史消息结束
                        if (isAutoSyncingHistory) {
                            isAutoSyncingHistory = false;
                            android.util.Log.d("ChatHistoryFix", "autoSyncHistory: completed! total synced=" + autoSyncedMsgCount + " messages");
                        }
                    }
                }
                isSyncLastMsg = false;
                showData(list, pullMode, isSetNewData, isScrollToEnd);
                wkVBinding.chatUnreadLayout.progress.setVisibility(View.GONE);
                wkVBinding.chatUnreadLayout.msgDownIv.setVisibility(View.VISIBLE);

                if (WKReader.isNotEmpty(chatAdapter.getData())) {
                    for (int i = 0, size = chatAdapter.getData().size(); i < size; i++) {
                        if (chatAdapter.getData().get(i).wkMsg != null && chatAdapter.getData().get(i).wkMsg.type == WKContentType.loading) {
                            chatAdapter.removeAt(i);
                            break;
                        }
                    }
                }
                isRefreshLoading = false;
                isMoreLoading = false;
                isFirstDataLoad = false;
                // 移除进入页面自动全量同步历史消息的逻辑
                // 用户下拉刷新时才主动加载更早的消息，避免进入页面卡顿和重复加载
            }
        });


    }

    /**
     * 显示数据
     *
     * @param msgList       数据源
     * @param pullMode      拉取模式 0:向下拉取 1:向上拉取
     * @param isSetNewData  是否重新显示新数据
     * @param isScrollToEnd 是否滚动到底部
     */
    private void showData(List<WKMsg> msgList, int pullMode, boolean isSetNewData, boolean isScrollToEnd) {
        // 按timestamp和orderSeq严格排序，确保聊天记录按时间顺序显示
        if (WKReader.isNotEmpty(msgList)) {
            Collections.sort(msgList, (a, b) -> {
                long t1 = a.timestamp;
                long t2 = b.timestamp;
                if (t1 != t2) return Long.compare(t1, t2);
                return Long.compare(a.orderSeq, b.orderSeq);
            });
        }
        // 新成员查看历史消息控制：群聊且不允许查看历史消息时，过滤掉入群时间之前的消息
        if (channelType == WKChannelType.GROUP && !isAllowViewHistoryMsg && memberJoinTimestamp > 0 && WKReader.isNotEmpty(msgList)) {
            List<WKMsg> filteredList = new ArrayList<>();
            for (WKMsg msg : msgList) {
                // 保留系统占位类型的消息（emptyView等由UI添加的）
                if (msg.type == WKContentType.emptyView || msg.type == WKContentType.spanEmptyView) {
                    filteredList.add(msg);
                } else if (msg.timestamp >= memberJoinTimestamp) {
                    // 只保留入群时间之后的真实消息
                    filteredList.add(msg);
                }
            }
            msgList.clear();
            msgList.addAll(filteredList);
        }
        boolean isAddEmptyView = WKReader.isNotEmpty(msgList) && msgList.size() < limit;
        if (isAddEmptyView) {
            WKMsg msg = new WKMsg();
            msg.timestamp = 0;
            msg.type = WKContentType.emptyView;
            msgList.add(0, msg);
        }
        if (isShowPinnedView && pullMode == 0) {
            if (WKReader.isNotEmpty(chatAdapter.getData()) && chatAdapter.getData().get(0).wkMsg != null && chatAdapter.getData().get(0).wkMsg.type == WKContentType.spanEmptyView) {
                chatAdapter.removeAt(0);
            }
            WKMsg msg = new WKMsg();
            msg.timestamp = 0;
            msg.type = WKContentType.spanEmptyView;
            msgList.add(0, msg);
        }

        List<WKUIChatMsgItemEntity> list = new ArrayList<>();
        if (WKReader.isNotEmpty(msgList)) {
            long pre_msg_time = chatAdapter.getLastTimeMsg();
            for (int i = 0, size = msgList.size(); i < size; i++) {

                if (WKTimeUtils.getInstance().isNeedShowTimeDivider(msgList.get(i).timestamp, pre_msg_time) && msgList.get(i).type != WKContentType.emptyView && msgList.get(i).type != WKContentType.spanEmptyView) {
                    //显示聊天时间
                    WKUIChatMsgItemEntity uiChatMsgEntity = new WKUIChatMsgItemEntity(this, new WKMsg(), null);
                    uiChatMsgEntity.wkMsg.type = WKContentType.msgPromptTime;
                    uiChatMsgEntity.wkMsg.content = WKTimeUtils.getInstance().getTimeString(msgList.get(i).timestamp * 1000);
                    uiChatMsgEntity.wkMsg.timestamp = msgList.get(i).timestamp;
                    list.add(uiChatMsgEntity);
                }
                pre_msg_time = msgList.get(i).timestamp;
                WKUIChatMsgItemEntity uiMsg = WKIMUtils.getInstance().msg2UiMsg(this, msgList.get(i), count, showNickName, chatAdapter.isShowChooseItem());
                if (msgList.get(i).remoteExtra != null) {
                    if (hideChannelAllPinnedMessage == 1) {
                        uiMsg.isPinned = 0;
                    } else {
                        uiMsg.isPinned = msgList.get(i).remoteExtra.isPinned;
                    }
                }
                String pinKey = String.format("pinned_msg_%s_%s", channelId, channelType);
                String pinnedClientMsgNO = WKSharedPreferencesUtil.getInstance().getSPWithUID(pinKey);
                if (!TextUtils.isEmpty(pinnedClientMsgNO)
                        && msgList.get(i).clientMsgNO != null
                        && msgList.get(i).clientMsgNO.equals(pinnedClientMsgNO)) {
                    if (msgList.get(i).remoteExtra == null) {
                        msgList.get(i).remoteExtra = new WKMsgExtra();
                    }
                    msgList.get(i).remoteExtra.isPinned = 1;
                    uiMsg.isPinned = 1;
                }
                list.add(uiMsg);
            }
        }

        if (isSetNewData) {
            if (unreadStartMsgOrderSeq != 0) {
                for (int i = 0, size = list.size(); i < size; i++) {
                    if (list.get(i).wkMsg != null && list.get(i).wkMsg.orderSeq == unreadStartMsgOrderSeq) {
                        //插入一条本地的新消息分割线
                        WKUIChatMsgItemEntity uiChatMsgItemEntity = new WKUIChatMsgItemEntity(this, new WKMsg(), null);
                        uiChatMsgItemEntity.wkMsg.type = WKContentType.msgPromptNewMsg;
                        int index = i;
                        if (index <= 0) index = 0;
                        if (index > list.size() - 1) index = list.size() - 1;
                        list.add(index, uiChatMsgItemEntity);
                        if (index >= 1) {
                            linearLayoutManager.scrollToPositionWithOffset(index, 50);
                        } else wkVBinding.recyclerView.scrollToPosition(index);
                        unreadStartMsgOrderSeq = 0;
                        break;
                    }
                }
            }
            chatAdapter.resetData(list);
            chatAdapter.setNewInstance(list);
            restorePinnedBanner();
        } else {
            chatAdapter.resetData(list);
            if (pullMode == 1) {
                // 去除与已有数据重复的消息（时间戳跟随消息：消息被去重则时间戳也去掉）
                List<WKUIChatMsgItemEntity> filteredList = new ArrayList<>();
                WKUIChatMsgItemEntity pendingTimeItem = null;
                for (int i = 0, size = list.size(); i < size; i++) {
                    WKMsg wk = list.get(i).wkMsg;
                    if (wk != null && wk.type == WKContentType.msgPromptTime) {
                        // 缓存时间戳，等下一条消息决定是否保留
                        pendingTimeItem = list.get(i);
                        continue;
                    }
                    if (wk != null && !chatAdapter.isExist(wk.clientMsgNO)) {
                        // 消息需要保留，先加入前面的时间戳
                        if (pendingTimeItem != null) {
                            filteredList.add(pendingTimeItem);
                            pendingTimeItem = null;
                        }
                        filteredList.add(list.get(i));
                    } else {
                        // 消息被去重，丢弃对应的时间戳
                        pendingTimeItem = null;
                    }
                }
                list = filteredList;
                if (WKReader.isNotEmpty(chatAdapter.getData()) && WKReader.isNotEmpty(list))
                    list.get(0).previousMsg = chatAdapter.getData().get(chatAdapter.getData().size() - 1).wkMsg;
                chatAdapter.addData(list);
            } else {
                // 去除与已有数据重复的消息（时间戳跟随消息：消息被去重则时间戳也去掉）
                List<WKUIChatMsgItemEntity> filteredList = new ArrayList<>();
                WKUIChatMsgItemEntity pendingTimeItem = null;
                for (int i = 0, size = list.size(); i < size; i++) {
                    WKMsg wk = list.get(i).wkMsg;
                    if (wk != null && wk.type == WKContentType.msgPromptTime) {
                        // 缓存时间戳，等下一条消息决定是否保留
                        pendingTimeItem = list.get(i);
                        continue;
                    }
                    if (wk != null && !chatAdapter.isExist(wk.clientMsgNO)) {
                        // 消息需要保留，先加入前面的时间戳
                        if (pendingTimeItem != null) {
                            filteredList.add(pendingTimeItem);
                            pendingTimeItem = null;
                        }
                        filteredList.add(list.get(i));
                    } else {
                        // 消息被去重，丢弃对应的时间戳
                        pendingTimeItem = null;
                    }
                }
                list = filteredList;
                if (WKReader.isNotEmpty(list) && WKReader.isNotEmpty(chatAdapter.getData())) {
                    list.get(list.size() - 1).nextMsg = chatAdapter.getData().get(0).wkMsg;
                }
                chatAdapter.addData(0, list);
            }
        }
        if (tipsOrderSeq != 0 || lastPreviewMsgOrderSeq != 0) {
            wkVBinding.recyclerView.setVisibility(View.VISIBLE);
            if (tipsOrderSeq != 0) {
                for (int i = 0; i < chatAdapter.getData().size(); i++) {
                    if (chatAdapter.getItem(i).wkMsg.orderSeq == tipsOrderSeq) {
                        linearLayoutManager.scrollToPositionWithOffset(i, AndroidUtilities.dp(50));
                        chatAdapter.getItem(i).isShowTips = true;
                        chatAdapter.notifyItemChanged(i);
                        tipsOrderSeq = 0;
                        break;
                    }
                }
            }
            if (lastPreviewMsgOrderSeq != 0) {
                for (int i = 0; i < chatAdapter.getData().size(); i++) {
                    if (chatAdapter.getItem(i).wkMsg.orderSeq == lastPreviewMsgOrderSeq) {
                        linearLayoutManager.scrollToPositionWithOffset(i, keepOffsetY);
                        break;
                    }
                }
            }
        } else {
            if (isScrollToEnd)
                wkVBinding.recyclerView.scrollToPosition(chatAdapter.getItemCount() - 1);
            else wkVBinding.recyclerView.setVisibility(View.VISIBLE);
        }
        if (isCanLoadMore && WKReader.isNotEmpty(chatAdapter.getData()) && chatAdapter.getData().get(chatAdapter.getData().size() - 1).wkMsg != null) {
            int maxSeq = WKIM.getInstance().getMsgManager().getMaxMessageSeqWithChannel(channelId, channelType);
            if (chatAdapter.getData().get(chatAdapter.getData().size() - 1).wkMsg.messageSeq == maxSeq) {
                isCanLoadMore = false;
            }
        }
    }


    private void hideOrShowRightView(boolean isShow) {
        if (wkVBinding.topLayout != null && wkVBinding.topLayout.rightView != null) {
            wkVBinding.topLayout.rightView.setVisibility(isShow ? View.VISIBLE : View.GONE);
        }
        // 系统账号和群聊隐藏通话按钮
        if (wkVBinding.topLayout != null && wkVBinding.topLayout.callView != null) {
            if (channelType == WKChannelType.GROUP) {
                wkVBinding.topLayout.callView.setVisibility(View.GONE);
            } else if (channelType == WKChannelType.PERSONAL && WKSystemAccount.isSystemAccount(channelId)) {
                wkVBinding.topLayout.callView.setVisibility(View.GONE);
            } else {
                wkVBinding.topLayout.callView.setVisibility(isShow ? View.VISIBLE : View.GONE);
            }
        }
    }

    private void resetReminder(List<WKReminder> list) {
        if (WKReader.isNotEmpty(list)) {
            List<WKUIChatMsgItemEntity> msgList = chatAdapter.getData();
            List<Long> ids = new ArrayList<>();
            for (int i = 0, size = list.size(); i < size; i++) {
                if (list.get(i).done == 1) continue;
                for (int j = 0, len = msgList.size(); j < len; j++) {
                    if (msgList.get(j).wkMsg != null && !TextUtils.isEmpty(msgList.get(j).wkMsg.messageID) && msgList.get(j).wkMsg.messageID.equals(list.get(i).messageID)) {
                        if (msgList.get(j).wkMsg.viewed == 1) {
                            ids.add(list.get(i).reminderID);
                            list.remove(i);
                            i--;
                            size--;
                            break;
                        }
                    }
                }
            }
            MsgModel.getInstance().doneReminder(ids);
            if (WKReader.isEmpty(list)) {
                return;
            }
            String loginUID = WKConfig.getInstance().getUid();
            for (WKReminder reminder : list) {
                boolean isPublisher = !TextUtils.isEmpty(reminder.publisher) && reminder.publisher.equals(loginUID);
                if (!reminder.channelID.equals(channelId) || isPublisher) continue;
                if (reminder.done == 0) {
                    boolean isAdd = true;
                    for (int i = 0, size = reminderList.size(); i < size; i++) {
                        if (reminder.reminderID == reminderList.get(i).reminderID && reminder.type == reminderList.get(i).type) {
                            isAdd = false;
                            reminderList.get(i).done = 0;
                            break;
                        }
                    }
                    if (isAdd && reminder.type == WKMentionType.WKReminderTypeMentionMe)
                        reminderList.add(reminder);
                    boolean isAddApprove = true;
                    for (int i = 0, size = groupApproveList.size(); i < size; i++) {
                        if (reminder.reminderID == groupApproveList.get(i).reminderID && reminder.type == groupApproveList.get(i).type) {
                            isAddApprove = false;
                            groupApproveList.get(i).done = 0;
                            break;
                        }
                    }
                    if (isAddApprove && reminder.type == WKMentionType.WKApplyJoinGroupApprove)
                        groupApproveList.add(reminder);
                }
            }
            resetRemindView();
            resetGroupApproveView();
        }
    }

    private void resetRemindView() {
        wkVBinding.chatUnreadLayout.remindCountTv.setCount(reminderList.size(), true);
        wkVBinding.chatUnreadLayout.remindCountTv.setVisibility(WKReader.isNotEmpty(reminderList) ? View.VISIBLE : View.GONE);
        wkVBinding.chatUnreadLayout.remindLayout.post(() -> CommonAnim.getInstance().showOrHide(wkVBinding.chatUnreadLayout.remindLayout, WKReader.isNotEmpty(reminderList), WKReader.isNotEmpty(reminderList), false));
    }

    private void resetGroupApproveView() {
        wkVBinding.chatUnreadLayout.approveCountTv.setCount(groupApproveList.size(), true);
        wkVBinding.chatUnreadLayout.approveCountTv.setVisibility(WKReader.isNotEmpty(groupApproveList) ? View.VISIBLE : View.GONE);
        wkVBinding.chatUnreadLayout.groupApproveLayout.post(() -> CommonAnim.getInstance().showOrHide(wkVBinding.chatUnreadLayout.groupApproveLayout, WKReader.isNotEmpty(groupApproveList), WKReader.isNotEmpty(reminderList), false));
    }

    private void showUnReadCountView() {
        wkVBinding.chatUnreadLayout.msgCountTv.setCount(redDot, false);
        wkVBinding.chatUnreadLayout.msgCountTv.setVisibility(redDot > 0 ? View.VISIBLE : View.GONE);
//        wkVBinding.chatUnreadLayout.newMsgLayout.post(() -> CommonAnim.getInstance().showOrHide(wkVBinding.chatUnreadLayout.newMsgLayout, redDot > 0, true, false));
    }

    private void showChannelName(WKChannel channel) {
        String showName;
        if (channelId.equals(WKSystemAccount.system_team)) {
            showName = getString(R.string.wk_system_notice);
        } else if (channelId.equals(WKSystemAccount.system_file_helper)) {
            showName = getString(R.string.wk_file_helper);
        } else {
            showName = TextUtils.isEmpty(channel.channelRemark) ? channel.channelName : channel.channelRemark;
        }
        wkVBinding.topLayout.titleCenterTv.setText(showName);
    }

    private void removeMsg(WKMsg msg) {
        EndpointManager.getInstance().invoke("stop_reaction_animation", null);
        int tempIndex = 0;
        for (int i = 0, size = chatAdapter.getData().size(); i < size; i++) {
            if (chatAdapter.getData().get(i).wkMsg != null && (chatAdapter.getData().get(i).wkMsg.clientSeq == msg.clientSeq || chatAdapter.getData().get(i).wkMsg.clientMsgNO.equals(msg.clientMsgNO))) {
                tempIndex = i;
                if (i - 1 >= 0) {
                    if (i + 1 <= chatAdapter.getData().size() - 1) {
                        chatAdapter.getData().get(i - 1).nextMsg = chatAdapter.getData().get(i + 1).wkMsg;
                    } else {
                        chatAdapter.getData().get(i - 1).nextMsg = null;
                    }
                }
                if (i + 1 <= chatAdapter.getData().size() - 1) {
                    if (i - 1 >= 0) {
                        chatAdapter.getData().get(i + 1).previousMsg = chatAdapter.getData().get(i - 1).wkMsg;
                    } else chatAdapter.getData().get(i + 1).previousMsg = null;
                }
                chatAdapter.removeAt(i);
                break;
            }
        }

        int timeIndex = tempIndex - 1;
        if (timeIndex < 0) return;
        //如果是时间也删除
        if (chatAdapter.getData().size() >= timeIndex) {
            if (chatAdapter.getData().get(timeIndex).wkMsg.type == WKContentType.msgPromptTime) {

                if (timeIndex - 1 >= 0) {
                    if (timeIndex + 1 <= chatAdapter.getData().size() - 1) {
                        chatAdapter.getData().get(timeIndex - 1).nextMsg = chatAdapter.getData().get(timeIndex + 1).wkMsg;
                    } else {
                        chatAdapter.getData().get(timeIndex - 1).nextMsg = null;
                    }
                }
                if (timeIndex + 1 <= chatAdapter.getData().size() - 1) {
                    if (timeIndex - 1 >= 0) {
                        chatAdapter.getData().get(timeIndex + 1).previousMsg = chatAdapter.getData().get(timeIndex - 1).wkMsg;
                    } else chatAdapter.getData().get(timeIndex + 1).previousMsg = null;
                }
                chatAdapter.removeAt(timeIndex);
            }
        }
    }

    private void showToast(int textId) {
        WKToastUtils.getInstance().showToast(getString(textId));
    }

    private synchronized void setShowTime() {
        String showTime = "";
        int index = linearLayoutManager.findFirstVisibleItemPosition();
        if (index > 0 && index < chatAdapter.getData().size()) {
            WKUIChatMsgItemEntity WKUIChatMsgItemEntity = chatAdapter.getData().get(index);
            if (WKUIChatMsgItemEntity.wkMsg != null && WKUIChatMsgItemEntity.wkMsg.timestamp > 0) {
                showTime = WKTimeUtils.getInstance().getShowDate(WKUIChatMsgItemEntity.wkMsg.timestamp * 1000);
            }
        }
        if (!TextUtils.isEmpty(showTime)) {
            SpannableString str = new SpannableString(showTime);
            str.setSpan(new SystemMsgBackgroundColorSpan(ContextCompat.getColor(this, R.color.colorSystemBg), AndroidUtilities.dp(5), AndroidUtilities.dp(2 * 5)), 0, showTime.length(), 0);
            wkVBinding.timeTv.setText(str);
            CommonAnim.getInstance().showOrHide(wkVBinding.timeTv, true, true);
        } else {
            CommonAnim.getInstance().showOrHide(wkVBinding.timeTv, false, false);
        }
    }

    private boolean isRefreshReaction(List<WKMsgReaction> oldList, List<WKMsgReaction> newList) {
        if (WKReader.isEmpty(oldList) && WKReader.isEmpty(newList)) return false;
        if ((WKReader.isEmpty(oldList) && WKReader.isNotEmpty(newList)) || (WKReader.isEmpty(newList) && WKReader.isNotEmpty(oldList)) || (oldList.size() != newList.size())) {
            return true;
        }
        boolean isRefresh = false;
        for (WKMsgReaction reaction : newList) {
            boolean refresh = true;
            for (WKMsgReaction reaction1 : oldList) {
                if (reaction1.messageID.equals(reaction.messageID) && reaction1.emoji.equals(reaction.emoji) && reaction1.isDeleted == reaction.isDeleted) {
                    refresh = false;
                    break;
                }
            }
            if (refresh) {
                isRefresh = true;
                break;
            }
        }
        return isRefresh;
    }

    private void scrollToPosition(int index) {
        linearLayoutManager.scrollToPosition(index);
    }


    private void showRefreshLoading() {
        if (isRefreshLoading || !isCanRefresh) return;
        isRefreshLoading = true;
        WKMsg wkMsg = new WKMsg();
        wkMsg.type = WKContentType.loading;
        int index = 0;
        if (isShowPinnedView) {
            for (int i = 0, size = chatAdapter.getData().size(); i < size; i++) {
                if (chatAdapter.getData().get(i).wkMsg != null && chatAdapter.getData().get(i).wkMsg.type == WKContentType.spanEmptyView) {
                    index = i + 1;
                    break;
                }
            }
        }
        chatAdapter.addData(index, new WKUIChatMsgItemEntity(this, wkMsg, null));
        wkVBinding.recyclerView.scrollToPosition(0);
        lastPreviewMsgOrderSeq = 0;
        new Handler().postDelayed(() -> getData(0, false, 0, false), 300);
    }

    private void showMoreLoading() {
        if (isMoreLoading || !isCanLoadMore) return;
        isMoreLoading = true;
        WKMsg wkMsg = new WKMsg();
        wkMsg.type = WKContentType.loading;
        chatAdapter.addData(new WKUIChatMsgItemEntity(this, wkMsg, null));
        wkVBinding.recyclerView.scrollToPosition(chatAdapter.getItemCount() - 1);
        lastPreviewMsgOrderSeq = 0;
        unreadStartMsgOrderSeq = 0;
        new Handler().postDelayed(() -> getData(1, false, 0, false), 300);
    }

    /**
     * 自动全量同步历史消息 - 使用 getData(0,...) 让 showData 正确处理排序和插入位置
     * 进入聊天页面后自动循环拉取历史消息，直到拉取完所有消息
     */
    private void autoSyncMoreHistory() {
        if (!isAutoSyncingHistory) return;
        if (autoSyncedMsgCount >= MAX_AUTO_SYNC_MSG) {
            isAutoSyncingHistory = false;
            android.util.Log.d("ChatHistoryFix", "autoSyncHistory: reached max limit " + MAX_AUTO_SYNC_MSG + ", stopped");
            return;
        }

        long firstOrderSeq = chatAdapter.getFirstMsgOrderSeq();
        android.util.Log.d("ChatHistoryFix", "autoSyncMoreHistory: firstOrderSeq=" + firstOrderSeq + " total synced=" + autoSyncedMsgCount);

        if (firstOrderSeq <= 1) {
            isAutoSyncingHistory = false;
            android.util.Log.d("ChatHistoryFix", "autoSyncHistory: reached earliest message (orderSeq=" + firstOrderSeq + "), completed! total=" + autoSyncedMsgCount);
            return;
        }

        // 使用 getData(0, false, 0, false) 加载更早的历史消息
        // getData 会自动用 chatAdapter.getFirstMsgOrderSeq() 作为起点
        // showData 会正确排序并插入到列表顶部
        isRefreshLoading = true;
        lastPreviewMsgOrderSeq = 0;
        unreadStartMsgOrderSeq = 0;
        getData(0, false, 0, false);
    }

    private View pinnedBannerView;
    private WKMsg currentPinnedMsg;

    private void initPinnedMessageBanner() {
        pinnedBannerView = getLayoutInflater().inflate(R.layout.message_pin_layout, wkVBinding.pinnedLayout, false);
        wkVBinding.pinnedLayout.addView(pinnedBannerView);

        pinnedBannerView.setOnClickListener(v -> {
            if (currentPinnedMsg != null) {
                int position = -1;
                for (int i = 0; i < chatAdapter.getData().size(); i++) {
                    if (chatAdapter.getData().get(i).wkMsg != null &&
                            chatAdapter.getData().get(i).wkMsg.clientMsgNO != null &&
                            chatAdapter.getData().get(i).wkMsg.clientMsgNO.equals(currentPinnedMsg.clientMsgNO)) {
                        position = i;
                        break;
                    }
                }
                if (position >= 0) {
                    wkVBinding.recyclerView.scrollToPosition(position);
                }
            }
        });

        pinnedBannerView.findViewById(R.id.pinCloseIv).setOnClickListener(v -> {
            unpinMessage();
        });
    }

    public void pinMessage(WKMsg msg) {
        pinMessageInternal(msg, false);
    }

    private void pinMessageInternal(WKMsg msg, boolean isRetry) {
        android.util.Log.d("PinDebug", "pinMessageInternal: msgId=" + msg.messageID + " seq=" + msg.messageSeq + " isRetry=" + isRetry);
        MsgModel.getInstance().pinMsg(msg.messageID, msg.channelID, msg.channelType, msg.messageSeq, true, (code, result) -> {
            android.util.Log.d("PinDebug", "pinMsg response: code=" + code + " result=" + result);
            if (code == HttpResponseCode.success) {
                msg.remoteExtra.isPinned = 1;
                currentPinnedMsg = msg;
                showPinnedBanner(msg);
                MsgModel.getInstance().syncExtraMsg(channelId, channelType);
                WKToastUtils.getInstance().showToastNormal("已置顶");
            } else if (!isRetry) {
                MsgModel.getInstance().clearPinnedMsg(msg.channelID, msg.channelType, (code2, result2) -> {
                    if (code2 == HttpResponseCode.success) {
                        for (int i = 0, size = chatAdapter.getData().size(); i < size; i++) {
                            WKUIChatMsgItemEntity item = chatAdapter.getData().get(i);
                            if (item.wkMsg != null && item.wkMsg.remoteExtra != null) {
                                item.wkMsg.remoteExtra.isPinned = 0;
                                item.isPinned = 0;
                            }
                        }
                        new Handler(Looper.getMainLooper()).postDelayed(() -> pinMessageInternal(msg, true), 500);
                    } else {
                        pinMessageLocal(msg);
                    }
                });
            } else {
                pinMessageLocal(msg);
            }
        });
    }

    private void pinMessageLocal(WKMsg msg) {
        String key = String.format("pinned_msg_%s_%s", channelId, channelType);
        WKSharedPreferencesUtil.getInstance().putSPWithUID(key, msg.clientMsgNO);
        msg.remoteExtra.isPinned = 1;
        currentPinnedMsg = msg;
        showPinnedBanner(msg);
        WKToastUtils.getInstance().showToastNormal("已置顶");
    }

    private void showPinnedBanner(WKMsg msg) {
        currentPinnedMsg = msg;
        if (pinnedBannerView == null) return;
        TextView pinTitleTv = pinnedBannerView.findViewById(R.id.pinTitleTv);
        TextView pinContentTv = pinnedBannerView.findViewById(R.id.pinContentTv);
        AppCompatImageView pinImgIv = pinnedBannerView.findViewById(R.id.pinImgIv);

        String content = "";
        if (msg.baseContentMsgModel instanceof com.xinbida.wukongim.msgmodel.WKTextContent) {
            content = ((com.xinbida.wukongim.msgmodel.WKTextContent) msg.baseContentMsgModel).content;
        } else if (msg.baseContentMsgModel instanceof com.xinbida.wukongim.msgmodel.WKImageContent) {
            content = "[图片]";
            pinImgIv.setVisibility(View.VISIBLE);
        } else if (msg.baseContentMsgModel instanceof com.xinbida.wukongim.msgmodel.WKVideoContent) {
            content = "[视频]";
            pinImgIv.setVisibility(View.VISIBLE);
        } else if (msg.baseContentMsgModel instanceof com.xinbida.wukongim.msgmodel.WKVoiceContent) {
            content = "[语音]";
            pinImgIv.setVisibility(View.GONE);
        } else if (msg.baseContentMsgModel instanceof com.chat.uikit.location.WKLocationContent) {
            content = "[位置] " + ((com.chat.uikit.location.WKLocationContent) msg.baseContentMsgModel).title;
            pinImgIv.setVisibility(View.GONE);
        } else {
            if (msg.baseContentMsgModel != null) {
                content = msg.baseContentMsgModel.getDisplayContent();
            }
            pinImgIv.setVisibility(View.GONE);
        }
        pinContentTv.setText(content);

        wkVBinding.pinnedLayout.setVisibility(View.VISIBLE);
        wkVBinding.pinnedLayout.setTranslationY(-AndroidUtilities.dp(48));
        wkVBinding.pinnedLayout.animate().translationY(0).setDuration(200).start();
    }

    private void unpinMessage() {
        if (currentPinnedMsg == null) return;
        WKMsg msg = currentPinnedMsg;
        String key = String.format("pinned_msg_%s_%s", channelId, channelType);
        WKSharedPreferencesUtil.getInstance().putSPWithUID(key, "");
        MsgModel.getInstance().pinMsg(msg.messageID, msg.channelID, msg.channelType, msg.messageSeq, false, (code, result) -> {
            if (code == HttpResponseCode.success) {
                MsgModel.getInstance().syncExtraMsg(channelId, channelType);
            }
            msg.remoteExtra.isPinned = 0;
            currentPinnedMsg = null;
            wkVBinding.pinnedLayout.animate().translationY(-AndroidUtilities.dp(48)).setDuration(200).withEndAction(() -> {
                wkVBinding.pinnedLayout.setVisibility(View.GONE);
                wkVBinding.pinnedLayout.setTranslationY(0);
            }).start();
            WKToastUtils.getInstance().showToastNormal("已取消置顶");
        });
    }

    private void restorePinnedBanner() {
        String key = String.format("pinned_msg_%s_%s", channelId, channelType);
        String pinnedClientMsgNO = WKSharedPreferencesUtil.getInstance().getSPWithUID(key);
        if (!TextUtils.isEmpty(pinnedClientMsgNO)) {
            for (int i = chatAdapter.getData().size() - 1; i >= 0; i--) {
                WKUIChatMsgItemEntity item = chatAdapter.getData().get(i);
                if (item.wkMsg != null && item.wkMsg.clientMsgNO != null && item.wkMsg.clientMsgNO.equals(pinnedClientMsgNO)) {
                    if (item.wkMsg.remoteExtra == null) {
                        item.wkMsg.remoteExtra = new WKMsgExtra();
                    }
                    item.wkMsg.remoteExtra.isPinned = 1;
                    item.isPinned = 1;
                    currentPinnedMsg = item.wkMsg;
                    showPinnedBanner(item.wkMsg);
                    return;
                }
            }
        }
        for (int i = chatAdapter.getData().size() - 1; i >= 0; i--) {
            WKUIChatMsgItemEntity item = chatAdapter.getData().get(i);
            if (item.wkMsg != null && item.wkMsg.remoteExtra != null && item.wkMsg.remoteExtra.isPinned == 1) {
                currentPinnedMsg = item.wkMsg;
                item.isPinned = 1;
                showPinnedBanner(item.wkMsg);
                return;
            }
        }
        currentPinnedMsg = null;
    }

    private List<PopupMenuItem> getGroupApprovePopupItems() {
        PopupMenuItem item = new PopupMenuItem(getString(R.string.clear_all_remind), R.mipmap.msg_seen, () -> {
            List<WKReminder> list = WKIM.getInstance().getReminderManager().getRemindersWithType(channelId, channelType, WKMentionType.WKApplyJoinGroupApprove);
            List<Long> ids = new ArrayList<>();
            for (WKReminder reminder : list) {
                if (reminder.done == 0) {
                    ids.add(reminder.reminderID);
                }
            }
            groupApproveList.clear();
            resetGroupApproveView();
            MsgModel.getInstance().doneReminder(ids);
        });

        List<PopupMenuItem> list = new ArrayList<>();
        list.add(item);
        return list;
    }

    private List<PopupMenuItem> getRemindPopupItems() {
        PopupMenuItem item = new PopupMenuItem(getString(R.string.clear_all_remind), R.mipmap.msg_seen, () -> {
            List<WKReminder> list = WKIM.getInstance().getReminderManager().getRemindersWithType(channelId, channelType, WKMentionType.WKReminderTypeMentionMe);
            List<Long> ids = new ArrayList<>();
            for (WKReminder reminder : list) {
                if (reminder.done == 0) {
                    ids.add(reminder.reminderID);
                }
            }
            reminderList.clear();
            resetRemindView();
            MsgModel.getInstance().doneReminder(ids);
        });

        List<PopupMenuItem> list = new ArrayList<>();
        list.add(item);
        return list;
    }

    private void checkLoginUserInGroupStatus() {
        if (channelType == WKChannelType.GROUP) {
            WKChannelMember member = WKIM.getInstance().getChannelMembersManager().getMember(channelId, channelType, WKConfig.getInstance().getUid());
            hideOrShowRightView(member == null || member.isDeleted == 0);
        }
    }

    private void scrollToEnd() {
        linearLayoutManager.scrollToPosition(chatAdapter.getItemCount() - 1);
    }

    // 显示一条时间消息
    private WKMsg addTimeMsg(long newMsgTime) {
        long lastMsgTime = chatAdapter.getLastTimeMsg();
        WKMsg msg = null;
        if (WKTimeUtils.getInstance().isNeedShowTimeDivider(newMsgTime, lastMsgTime)) {
            int lastIndex = chatAdapter.getData().size() - 1;
            WKUIChatMsgItemEntity uiChatMsgEntity = new WKUIChatMsgItemEntity(this, null, null);
            msg = new WKMsg();
            uiChatMsgEntity.wkMsg = msg;
            uiChatMsgEntity.isChoose = (chatAdapter.getItemCount() > 0 && chatAdapter.getData().get(0).isChoose);
            uiChatMsgEntity.wkMsg.type = WKContentType.msgPromptTime;
            uiChatMsgEntity.wkMsg.content = WKTimeUtils.getInstance().getTimeString(newMsgTime * 1000);
            uiChatMsgEntity.wkMsg.timestamp = newMsgTime;
            chatAdapter.addData(uiChatMsgEntity);
            if (lastIndex >= 0) {
                chatAdapter.notifyBackground(lastIndex);
            }
        }
        return msg;
    }

    private boolean setBackListener() {
        if (!isViewingPicture) {

            if (isMultipleChoiceMode) {
                for (int i = 0, size = chatAdapter.getItemCount(); i < size; i++) {
                    chatAdapter.getItem(i).isChoose = false;
                    chatAdapter.getItem(i).isChecked = false;
                    chatAdapter.notifyItemChanged(i, chatAdapter.getItem(i));
                }
                chatPanelManager.hideMultipleChoice();
                CommonAnim.getInstance().rotateImage(wkVBinding.topLayout.backIv, 180f, 360f, R.mipmap.ic_ab_back);
                hideOrShowRightView(true);
                EndpointManager.getInstance().invoke("chat_page_reset", getChatChannelInfo());
                isMultipleChoiceMode = false;
            } else {
                if (chatPanelManager.isCanBack()) {
                    new Handler(Objects.requireNonNull(Looper.myLooper())).postDelayed(this::finish, 150);
                }
            }
        }
        return false;
    }


    // 定时上报已读消息
    private void startTimer() {
        Observable.interval(0, 3, TimeUnit.SECONDS).subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread()).subscribe(new Observer<>() {
            int syncCounter = 0;
            @Override
            public void onComplete() {
            }

            @Override
            public void onError(@io.reactivex.rxjava3.annotations.NonNull Throwable e) {
            }

            @Override
            public void onSubscribe(@io.reactivex.rxjava3.annotations.NonNull Disposable d) {
                disposable = d;
            }

            @Override
            public void onNext(@io.reactivex.rxjava3.annotations.NonNull Long value) {
                if (WKReader.isNotEmpty(readMsgList) && isUploadReadMsg) {
                    List<com.chat.base.endpoint.entity.ReadedMessageReq> msgIds = new ArrayList<>(readMsgList);
                    EndpointManager.getInstance().invoke("read_msg", new ReadMsgMenu(channelId, channelType, msgIds, 0));
                    readMsgList.clear();
                }
                syncCounter++;
                if (syncCounter >= 5) {
                    syncCounter = 0;
                    MsgModel.getInstance().syncExtraMsg(channelId, channelType);
                }
            }
        });
    }

    private void resetHideChannelAllPinnedMessage() {
        String key = String.format("hide_pin_msg_%s_%s", channelId, channelType);
        hideChannelAllPinnedMessage = WKSharedPreferencesUtil.getInstance().getIntWithUID(key);
    }

    @Override
    public boolean dispatchTouchEvent(MotionEvent ev) {
        if (ev.getAction() == MotionEvent.ACTION_DOWN) {
            EndpointManager.getInstance().invoke("chat_activity_touch", null);
            View recyclerView = findViewById(R.id.recyclerView);
            if (recyclerView != null && recyclerView.getVisibility() == View.VISIBLE) {
                int[] location = new int[2];
                recyclerView.getLocationOnScreen(location);
                float rawX = ev.getRawX();
                float rawY = ev.getRawY();
                boolean inRecyclerView = rawX >= location[0]
                        && rawX <= location[0] + recyclerView.getWidth()
                        && rawY >= location[1]
                        && rawY <= location[1] + recyclerView.getHeight();
                if (inRecyclerView) {
                    if (chatPanelManager != null) {
                        chatPanelManager.resetToolBar();
                    }
                    if (mHelper != null) {
                        mHelper.resetState();
                    } else {
                        View morePanel = findViewById(R.id.more_panel);
                        if (morePanel != null) {
                            morePanel.setVisibility(View.GONE);
                        }
                    }
                    SoftKeyboardUtils.getInstance().hideSoftKeyboard(this);
                }
            }
        }
        return super.dispatchTouchEvent(ev);
    }

    @Override
    public void onConfigurationChanged(@NonNull Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        float density = getResources().getDisplayMetrics().density;
        AndroidUtilities.setDensity(density);
        if (newConfig.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            // 横屏
            AndroidUtilities.isPORTRAIT = false;
            chatAdapter.notifyItemRangeChanged(0, chatAdapter.getItemCount());
        } else if (newConfig.orientation == Configuration.ORIENTATION_PORTRAIT) {
            // 竖屏
            AndroidUtilities.isPORTRAIT = true;
            chatAdapter.notifyItemRangeChanged(0, chatAdapter.getItemCount());
        }
    }

    @Override
    public void sendMessage(WKMessageContent messageContent) {

        if (messageContent.type == WKContentType.WK_TEXT && editMsg != null) {
            JSONObject jsonObject = messageContent.encodeMsg();
            if (jsonObject == null) jsonObject = new JSONObject();
            try {
                jsonObject.put("type", messageContent.type);
            } catch (JSONException e) {
                Log.e("消息类型错误", "-->");
            }
            boolean isUpdate = isUpdate(messageContent);
            if (isUpdate) {
                WKIM.getInstance().getMsgManager().updateMsgEdit(editMsg.messageID, channelId, channelType, jsonObject.toString());
            }
            deleteOperationMsg();
            return;
        }
        if (messageContent.type == WKContentType.WK_TEXT && replyWKMsg != null) {
            WKReply wkReply = new WKReply();
            if (replyWKMsg.remoteExtra != null && replyWKMsg.remoteExtra.contentEditMsgModel != null) {
                wkReply.payload = replyWKMsg.remoteExtra.contentEditMsgModel;
            } else {
                wkReply.payload = replyWKMsg.baseContentMsgModel;
            }
            String showName = "";
            if (replyWKMsg.getFrom() != null) {
                showName = replyWKMsg.getFrom().channelName;
            } else {
                WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(replyWKMsg.fromUID, WKChannelType.PERSONAL);
                if (channel != null) showName = channel.channelName;
            }
            wkReply.from_name = showName;
            wkReply.from_uid = replyWKMsg.fromUID;
            wkReply.message_id = replyWKMsg.messageID;
            wkReply.message_seq = replyWKMsg.messageSeq;
            if (replyWKMsg.baseContentMsgModel.reply != null && !TextUtils.isEmpty(replyWKMsg.baseContentMsgModel.reply.root_mid)) {
                wkReply.root_mid = replyWKMsg.baseContentMsgModel.reply.root_mid;
            } else {
                wkReply.root_mid = wkReply.message_id;
            }
            messageContent.reply = wkReply;
        }
        sendMsg(messageContent);
        replyWKMsg = null;

    }

    private void sendMsg(WKMessageContent messageContent) {
        if (redDot > 0) {
            wkVBinding.chatUnreadLayout.newMsgLayout.performClick();
        }
        WKMsg wkMsg = new WKMsg();
        wkMsg.channelID = channelId;
        wkMsg.channelType = channelType;
        wkMsg.type = messageContent.type;
        wkMsg.baseContentMsgModel = messageContent;
        WKChannel channel = getChatChannelInfo();
        wkMsg.setChannelInfo(channel);
        WKSendMsgUtils.getInstance().sendMessage(wkMsg);
    }

    private boolean isUpdate(WKMessageContent messageContent) {
        boolean isUpdate = false;
        if (editMsg.remoteExtra != null && editMsg.remoteExtra.contentEditMsgModel != null) {
            if (!editMsg.remoteExtra.contentEditMsgModel.getDisplayContent().equals(messageContent.getDisplayContent())) {
                isUpdate = true;
            }
        }
        if (!editMsg.baseContentMsgModel.getDisplayContent().equals(messageContent.getDisplayContent())) {
            isUpdate = true;
        }
        return isUpdate;
    }

    private void setOnlineView(WKChannel channel) {
        if (channel.online == 1) {
            String device = getString(R.string.phone);
            if (channel.deviceFlag == UserOnlineStatus.Web) device = getString(R.string.web);
            else if (channel.deviceFlag == UserOnlineStatus.PC) device = getString(R.string.pc);
            String content = String.format("%s%s", device, getString(R.string.online));
            wkVBinding.topLayout.subtitleTv.setText(content);
            wkVBinding.topLayout.subtitleView.setVisibility(View.VISIBLE);
        } else {
            if (channel.lastOffline > 0) {
                String showTime = WKTimeUtils.getInstance().getOnlineTime(channel.lastOffline);
                if (TextUtils.isEmpty(showTime)) {
                    wkVBinding.topLayout.subtitleView.setVisibility(View.VISIBLE);
                    String time = WKTimeUtils.getInstance().getShowDateAndMinute(channel.lastOffline * 1000L);
                    String content = String.format("%s%s", getString(R.string.last_seen_time), time);
                    wkVBinding.topLayout.subtitleTv.setText(content);
                } else {
                    wkVBinding.topLayout.subtitleTv.setText(showTime);
                    wkVBinding.topLayout.subtitleView.setVisibility(View.VISIBLE);
                }
            } else wkVBinding.topLayout.subtitleView.setVisibility(View.GONE);
        }
    }

    @Override
    public WKChannel getChatChannelInfo() {
        WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(channelId, channelType);
        if (channel == null) {
            channel = new WKChannel(channelId, channelType);
        }
        return channel;
    }

    @Override
    public void showMultipleChoice() {
        chatPanelManager.showMultipleChoice();
        CommonAnim.getInstance().rotateImage(wkVBinding.topLayout.backIv, 180f, 360f, R.mipmap.ic_close_white);
        isMultipleChoiceMode = true;
        EndpointManager.getInstance().invoke("hide_pinned_view", null);
    }

    @Override
    public void setTitleRightText(String text) {
        int num = Integer.parseInt(text);
        chatPanelManager.updateForwardView(num);
    }

    @Override
    public void showReply(WKMsg wkMsg) {
        this.editMsg = null;
        boolean showDialog = false;
        WKChannelMember mChannelMember = WKIM.getInstance().getChannelMembersManager().getMember(channelId, channelType, WKConfig.getInstance().getUid());
        WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(channelId, channelType);
        if (channel != null && mChannelMember != null) {
            if ((WKChannelUtils.getInstance().isGroupForbidden(channel) && mChannelMember.role == WKChannelMemberRole.normal) || mChannelMember.forbiddenExpirationTime > 0) {
                //普通成员
                showDialog = true;
            }
        }

        if (showDialog) {
            WKDialogUtils.getInstance().showSingleBtnDialog(this, "", getString(R.string.cannot_reply_msg), "", null);
            return;
        }

        if (channelType == WKChannelType.GROUP && !wkMsg.fromUID.equals(WKConfig.getInstance().getUid())) {
            WKChannelMember member = WKIM.getInstance().getChannelMembersManager().getMember(channelId, channelType, wkMsg.fromUID);
            if (member != null) {
                chatPanelManager.addSpan(member.memberName, member.memberUID);
            } else {
                WKChannel mChannel = WKIM.getInstance().getChannelManager().getChannel(wkMsg.fromUID, WKChannelType.PERSONAL);
                if (mChannel != null) {
                    chatPanelManager.addSpan(mChannel.channelName, mChannel.channelID);
                }
            }
//            WKVBinding.toolbarView.editText.addAtSpan("@", member.memberName, member.memberUID);
        }
        this.replyWKMsg = wkMsg;
        if (replyWKMsg != null) {
            chatPanelManager.showReplyLayout(replyWKMsg);
        }

    }

    @Override
    public void showEdit(WKMsg wkMsg) {
        boolean showDialog = false;
        WKChannelMember mChannelMember = WKIM.getInstance().getChannelMembersManager().getMember(channelId, channelType, WKConfig.getInstance().getUid());
        WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(channelId, channelType);
        if (channel != null && mChannelMember != null) {
            if ((WKChannelUtils.getInstance().isGroupForbidden(channel) && mChannelMember.role == WKChannelMemberRole.normal) || mChannelMember.forbiddenExpirationTime > 0) {
                //普通成员
                showDialog = true;
            }
        }

        if (showDialog) {
            WKDialogUtils.getInstance().showSingleBtnDialog(this, "", getString(R.string.cannot_edit_msg), "", null);
            return;
        }
        this.replyWKMsg = null;
        if (wkMsg != null) {
            this.editMsg = wkMsg;
            chatPanelManager.showEditLayout(wkMsg);
        }

    }

    @Override
    public void tipsMsg(String clientMsgNo) {

        isTipMessage = true;
        int index = -1;
        for (int i = 0, size = chatAdapter.getData().size(); i < size; i++) {
            if (chatAdapter.getData().get(i).wkMsg != null && chatAdapter.getData().get(i).wkMsg.clientMsgNO.equals(clientMsgNo)) {
                chatAdapter.getData().get(i).isShowTips = true;
                index = i;
                break;
            }
        }
        if (index != -1) {
            int lastItemPosition = linearLayoutManager.findLastVisibleItemPosition();
            int firstItemPosition = linearLayoutManager.findFirstVisibleItemPosition();
            if (index < firstItemPosition || index > lastItemPosition) {
                linearLayoutManager.scrollToPositionWithOffset(index, AndroidUtilities.dp(70));
            }
            chatAdapter.notifyItemChanged(index);
        } else {
            WKMsg msg = WKIM.getInstance().getMsgManager().getWithClientMsgNO(clientMsgNo);
            if (msg != null && msg.isDeleted == 0) {
                unreadStartMsgOrderSeq = 0;
                tipsOrderSeq = msg.orderSeq;
                // keepMessageSeq = msg.orderSeq;
                getData(0, true, msg.orderSeq, true);
                isCanLoadMore = true;
            } else {
                showToast(R.string.cannot_tips_msg);
            }
        }

    }

    @Override
    public void setEditContent(String content) {

        int curPosition = chatPanelManager.getEditText().getSelectionStart();
        StringBuilder sb = new StringBuilder(Objects.requireNonNull(chatPanelManager.getEditText().getText()).toString());
        sb.insert(curPosition, content);
        chatPanelManager.getEditText().setText(MoonUtil.getEmotionContent(this, chatPanelManager.getEditText(), sb.toString()));
        // 将光标设置到新增完表情的右侧
        chatPanelManager.getEditText().setSelection(curPosition + content.length());

    }

    @Override
    public AppCompatActivity getChatActivity() {
        return this;
    }

    @Override
    public WKMsg getReplyMsg() {
        return replyWKMsg;
    }

    @Override
    public void hideSoftKeyboard() {
        if (chatPanelManager != null) {
            chatPanelManager.resetToolBar();
        }
        if (mHelper != null) {
            mHelper.resetState();
        } else {
            View morePanel = findViewById(R.id.more_panel);
            if (morePanel != null) {
                morePanel.setVisibility(View.GONE);
            }
        }
        SoftKeyboardUtils.getInstance().hideSoftKeyboard(this);
    }

    @Override
    public ChatAdapter getChatAdapter() {
        return chatAdapter;
    }

    @Override
    public void sendCardMsg() {

        Intent intent = new Intent(this, ChooseContactsActivity.class);
        intent.putExtra("chooseBack", true);
        intent.putExtra("singleChoose", true);
        if (channelType == WKChannelType.PERSONAL) {
            intent.putExtra("unVisibleUIDs", channelId);
        }
        chooseCardResultLac.launch(intent);
    }

    @Override
    public void chatRecyclerViewScrollToEnd() {
        if (isToEnd) {
            scrollToEnd();
        }

    }

    @Override
    public void deleteOperationMsg() {

        this.replyWKMsg = null;
        this.editMsg = null;
    }

    @Override
    public void onChatAvatarClick(String uid, boolean isLongClick) {
        chatPanelManager.chatAvatarClick(uid, isLongClick);
    }

    @Override
    public void onViewPicture(boolean isViewing) {
        isViewingPicture = isViewing;
    }

    @Override
    public void onMsgViewed(WKMsg wkMsg, int position) {

        if (wkMsg == null) return;
        if (!TextUtils.isEmpty(wkMsg.messageID) && !isTipMessage) {
            EndpointManager.getInstance().invoke("tip_pinned_message", wkMsg.messageID);
        }
        if (wkMsg.flame == 1 && wkMsg.viewed == 0 && wkMsg.type != WKContentType.WK_IMAGE && wkMsg.type != WKContentType.WK_VIDEO && wkMsg.type != WKContentType.WK_VOICE) {

            wkMsg.viewed = 1;
            wkMsg.viewedAt = WKTimeUtils.getInstance().getCurrentMills();
            chatAdapter.updateDeleteTimer(position);
            WKIM.getInstance().getMsgManager().updateViewedAt(1, wkMsg.viewedAt, wkMsg.clientMsgNO);
        }
        if (wkMsg.viewed == 0 && wkMsg.type == WKContentType.WK_TEXT) {
            wkMsg.viewed = 1;
        }

        if (wkMsg.remoteExtra.readed == 0 && !TextUtils.isEmpty(wkMsg.fromUID) && !wkMsg.fromUID.equals(WKConfig.getInstance().getUid())
                && !WKContentType.isSystemMsg(wkMsg.type) && !WKContentType.isLocalMsg(wkMsg.type)
                && wkMsg.type != WKContentType.typing) {
            boolean isAdd = true;
            for (int j = 0, size = readMsgList.size(); j < size; j++) {
                if (readMsgList.get(j).message_id.equals(wkMsg.messageID)) {

                    isAdd = false;
                    break;
                }
            }
            if (isAdd && !TextUtils.isEmpty(wkMsg.messageID)) {
                readMsgList.add(new com.chat.base.endpoint.entity.ReadedMessageReq(
                        wkMsg.messageID, wkMsg.fromUID, wkMsg.messageSeq));
            }
        }
        boolean isResetRemind = false;
        if (WKReader.isNotEmpty(reminderList) && !TextUtils.isEmpty(wkMsg.messageID)) {
            for (int j = 0; j < reminderList.size(); j++) {
                if (reminderList.get(j).messageID.equals(wkMsg.messageID)) {
                    if (reminderList.get(j).done == 0) {
                        reminderIds.add(reminderList.get(j).reminderID);
                    }
                    reminderList.remove(j);
                    j = j - 1;
                    isResetRemind = true;
                }
            }
        }

        boolean isResetGroupApprove = false;
        if (WKReader.isNotEmpty(groupApproveList) && !TextUtils.isEmpty(wkMsg.messageID)) {
            for (int j = 0, size = groupApproveList.size(); j < size; j++) {
                if (groupApproveList.get(j).messageID.equals(wkMsg.messageID) && groupApproveList.get(j).done == 0) {
                    reminderIds.add(groupApproveList.get(j).reminderID);
                    groupApproveList.remove(j);
                    isResetGroupApprove = true;
                    break;
                }
            }
        }

        // 保存最新浏览到的位置
        if (wkMsg.messageSeq > browseTo) {
            browseTo = wkMsg.messageSeq;
        }
        boolean isResetUnread = false;
        if (wkMsg.messageSeq > lastVisibleMsgSeq) {
            lastVisibleMsgSeq = wkMsg.messageSeq;
        }
        if (lastVisibleMsgSeq != 0) {
            long lastVisibleMsgOrderSeq = WKIM.getInstance().getMsgManager().getMessageOrderSeq(lastVisibleMsgSeq, channelId, channelType);
            if (lastVisibleMsgOrderSeq < unreadStartMsgOrderSeq) {
                lastVisibleMsgSeq = (int) WKIM.getInstance().getMsgManager().getReliableMessageSeq(unreadStartMsgOrderSeq);
                lastVisibleMsgSeq = lastVisibleMsgSeq - 1;
            }
        }
        if (redDot > 0) {
            if (lastVisibleMsgSeq != 0) {
                redDot = maxMsgSeq - lastVisibleMsgSeq;
            }
            if (redDot < 0) redDot = 0;
            isResetUnread = true;
            if (isUpdateRedDot) {
                MsgModel.getInstance().clearUnread(channelId, channelType, redDot, (code, msg) -> {
                    if (code == HttpResponseCode.success && redDot == 0) {
                        isUpdateRedDot = false;
                    }
                });
            }
        }
        if (isResetGroupApprove) resetGroupApproveView();
        if (isResetRemind) resetRemindView();
        if (isResetUnread) showUnReadCountView();
    }

    @Override
    public View getRecyclerViewLayout() {
        return wkVBinding.recyclerViewLayout;
    }

    @Override
    public boolean isShowChatActivity() {
        return isShowChatActivity;
    }

    @Override
    public void closeActivity() {
        finish();
    }

    @Override
    public void finish() {
        super.finish();
        SoftKeyboardUtils.getInstance().hideSoftKeyboard(this);
        EndpointManager.getInstance().remove(channelId);
        EndpointManager.getInstance().invoke("stop_screen_shot", this);
        WKIM.getInstance().getMsgManager().removeDeleteMsgListener(channelId);
        WKIM.getInstance().getMsgManager().removeNewMsgListener(channelId);
        WKIM.getInstance().getMsgManager().removeRefreshMsgListener(channelId);
        WKIM.getInstance().getMsgManager().removeSendMsgCallBack(channelId);
        WKIM.getInstance().getChannelManager().removeRefreshChannelInfo(channelId);
        WKIM.getInstance().getChannelMembersManager().removeRefreshChannelMemberInfo(channelId);
        WKIM.getInstance().getChannelMembersManager().removeAddChannelMemberListener(channelId);
        WKIM.getInstance().getChannelMembersManager().removeRemoveChannelMemberListener(channelId);
        WKIM.getInstance().getCMDManager().removeCmdListener(channelId);
        WKIM.getInstance().getMsgManager().removeSendMsgAckListener(channelId);
        WKIM.getInstance().getMsgManager().removeClearMsg(channelId);
        WKIM.getInstance().getRobotManager().removeRefreshRobotMenu(channelId);
        WKIM.getInstance().getReminderManager().removeNewReminderListener(channelId);
        WKIM.getInstance().getConnectionManager().removeOnConnectionStatusListener(channelId);
    }

    @Override
    protected void onDestroy() {
        EndpointManager.getInstance().remove(channelId);
        EndpointManager.getInstance().invoke("stop_screen_shot", this);
        WKIM.getInstance().getMsgManager().removeDeleteMsgListener(channelId);
        WKIM.getInstance().getMsgManager().removeNewMsgListener(channelId);
        WKIM.getInstance().getMsgManager().removeRefreshMsgListener(channelId);
        WKIM.getInstance().getMsgManager().removeSendMsgCallBack(channelId);
        WKIM.getInstance().getChannelManager().removeRefreshChannelInfo(channelId);
        WKIM.getInstance().getChannelMembersManager().removeRefreshChannelMemberInfo(channelId);
        WKIM.getInstance().getChannelMembersManager().removeAddChannelMemberListener(channelId);
        WKIM.getInstance().getChannelMembersManager().removeRemoveChannelMemberListener(channelId);
        WKIM.getInstance().getCMDManager().removeCmdListener(channelId);
        WKIM.getInstance().getMsgManager().removeSendMsgAckListener(channelId);
        WKIM.getInstance().getMsgManager().removeClearMsg(channelId);
        WKIM.getInstance().getRobotManager().removeRefreshRobotMenu(channelId);
        WKIM.getInstance().getReminderManager().removeNewReminderListener(channelId);
        WKIM.getInstance().getConnectionManager().removeOnConnectionStatusListener(channelId);
        super.onDestroy();
        if (chatPanelManager != null) {
            chatPanelManager.onDestroy();
        }
        ActManagerUtils.getInstance().removeActivity(this);
        if (disposable != null) {
            disposable.dispose();
            disposable = null;
        }
        if (WKReader.isNotEmpty(readMsgList)) {
            EndpointManager.getInstance().invoke("read_msg", new ReadMsgMenu(channelId, channelType, new ArrayList<>(readMsgList), 0));
        }
        MsgModel.getInstance().startCheckFlameMsgTimer();
        saveEditContent();

    }

    private void saveEditContent() {
        //停止语音播放
        //AudioPlaybackManager.getInstance().stopAudio();
        int firstItemPosition = linearLayoutManager.findFirstVisibleItemPosition();
        int endItemPosition = linearLayoutManager.findLastVisibleItemPosition();
        long keepMsgSeq = 0;
        int offsetY = 0;
        if (firstItemPosition >= 0 && endItemPosition >= 0
                && endItemPosition != chatAdapter.getData().size() - 1) {
            WKMsg msg = chatAdapter.getFirstVisibleItem(firstItemPosition);
            if (msg != null) {
                keepMsgSeq = msg.messageSeq;
                int index = chatAdapter.getFirstVisibleItemIndex(firstItemPosition);
                View view = linearLayoutManager.findViewByPosition(index);
                if (view != null) {
                    offsetY = view.getTop();
                }
            }
        }
        int unreadCount = wkVBinding.chatUnreadLayout.msgCountTv.getCount();
        MsgModel.getInstance().clearUnread(channelId, channelType, unreadCount, null);
        String content = Objects.requireNonNull(chatPanelManager.getEditText().getText()).toString();
        MsgModel.getInstance().updateCoverExtra(channelId, channelType, browseTo, keepMsgSeq, offsetY, content);
        MsgModel.getInstance().deleteFlameMsg();
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            return setBackListener();
        }
        return super.onKeyDown(keyCode, event);
    }

    @Override
    protected void onStop() {
        super.onStop();
        isShowChatActivity = false;
        WKUIKitApplication.getInstance().chattingChannelID = "";
        WKUIKitApplication.getInstance().chattingChannelType = WKChannelType.PERSONAL;
        isUploadReadMsg = false;
        WKPlayVoiceUtils.getInstance().stopPlay();
        MsgModel.getInstance().doneReminder(reminderIds);
        EndpointManager.getInstance().invoke("stop_screen_shot", this);
    }


    ActivityResultLauncher<Intent> previewNewImgResultLac = registerForActivityResult(new ActivityResultContracts.StartActivityForResult(), result -> {
        if (result.getData() != null && result.getResultCode() == Activity.RESULT_OK) {
            String path = result.getData().getStringExtra("path");
            if (!TextUtils.isEmpty(path)) {
                sendMsg(new WKImageContent(path));
            }
        }
    });
    ActivityResultLauncher<Intent> chooseCardResultLac = registerForActivityResult(new ActivityResultContracts.StartActivityForResult(), result -> {
        if (result.getData() != null && result.getResultCode() == Activity.RESULT_OK) {
            String uid = result.getData().getStringExtra("uid");
            if (!TextUtils.isEmpty(uid)) {
                WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(uid, WKChannelType.PERSONAL);
                WKCardContent WKCardContent = new WKCardContent();
                WKCardContent.name = channel.channelName;
                WKCardContent.uid = channel.channelID;
                if (channel.remoteExtraMap != null && channel.remoteExtraMap.containsKey(WKChannelExtras.vercode))
                    WKCardContent.vercode = (String) channel.remoteExtraMap.get(WKChannelExtras.vercode);
                List<WKMessageContent> messageContentList = new ArrayList<>();
                messageContentList.add(WKCardContent);
                List<WKChannel> list = new ArrayList<>();
                list.add(WKIM.getInstance().getChannelManager().getChannel(channelId, channelType));
                WKUIKitApplication.getInstance().showChatConfirmDialog(ChatActivity.this, list, messageContentList, (list1, messageContentList1) -> sendMsg(WKCardContent));
            }
        }
    });

    private void sendMsgInserted(WKMsg msg) {
        if (msg.channelType == channelType && msg.channelID.equals(channelId) && msg.isDeleted == 0 && (msg.header == null || !msg.header.noPersist)) {
            if (chatAdapter.isExist(msg.clientMsgNO)) {
                return;
            }
            if (msg.orderSeq > maxMsgOrderSeq) {
                maxMsgOrderSeq = msg.orderSeq;
            }
            WKMsg timeMsg = addTimeMsg(msg.timestamp);
            //判断当前会话是否存在正在输入
            int index = chatAdapter.getData().size() - 1;
            if (chatAdapter.lastMsgIsTyping()) index--;
            if (index < 0) index = 0;
            WKUIChatMsgItemEntity itemEntity = WKIMUtils.getInstance().msg2UiMsg(this, msg, count, showNickName, chatAdapter.isShowChooseItem());
            if (timeMsg == null) {
                if (WKReader.isNotEmpty(chatAdapter.getData())) {
                    chatAdapter.getData().get(index).nextMsg = msg;
                    itemEntity.previousMsg = chatAdapter.getData().get(index).wkMsg;
                }
            } else {
                chatAdapter.getData().get(index).nextMsg = timeMsg;
                itemEntity.previousMsg = timeMsg;
            }
            chatAdapter.addData(index + 1, itemEntity);
            int type = chatAdapter.getData().get(index).wkMsg.type;
            if (WKContentType.isLocalMsg(type) || WKContentType.isSystemMsg(type)) {
                chatAdapter.notifyItemChanged(index);
            } else {
                chatAdapter.notifyBackground(index);
            }

            if (isToEnd) {
                scrollToEnd();
            }
            isToEnd = true;
        }
    }

    private void receivedMessages(List<WKMsg> list) {
        if (WKReader.isNotEmpty(list)) {
            boolean needScrollToEnd = false;
            for (WKMsg msg : list) {
                // 命令消息和撤回消息不显示在聊天
                if (msg.type == WKContentType.WK_INSIDE_MSG || msg.type == WKContentType.withdrawSystemInfo || msg.isDeleted == 1 || (msg.header != null && msg.header.noPersist))
                    continue;

                // 收到视频消息立即触发预下载（比等UI渲染更早，用户点击时大概率已下完）
                if (msg.type == WKContentType.WK_VIDEO && msg.baseContentMsgModel instanceof com.xinbida.wukongim.msgmodel.WKVideoContent) {
                    com.xinbida.wukongim.msgmodel.WKVideoContent videoContent = (com.xinbida.wukongim.msgmodel.WKVideoContent) msg.baseContentMsgModel;
                    if (videoContent.url != null && !videoContent.url.isEmpty()) {
                        String fullUrl = WKApiConfig.getShowUrl(videoContent.url);
                        VideoPreDownloader.getInstance().preDownload(fullUrl);
                    }
                }

                if (msg.remoteExtra != null && msg.remoteExtra.readedCount == 0) {
                    msg.remoteExtra.unreadCount = count - 1;
                }

                if (msg.channelID.equals(channelId) && msg.channelType == channelType) {
                    if (!chatAdapter.isExist(msg.clientMsgNO)
                            && !chatAdapter.isExistByMessageId(msg.messageID)) {
                        if (!isCanLoadMore) {
                            //移除正在输入
                            if (chatAdapter.getItemCount() > 0 && chatAdapter.getData().get(chatAdapter.getItemCount() - 1).wkMsg != null && chatAdapter.getData().get(chatAdapter.getItemCount() - 1).wkMsg.type == WKContentType.typing) {
                                chatAdapter.removeAt(chatAdapter.getItemCount() - 1);
                            }
                            WKMsg timeMsg = addTimeMsg(msg.timestamp);
                            WKUIChatMsgItemEntity itemEntity = WKIMUtils.getInstance().msg2UiMsg(this, msg, count, showNickName, chatAdapter.isShowChooseItem());
                            if (timeMsg != null && chatAdapter.getData().size() > 1) {
                                chatAdapter.getData().get(chatAdapter.getData().size() - 2).nextMsg = timeMsg;
                            }
                            int previousMsgIndex = -1;
                            if (timeMsg == null) {
                                if (WKReader.isNotEmpty(chatAdapter.getData())) {
                                    itemEntity.previousMsg = chatAdapter.getData().get(chatAdapter.getData().size() - 1).wkMsg;
                                    chatAdapter.getData().get(chatAdapter.getData().size() - 1).nextMsg = itemEntity.wkMsg;
                                }
                            } else {
                                itemEntity.previousMsg = timeMsg;
                            }
                            if (WKReader.isNotEmpty(chatAdapter.getData())) {
                                previousMsgIndex = chatAdapter.getData().size() - 1;
                            }
                            if (!isShowHistory && redDot == 0 && itemEntity.wkMsg.flame == 1 && itemEntity.wkMsg.type != WKContentType.WK_VOICE && itemEntity.wkMsg.type != WKContentType.WK_IMAGE && itemEntity.wkMsg.type != WKContentType.WK_VIDEO) {
                                itemEntity.wkMsg.viewed = 1;
                                itemEntity.wkMsg.viewedAt = WKTimeUtils.getInstance().getCurrentMills();
                                WKIM.getInstance().getMsgManager().updateViewedAt(1, itemEntity.wkMsg.viewedAt, itemEntity.wkMsg.clientMsgNO);
                            }
                            WKPlaySound.getInstance().playInMsg(R.raw.sound_in);
                            // 判断消息是否需要按顺序插入而非追加到末尾
                            int insertIndex = chatAdapter.getData().size();
                            if (WKReader.isNotEmpty(chatAdapter.getData())) {
                                WKMsg lastMsg = chatAdapter.getLastMsg();
                                if (lastMsg != null && msg.orderSeq > 0 && msg.orderSeq < lastMsg.orderSeq) {
                                    // 消息乱序到达，找到正确插入位置
                                    for (int i = chatAdapter.getData().size() - 1; i >= 0; i--) {
                                        WKMsg curMsg = chatAdapter.getData().get(i).wkMsg;
                                        if (curMsg != null && curMsg.orderSeq > 0
                                                && !WKContentType.isLocalMsg(curMsg.type)
                                                && curMsg.orderSeq < msg.orderSeq) {
                                            insertIndex = i + 1;
                                            break;
                                        }
                                        insertIndex = i;
                                    }
                                    // 插入时间分割线
                                    if (timeMsg != null && insertIndex > 0) {
                                        chatAdapter.getData().get(insertIndex - 1).nextMsg = timeMsg;
                                    }
                                    if (timeMsg == null && insertIndex > 0) {
                                        itemEntity.previousMsg = chatAdapter.getData().get(insertIndex - 1).wkMsg;
                                        chatAdapter.getData().get(insertIndex - 1).nextMsg = itemEntity.wkMsg;
                                    } else {
                                        itemEntity.previousMsg = timeMsg;
                                    }
                                    chatAdapter.addData(insertIndex, itemEntity);
                                } else {
                                    chatAdapter.addData(itemEntity);
                                }
                            } else {
                                chatAdapter.addData(itemEntity);
                            }
                            if (msg.messageSeq > maxMsgSeq) {
                                maxMsgSeq = msg.messageSeq;
                            }
                            if (msg.orderSeq > maxMsgOrderSeq) {
                                maxMsgOrderSeq = msg.orderSeq;
                            }
                            if (previousMsgIndex != -1) {
                                chatAdapter.notifyBackground(previousMsgIndex);
                            }
                        }
                        if (isShowHistory || redDot > 0) {
                            redDot += 1;
                            showUnReadCountView();
                            wkVBinding.chatUnreadLayout.newMsgLayout.post(() -> CommonAnim.getInstance().showOrHide(wkVBinding.chatUnreadLayout.newMsgLayout, redDot > 0, true, false));
                        } else {
                            needScrollToEnd = true;
                            // 放宽已读上报条件：普通消息类型都上报已读，不再依赖 setting.receipt
                            if (!WKContentType.isSystemMsg(msg.type) && !WKContentType.isLocalMsg(msg.type)
                                    && msg.type != WKContentType.typing
                                    && !TextUtils.isEmpty(msg.messageID)) {
                                readMsgList.add(new com.chat.base.endpoint.entity.ReadedMessageReq(
                                        msg.messageID, msg.fromUID, msg.messageSeq));
                            }
                        }
                    }
                }

            }
            // 批量处理完后只滚动一次，避免频繁scrollToEnd导致卡顿
            if (needScrollToEnd) {
                scrollToEnd();
            }
        }
    }

    private synchronized void typing(WKCMD wkCmd) {

        if (redDot > 0) return;
        String channel_id = wkCmd.paramJsonObject.optString("channel_id");
        byte channel_type = (byte) wkCmd.paramJsonObject.optInt("channel_type");
        String from_uid = wkCmd.paramJsonObject.optString("from_uid");
        String from_name = wkCmd.paramJsonObject.optString("from_name");
        int isRobot;
        WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(from_uid, WKChannelType.PERSONAL);
        if (channel == null) {
            channel = new WKChannel(from_uid, WKChannelType.PERSONAL);
            channel.channelName = from_name;
        }
        isRobot = channel.robot;
        if (channelId.equals(channel_id) && channelType == channel_type && !TextUtils.equals(from_uid, WKConfig.getInstance().getUid())) {
            WKChannelMember mChannelMember = null;
            if (channelType == WKChannelType.GROUP && isRobot == 0) {
                // 没在群内的cmd不显示
                mChannelMember = WKIM.getInstance().getChannelMembersManager().getMember(channelId, channelType, from_uid);
                if (mChannelMember == null || mChannelMember.isDeleted == 1) return;
            }
            // 在标题栏显示"对方输入中..."
            showTypingInTitle();
            // 移除之前的隐藏延迟，重新计时（8秒后自动隐藏）
            typingHandler.removeCallbacks(hideTypingRunnable);
            typingHandler.postDelayed(hideTypingRunnable, 8000);
        }
    }

    // 在标题栏显示"对方输入中..."
    private void showTypingInTitle() {
        if (isTypingShowing) return;
        isTypingShowing = true;
        wkVBinding.topLayout.subtitleView.setVisibility(View.VISIBLE);
        wkVBinding.topLayout.subtitleTv.setText("对方输入中...");
        wkVBinding.topLayout.subtitleCountTv.setVisibility(View.GONE);
    }

    // 隐藏标题栏的"对方输入中..."
    private void hideTypingInTitle() {
        if (!isTypingShowing) return;
        isTypingShowing = false;
        // 如果正在显示连接状态，则恢复显示连接状态
        if (isShowingConnectionStatus) {
            showConnectionStatusInTitle();
        } else {
            wkVBinding.topLayout.subtitleView.setVisibility(View.INVISIBLE);
            wkVBinding.topLayout.subtitleTv.setText("");
        }
    }

    // 更新标题栏连接状态显示
    private void updateConnectionStatusInTitle(int status) {
        currentConnectionStatus = status;
        if (status == WKConnectStatus.success || status == WKConnectStatus.syncCompleted) {
            // 连接成功/同步完成，恢复原始副标题
            if (isShowingConnectionStatus) {
                isShowingConnectionStatus = false;
                // 如果"对方输入中"正在显示，则不处理，等输入结束后再恢复
                if (!isTypingShowing) {
                    restoreSubtitle();
                }
            }
        } else if (status == WKConnectStatus.syncMsg) {
            // 同步消息中（收取中）
            saveCurrentSubtitleIfNeeded();
            isShowingConnectionStatus = true;
            if (!isTypingShowing) {
                showConnectionStatusInTitle();
            }
        } else {
            // 其他状态（断开/连接中/被踢等），显示连接状态
            saveCurrentSubtitleIfNeeded();
            isShowingConnectionStatus = true;
            if (!isTypingShowing) {
                showConnectionStatusInTitle();
            }
        }
    }

    // 保存当前副标题内容（仅在未显示连接状态且未显示输入中时保存）
    private void saveCurrentSubtitleIfNeeded() {
        if (!isShowingConnectionStatus && !isTypingShowing) {
            savedSubtitleText = wkVBinding.topLayout.subtitleTv.getText();
            savedSubtitleVisibility = wkVBinding.topLayout.subtitleView.getVisibility();
        }
    }

    // 在标题栏显示连接状态文本
    private void showConnectionStatusInTitle() {
        wkVBinding.topLayout.subtitleView.setVisibility(View.VISIBLE);
        wkVBinding.topLayout.subtitleCountTv.setVisibility(View.GONE);
        if (currentConnectionStatus == WKConnectStatus.syncMsg) {
            wkVBinding.topLayout.subtitleTv.setText("收取中...");
        } else if (currentConnectionStatus == WKConnectStatus.kicked) {
            wkVBinding.topLayout.subtitleTv.setText("已断开");
        } else {
            wkVBinding.topLayout.subtitleTv.setText("连接中...");
        }
    }

    // 恢复原始副标题显示
    private void restoreSubtitle() {
        wkVBinding.topLayout.subtitleTv.setText(savedSubtitleText);
        wkVBinding.topLayout.subtitleView.setVisibility(savedSubtitleVisibility);
        // 如果是群聊且之前显示了在线人数，需要重新获取并显示
        if (channelType == WKChannelType.GROUP) {
            WKChannel channel = getChatChannelInfo();
            if (channel != null && channel.remoteExtraMap != null) {
                Object onlineCountObject = channel.remoteExtraMap.get(WKChannelCustomerExtras.onlineCount);
                if (onlineCountObject instanceof Integer) {
                    int onlineCount = (int) onlineCountObject;
                    if (onlineCount > 0) {
                        wkVBinding.topLayout.subtitleCountTv.setVisibility(View.VISIBLE);
                        wkVBinding.topLayout.subtitleCountTv.setText(String.format(getString(R.string.online_count), onlineCount));
                    }
                }
            }
        }
    }

    private synchronized void refreshMsg(WKMsg wkMsg) {
        // 如果RecyclerView正在计算布局或滚动，延迟到下一帧执行，避免IllegalStateException
        if (wkVBinding.recyclerView.isComputingLayout() || wkVBinding.recyclerView.isLayoutFrozen()) {
            wkVBinding.recyclerView.post(() -> refreshMsg(wkMsg));
            return;
        }
        android.util.Log.d("WKReceiptDebug", "refreshMsg: msgID=" + wkMsg.messageID
                + ", clientMsgNO=" + wkMsg.clientMsgNO
                + ", status=" + wkMsg.status
                + ", setting.receipt=" + (wkMsg.setting != null ? wkMsg.setting.receipt : "null")
                + ", readedCount=" + (wkMsg.remoteExtra != null ? wkMsg.remoteExtra.readedCount : "null")
                + ", readed=" + (wkMsg.remoteExtra != null ? wkMsg.remoteExtra.readed : "null"));
        WKIMUtils.getInstance().resetMsgProhibitWord(wkMsg);
        List<WKUIChatMsgItemEntity> list = chatAdapter.getData();
        chatAdapter.refreshReplyMsg(wkMsg);
        for (int i = 0, size = list.size(); i < size; i++) {
            if (list.get(i).wkMsg == null) {
                continue;
            }
            boolean isNotify = false;
            if (list.get(i).wkMsg.clientSeq == wkMsg.clientSeq
                    || list.get(i).wkMsg.clientMsgNO.equals(wkMsg.clientMsgNO)
                    || (!TextUtils.isEmpty(list.get(i).wkMsg.messageID) && !TextUtils.isEmpty(wkMsg.messageID) && list.get(i).wkMsg.messageID.equals(wkMsg.messageID))) {
                if (wkMsg.messageSeq > maxMsgSeq) {
                    maxMsgSeq = wkMsg.messageSeq;
                }
                if (wkMsg.messageSeq > lastVisibleMsgSeq) {
                    lastVisibleMsgSeq = wkMsg.messageSeq;
                }
                if (list.get(i).wkMsg.remoteExtra.revoke != wkMsg.remoteExtra.revoke) {
                    isNotify = true;
                }
                // 消息撤回
                list.get(i).wkMsg.remoteExtra.revoke = wkMsg.remoteExtra.revoke;
                list.get(i).wkMsg.remoteExtra.revoker = wkMsg.remoteExtra.revoker;
                if (list.get(i).wkMsg.status != WKSendMsgResult.send_success && wkMsg.status == WKSendMsgResult.send_success) {
                    WKPlaySound.getInstance().playOutMsg(R.raw.sound_out);
                }
                boolean isResetStatus = false;
                boolean isResetData = false;
                boolean isResetReaction = false;
                if (list.get(i).wkMsg.status != wkMsg.status
                        || list.get(i).wkMsg.remoteExtra.readedCount != wkMsg.remoteExtra.readedCount
                        || list.get(i).wkMsg.remoteExtra.editedAt != wkMsg.remoteExtra.editedAt
                ) {
                    list.get(i).isUpdateStatus = true;
                    isResetStatus = true;
                }
                if (list.get(i).wkMsg.remoteExtra.isPinned != wkMsg.remoteExtra.isPinned) {
                    isResetStatus = true;
                }
                list.get(i).wkMsg.voiceStatus = wkMsg.voiceStatus;
                if (hideChannelAllPinnedMessage == 0) {
                    list.get(i).isPinned = wkMsg.remoteExtra.isPinned;
                } else {
                    list.get(i).isPinned = 0;
                }
                list.get(i).wkMsg.remoteExtra.isPinned = wkMsg.remoteExtra.isPinned;
                String localPinKey = String.format("pinned_msg_%s_%s", channelId, channelType);
                String localPinnedMsgNO = WKSharedPreferencesUtil.getInstance().getSPWithUID(localPinKey);
                if (!TextUtils.isEmpty(localPinnedMsgNO)
                        && list.get(i).wkMsg.clientMsgNO != null
                        && list.get(i).wkMsg.clientMsgNO.equals(localPinnedMsgNO)) {
                    list.get(i).wkMsg.remoteExtra.isPinned = 1;
                    list.get(i).isPinned = 1;
                }
                list.get(i).wkMsg.remoteExtra.readed = wkMsg.remoteExtra.readed;
                list.get(i).wkMsg.remoteExtra.readedCount = wkMsg.remoteExtra.readedCount;
                list.get(i).wkMsg.remoteExtra.needUpload = wkMsg.remoteExtra.needUpload;
                if (list.get(i).wkMsg.remoteExtra.readedCount == 0) {
                    list.get(i).wkMsg.remoteExtra.unreadCount = count - 1;
                } else
                    list.get(i).wkMsg.remoteExtra.unreadCount = wkMsg.remoteExtra.unreadCount;
                if ((TextUtils.isEmpty(list.get(i).wkMsg.remoteExtra.contentEdit) && !TextUtils.isEmpty(wkMsg.remoteExtra.contentEdit)) || (!TextUtils.isEmpty(list.get(i).wkMsg.remoteExtra.contentEdit) && !TextUtils.isEmpty(wkMsg.remoteExtra.contentEdit) && !list.get(i).wkMsg.remoteExtra.contentEdit.equals(wkMsg.remoteExtra.contentEdit))) {
                    list.get(i).wkMsg.remoteExtra.editedAt = wkMsg.remoteExtra.editedAt;
                    list.get(i).wkMsg.remoteExtra.contentEdit = wkMsg.remoteExtra.contentEdit;
                    list.get(i).wkMsg.remoteExtra.contentEditMsgModel = wkMsg.remoteExtra.contentEditMsgModel;
                    list.get(i).isUpdateStatus = true;
                    list.get(i).formatSpans(ChatActivity.this, chatAdapter.getData().get(i).wkMsg);
                    isResetData = true;
                }

                list.get(i).wkMsg.isDeleted = wkMsg.isDeleted;
                list.get(i).wkMsg.messageID = wkMsg.messageID;
                list.get(i).wkMsg.messageSeq = wkMsg.messageSeq;
                list.get(i).wkMsg.orderSeq = wkMsg.orderSeq;
                if ((wkMsg.localExtraMap != null && !wkMsg.localExtraMap.isEmpty())) {
                    isNotify = true;
                }
                if (isRefreshReaction(list.get(i).wkMsg.reactionList, wkMsg.reactionList)) {
                    isResetReaction = true;
                }
                list.get(i).wkMsg.localExtraMap = wkMsg.localExtraMap;
                list.get(i).wkMsg.content = wkMsg.content;
                list.get(i).wkMsg.reactionList = wkMsg.reactionList;
                list.get(i).wkMsg.baseContentMsgModel = wkMsg.baseContentMsgModel;
                list.get(i).wkMsg.status = wkMsg.status;
                if (isNotify) {
                    EndpointManager.getInstance().invoke("stop_reaction_animation", null);
                    chatAdapter.notifyItemChanged(i);
                } else {
                    if (isResetStatus) {
                        chatAdapter.notifyStatus(i);
                    }
                    if (isResetData) {
                        chatAdapter.notifyData(i);
                    }
                    if (isResetReaction) {
                        list.get(i).isRefreshReaction = true;
                        chatAdapter.notifyItemChanged(i, list.get(i));
                        //chatAdapter.notifyReaction(i, wkMsg.reactionList);
                    }
                }

                if (list.get(i).wkMsg.remoteExtra.revoke == 1) {
                    int finalI = i;
                    new Handler(Looper.getMainLooper()).postDelayed(() -> {
                        int curSize = list.size();
                        int previousIndex = finalI - 1;
                        int nextIndex = finalI + 1;
                        if (previousIndex >= 0 && previousIndex < curSize && list.get(previousIndex).wkMsg.remoteExtra.revoke == 0) {
                            chatAdapter.notifyItemChanged(previousIndex);
                        }
                        if (nextIndex < curSize && list.get(nextIndex).wkMsg.remoteExtra.revoke == 0) {
                            chatAdapter.notifyItemChanged(nextIndex);
                        }
                    }, 200);
                }

                if ((wkMsg.status == WKSendMsgResult.no_relation || wkMsg.status == WKSendMsgResult.not_on_white_list) && channelType == WKChannelType.PERSONAL) {
                    if (UserUtils.getInstance().checkBlacklist(channelId)) {
                        return;
                    }
                    // 不是好友
                    WKMsg noRelationMsg = new WKMsg();
                    noRelationMsg.channelID = channelId;
                    noRelationMsg.channelType = channelType;
                    noRelationMsg.type = WKContentType.noRelation;
                    long tempOrderSeq = WKIM.getInstance().getMsgManager().getMessageOrderSeq(0, wkMsg.channelID, wkMsg.channelType);
                    noRelationMsg.orderSeq = tempOrderSeq + 1;
                    noRelationMsg.status = WKSendMsgResult.send_success;

                    int index = chatAdapter.getData().size() - 1;
                    if (chatAdapter.lastMsgIsTyping()) index--;
                    WKUIChatMsgItemEntity itemEntity = WKIMUtils.getInstance().msg2UiMsg(this, noRelationMsg, count, showNickName, chatAdapter.isShowChooseItem());
                    chatAdapter.getData().get(index).nextMsg = noRelationMsg;
                    itemEntity.previousMsg = chatAdapter.getData().get(index).wkMsg;

                    chatAdapter.notifyItemChanged(index);
                    chatAdapter.addData(index + 1, itemEntity);
                    if (isToEnd) {
                        scrollToEnd();
                    }
                    WKIM.getInstance().getMsgManager().saveAndUpdateConversationMsg(noRelationMsg, false);
                }
                break;
            }
        }
    }
}
