package com.chat.uikit;

import static android.content.Intent.FLAG_ACTIVITY_NEW_TASK;

import android.Manifest;
import android.app.Activity;
import android.app.Application;
import android.app.Dialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Build;
import android.provider.MediaStore;
import android.os.Parcelable;
import android.text.TextUtils;
import android.util.Log;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.alibaba.fastjson.JSON;
import com.chat.base.WKBaseApplication;
import com.chat.base.config.WKApiConfig;
import com.chat.base.config.WKBinder;
import com.chat.base.config.WKConfig;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.config.WKSystemAccount;
import com.chat.base.endpoint.EndpointCategory;
import com.chat.base.endpoint.EndpointManager;
import com.chat.base.endpoint.EndpointSID;
import com.chat.base.endpoint.entity.ChatChooseContacts;
import com.chat.base.endpoint.entity.ChatFunctionMenu;
import com.chat.base.endpoint.entity.ChatSettingCellMenu;
import com.chat.base.endpoint.entity.RTCMenu;
import com.chat.base.trtc.TRTCManager;
import com.chat.base.trtc.TRTCType;
import com.chat.base.endpoint.entity.ChatItemPopupMenu;
import com.chat.base.endpoint.entity.ChatToolBarMenu;
import com.chat.base.endpoint.entity.ChatViewMenu;
import com.chat.base.endpoint.entity.ChooseChatMenu;
import com.chat.base.endpoint.entity.ChooseContactsMenu;
import com.chat.base.endpoint.entity.ChooseLabelEntity;
import com.chat.base.endpoint.entity.ChooseLabelMenu;
import com.chat.base.endpoint.entity.ContactsMenu;
import com.chat.base.endpoint.entity.DBMenu;
import com.chat.base.endpoint.entity.EditImgMenu;
import com.chat.base.endpoint.entity.LoginMenu;
import com.chat.base.endpoint.entity.MsgConfig;
import com.chat.base.endpoint.entity.PersonalInfoMenu;
import com.chat.base.endpoint.entity.ScanResultMenu;
import com.chat.scan.WKScanActivity;
import com.chat.base.endpoint.entity.SaveLabelMenu;
import com.chat.base.endpoint.entity.SetChatBgMenu;
import com.chat.base.endpoint.entity.UserDetailMenu;
import com.chat.base.endpoint.entity.WKMsg2UiMsgMenu;
import com.chat.base.endpoint.entity.WithdrawMsgMenu;
import com.chat.base.common.WKCommonModel;
import com.chat.base.entity.ChannelInfoEntity;
import com.chat.base.entity.PopupMenuItem;
import com.chat.base.entity.UserInfoEntity;
import com.chat.base.glide.ChooseMimeType;
import com.chat.base.glide.ChooseResult;
import com.chat.base.glide.ChooseResultModel;
import com.chat.base.glide.GlideUtils;
import com.chat.base.msg.IConversationContext;
import com.chat.base.msg.model.WKGifContent;
import com.chat.base.msgitem.WKContentType;
import com.chat.base.msgitem.WKMsgItemViewManager;
import com.chat.base.msgitem.WKRTCType;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.net.ICommonListener;
import com.chat.base.ui.components.AlertDialog;
import com.chat.base.ui.components.AvatarView;
import com.chat.base.ui.components.SwitchView;
import com.chat.base.views.expandablelayout.ExpandableLayout;
import com.chat.base.utils.ActManagerUtils;
import com.chat.base.utils.ImageUtils;
import com.chat.base.utils.LayoutHelper;
import com.chat.base.utils.WKDeviceUtils;
import com.chat.base.utils.WKFileUtils;
import com.chat.base.utils.WKMediaFileUtils;
import com.chat.base.utils.WKPermissions;
import com.chat.base.utils.WKReader;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.WKTimeUtils;
import com.chat.uikit.chat.ChatActivity;
import com.chat.uikit.chat.ChooseChatActivity;
import com.chat.uikit.chat.face.WKVoiceViewManager;
import com.chat.uikit.chat.manager.FaceManger;
import com.chat.uikit.chat.manager.WKIMUtils;
import com.chat.uikit.chat.msgmodel.WKCardContent;
import com.chat.uikit.chat.msgmodel.WKMultiForwardContent;
import com.chat.uikit.chat.provider.LoadingProvider;
import com.chat.uikit.chat.provider.WKCardProvider;
import com.chat.uikit.chat.provider.WKCallProvider;
import com.chat.uikit.chat.provider.WKEmptyProvider;
import com.chat.uikit.chat.provider.WKGifProvider;
import com.chat.uikit.chat.provider.WKImageProvider;
import com.chat.uikit.chat.provider.WKLocationProvider;
import com.chat.uikit.chat.provider.WKMultiForwardProvider;
import com.chat.uikit.chat.provider.WKNoRelationProvider;
import com.chat.uikit.chat.provider.WKVideoProvider;
import com.chat.uikit.chat.provider.WKPromptNewMsgProvider;
import com.chat.uikit.chat.provider.WKSensitiveWordsProvider;
import com.chat.uikit.chat.provider.WKSpanEmptyProvider;
import com.chat.uikit.chat.provider.WKTextProvider;
import com.chat.uikit.chat.provider.WKVoiceProvider;
import com.chat.uikit.contacts.ChooseContactsActivity;
import com.chat.uikit.contacts.NewFriendsActivity;
import com.chat.uikit.enity.SensitiveWords;
import com.chat.uikit.contacts.service.FriendModel;
import com.chat.uikit.group.service.GroupModel;
import com.chat.uikit.label.ChooseLabelActivity;
import com.chat.uikit.label.LabelActivity;
import com.chat.uikit.label.LabelDetailActivity;
import com.chat.uikit.label.LabelManager;
import com.chat.uikit.group.SavedGroupsActivity;
import com.chat.uikit.message.MsgModel;
import com.chat.uikit.message.ProhibitWordModel;
import com.chat.uikit.search.AddFriendsActivity;
import com.chat.uikit.setting.MsgNoticesSettingActivity;
import com.chat.uikit.setting.SettingActivity;
import com.chat.uikit.user.UserDetailActivity;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannel;
import com.xinbida.wukongim.entity.WKChannelType;
import com.xinbida.wukongim.entity.WKMsg;
import com.xinbida.wukongim.entity.WKChannelMember;
import com.chat.base.msgitem.WKChannelMemberRole;
import com.xinbida.wukongim.msgmodel.WKImageContent;
import com.xinbida.wukongim.msgmodel.WKMessageContent;
import com.xinbida.wukongim.msgmodel.WKTextContent;
import com.xinbida.wukongim.msgmodel.WKVideoContent;

import org.json.JSONObject;

import java.io.File;
import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

/**
 * 2020-03-01 17:32
 * ui kit
 */
public class WKUIKitApplication {
    private int totalMsgCount = 0;

    public int getTotalMsgCount() {
        return totalMsgCount;
    }

    public void setTotalMsgCount(int count) {
        this.totalMsgCount = count;
    }
    public String chattingChannelID;
    public byte chattingChannelType;
    public SensitiveWords sensitiveWords;
    public boolean isRefreshChatActivityMessage = false;
    private boolean isIMInited = false;
    private boolean isListenersRegistered = false;

    private WKUIKitApplication() {
    }

    private static class KitApplicationBinder {
        private static final WKUIKitApplication uikit = new WKUIKitApplication();
    }

    public static WKUIKitApplication getInstance() {
        return KitApplicationBinder.uikit;
    }

    private WeakReference<Application> mContext;

    public void init(Application mContext) {
        this.mContext = new WeakReference<>(mContext);
        try { initIM(); } catch (Throwable e) { Log.e("WKUIKitApplication", "initIM error: " + e.getMessage(), e); }
        try { WKIMUtils.getInstance().initIMListener(); } catch (Throwable e) { Log.e("WKUIKitApplication", "initIMListener error: " + e.getMessage(), e); }
        try { initKitModuleListener(); } catch (Throwable e) { Log.e("WKUIKitApplication", "initKitModuleListener error: " + e.getMessage(), e); }
        if (isIMInited) {
            isListenersRegistered = true;
            // 初始化成功后立即建立连接，确保消息能及时接收
            try { startChat(); } catch (Throwable e) { Log.e("WKUIKitApplication", "startChat error: " + e.getMessage(), e); }
        }
        try {
            String json = WKSharedPreferencesUtil.getInstance().getSP("wk_sensitive_words");
            if (!TextUtils.isEmpty(json)) {
                sensitiveWords = JSON.parseObject(json, SensitiveWords.class);
            }
        } catch (Throwable e) { Log.e("WKUIKitApplication", "parse sensitive words error: " + e.getMessage(), e); }
        try { MsgModel.getInstance().syncSensitiveWords(); } catch (Throwable e) { Log.e("WKUIKitApplication", "syncSensitiveWords error: " + e.getMessage(), e); }
        try { ProhibitWordModel.Companion.getInstance().sync(); } catch (Throwable e) { Log.e("WKUIKitApplication", "sync prohibit words error: " + e.getMessage(), e); }
        try { MsgModel.getInstance().deleteFlameMsg(); } catch (Throwable e) { Log.e("WKUIKitApplication", "deleteFlameMsg error: " + e.getMessage(), e); }
    }

    public Context getContext() {
        Context ctx = mContext != null ? mContext.get() : null;
        if (ctx == null) {
            ctx = WKBaseApplication.getInstance().getContext();
        }
        return ctx;
    }


    public boolean isIMInited() {
        return isIMInited;
    }

    public void initIM() {
        if (!TextUtils.isEmpty(WKConfig.getInstance().getToken())) {
            String imToken = WKConfig.getInstance().getImToken();
            String uid = WKConfig.getInstance().getUid();
            if (TextUtils.isEmpty(uid) || TextUtils.isEmpty(imToken)) {
                Log.e("WKUIKitApplication", "initIM skip: uid or imToken empty. uid=" + uid + " hasImToken=" + !TextUtils.isEmpty(imToken));
                return;
            }
            if (mContext == null || mContext.get() == null) {
                Log.e("WKUIKitApplication", "initIM skip: context is null");
                return;
            }
            try {
                WKIM.getInstance().setDebug(WKBinder.isDebug);
                WKIM.getInstance().setFileCacheDir("wkIMFile");
                WKIM.getInstance().init(mContext.get(), uid, imToken);
                isIMInited = true;
                Log.e("WKUIKitApplication", "initIM success uid=" + uid);
            } catch (Throwable e) {
                Log.e("WKUIKitApplication", "initIM Throwable: " + e.getMessage(), e);
                isIMInited = false;
            }
        }
    }

    public void startChat() {
        if (!TextUtils.isEmpty(WKConfig.getInstance().getToken()) && isIMInited) {
            try {
                WKIM.getInstance().getConnectionManager().connection();
            } catch (Throwable e) {
                Log.e("WKUIKitApplication", "startChat Throwable: " + e.getMessage(), e);
            }
        }
    }

    public void stopConn() {
        try {
            EndpointManager.getInstance().invoke("push_update_device_badge", totalMsgCount);
            if (isIMInited) {
                WKIM.getInstance().getConnectionManager().disconnect(false);
            }
        } catch (Throwable e) {
            Log.e("WKUIKitApplication", "stopConn error: " + e.getMessage(), e);
        }
    }

    public void registerContentTypes() {
        try {
            WKIM.getInstance().getMsgManager().registerContentMsg(WKCardContent.class);
            WKIM.getInstance().getMsgManager().registerContentMsg(WKMultiForwardContent.class);
            WKIM.getInstance().getMsgManager().registerContentMsg(com.chat.uikit.location.WKLocationContent.class);
            WKIM.getInstance().getMsgManager().registerContentMsg(com.chat.base.msg.model.WKGifContent.class);
            WKIM.getInstance().getMsgManager().registerContentMsg(com.chat.richeditor.msg.RichTextContent.class);
            WKIM.getInstance().getMsgManager().registerContentMsg(com.chat.uikit.chat.msgmodel.WKFileContent.class);
            // 注册 RTC 通话相关消息类型
            WKIM.getInstance().getMsgManager().registerContentMsg(com.chat.uikit.trtc.RTCSignalContent.class);
            WKIM.getInstance().getMsgManager().registerContentMsg(com.chat.uikit.trtc.RTCMsgContent.class);
            // 注册笔记消息类型
            WKIM.getInstance().getMsgManager().registerContentMsg(com.chat.uikit.chat.msgmodel.WKNoteContent.class);
            WKIM.getInstance().getMsgManager().registerContentMsg(com.chat.uikit.chat.msgmodel.WKScreenshotContent.class);
        } catch (Throwable e) {
            Log.e("WKUIKitApplication", "registerContentMsg error: " + e.getMessage(), e);
        }
    }

    public void postLoginIMInit() {
        if (isListenersRegistered) return;
        try {
            WKIMUtils.getInstance().initIMListener();
        } catch (Throwable e) {
            Log.e("WKUIKitApplication", "postLogin initIMListener error: " + e.getMessage(), e);
        }
        try {
            registerContentTypes();
        } catch (Throwable e) {
            Log.e("WKUIKitApplication", "postLogin registerContentTypes error: " + e.getMessage(), e);
        }
        isListenersRegistered = true;
    }

    private void initKitModuleListener() {
        registerContentTypes();
        //添加消息item
        try {
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.sensitiveWordsTips, new WKSensitiveWordsProvider());
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.screenshot, new com.chat.uikit.chat.provider.WKScreenshotProvider());
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.noRelation, new WKNoRelationProvider());
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.systemMsg, new com.chat.base.msgitem.WKSystemProvider(WKContentType.systemMsg));
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.msgPromptTime, new com.chat.base.msgitem.WKSystemProvider(WKContentType.msgPromptTime));
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.revoke, new com.chat.base.msgitem.WKRevokeProvider());
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.typing, new com.chat.base.msgitem.WKTypingProvider());
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.unknown_msg, new com.chat.base.msgitem.WKUnknownProvider());
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.msgPromptNewMsg, new WKPromptNewMsgProvider());
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.WK_TEXT, new WKTextProvider());
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.WK_IMAGE, new WKImageProvider());
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.emptyView, new WKEmptyProvider());
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.spanEmptyView, new WKSpanEmptyProvider());
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.WK_VOICE, new WKVoiceProvider());
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.WK_CARD, new WKCardProvider());
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.WK_MULTIPLE_FORWARD, new WKMultiForwardProvider());
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.loading, new LoadingProvider());
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.WK_LOCATION, new WKLocationProvider());
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.WK_VIDEO, new WKVideoProvider());
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.WK_GIF, new WKGifProvider());
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.richText, new com.chat.richeditor.msg.RichChatProvider());
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.WK_FILE, new com.chat.uikit.chat.provider.WKFileProvider());
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKContentType.noteMsg, new com.chat.uikit.chat.provider.WKNoteProvider());
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKRTCType.WK_P2P_CALL, new WKCallProvider());
        // RTC 信令消息（不显示在聊天列表中）
        WKMsgItemViewManager.getInstance().addChatItemViewProvider(WKRTCType.wk_video_call_received, new com.chat.uikit.trtc.RTCSignalProvider());
        } catch (Throwable e) {
            Log.e("WKUIKitApplication", "addChatItemViewProvider error: " + e.getMessage(), e);
        }
        // 设置消息长按选项
        EndpointManager.getInstance().setMethod(EndpointCategory.msgConfig + WKContentType.WK_TEXT, object -> new MsgConfig(true));
        EndpointManager.getInstance().setMethod(EndpointCategory.msgConfig + WKContentType.WK_IMAGE, object -> new MsgConfig(true));
        EndpointManager.getInstance().setMethod(EndpointCategory.msgConfig + WKContentType.WK_CARD, object -> new MsgConfig(true));
        EndpointManager.getInstance().setMethod(EndpointCategory.msgConfig + WKContentType.WK_LOCATION, object -> new MsgConfig(true));
        EndpointManager.getInstance().setMethod(EndpointCategory.msgConfig + WKContentType.WK_VIDEO, object -> new MsgConfig(true));
        EndpointManager.getInstance().setMethod(EndpointCategory.msgConfig + WKContentType.WK_GIF, object -> new MsgConfig(true));
        EndpointManager.getInstance().setMethod(EndpointCategory.msgConfig + WKContentType.WK_VOICE, object -> new MsgConfig(true));
        EndpointManager.getInstance().setMethod(EndpointCategory.msgConfig + WKContentType.WK_MULTIPLE_FORWARD, object -> new MsgConfig(true));
        EndpointManager.getInstance().setMethod(EndpointCategory.msgConfig + WKContentType.richText, object -> new MsgConfig(true));
        EndpointManager.getInstance().setMethod(EndpointCategory.msgConfig + WKContentType.WK_FILE, object -> new MsgConfig(true));
        EndpointManager.getInstance().setMethod(EndpointCategory.msgConfig + WKRTCType.WK_P2P_CALL, object -> new MsgConfig(true));
        // 设置聊天背景
        EndpointManager.getInstance().setMethod("set_chat_bg", object -> {
            if (object instanceof SetChatBgMenu) {
                SetChatBgMenu menu = (SetChatBgMenu) object;
                android.widget.ImageView bgIv = menu.getBackGroundIV();
                if (bgIv != null) {
                    bgIv.setImageResource(R.mipmap.ic_chat_bg);
                    bgIv.setScaleType(android.widget.ImageView.ScaleType.CENTER_CROP);
                }
            }
            return null;
        });
        // 阅后即焚设置（支持单聊和群聊）
        EndpointManager.getInstance().setMethod("chat_setting_msg_privacy", object -> {
            if (object instanceof ChatSettingCellMenu) {
                ChatSettingCellMenu menu = (ChatSettingCellMenu) object;
                android.content.Context context = menu.getParentLayout().getContext();
                View burnView = LayoutInflater.from(context).inflate(R.layout.chat_setting_message_privacy_layout, menu.getParentLayout(), false);

                SwitchView burnSwitchView = burnView.findViewById(R.id.burnSwitchView);
                ExpandableLayout burnTimeExpandLayout = burnView.findViewById(R.id.burnTimeExpandLayout);
                TextView burnTimeDescTv = burnView.findViewById(R.id.burnTimeDescTv);
                View time10Layout = burnView.findViewById(R.id.time10Layout);
                View time20Layout = burnView.findViewById(R.id.time20Layout);
                View time30Layout = burnView.findViewById(R.id.time30Layout);
                View time60Layout = burnView.findViewById(R.id.time60Layout);
                View time120Layout = burnView.findViewById(R.id.time120Layout);
                View time180Layout = burnView.findViewById(R.id.time180Layout);
                View time10CheckIv = burnView.findViewById(R.id.time10CheckIv);
                View time20CheckIv = burnView.findViewById(R.id.time20CheckIv);
                View time30CheckIv = burnView.findViewById(R.id.time30CheckIv);
                View time60CheckIv = burnView.findViewById(R.id.time60CheckIv);
                View time120CheckIv = burnView.findViewById(R.id.time120CheckIv);
                View time180CheckIv = burnView.findViewById(R.id.time180CheckIv);

                final int[] burnTime = {10};
                final boolean[] burnEnabled = {false};

                // 更新阅后即焚时间UI
                java.util.function.Consumer<Integer> updateBurnTimeUI = time -> {
                    time10CheckIv.setVisibility(time == 10 ? View.VISIBLE : View.GONE);
                    time20CheckIv.setVisibility(time == 20 ? View.VISIBLE : View.GONE);
                    time30CheckIv.setVisibility(time == 30 ? View.VISIBLE : View.GONE);
                    time60CheckIv.setVisibility(time == 60 ? View.VISIBLE : View.GONE);
                    time120CheckIv.setVisibility(time == 120 ? View.VISIBLE : View.GONE);
                    time180CheckIv.setVisibility(time == 180 ? View.VISIBLE : View.GONE);

                    String timeStr;
                    if (time < 60) {
                        timeStr = time + "秒";
                    } else {
                        timeStr = (time / 60) + "分钟";
                    }
                    burnTimeDescTv.setText(String.format(context.getString(R.string.burn_time_desc), timeStr));
                };

                // 保存阅后即焚设置
                java.util.function.BiConsumer<String, Integer> saveBurnSetting = (key, value) -> {
                    ICommonListener listener = (code, msg) -> {
                        if (code != HttpResponseCode.success) {
                            WKToastUtils.getInstance().showToastNormal(msg);
                        }
                    };
                    if (menu.getChannelType() == WKChannelType.GROUP) {
                        GroupModel.getInstance().updateMyGroupSetting(menu.getChannelID(), key, value, listener);
                    } else {
                        FriendModel.getInstance().updateUserSetting(menu.getChannelID(), key, value, listener);
                    }
                };

                // 开关监听
                burnSwitchView.setOnCheckedChangeListener((buttonView, isChecked) -> {
                    if (buttonView.isPressed()) {
                        ICommonListener switchListener = (code, msg) -> {
                            if (code != HttpResponseCode.success) {
                                burnSwitchView.setChecked(!isChecked);
                                WKToastUtils.getInstance().showToastNormal(msg);
                            } else {
                                burnEnabled[0] = isChecked;
                                burnTimeExpandLayout.setExpanded(isChecked);
                                WKToastUtils.getInstance().showToastNormal(isChecked ? "已开启阅后即焚" : "已关闭阅后即焚");
                            }
                        };
                        if (menu.getChannelType() == WKChannelType.GROUP) {
                            GroupModel.getInstance().updateGroupSetting(menu.getChannelID(), "flame", isChecked ? 1 : 0, switchListener);
                        } else {
                            FriendModel.getInstance().updateUserSetting(menu.getChannelID(), "flame", isChecked ? 1 : 0, switchListener);
                        }
                    }
                });

                // 时间选择监听
                View.OnClickListener timeClickListener = v -> {
                    int time = 10;
                    if (v.getId() == R.id.time10Layout) time = 10;
                    else if (v.getId() == R.id.time20Layout) time = 20;
                    else if (v.getId() == R.id.time30Layout) time = 30;
                    else if (v.getId() == R.id.time60Layout) time = 60;
                    else if (v.getId() == R.id.time120Layout) time = 120;
                    else if (v.getId() == R.id.time180Layout) time = 180;

                    burnTime[0] = time;
                    updateBurnTimeUI.accept(time);
                    saveBurnSetting.accept("flame_second", time);
                };

                time10Layout.setOnClickListener(timeClickListener);
                time20Layout.setOnClickListener(timeClickListener);
                time30Layout.setOnClickListener(timeClickListener);
                time60Layout.setOnClickListener(timeClickListener);
                time120Layout.setOnClickListener(timeClickListener);
                time180Layout.setOnClickListener(timeClickListener);

                // 加载当前设置
                WKCommonModel.getInstance().getChannel(menu.getChannelID(), menu.getChannelType(), (code, msg, entity) -> {
                    if (code == HttpResponseCode.success && entity != null) {
                        burnEnabled[0] = entity.flame == 1;
                        burnTime[0] = entity.flame_second > 0 ? entity.flame_second : 10;
                        burnSwitchView.setChecked(burnEnabled[0]);
                        burnTimeExpandLayout.setExpanded(burnEnabled[0]);
                        updateBurnTimeUI.accept(burnTime[0]);
                    }
                });

                return burnView;
            }
            return null;
        });
        // 消息回执设置（聊天回执）
        EndpointManager.getInstance().setMethod("msg_receipt_view", object -> {
            if (object instanceof ChatSettingCellMenu) {
                ChatSettingCellMenu menu = (ChatSettingCellMenu) object;
                android.content.Context context = menu.getParentLayout().getContext();
                View receiptView = LayoutInflater.from(context).inflate(R.layout.item_msg_receipt_layout, menu.getParentLayout(), false);
                com.chat.base.ui.components.SwitchView receiptSwitchView = receiptView.findViewById(R.id.receiptSwitchView);

                // 加载当前设置
                WKCommonModel.getInstance().getChannel(menu.getChannelID(), menu.getChannelType(), (code, msg, entity) -> {
                    if (code == HttpResponseCode.success && entity != null) {
                        receiptSwitchView.setChecked(entity.receipt == 1);
                    }
                });

                // 开关监听
                receiptSwitchView.setOnCheckedChangeListener((buttonView, isChecked) -> {
                    if (buttonView.isPressed()) {
                        ICommonListener switchListener = (code, msg1) -> {
                            if (code != HttpResponseCode.success) {
                                receiptSwitchView.setChecked(!isChecked);
                                com.chat.base.utils.WKToastUtils.getInstance().showToastNormal(msg1);
                            } else {
                                com.chat.base.utils.WKToastUtils.getInstance().showToastNormal(isChecked ? "已开启消息回执" : "已关闭消息回执");
                            }
                        };
                        if (menu.getChannelType() == com.xinbida.wukongim.entity.WKChannelType.GROUP) {
                            com.chat.uikit.group.service.GroupModel.getInstance().updateMyGroupSetting(menu.getChannelID(), "receipt", isChecked ? 1 : 0, switchListener);
                        } else {
                            com.chat.uikit.contacts.service.FriendModel.getInstance().updateUserSetting(menu.getChannelID(), "receipt", isChecked ? 1 : 0, switchListener);
                        }
                    }
                });

                return receiptView;
            }
            return null;
        });
        EndpointManager.getInstance().setMethod("uikit_sql", EndpointCategory.wkDBMenus, object -> new DBMenu("uikit_sql"));
        //注册消息长按菜单配置
        EndpointManager.getInstance().setMethod(EndpointCategory.msgConfig + WKContentType.WK_VOICE, object -> new MsgConfig(false, true, true, false, false, false));
        EndpointManager.getInstance().setMethod(EndpointCategory.msgConfig + WKContentType.typing, object -> new MsgConfig(false));
        EndpointManager.getInstance().setMethod("", EndpointCategory.wkChatPopupItem, 90, object -> {
            WKMsg wkMsg = (WKMsg) object;
            if (wkMsg.type == WKContentType.WK_TEXT) {
                return new ChatItemPopupMenu(R.mipmap.msg_copy, getContext().getString(R.string.copy), (msg, iConversationContext) -> {
                    WKTextContent textContent = (WKTextContent) msg.baseContentMsgModel;
                    String content = textContent.content;
                    if (msg.remoteExtra.contentEditMsgModel != null) {
                        content = msg.remoteExtra.contentEditMsgModel.getDisplayContent();
                    }
                    ClipboardManager cm = (ClipboardManager) iConversationContext.getChatActivity().getSystemService(Context.CLIPBOARD_SERVICE);
                    ClipData mClipData = ClipData.newPlainText("Label", content);
                    assert cm != null;
                    cm.setPrimaryClip(mClipData);
                    WKToastUtils.getInstance().showToastNormal(iConversationContext.getChatActivity().getString(R.string.copyed));
                });
            }
            return null;
        });

        // 置顶消息选项
        EndpointManager.getInstance().setMethod("pin_message", EndpointCategory.wkChatPopupItem, 88, object -> {
            WKMsg wkMsg = (WKMsg) object;
            if (wkMsg.type == WKContentType.WK_TEXT || wkMsg.type == WKContentType.WK_IMAGE
                    || wkMsg.type == WKContentType.WK_VIDEO || wkMsg.type == WKContentType.WK_VOICE
                    || wkMsg.type == WKContentType.WK_LOCATION) {
                if (wkMsg.channelType == WKChannelType.GROUP) {
                    WKChannelMember member = WKIM.getInstance().getChannelMembersManager().getMember(
                            wkMsg.channelID, wkMsg.channelType, WKConfig.getInstance().getUid());
                    if (member == null || (member.role != WKChannelMemberRole.admin && member.role != WKChannelMemberRole.manager)) {
                        return null;
                    }
                }
                return new ChatItemPopupMenu(R.mipmap.msg_fave, "置顶", (msg, iConversationContext) -> {
                    if (iConversationContext.getChatActivity() instanceof ChatActivity) {
                        ((ChatActivity) iConversationContext.getChatActivity()).pinMessage(msg);
                    }
                });
            }
            return null;
        });

        // 收藏消息选项
        EndpointManager.getInstance().setMethod("", EndpointCategory.wkChatPopupItem, 85, object -> {
            WKMsg wkMsg = (WKMsg) object;
            if (wkMsg.type == WKContentType.WK_TEXT) {
                return new ChatItemPopupMenu(R.mipmap.msg_fave, "收藏", (msg, iConversationContext) -> {
                    WKTextContent textContent = (WKTextContent) msg.baseContentMsgModel;
                    String content = textContent.content;
                    if (msg.remoteExtra.contentEditMsgModel != null) {
                        content = msg.remoteExtra.contentEditMsgModel.getDisplayContent();
                    }
                    String senderName = "";
                    if (msg.getFrom() != null) senderName = msg.getFrom().channelName;
                    String timeStr = WKTimeUtils.getInstance().getTimeString(msg.timestamp * 1000L);
                    com.chat.uikit.favorite.FavoriteStorageManager.getInstance(mContext.get())
                            .addFavorite(com.chat.uikit.favorite.FavoriteItem.TYPE_TEXT, content, null, senderName, timeStr);
                    WKToastUtils.getInstance().showToastNormal("已收藏");
                });
            } else if (wkMsg.type == WKContentType.WK_IMAGE) {
                return new ChatItemPopupMenu(R.mipmap.msg_fave, "收藏", (msg, iConversationContext) -> {
                    WKImageContent imgContent = (WKImageContent) msg.baseContentMsgModel;
                    String imgUrl = imgContent.localPath;
                    if (imgContent.url != null && !imgContent.url.isEmpty()) {
                        imgUrl = com.chat.base.config.WKApiConfig.getShowUrl(imgContent.url);
                    }
                    String senderName = "";
                    if (msg.getFrom() != null) senderName = msg.getFrom().channelName;
                    String timeStr = WKTimeUtils.getInstance().getTimeString(msg.timestamp * 1000L);
                    com.chat.uikit.favorite.FavoriteStorageManager.getInstance(mContext.get())
                            .addFavorite(com.chat.uikit.favorite.FavoriteItem.TYPE_IMAGE, "", imgUrl, senderName, timeStr, imgContent.width, imgContent.height, null);
                    WKToastUtils.getInstance().showToastNormal("已收藏图片");
                });
            } else if (wkMsg.type == WKContentType.WK_VIDEO) {
                return new ChatItemPopupMenu(R.mipmap.msg_fave, "收藏", (msg, iConversationContext) -> {
                    WKVideoContent videoContent = (WKVideoContent) msg.baseContentMsgModel;
                    String coverUrl = videoContent.cover;
                    if (coverUrl != null && !coverUrl.isEmpty()) {
                        coverUrl = com.chat.base.config.WKApiConfig.getShowUrl(coverUrl);
                    }
                    String remoteVideoUrl = videoContent.url;
                    if (remoteVideoUrl != null && !remoteVideoUrl.isEmpty()) {
                        remoteVideoUrl = com.chat.base.config.WKApiConfig.getShowUrl(remoteVideoUrl);
                    }
                    String senderName = "";
                    if (msg.getFrom() != null) senderName = msg.getFrom().channelName;
                    String timeStr = WKTimeUtils.getInstance().getTimeString(msg.timestamp * 1000L);
                    com.chat.uikit.favorite.FavoriteStorageManager.getInstance(mContext.get())
                            .addFavorite(com.chat.uikit.favorite.FavoriteItem.TYPE_VIDEO, "", coverUrl, senderName, timeStr, videoContent.width, videoContent.height, remoteVideoUrl);
                    WKToastUtils.getInstance().showToastNormal("已收藏视频");
                });
            } else if (wkMsg.type == WKContentType.WK_LOCATION) {
                return new ChatItemPopupMenu(R.mipmap.msg_fave, "收藏", (msg, iConversationContext) -> {
                    com.chat.uikit.location.WKLocationContent locContent = (com.chat.uikit.location.WKLocationContent) msg.baseContentMsgModel;
                    String title = locContent.title != null ? locContent.title : "";
                    String address = locContent.address != null ? locContent.address : "";
                    // content用于列表显示："[位置] 标题，详细地址"
                    StringBuilder contentSb = new StringBuilder("[位置] ");
                    if (!title.isEmpty()) {
                        contentSb.append(title);
                    }
                    if (!address.isEmpty() && !address.equals(title)) {
                        if (!title.isEmpty()) contentSb.append("，");
                        contentSb.append(address);
                    }
                    String content = contentSb.toString();
                    // extra保存完整结构化信息："lng,lat|imgUrl|address|title"
                    String imgUrl = locContent.url != null ? locContent.url : "";
                    String extra = locContent.longitude + "," + locContent.latitude + "|" + imgUrl + "|" + address + "|" + title;
                    String senderName = "";
                    if (msg.getFrom() != null) senderName = msg.getFrom().channelName;
                    String timeStr = WKTimeUtils.getInstance().getTimeString(msg.timestamp * 1000L);
                    com.chat.uikit.favorite.FavoriteStorageManager.getInstance(mContext.get())
                            .addFavorite(com.chat.uikit.favorite.FavoriteItem.TYPE_LOCATION, content, extra, senderName, timeStr);
                    WKToastUtils.getInstance().showToastNormal("已收藏");
                });
            } else if (wkMsg.type == WKContentType.WK_VOICE) {
                return null;
            }
            return null;
        });

        //添加个人中心
        EndpointManager.getInstance().setMethod("personal_center_currency", EndpointCategory.personalCenter, 2, object -> new PersonalInfoMenu(R.mipmap.icon_setting, mContext.get().getString(R.string.currency), () -> {
            Intent intent = new Intent(mContext.get(), SettingActivity.class);
            intent.addFlags(FLAG_ACTIVITY_NEW_TASK);
            mContext.get().startActivity(intent);
        }));
        EndpointManager.getInstance().setMethod("personal_center_new_msg_notice", EndpointCategory.personalCenter, 3, object -> new PersonalInfoMenu(R.mipmap.icon_notice, mContext.get().getString(R.string.new_msg_notice), () -> {
            Intent intent = new Intent(mContext.get(), MsgNoticesSettingActivity.class);
            intent.addFlags(FLAG_ACTIVITY_NEW_TASK);
            mContext.get().startActivity(intent);
        }));
        EndpointManager.getInstance().setMethod("personal_center_web_login", EndpointCategory.personalCenter, 1000, object -> new PersonalInfoMenu(R.mipmap.icon_web_login, mContext.get().getString(R.string.web_login), () -> EndpointManager.getInstance().invoke("show_web_login_desc", mContext.get())));
        EndpointManager.getInstance().setMethod("personal_center_note", EndpointCategory.personalCenter, 1, object -> new PersonalInfoMenu(R.drawable.ic_func_note, "我的笔记", () -> {
            Intent intent = new Intent(mContext.get(), com.chat.uikit.note.NoteListActivity.class);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            mContext.get().startActivity(intent);
        }));
        EndpointManager.getInstance().setMethod("personal_center_favorite", EndpointCategory.personalCenter, 4, object -> new PersonalInfoMenu(R.drawable.ic_func_favorite, mContext.get().getString(R.string.favorite), () -> {
            Intent intent = new Intent(mContext.get(), com.chat.uikit.favorite.FavoriteActivity.class);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            mContext.get().startActivity(intent);
        }));

        //添加通讯录
        EndpointManager.getInstance().setMethod(EndpointCategory.mailList + "_friends", EndpointCategory.mailList, 100, object -> new ContactsMenu("friend", R.mipmap.icon_new_friend, mContext.get().getString(R.string.new_friends), () -> {
            Intent intent = new Intent(mContext.get(), NewFriendsActivity.class);
            intent.addFlags(FLAG_ACTIVITY_NEW_TASK);
            mContext.get().startActivity(intent);
        }));
        EndpointManager.getInstance().setMethod(EndpointCategory.mailList + "_groups", EndpointCategory.mailList, 90, object -> new ContactsMenu("group", R.mipmap.icon_groups, mContext.get().getString(R.string.saved_groups), () -> {
            Intent intent = new Intent(mContext.get(), SavedGroupsActivity.class);
            intent.addFlags(FLAG_ACTIVITY_NEW_TASK);
            mContext.get().startActivity(intent);
        }));
        // 标签
        EndpointManager.getInstance().setMethod(EndpointCategory.mailList + "_labels", EndpointCategory.mailList, 80, object -> new ContactsMenu("label", R.mipmap.icon_label, mContext.get().getString(R.string.str_label), () -> {
            Intent intent = new Intent(mContext.get(), LabelActivity.class);
            intent.addFlags(FLAG_ACTIVITY_NEW_TASK);
            mContext.get().startActivity(intent);
        }));

        // 添加聊天工具栏菜单语音
        EndpointManager.getInstance().setMethod(EndpointCategory.wkChatToolBar + "_voice", EndpointCategory.wkChatToolBar, 98, object -> {
            IConversationContext iConversationContext = (IConversationContext) object;
            View voiceView = WKVoiceViewManager.getInstance().getVoiceView(iConversationContext);
            return new ChatToolBarMenu("wk_chat_toolbar_voice", R.mipmap.icon_chat_toolbar_voice, R.mipmap.icon_chat_toolbar_voice, voiceView, (isSelected, iConversationContext14) -> {
                // TODO: 1/1/21
            });
        });
        //聊天工具栏相册
        EndpointManager.getInstance().setMethod(EndpointCategory.wkChatToolBar + "_album", EndpointCategory.wkChatToolBar, 95, object -> new ChatToolBarMenu("wk_chat_toolbar_album", R.mipmap.icon_chat_toolbar_album, -1, null, (isSelected, iConversationContext1) -> {
            if (isSelected) {
                chooseIMG(iConversationContext1);
            }
        }));
        //聊天工具栏笔记
        EndpointManager.getInstance().setMethod(EndpointCategory.wkChatToolBar + "_note", EndpointCategory.wkChatToolBar, 90, object -> new ChatToolBarMenu("wk_chat_toolbar_note", R.mipmap.my_note2, -1, null, (isSelected, iConversationContext13) -> {
            if (isSelected) {
                Intent intent = new Intent(mContext.get(), com.chat.uikit.note.NoteListActivity.class);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                if (iConversationContext13 != null && iConversationContext13.getChatChannelInfo() != null) {
                    WKChannel channel = iConversationContext13.getChatChannelInfo();
                    intent.putExtra("channelId", channel.channelID);
                    intent.putExtra("channelType", channel.channelType);
                }
                mContext.get().startActivity(intent);
            }
        }));
        //聊天工具栏收藏
        EndpointManager.getInstance().setMethod(EndpointCategory.wkChatToolBar + "_favorite", EndpointCategory.wkChatToolBar, 85, object -> new ChatToolBarMenu("wk_chat_toolbar_favorite", R.mipmap.icon_toolbar_fav, -1, null, (isSelected, iConversationContext12) -> {
            if (isSelected) {
                Intent intent = new Intent(mContext.get(), com.chat.uikit.favorite.FavoriteActivity.class);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                if (iConversationContext12 != null && iConversationContext12.getChatChannelInfo() != null) {
                    WKChannel channel = iConversationContext12.getChatChannelInfo();
                    intent.putExtra("channelId", channel.channelID);
                    intent.putExtra("channelType", channel.channelType);
                }
                mContext.get().startActivity(intent);
            }
        }));
        //聊天工具栏相机
        EndpointManager.getInstance().setMethod(EndpointCategory.wkChatToolBar + "_camera", EndpointCategory.wkChatToolBar, 80, object -> new ChatToolBarMenu("wk_chat_toolbar_camera", R.mipmap.icon_chat_toolbar_camera, -1, null, (isSelected, iConversationContext11) -> {
            if (isSelected) {
                try {
                    com.chat.uikit.chat.RecordingActivity.start(mContext.get(),
                            iConversationContext11.getChatChannelInfo().channelID,
                            iConversationContext11.getChatChannelInfo().channelType);
                } catch (Exception e) {
                    WKToastUtils.getInstance().showToastNormal("无法打开相机: " + e.getMessage());
                }
            }
        }));
        //聊天工具栏定位
        EndpointManager.getInstance().setMethod(EndpointCategory.wkChatToolBar + "_location", EndpointCategory.wkChatToolBar, 75, object -> new ChatToolBarMenu("wk_chat_toolbar_location", R.mipmap.icon_chat_toolbar_location, -1, null, (isSelected, iConversationContext10) -> {
            if (isSelected) {
                openLocationPicker(iConversationContext10);
            }
        }));
        //聊天工具栏@
        EndpointManager.getInstance().setMethod(EndpointCategory.wkChatToolBar + "_remind", EndpointCategory.wkChatToolBar, 70, object
                -> {
            IConversationContext iConversationContext = (IConversationContext) object;
            if (iConversationContext.getChatChannelInfo().channelType == WKChannelType.PERSONAL)
                return null;
            return new ChatToolBarMenu("wk_chat_toolbar_remind", R.mipmap.icon_chat_toolbar_aite, -1, null, (isSelected, iConversationContext12) -> {

            });
        });
        // 添加聊天工具栏更多
        EndpointManager.getInstance().setMethod(EndpointCategory.wkChatToolBar + "_more", EndpointCategory.wkChatToolBar, 60, object -> {
            IConversationContext iConversationContext = (IConversationContext) object;
            View moreView = FaceManger.getInstance().getFunctionView(iConversationContext, chatFunctionMenu -> chatFunctionMenu.iChatFunctionCLick.onClick(iConversationContext));
            return new ChatToolBarMenu("wk_chat_toolbar_more", R.mipmap.icon_chat_toolbar_more, R.mipmap.icon_chat_toolbar_more, moreView, (isSelected, iConversationContext13) -> {
            });
        });
        //添加聊天功能面板（顺序：图片、拍摄、位置、名片）
        EndpointManager.getInstance().setMethod(EndpointCategory.chatFunction + "_chooseImg", EndpointCategory.chatFunction, 100, object -> new ChatFunctionMenu("chooseImg", R.mipmap.icon_func_album, mContext.get().getString(R.string.image), this::chooseIMG));
        EndpointManager.getInstance().setMethod(EndpointCategory.chatFunction + "_camera", EndpointCategory.chatFunction, 95, object -> new ChatFunctionMenu("camera", R.mipmap.icon_func_recording, "拍摄", iConversationContext -> {
            try {
                com.chat.uikit.chat.RecordingActivity.start(mContext.get(),
                        iConversationContext.getChatChannelInfo().channelID,
                        iConversationContext.getChatChannelInfo().channelType);
            } catch (Exception e) {
                WKToastUtils.getInstance().showToastNormal("无法打开相机: " + e.getMessage());
            }
        }));
        EndpointManager.getInstance().setMethod(EndpointCategory.chatFunction + "_chooseLocation", EndpointCategory.chatFunction, 90, object -> new ChatFunctionMenu("chooseLocation", R.mipmap.icon_func_location, mContext.get().getString(R.string.location), this::openLocationPicker));
        EndpointManager.getInstance().setMethod(EndpointCategory.chatFunction + "_chooseCard", EndpointCategory.chatFunction, 85, object -> new ChatFunctionMenu("chooseCard", R.mipmap.icon_func_card, mContext.get().getString(R.string.card), IConversationContext::sendCardMsg));
        //添加tab页
        EndpointManager.getInstance().setMethod(EndpointCategory.tabMenus + "_start_chat", EndpointCategory.tabMenus, 200, object -> new PopupMenuItem(mContext.get().getString(R.string.start_group_chat), R.mipmap.menu_chats, () -> {
            Intent intent = new Intent(mContext.get(), ChooseContactsActivity.class);
            intent.addFlags(FLAG_ACTIVITY_NEW_TASK);
            mContext.get().startActivity(intent);
        }));
        EndpointManager.getInstance().setMethod(EndpointCategory.tabMenus + "_add_friends", EndpointCategory.tabMenus, 99, object -> new PopupMenuItem(mContext.get().getString(R.string.add_friends), R.mipmap.menu_invite, () -> {
            Intent intent = new Intent(mContext.get(), AddFriendsActivity.class);
            intent.addFlags(FLAG_ACTIVITY_NEW_TASK);
            mContext.get().startActivity(intent);
        }));
        EndpointManager.getInstance().setMethod(EndpointCategory.tabMenus + "_scan", EndpointCategory.tabMenus, 150, object -> new PopupMenuItem(mContext.get().getString(R.string.scan), R.mipmap.menu_invite, () -> {
            try {
                Activity currentActivity = ActManagerUtils.getInstance().getCurrentActivity();
                if (currentActivity instanceof androidx.fragment.app.FragmentActivity) {
                    androidx.fragment.app.FragmentActivity fragmentActivity = (androidx.fragment.app.FragmentActivity) currentActivity;
                    String permissionDesc = String.format(mContext.get().getString(R.string.camera_permissions_desc), mContext.get().getString(R.string.app_name));
                    WKPermissions.getInstance().checkPermissions(new WKPermissions.IPermissionResult() {
                        @Override
                        public void onResult(boolean result) {
                            if (result) {
                                Intent intent = new Intent(mContext.get(), WKScanActivity.class);
                                intent.addFlags(FLAG_ACTIVITY_NEW_TASK);
                                mContext.get().startActivity(intent);
                            }
                        }

                        @Override
                        public void clickResult(boolean isCancel) {
                            if (isCancel) {
                                WKToastUtils.getInstance().showToastNormal(mContext.get().getString(R.string.ps_camera));
                            }
                        }
                    }, fragmentActivity, permissionDesc, Manifest.permission.CAMERA);
                } else {
                    Intent intent = new Intent(mContext.get(), WKScanActivity.class);
                    intent.addFlags(FLAG_ACTIVITY_NEW_TASK);
                    mContext.get().startActivity(intent);
                }
            } catch (Exception e) {
                e.printStackTrace();
                try {
                    Intent intent = new Intent(mContext.get(), WKScanActivity.class);
                    intent.addFlags(FLAG_ACTIVITY_NEW_TASK);
                    mContext.get().startActivity(intent);
                } catch (Exception ex) {
                    ex.printStackTrace();
                    WKToastUtils.getInstance().showToastNormal(mContext.get().getString(R.string.ps_camera));
                }
            }
        }));

        //显示聊天页面
        EndpointManager.getInstance().setMethod(EndpointSID.chatView, object -> {
            if (object instanceof ChatViewMenu chatViewMenu) {
                if (!TextUtils.isEmpty(chatViewMenu.channelID)) {
                    WKIMUtils.getInstance().startChatActivity(chatViewMenu);
                }
            }
            return null;
        });

        //撤回消息
        EndpointManager.getInstance().setMethod("chat_withdraw_msg", object -> {
            final WithdrawMsgMenu withdrawMsgMenu = (WithdrawMsgMenu) object;
            if (withdrawMsgMenu != null) {
                MsgModel.getInstance().revokeMsg(withdrawMsgMenu.message_id, withdrawMsgMenu.channel_id, withdrawMsgMenu.channel_type, withdrawMsgMenu.client_msg_no, (code, msg) -> {
                    if (code != HttpResponseCode.success) {
                        WKToastUtils.getInstance().showToastNormal(msg);
                        //  WKIM.getInstance().getMsgManager().updateMsgRevokeWithMessageID(withdrawMsgMenu.message_id, 1);
//                        WKIM.getInstance().getMessageManager().deleteMsgByClientMsgNo(client_msg_no);
                    }
                });
            }
            return null;
        });
        EndpointManager.getInstance().setMethod("str_delete_msg", object -> {
            WKMsg msg = (WKMsg) object;
            if (msg != null) {
                List<WKMsg> list = new ArrayList<>();
                list.add(msg);
                MsgModel.getInstance().deleteMsg(list, null);
            }
            return null;
        });
        //选择会话
        EndpointManager.getInstance().setMethod(EndpointSID.showChooseChatView, object -> {
            ChooseChatMenu messageContent = (ChooseChatMenu) object;
            Intent intent = new Intent(mContext.get(), ChooseChatActivity.class);
            intent.putExtra("isChoose", true);
            intent.addFlags(FLAG_ACTIVITY_NEW_TASK);
            mContext.get().startActivity(intent);
            WKUIKitApplication.this.messageContentList = messageContent.list;
            WKUIKitApplication.this.chooseChatCallBack = messageContent.mChatChooseContacts;
            return null;
        });

        //处理扫一扫结果
        EndpointManager.getInstance().setMethod("", EndpointCategory.wkScan, object -> new ScanResultMenu(hashMap -> {
            Object typeObj = hashMap.get("type");
            if (typeObj == null) return false;
            String type = typeObj.toString();
            if (type.equals("userInfo")) {
                JSONObject dataJson = (JSONObject) hashMap.get("data");
                if (dataJson != null && dataJson.has("uid")) {
                    String uid = dataJson.optString("uid");
                    String verCode = dataJson.optString("vercode");
                    if (!TextUtils.isEmpty(uid)) {
                        Intent intent = new Intent(mContext.get(), UserDetailActivity.class);
                        intent.putExtra("uid", uid);
                        intent.putExtra("vercode", verCode);
                        intent.addFlags(FLAG_ACTIVITY_NEW_TASK);
                        mContext.get().startActivity(intent);
                    }
                }
                return true;
            } else return false;

        }));
        //选择联系人
        EndpointManager.getInstance().setMethod("choose_contacts", object -> {
            Intent intent = new Intent(mContext.get(), ChooseContactsActivity.class);
            intent.putExtra("type", 2);
            this.contactsMenu = (ChooseContactsMenu) object;
            if (contactsMenu != null) {
                intent.putParcelableArrayListExtra("defaultSelected", (ArrayList<? extends Parcelable>) contactsMenu.defaultSelected);
                intent.putExtra("isShowSaveLabelDialog", contactsMenu.isShowSaveLabelDialog);
                if (WKReader.isNotEmpty(contactsMenu.defaultSelected) && !contactsMenu.isCanDeselect) {
                    String unSelectUids = "";
                    for (int i = 0, size = contactsMenu.defaultSelected.size(); i < size; i++) {
                        if (TextUtils.isEmpty(unSelectUids)) {
                            unSelectUids = contactsMenu.defaultSelected.get(i).channelID;
                        } else
                            unSelectUids = unSelectUids + "," + contactsMenu.defaultSelected.get(i).channelID;
                    }
                    intent.putExtra("unSelectUids", unSelectUids);
                }
            }
            intent.addFlags(FLAG_ACTIVITY_NEW_TASK);
            mContext.get().startActivity(intent);
            return null;
        });
        // 选择标签
        EndpointManager.getInstance().setMethod("choose_label", object -> {
            ChooseLabelMenu labelMenu = (ChooseLabelMenu) object;
            if (labelMenu != null && labelMenu.iChooseLabel != null) {
                // 暂存回调
                chooseLabelCallback = labelMenu.iChooseLabel;
                Intent intent = new Intent(mContext.get(), ChooseLabelActivity.class);
                intent.addFlags(FLAG_ACTIVITY_NEW_TASK);
                mContext.get().startActivity(intent);
            }
            return null;
        });
        // 保存为标签
        EndpointManager.getInstance().setMethod("save_label", object -> {
            SaveLabelMenu saveLabelMenu = (SaveLabelMenu) object;
            if (saveLabelMenu != null) {
                // 暂存待保存的成员列表
                saveLabelMembers = saveLabelMenu.list;
                Intent intent = new Intent(mContext.get(), LabelDetailActivity.class);
                intent.addFlags(FLAG_ACTIVITY_NEW_TASK);
                mContext.get().startActivity(intent);
            }
            return null;
        });
        EndpointManager.getInstance().setMethod("exit_login", object -> {
            exitLogin(0);
            return null;
        });
        //查看用户详情
        EndpointManager.getInstance().setMethod(EndpointSID.userDetailView, object -> {
            UserDetailMenu wkUserDetailMenu = (UserDetailMenu) object;
            if (wkUserDetailMenu != null) {
                if (!TextUtils.isEmpty(wkUserDetailMenu.uid)) {
                    Intent intent = new Intent(mContext.get(), UserDetailActivity.class);
                    intent.putExtra("uid", wkUserDetailMenu.uid);
                    if (!TextUtils.isEmpty(wkUserDetailMenu.groupID)) {
                        intent.putExtra("groupID", wkUserDetailMenu.groupID);
                    }
                    wkUserDetailMenu.context.startActivity(intent);
                }

            }
            return null;
        });

        EndpointManager.getInstance().setMethod("show_tab_main", object -> {
            Intent intent = new Intent(mContext.get(), TabActivity.class);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            mContext.get().startActivity(intent);
            return null;
        });
        //监听登录状态
        EndpointManager.getInstance().setMethod("", EndpointCategory.loginMenus, object -> new LoginMenu(() -> {
            Log.e("接受登录", "-->3");
            WKSharedPreferencesUtil.getInstance().putInt("wk_lock_screen_pwd_count", 5);
            WKSharedPreferencesUtil.getInstance().putBoolean("sync_friend", true);
            //初始化im
            WKUIKitApplication.getInstance().initIM();
            // 注册IM监听器和消息内容类型（首次登录时init()中因token为空而跳过）
            WKUIKitApplication.getInstance().postLoginIMInit();
            try {
                UserInfoEntity userInfo = WKConfig.getInstance().getUserInfo();
                if (userInfo != null && !TextUtils.isEmpty(userInfo.rsa_public_key)) {
                    WKIM.getInstance().getCMDManager().setRSAPublicKey(userInfo.rsa_public_key);
                }
                if (userInfo != null && !TextUtils.isEmpty(userInfo.uid)) {
                    WKIM.getInstance().getChannelManager().updateAvatarCacheKey(userInfo.uid, WKChannelType.PERSONAL, UUID.randomUUID().toString().replaceAll("-", ""));
                }
            } catch (Exception e) {
                Log.e("WKUIKitApplication", "login setRSA exception: " + e.getMessage(), e);
            }
            Intent intent = new Intent(mContext.get(), TabActivity.class);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            mContext.get().startActivity(intent);
            startChat();
            try {
                ProhibitWordModel.Companion.getInstance().sync();
                MsgModel.getInstance().deleteFlameMsg();
            } catch (Exception e) {
                Log.e("WKUIKitApplication", "login sync exception: " + e.getMessage(), e);
            }
        }));

        EndpointManager.getInstance().setMethod("syncExtraMsg", object -> {
            if (object != null) {
                WKChannel channel = (WKChannel) object;
                MsgModel.getInstance().syncExtraMsg(channel.channelID, channel.channelType);
            }
            return null;
        });

        EndpointManager.getInstance().setMethod("deleteRemoteMsg", object -> {
            if (object instanceof String clientMsgNo) {
                WKMsg msg = WKIM.getInstance().getMsgManager().getWithClientMsgNO(clientMsgNo);
                if (msg != null) {
                    List<WKMsg> list = new ArrayList<>();
                    list.add(msg);
                    MsgModel.getInstance().deleteMsg(list, null);
                }
            }
            return null;
        });
        EndpointManager.getInstance().setMethod("get_chat_uid_msg", object -> {
            if (object instanceof WKMsg2UiMsgMenu wkMsg2UiMsgMenu) {
                return WKIMUtils.getInstance().msg2UiMsg(wkMsg2UiMsgMenu.getIConversationContext(), wkMsg2UiMsgMenu.getWkMsg(), wkMsg2UiMsgMenu.getMemberCount(), wkMsg2UiMsgMenu.getShowNickName(), wkMsg2UiMsgMenu.isChoose());
            }
            return null;
        });

        // 注册音视频通话功能
        EndpointManager.getInstance().setMethod("is_register_rtc", object -> true);
        EndpointManager.getInstance().setMethod("rtc_is_calling", object -> com.chat.base.trtc.TRTCManager.getInstance().isInRoom());
        EndpointManager.getInstance().setMethod("rtc_max_number", object -> 9);

        EndpointManager.getInstance().setMethod("wk_p2p_call", object -> {
            if (object instanceof RTCMenu rtcMenu) {
                try {
                    String userId = WKConfig.getInstance().getUid();
                    if (userId == null || userId.isEmpty()) {
                        WKToastUtils.getInstance().showToastNormal("用户未登录");
                        return null;
                    }
                    String channelID = rtcMenu.iConversationContext.getChatChannelInfo().channelID;
                    int channelType = rtcMenu.iConversationContext.getChatChannelInfo().channelType;
                    int roomId = (int) (System.currentTimeMillis() / 1000);
                    String callerName = rtcMenu.iConversationContext.getChatChannelInfo().channelName;
                    if (callerName == null || callerName.isEmpty()) {
                        callerName = "用户";
                    }
                    String myName = WKConfig.getInstance().getUserName();
                    if (myName == null || myName.isEmpty()) {
                        myName = "用户";
                    }
                    // 强制使用语音通话
                    int callType = com.chat.base.trtc.TRTCType.AUDIO_CALL;
                    // TRTC 配置
                    int sdkAppId = 1600159338;
                    String secretKey = "b3132bc984dcaefdb93179dc33cc950a3ca184d03d0e32d4c2c99a73e7220b98";
                    String userSig = com.chat.base.trtc.UserSigGenerator.genUserSig(sdkAppId, userId, secretKey);
                    // 保存到配置
                    WKConfig.getInstance().setTrtcSdkAppId(sdkAppId);
                    WKConfig.getInstance().setTrtcUserSig(userSig);
                    Log.e("WKUIKitApplication", "p2p call: sdkAppId=" + sdkAppId + ", userId=" + userId + ", userSigLen=" + (userSig != null ? userSig.length() : 0));
                    Intent intent = new Intent(mContext.get(), com.chat.uikit.trtc.TRTCCallActivity.class);
                    intent.putExtra(com.chat.uikit.trtc.TRTCCallActivity.EXTRA_USER_ID, userId);
                    intent.putExtra(com.chat.uikit.trtc.TRTCCallActivity.EXTRA_TARGET_UID, channelID);
                    intent.putExtra(com.chat.uikit.trtc.TRTCCallActivity.EXTRA_CHANNEL_ID, channelID);
                    intent.putExtra(com.chat.uikit.trtc.TRTCCallActivity.EXTRA_CHANNEL_TYPE, channelType);
                    intent.putExtra(com.chat.uikit.trtc.TRTCCallActivity.EXTRA_ROOM_ID, roomId);
                    intent.putExtra(com.chat.uikit.trtc.TRTCCallActivity.EXTRA_CALLER_NAME, callerName);
                    intent.putExtra(com.chat.uikit.trtc.TRTCCallActivity.EXTRA_MY_NAME, myName);
                    intent.putExtra(com.chat.uikit.trtc.TRTCCallActivity.EXTRA_CALL_TYPE, callType);
                    intent.putExtra(com.chat.uikit.trtc.TRTCCallActivity.EXTRA_SDK_APP_ID, sdkAppId);
                    intent.putExtra(com.chat.uikit.trtc.TRTCCallActivity.EXTRA_USER_SIG, userSig);
                    // 从聊天页面启动，不用 NEW_TASK，挂断后自然回到聊天页面
                    android.app.Activity chatActivity = rtcMenu.iConversationContext.getChatActivity();
                    if (chatActivity != null) {
                        chatActivity.startActivity(intent);
                    } else {
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                        mContext.get().startActivity(intent);
                    }
                } catch (Exception e) {
                    Log.e("WKUIKitApplication", "p2p call error: " + e.getMessage(), e);
                    WKToastUtils.getInstance().showToastNormal("通话发起失败: " + e.getMessage());
                }
            }
            return null;
        });

        // 注册截图安全模块端点
        EndpointManager.getInstance().setMethod("add_security_module", object -> true);

        // 注册截屏通知检测端点
        EndpointManager.getInstance().setMethod("start_screen_shot", object -> {
            if (object instanceof android.app.Activity activity) {
                String currentChannelId = WKUIKitApplication.getInstance().chattingChannelID;
                byte currentChannelType = WKUIKitApplication.getInstance().chattingChannelType;
                if (currentChannelId != null && !currentChannelId.isEmpty()) {
                    com.chat.uikit.chat.ScreenShotHelper.getInstance().startMonitoring(activity, currentChannelId, currentChannelType);
                }
            }
            return null;
        });
        EndpointManager.getInstance().setMethod("stop_screen_shot", object -> {
            com.chat.uikit.chat.ScreenShotHelper.getInstance().stopMonitoring();
            return null;
        });

        // 富文本编辑器端点
        EndpointManager.getInstance().setMethod("show_rich_edit", object -> {
            if (object instanceof IConversationContext) {
                IConversationContext context = (IConversationContext) object;
                Intent intent = new Intent(context.getChatActivity(), com.chat.richeditor.ui.EditActivity.class);
                intent.putExtra(com.chat.richeditor.ui.EditActivity.KEY_CHANNEL_ID, context.getChatChannelInfo().channelID);
                intent.putExtra(com.chat.richeditor.ui.EditActivity.KEY_CHANNEL_TYPE, context.getChatChannelInfo().channelType);
                context.getChatActivity().startActivity(intent);
            }
            return null;
        });
    }

    public void sendChooseChatBack(List<WKChannel> list) {
        if (chooseChatCallBack != null) {
            chooseChatCallBack.iChoose.onResult(list);
            chooseChatCallBack = null;
        }
    }

    public List<WKMessageContent> getMessageContentList() {
        return messageContentList;
    }

    public void setChooseContactsBack(List<WKChannel> list) {
        if (contactsMenu != null) {
            contactsMenu.iChooseBack.onBack(list);
            contactsMenu = null;
        }
    }

    public void setChooseLabelBack(List<ChooseLabelEntity> list) {
        if (chooseLabelCallback != null) {
            chooseLabelCallback.onResult(list);
            chooseLabelCallback = null;
        }
    }

    public List<WKChannel> getSaveLabelMembers() {
        List<WKChannel> list = saveLabelMembers;
        saveLabelMembers = null;
        return list;
    }

    private ChatChooseContacts chooseChatCallBack;
    private ChooseContactsMenu contactsMenu;
    private List<WKMessageContent> messageContentList;
    private ChooseLabelMenu.IChooseLabel chooseLabelCallback;
    private List<com.xinbida.wukongim.entity.WKChannel> saveLabelMembers;

    public void exitLogin(int from) {
        MsgModel.getInstance().stopTimer();
        EndpointManager.getInstance().invoke("wk_logout", null);
        WKConfig.getInstance().clearInfo();
        if (isIMInited) {
            try {
                WKIM.getInstance().getConnectionManager().disconnect(true);
            } catch (Throwable e) {
                Log.e("WKUIKitApplication", "exitLogin disconnect error: " + e.getMessage(), e);
            }
        }
        isIMInited = false;
        isListenersRegistered = false;
        ActManagerUtils.getInstance().clearAllActivity();
        EndpointManager.getInstance().invoke("main_show_home_view", from);
        //关闭UI层数据库
        WKBaseApplication.getInstance().closeDbHelper();

    }

    private void openLocationPicker(IConversationContext iConversationContext) {
        String[] permissions = new String[]{
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
        };
        String desc = String.format(iConversationContext.getChatActivity().getString(R.string.location_permission_desc),
                iConversationContext.getChatActivity().getString(R.string.app_name));
        WKPermissions.getInstance().checkPermissions(new WKPermissions.IPermissionResult() {
            @Override
            public void onResult(boolean result) {
                if (result) {
                    try {
                        Intent intent = new Intent(mContext.get(), com.chat.uikit.location.LocationPickerActivity.class);
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                        intent.putExtra("channel_id", iConversationContext.getChatChannelInfo().channelID);
                        intent.putExtra("channel_type", iConversationContext.getChatChannelInfo().channelType);
                        mContext.get().startActivity(intent);
                    } catch (Exception e) {
                        WKToastUtils.getInstance().showToastNormal("无法打开位置选择: " + e.getMessage());
                    }
                }
            }

            @Override
            public void clickResult(boolean isCancel) {
            }
        }, iConversationContext.getChatActivity(), desc, permissions);
    }

    private void chooseIMG(IConversationContext iConversationContext) {
        String[] permissionStr = new String[]{Manifest.permission.READ_EXTERNAL_STORAGE};
//        String permissionStr = Manifest.permission.READ_EXTERNAL_STORAGE;
        if (Build.VERSION.SDK_INT >= 33) {
//            permissionStr = Manifest.permission.READ_MEDIA_IMAGES;
            permissionStr = new String[]{Manifest.permission.READ_MEDIA_IMAGES, Manifest.permission.READ_MEDIA_VIDEO, Manifest.permission.READ_MEDIA_AUDIO};
        }
        String desc = String.format(iConversationContext.getChatActivity().getString(R.string.album_permissions_desc), iConversationContext.getChatActivity().getString(R.string.app_name));
        WKPermissions.getInstance().checkPermissions(new WKPermissions.IPermissionResult() {
            @Override
            public void onResult(boolean result) {
                ChooseMimeType mimeType = ChooseMimeType.img;
                if (result) {
                    Object isRegisterVideo = EndpointManager.getInstance().invoke("is_register_video", null);
                    if (isRegisterVideo instanceof Boolean) {
                        boolean isRegister = (boolean) isRegisterVideo;
                        if (isRegister) {
                            mimeType = ChooseMimeType.all;
                        }
                    }
                    GlideUtils.getInstance().chooseIMG(iConversationContext.getChatActivity(), 9, true, mimeType, true, new GlideUtils.ISelectBack() {
                        @Override
                        public void onBack(List<ChooseResult> paths) {
                            if (paths.size() == 1 && paths.get(0).model == ChooseResultModel.video) {
                                // 立即发送视频消息，不等待封面提取（封面在上传阶段异步提取）
                                WKVideoContent videoContent = new WKVideoContent();
                                videoContent.localPath = paths.get(0).path;
                                videoContent.size = new java.io.File(paths.get(0).path).length();
                                iConversationContext.sendMessage(videoContent);
                                return;
                            }

                            for (int i = 0, size = paths.size(); i < size; i++) {
                                String path = paths.get(i).path;
                                if (paths.get(i).model == ChooseResultModel.video) {
                                    // 立即发送视频消息，不等待封面提取
                                    WKVideoContent videoContent = new WKVideoContent();
                                    videoContent.localPath = path;
                                    videoContent.size = new java.io.File(path).length();
                                    iConversationContext.sendMessage(videoContent);
                                } else {
                                    if (WKFileUtils.getInstance().isGif(path)) {
                                        Object isRegisterSticker = EndpointManager.getInstance().invoke("is_register_sticker", null);
                                        if (isRegisterSticker instanceof Boolean) {
                                            WKGifContent mGifContent = new WKGifContent();
                                            mGifContent.format = "gif";
                                            mGifContent.localPath = path;
                                            Bitmap bitmap = BitmapFactory.decodeFile(path);
                                            if (bitmap != null) {
                                                mGifContent.height = bitmap.getHeight();
                                                mGifContent.width = bitmap.getWidth();
                                            }
                                            iConversationContext.sendMessage(mGifContent);
                                            return;
                                        }
                                    }
                                    WKImageContent imageContent = new WKImageContent(path);
                                    iConversationContext.sendMessage(imageContent);

                                }

                            }
                        }

                        @Override
                        public void onCancel() {

                        }
                    });
                }
            }

            @Override
            public void clickResult(boolean isCancel) {
            }
        }, iConversationContext.getChatActivity(), desc, permissionStr);
    }

    public interface IShowChatConfirm {
        void onBack(@NonNull List<WKChannel> list, @NonNull List<WKMessageContent> messageContentList);
    }

    public void showChatConfirmDialog(@NonNull Context context, @NonNull List<WKChannel> list, @NonNull List<WKMessageContent> messageContentList, final IShowChatConfirm iShowChatConfirm) {
        View view = LayoutInflater.from(context).inflate(R.layout.chat_confirm_dialog_view, null, false);
        RecyclerView recyclerView = view.findViewById(R.id.recyclerView);
        AvatarView avatarView = view.findViewById(R.id.avatarView);
        TextView nameTv = view.findViewById(R.id.nameTv);
        ImageView imageView = view.findViewById(R.id.imageView);
        TextView contentTv = view.findViewById(R.id.contentTv);
        if (list.size() == 1) {
            avatarView.showAvatar(list.get(0));
            String showName = list.get(0).channelRemark;
            if (TextUtils.isEmpty(showName)) showName = list.get(0).channelName;
            if (list.get(0).channelID.equals(WKSystemAccount.system_file_helper)) {
                showName = context.getString(R.string.wk_file_helper);
            }
            if (list.get(0).channelID.equals(WKSystemAccount.system_team)) {
                showName = context.getString(R.string.wk_system_notice);
            }
            nameTv.setText(showName);
            recyclerView.setVisibility(View.GONE);
            avatarView.setVisibility(View.VISIBLE);
            nameTv.setVisibility(View.VISIBLE);
        } else {
            class AvatarViewHolder extends RecyclerView.ViewHolder {
                final AvatarView avatarView;

                public AvatarViewHolder(@NonNull View itemView) {
                    super(itemView);
                    avatarView = itemView.findViewWithTag("avatar");
                }
            }
            recyclerView.setLayoutManager(new GridLayoutManager(context, 5));
            recyclerView.setAdapter(new RecyclerView.Adapter<AvatarViewHolder>() {
                @NonNull
                @Override
                public AvatarViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
                    LinearLayout view1 = new LinearLayout(parent.getContext());
                    AvatarView avatarView1 = new AvatarView(parent.getContext());
                    avatarView1.setTag("avatar");
                    view1.addView(avatarView1, LayoutHelper.createLinear(LayoutHelper.WRAP_CONTENT, LayoutHelper.WRAP_CONTENT, Gravity.CENTER, 5, 5, 5, 5));
                    return new AvatarViewHolder(view1);
                }

                @Override
                public void onBindViewHolder(@NonNull AvatarViewHolder holder, int position) {
                    holder.avatarView.setSize(40);
                    holder.avatarView.showAvatar(list.get(position));
                }

                @Override
                public int getItemCount() {
                    return list.size();
                }
            });
            nameTv.setVisibility(View.GONE);
            avatarView.setVisibility(View.GONE);
            contentTv.setVisibility(View.GONE);
        }

        if (messageContentList.size() == 1) {
            WKMessageContent messageContent = messageContentList.get(0);
            if (messageContent.type == WKContentType.WK_IMAGE) {
                WKImageContent imgMsgModel = (WKImageContent) messageContent;
                ViewGroup.LayoutParams layoutParams = imageView.getLayoutParams();
                int[] ints = ImageUtils.getInstance().getImageWidthAndHeightToTalk(imgMsgModel.width, imgMsgModel.height);
                layoutParams.height = ints[1];
                layoutParams.width = ints[0];
                imageView.setLayoutParams(layoutParams);
                String showUrl;
                if (!TextUtils.isEmpty(imgMsgModel.localPath)) {
                    showUrl = imgMsgModel.localPath;
                    File file = new File(showUrl);
                    if (!file.exists()) {
                        //如果本地文件被删除就显示网络图片
                        showUrl = WKApiConfig.getShowUrl(imgMsgModel.url);
                    }
                } else {
                    showUrl = WKApiConfig.getShowUrl(imgMsgModel.url);
                }
                GlideUtils.getInstance().showImg(context, showUrl, ints[0], ints[1], imageView);
                imageView.setVisibility(View.VISIBLE);
                contentTv.setVisibility(View.GONE);
            } else {
                String content = messageContent.getDisplayContent();
                if (messageContent.type == WKContentType.WK_CARD) {
                    WKCardContent WKCardContent = (WKCardContent) messageContent;
                    content = content + WKCardContent.name;
                }
                contentTv.setText(content);
                imageView.setVisibility(View.GONE);
                contentTv.setVisibility(View.VISIBLE);
            }
        } else {
            imageView.setVisibility(View.GONE);
            contentTv.setVisibility(View.VISIBLE);
            contentTv.setText(String.format(context.getString(R.string.item_forward_count), messageContentList.size()));
        }
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setTitle(context.getString(R.string.send_to));

        builder.setView(view);
        builder.setPositiveButton(context.getString(R.string.sure), (dialog, which) -> iShowChatConfirm.onBack(list, messageContentList));
        builder.setNegativeButton(context.getString(R.string.cancel), (dialog, which) -> {

        });

        AlertDialog dialog = builder.create();
        dialog.setBlurParams(1f, true, true);
        dialog.show();
        TextView sureTv = (TextView) dialog.getButton(Dialog.BUTTON_POSITIVE);
        sureTv.setTextColor(ContextCompat.getColor(context, R.color.colorAccent));

    }
}
