package com.chat.uikit.chat.manager;

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.media.AudioAttributes;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.Parcelable;
import android.os.Vibrator;
import android.text.TextUtils;
import android.util.Log;

import com.chat.base.WKBaseApplication;
import com.chat.base.common.WKCommonModel;
import com.chat.base.config.WKConfig;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.db.ApplyDB;
import com.chat.base.endpoint.EndpointManager;
import com.chat.base.endpoint.entity.ChatViewMenu;
import com.chat.base.entity.NewFriendEntity;
import com.chat.base.entity.UserInfoEntity;
import com.chat.base.entity.UserInfoSetting;
import com.chat.base.msg.IConversationContext;
import com.chat.base.msgitem.WKContentType;
import com.chat.base.msgitem.WKUIChatMsgItemEntity;
import com.chat.base.ui.Theme;
import com.chat.base.ui.components.AvatarView;
import com.chat.base.utils.NotificationCompatUtil;
import com.chat.base.utils.WKCommonUtils;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.WKLogUtils;
import com.chat.base.utils.WKReader;
import com.chat.base.utils.WKTimeUtils;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.views.pwdview.NumPwdDialog;
import com.chat.uikit.R;
import com.chat.uikit.WKUIKitApplication;
import com.chat.uikit.chat.ChatActivity;
import com.chat.uikit.contacts.service.FriendModel;
import com.chat.uikit.db.WKContactsDB;
import com.chat.uikit.enity.ProhibitWord;
import com.chat.uikit.group.service.GroupModel;
import com.chat.uikit.message.MsgModel;
import com.chat.uikit.message.ProhibitWordModel;
import com.chat.uikit.search.SearchUserActivity;
import com.chat.uikit.user.UserDetailActivity;
import com.chat.uikit.utils.PushNotificationHelper;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKCMDKeys;
import com.xinbida.wukongim.entity.WKChannel;
import com.xinbida.wukongim.entity.WKChannelExtras;
import com.xinbida.wukongim.entity.WKChannelMember;
import com.xinbida.wukongim.entity.WKChannelType;
import com.xinbida.wukongim.entity.WKConversationMsg;
import com.xinbida.wukongim.entity.WKMsg;
import com.xinbida.wukongim.entity.WKUIConversationMsg;
import com.xinbida.wukongim.message.type.WKSendMsgResult;
import com.xinbida.wukongim.message.type.WKConnectStatus;
import com.xinbida.wukongim.msgmodel.WKTextContent;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

/**
 * 2019-11-18 11:30
 * im监听相关处理
 */
public class WKIMUtils {

    private WKIMUtils() {
    }

    private static class IMUtilsBinder {
        private final static WKIMUtils util = new WKIMUtils();
    }

    public static WKIMUtils getInstance() {
        return IMUtilsBinder.util;
    }

    /**
     * 初始化事件
     */
    public void initIMListener() {
        // 全局连接状态监听：连接成功或同步完成后，重发卡住的消息
        WKIM.getInstance().getConnectionManager().addOnConnectionStatusListener("global_retry", (status, reason) -> {
            if (status == WKConnectStatus.syncCompleted || status == WKConnectStatus.success) {
                WKSendMsgUtils.getInstance().retryStuckMessages();
            }
        });
        EndpointManager.getInstance().setMethod("show_rtc_notification", object -> {
            if (object instanceof String fromUID) {
                WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(fromUID, WKChannelType.PERSONAL);
                var fromName = "";
                if (channel != null) {
                    if (TextUtils.isEmpty(channel.channelRemark)) {
                        fromName = channel.channelName;
                    } else fromName = channel.channelRemark;
                }

                // 读取用户通知设置
                UserInfoSetting rtcSetting = WKConfig.getInstance().getUserInfo() != null
                        ? WKConfig.getInstance().getUserInfo().setting : null;
                boolean rtcVibrate = rtcSetting == null || rtcSetting.shock_on != 0;
                boolean rtcPlaySound = rtcSetting == null || rtcSetting.voice_on != 0;
                if (isInDoNotDisturbPeriod(rtcSetting)) {
                    rtcVibrate = false;
                    rtcPlaySound = false;
                }
                if (rtcVibrate) {
                    Vibrator mVibrator = (Vibrator) WKBaseApplication.getInstance().getContext().getSystemService(Context.VIBRATOR_SERVICE);
                    long[] pattern = {0, 1000, 1000};
                    AudioAttributes audioAttributes;
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        audioAttributes = new AudioAttributes.Builder()
                                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                .setUsage(AudioAttributes.USAGE_NOTIFICATION) //key
                                .build();
                        mVibrator.vibrate(pattern, 0, audioAttributes);
                    } else {
                        mVibrator.vibrate(pattern, 0);
                    }
                }
                PushNotificationHelper.INSTANCE.notifyCall(WKUIKitApplication.getInstance().getContext(), 2, fromName, WKBaseApplication.getInstance().getContext().getString(R.string.invite_call), rtcPlaySound, rtcVibrate);
            }
            return null;
        });
        EndpointManager.getInstance().setMethod("cancel_rtc_notification", object -> {
            Vibrator vibrator = (Vibrator) WKBaseApplication.getInstance().getContext().getSystemService(Context.VIBRATOR_SERVICE);
            vibrator.cancel();
            NotificationCompatUtil.Companion.cancel(WKUIKitApplication.getInstance().getContext(), 2);
            return null;
        });
        // 注册已读消息上报 endpoint
        EndpointManager.getInstance().setMethod("read_msg", object -> {
            if (object instanceof com.chat.base.endpoint.entity.ReadMsgMenu readMsgMenu) {
                MsgModel.getInstance().readMsg(readMsgMenu.channelID, readMsgMenu.channelType, readMsgMenu.msgIds, readMsgMenu.maxLargeMessageSeq);
            }
            return null;
        });
        // 获取用户密钥
//        WKIM.getInstance().getSignalProtocolManager().addOnCryptoSignalDataListener((channelID, channelTyp, iCryptoSignalDataResult) -> {
//            if (channelTyp == WKChannelType.PERSONAL) {
//                WKCryptoModel.getInstance().getUserKey(channelID, (code, msg, data) -> {
//                    if (code == HttpResponseCode.success && data != null) {
//                        WKSignalKey signalKey = new WKSignalKey();
//                        signalKey.UID = data.uid;
//                        signalKey.registrationID = data.registration_id;
//                        signalKey.identityKey = data.identity_key;
//                        signalKey.signedPubKey = data.signed_pubkey;
//                        signalKey.signedSignature = data.signed_signature;
//                        signalKey.signedPreKeyID = data.signed_prekey_id;
//                        WKOneTimePreKey oneTimePreKey = new WKOneTimePreKey();
//                        oneTimePreKey.pubKey = data.onetime_prekey.pubkey;
//                        oneTimePreKey.keyID = data.onetime_prekey.key_id;
//                        signalKey.oneTimePreKey = oneTimePreKey;
//                        iCryptoSignalDataResult.onResult(signalKey);
//                    } else {
//                        iCryptoSignalDataResult.onResult(null);
//                    }
//                });
//            }
//        });

        //监听sdk获取IP和port
        WKIM.getInstance().getConnectionManager().addOnGetIpAndPortListener(andPortListener -> MsgModel.getInstance().getChatIp((code, ip, port) -> {
            try {
                if (!TextUtils.isEmpty(ip) && !TextUtils.isEmpty(port)) {
                    andPortListener.onGetSocketIpAndPort(ip, Integer.parseInt(port));
                } else {
                    Log.e("WKIMUtils", "getChatIp empty ip=" + ip + " port=" + port + " code=" + code);
                }
            } catch (Exception e) {
                Log.e("WKIMUtils", "getChatIp parse exception: " + e.getMessage(), e);
            }
        }));
        //消息存库拦截器监听 - 确保消息永久持久化保存
        WKIM.getInstance().getMsgManager().addMessageStoreBeforeIntercept(msg -> {
            if (msg != null) {
                // 截图消息特殊处理：根据频道设置决定是否保存
                if (msg.type == WKContentType.screenshot) {
                    WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(msg.channelID, msg.channelType);
                    if (channel != null && channel.remoteExtraMap != null && channel.remoteExtraMap.containsKey(WKChannelExtras.screenshot)) {
                        Object object = channel.remoteExtraMap.get(WKChannelExtras.screenshot);
                        int screenshot = 0;
                        if (object != null) {
                            screenshot = (int) object;
                        }
                        boolean shouldPersist = screenshot != 0;
                        android.util.Log.d("ChatHistoryFix", "storeIntercept: screenshot msg, shouldPersist=" + shouldPersist
                                + " channel=" + msg.channelID + " type=" + msg.type);
                        return shouldPersist;
                    } else {
                        return true;
                    }
                }
                // 确保所有其他类型的消息都持久化保存（除非明确标记了noPersist）
                if (msg.header != null && msg.header.noPersist) {
                    android.util.Log.d("ChatHistoryFix", "storeIntercept: msg marked noPersist, skip saving. clientMsgNo=" + msg.clientMsgNO + " type=" + msg.type);
                }
            }
            return true;
        });
        //监听聊天附件上传
        WKIM.getInstance().getMsgManager().addOnUploadAttachListener((msg, listener) -> WKSendMsgUtils.getInstance().uploadChatAttachment(msg, listener));
        //监听同步会话 - 全量同步历史消息（确保同步到最早的消息：加好友/进群时的第一条消息）
        WKIM.getInstance().getConversationManager().addOnSyncConversationListener((s, i, l, iSyncConvChatBack) -> {
            // 大幅增加同步消息数量，确保历史消息完整同步
            // 单聊同步到加好友的第一条消息，群聊同步到进群时的第一条消息
            int syncMsgCount = Math.max(i, 1000);
            android.util.Log.d("ChatHistoryFix", "syncChat: original msg_count=" + i + ", adjusted to=" + syncMsgCount);
            MsgModel.getInstance().syncChat(s, syncMsgCount, l, iSyncConvChatBack);
        });
        //监听同步频道会话 - 增大单频道消息同步数量，支持全量拉取历史消息
        WKIM.getInstance().getMsgManager().addOnSyncChannelMsgListener((channelID, channelType, startMessageSeq, endMessageSeq, limit, pullMode, iSyncChannelMsgBack) -> {
            // 增大同步消息数量限制，确保能拉取完整历史记录
            int syncLimit = Math.max(limit, 200);
            android.util.Log.d("ChatHistoryFix", "syncChannelMsg: channel=" + channelID + " original limit=" + limit + ", adjusted to=" + syncLimit + " pullMode=" + pullMode);
            MsgModel.getInstance().syncChannelMsg(channelID, channelType, startMessageSeq, endMessageSeq, syncLimit, pullMode, iSyncChannelMsgBack);
        });
        //新消息监听
        WKIM.getInstance().getMsgManager().addOnNewMsgListener("system", msgList -> {
            boolean isAlertMsg = false;
            String channelID = "";
            byte channelType = WKChannelType.PERSONAL;
            WKMsg sensitiveWordsMsg = null;
            String loginUID = WKConfig.getInstance().getUid();
            // 添加日志：追踪新消息接收
            if (WKReader.isNotEmpty(msgList)) {
                android.util.Log.d("ChatHistoryFix", "onNewMsg: received " + msgList.size() + " new messages, channel=" + msgList.get(0).channelID);
            }
            if (WKReader.isNotEmpty(msgList)) {
                channelID = msgList.get(msgList.size() - 1).channelID;
                channelType = msgList.get(msgList.size() - 1).channelType;
                for (int i = 0, size = msgList.size(); i < size; i++) {
                    if (msgList.get(i).type == WKContentType.setNewGroupAdmin) {
                        GroupModel.getInstance().groupMembersSync(msgList.get(i).channelID, null);
                    } else if (msgList.get(i).type == WKContentType.groupSystemInfo) {
                        WKCommonModel.getInstance().getChannel(msgList.get(i).channelID, WKChannelType.GROUP, null);
                        GroupModel.getInstance().groupMembersSync(msgList.get(i).channelID, null);
                    } else if (msgList.get(i).type == WKContentType.addGroupMembersMsg || msgList.get(i).type == WKContentType.removeGroupMembersMsg) {
                        //同步信息
                        GroupModel.getInstance().groupMembersSync(msgList.get(i).channelID, null);
                    } else if (msgList.get(i).type == WKContentType.approveGroupMember) {
                        // 入群审核消息
                        try {
                            String jsonStr = msgList.get(i).content;
                            GroupModel.getInstance().saveGroupApplyMsg(jsonStr);
                        } catch (Exception e) {
                            WKLogUtils.e("处理入群申请消息错误: " + e.getMessage());
                        }
                    } else if (msgList.get(i).type == com.chat.base.msgitem.WKRTCType.wk_video_call_received) {
                        // RTC 通话信令消息
                        handleRTCSignal(msgList.get(i));
                    } else {
                        if (msgList.get(i).type != WKContentType.WK_INSIDE_MSG) {
                            isAlertMsg = true;
                        }
                    }

                    if (msgList.get(i).header.noPersist || !msgList.get(i).header.redDot || !WKContentType.isSupportNotification(msgList.get(i).type)) {
                        isAlertMsg = false;
                    }
                    if (!TextUtils.isEmpty(loginUID) && !TextUtils.isEmpty(msgList.get(i).fromUID) && msgList.get(i).fromUID.equals(loginUID)) {
                        isAlertMsg = false;
                    }
                    if (msgList.get(i).type == WKContentType.WK_TEXT) {
                        boolean isContains = false;
                        WKTextContent textContent = (WKTextContent) msgList.get(i).baseContentMsgModel;
                        // 判断是否包含敏感词
                        if (WKUIKitApplication.getInstance().sensitiveWords != null
                                && WKReader.isNotEmpty(WKUIKitApplication.getInstance().sensitiveWords.list)
                                && textContent != null && !TextUtils.isEmpty(textContent.getDisplayContent())) {
                            for (String word : WKUIKitApplication.getInstance().sensitiveWords.list) {
                                if (textContent.getDisplayContent().contains(word)) {
                                    isContains = true;
                                    break;
                                }
                            }
                        }
                        if (isContains) {
                            sensitiveWordsMsg = new WKMsg();
                            sensitiveWordsMsg.channelID = msgList.get(i).channelID;
                            sensitiveWordsMsg.channelType = msgList.get(i).channelType;
                            JSONObject jsonObject = new JSONObject();
                            try {
                                jsonObject.put("content", WKUIKitApplication.getInstance().sensitiveWords.tips);
                                jsonObject.put("type", WKContentType.sensitiveWordsTips);
                            } catch (JSONException e) {
                                WKLogUtils.e("解析敏感词错误");
                            }
                            WKChannel channel = new WKChannel(msgList.get(i).channelID, msgList.get(i).channelType);
                            sensitiveWordsMsg.setChannelInfo(channel);
                            sensitiveWordsMsg.content = jsonObject.toString();
                            sensitiveWordsMsg.type = WKContentType.sensitiveWordsTips;
                            long tempOrderSeq = WKIM.getInstance().getMsgManager().getMessageOrderSeq(0, msgList.get(i).channelID, msgList.get(i).channelType);
                            sensitiveWordsMsg.orderSeq = tempOrderSeq + 1;
                            sensitiveWordsMsg.status = WKSendMsgResult.send_success;

                        }
                    }
                }
            }
            boolean isVibrate = true;
            boolean playNewMsgMedia = true;
            boolean newMsgNotice = true;
            UserInfoSetting setting = WKConfig.getInstance().getUserInfo() != null
                    ? WKConfig.getInstance().getUserInfo().setting : null;
            int msgShowDetail = 1;
            if (setting != null) {
                msgShowDetail = setting.msg_show_detail;
                if (setting.new_msg_notice == 0) {
                    newMsgNotice = false;
                    playNewMsgMedia = false;
                    isVibrate = false;
                } else {
                    if (setting.voice_on == 0) {
                        playNewMsgMedia = false;
                    }
                    if (setting.shock_on == 0) {
                        isVibrate = false;
                    }
                }
            }
            // 免打扰时段：静音并取消震动，但仍显示通知
            if (isInDoNotDisturbPeriod(setting)) {
                playNewMsgMedia = false;
                isVibrate = false;
            }
            if (newMsgNotice && isAlertMsg && (TextUtils.isEmpty(WKUIKitApplication.getInstance().chattingChannelID) || !WKUIKitApplication.getInstance().chattingChannelID.equals(channelID))) {
                WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(channelID, channelType);
                android.util.Log.d("WKBadgeDebug", "newMsg: newMsgNotice=" + newMsgNotice + ", isAlertMsg=" + isAlertMsg
                        + ", chattingChannelID=" + WKUIKitApplication.getInstance().chattingChannelID
                        + ", msgChannelID=" + channelID
                        + ", channel=" + (channel != null) + (channel != null ? ", mute=" + channel.mute : ""));
                if (channel != null && channel.mute == 0) {
                    showNotification(msgList.get(msgList.size() - 1), msgShowDetail, channel, playNewMsgMedia, isVibrate);
                }
            }

            if (sensitiveWordsMsg != null) {
                WKMsg finalSensitiveWordsMsg = sensitiveWordsMsg;
                new Handler(Objects.requireNonNull(Looper.myLooper())).postDelayed(() -> WKIM.getInstance().getMsgManager().saveAndUpdateConversationMsg(finalSensitiveWordsMsg, false), 1000 * 2);
            }
        });
        WKIM.getInstance().getMsgManager().addOnUploadMsgExtraListener(msgExtra -> {
            WKMsg msg = WKIM.getInstance().getMsgManager().getWithMessageID(msgExtra.messageID);
            int msgSeq = 0;
            if (msg != null) {
                msgSeq = msg.messageSeq;
            }
            MsgModel.getInstance().editMsg(msgExtra.messageID, msgSeq, msgExtra.channelID, msgExtra.channelType, msgExtra.contentEdit, null);
        });

        /*
         * 设置获取频道信息的监听
         */
        WKIM.getInstance().getChannelManager().addOnGetChannelInfoListener((channelId, channelType, iChannelInfoListener) -> {
            WKCommonModel.getInstance().getChannel(channelId, channelType, null);
            return null;
        });
        WKIM.getInstance().getChannelMembersManager().addOnGetChannelMembersListener((channelID, b, keyword, page, limit, iChannelMemberListResult) -> GroupModel.getInstance().getChannelMembers(channelID, keyword, page, limit, iChannelMemberListResult));
        /*
         * 获取频道成员
         */
        WKIM.getInstance().getChannelMembersManager().addOnGetChannelMemberListener((channelId, channelType, uid, iChannelMemberInfoListener) -> {
            WKCommonModel.getInstance().getChannel(uid, WKChannelType.PERSONAL, (code, msg, entity) -> {
                WKChannelMember channelMember = new WKChannelMember();
                channelMember.memberName = entity.name;
                channelMember.memberUID = entity.channel.channel_id;
                channelMember.channelID = channelId;
                channelMember.channelType = channelType;
                WKIM.getInstance().getChannelMembersManager().refreshChannelMemberCache(channelMember);
                iChannelMemberInfoListener.onResult(channelMember);
            });
            return null;
        });

        //监听频道修改头像
        WKIM.getInstance().getChannelManager().addOnRefreshChannelAvatar((s, b) -> {
            // 头像需要本地修改
            String key = UUID.randomUUID().toString().replace("-", "");
            AvatarView.clearCache(s, b);
            WKIM.getInstance().getChannelManager().updateAvatarCacheKey(s, b, key);
        });
        //刷新群成员
        WKIM.getInstance().getChannelMembersManager().addOnSyncChannelMembers((channelID, channelType) -> {
            if (!TextUtils.isEmpty(channelID) && channelType == WKChannelType.GROUP) {
                GroupModel.getInstance().groupMembersSync(channelID, null);
            }
        });

        WKIM.getInstance().getCMDManager().addCmdListener("system", cmd -> {
            if (!TextUtils.isEmpty(cmd.cmdKey)) {
                switch (cmd.cmdKey) {
                    case WKCMDKeys.wk_messageRevoke -> revokeMsg(cmd.paramJsonObject);
                    case WKCMDKeys.wk_friendRequest ->
                            FriendModel.getInstance().saveNewFriendsMsg(cmd.paramJsonObject.toString());
                    case WKCMDKeys.wk_friendDeleted, WKCMDKeys.wk_friendAccept -> {
                        FriendModel.getInstance().syncFriends(null);
                        if (cmd.cmdKey.equals(WKCMDKeys.wk_friendAccept)
                                && cmd.paramJsonObject != null && cmd.paramJsonObject.has("to_uid")) {
                            String uid = cmd.paramJsonObject.optString("to_uid");
                            WKContactsDB.getInstance().updateFriendStatus(uid, 1);
                            NewFriendEntity entity = ApplyDB.getInstance().query(uid);
                            if (entity != null && entity.status == 0) {
                                entity.status = 1;
                                ApplyDB.getInstance().update(entity);
                            }
                        }
                    }
                    case WKCMDKeys.wk_sync_message_extra -> {
                        if (cmd.paramJsonObject == null) {
                            return;
                        }
                        String channelID = cmd.paramJsonObject.optString("channel_id");
                        byte channelType = (byte) cmd.paramJsonObject.optInt("channel_type");
                        if (TextUtils.isEmpty(channelID)) {
                            return;
                        }
                        MsgModel.getInstance().syncExtraMsg(channelID, channelType);
                    }
                    case WKCMDKeys.wk_sync_reminders -> MsgModel.getInstance().syncReminder();
                    case WKCMDKeys.wk_sync_conversation_extra -> MsgModel.getInstance().syncCoverExtra();
                }
            }
        });
    }

    public WKUIChatMsgItemEntity msg2UiMsg(IConversationContext context, WKMsg msg, int memberCount, boolean showNickName, boolean isChoose) {
        if (msg.remoteExtra.readedCount == 0) {
            msg.remoteExtra.unreadCount = memberCount - 1;
        }
        if (msg.type == WKContentType.WK_TEXT) {
//            WKTextContent textContent = (WKTextContent) msg.baseContentMsgModel;
//            if (textContent != null && !TextUtils.isEmpty(textContent.getDisplayContent())) {
//                List<String> urls = StringUtils.getStrUrls(textContent.getDisplayContent());
//                if (urls.size() > 0) {
//                    String url = urls.get(urls.size() - 1);
//                    String contentJson = WKSharedPreferencesUtil.getInstance().getSP(url);
//                    if (!TextUtils.isEmpty(contentJson)) {
//                        try {
//                            JSONObject jsonObject = new JSONObject(contentJson);
//                            long expirationTime = jsonObject.optLong("expirationTime");
//                            long tempTime = WKTimeUtils.getInstance().getCurrentSeconds() - expirationTime;
//                            if (tempTime >= 60 * 60 * 24 * 360) {
//                                WKJsoupUtils.getInstance().getURLContent(url, msg.clientMsgNO);
//                            }
//                        } catch (JSONException e) {
//                            e.printStackTrace();
//                        }
//                    } else {
//                        WKJsoupUtils.getInstance().getURLContent(url, msg.clientMsgNO);
//                    }
//                }
//
//            }
            resetMsgProhibitWord(msg);
        }
        WKUIChatMsgItemEntity uiChatMsgItemEntity = new WKUIChatMsgItemEntity(context, msg, new WKUIChatMsgItemEntity.ILinkClick() {
            @Override
            public void onShowUserDetail(String uid, String groupNo) {
                Intent intent = new Intent(context.getChatActivity(), UserDetailActivity.class);
                intent.putExtra("uid", uid);
                if (!TextUtils.isEmpty(groupNo)) {
                    intent.putExtra("groupID", groupNo);
                }
                context.getChatActivity().startActivity(intent);
            }

            @Override
            public void onShowSearchUser(String phone) {
                Intent intent = new Intent(context.getChatActivity(), SearchUserActivity.class);
                intent.putExtra("phone", phone);
                context.getChatActivity().startActivity(intent);
            }
        });
        uiChatMsgItemEntity.wkMsg = msg;
        uiChatMsgItemEntity.isChoose = isChoose;
        uiChatMsgItemEntity.showNickName = showNickName;

        // 计算气泡类型
        return uiChatMsgItemEntity;
    }

    public void resetMsgProhibitWord(WKMsg msg) {
        if (msg == null || msg.type != WKContentType.WK_TEXT) {
            return;
        }
        List<ProhibitWord> list = ProhibitWordModel.Companion.getInstance().getAll();
        if (WKReader.isNotEmpty(list)) {
            String content = getContent(msg);
            for (ProhibitWord word : list) {
                if (content.contains(word.content)) {
                    StringBuilder sb = new StringBuilder();
                    for (int i = 0; i < word.content.length(); i++) {
                        sb.append("*");
                    }
                    content = content.replaceAll(word.content, sb.toString());
                }
            }

            if (msg.remoteExtra.contentEditMsgModel != null && !TextUtils.isEmpty(msg.remoteExtra.contentEditMsgModel.getDisplayContent())) {
                msg.remoteExtra.contentEditMsgModel.content = content;
            } else {
                msg.baseContentMsgModel.content = content;
            }
        }
    }

    private String getContent(WKMsg msg) {
        String showContent = msg.baseContentMsgModel.getDisplayContent();
        if (msg.remoteExtra.contentEditMsgModel != null && !TextUtils.isEmpty(msg.remoteExtra.contentEditMsgModel.getDisplayContent())) {
            showContent = msg.remoteExtra.contentEditMsgModel.getDisplayContent();
        }
        return showContent;
    }


    public void revokeMsg(JSONObject jsonObject) {
        //撤回消息
        if (jsonObject != null) {
            if (jsonObject.has("message_id")) {
                String messageId = jsonObject.optString("message_id");
                //  String client_msg_no = jsonObject.optString("client_msg_no");
                String channelID = jsonObject.optString("channel_id");
                byte channelType = (byte) jsonObject.optInt("channel_type");
                WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(channelID, channelType);
                //是否撤回提醒
                int revokeRemind = 0;
                if (channel != null && channel.remoteExtraMap != null && channel.remoteExtraMap.containsKey(WKChannelExtras.revokeRemind)) {
                    Object object = channel.remoteExtraMap.get(WKChannelExtras.revokeRemind);
                    if (object != null) {
                        revokeRemind = (int) object;
                    }
                }
                // 始终显示撤回通知
                MsgModel.getInstance().syncExtraMsg(channelID, channelType);

            }
        }
    }


    /**
     * 显示聊天
     *
     * @param chatViewMenu 参数
     */
    public void startChatActivity(ChatViewMenu chatViewMenu) {
        if (chatViewMenu == null || chatViewMenu.activity == null || TextUtils.isEmpty(chatViewMenu.channelID)) {
            return;
        }
        WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(chatViewMenu.channelID, chatViewMenu.channelType);
        int chatPwdON = 0;
        if (channel != null && channel.remoteExtraMap != null && channel.remoteExtraMap.containsKey(WKChannelExtras.chatPwdOn)) {
            Object object = channel.remoteExtraMap.get(WKChannelExtras.chatPwdOn);
            if (object instanceof Integer) {
                chatPwdON = (int) object;
            }
        }
        if (chatPwdON == 1) {
            showChatPwdDialog(chatViewMenu, channel);
            return;
        }
        startChat(chatViewMenu);
    }

    private void startChat(ChatViewMenu chatViewMenu) {
        if (WKTimeUtils.isFastDoubleClick()) {
            return;
        }
        MsgModel.getInstance().deleteFlameMsg();
        Intent intent = new Intent(chatViewMenu.activity, ChatActivity.class);
        intent.putExtra("channelId", chatViewMenu.channelID);
        intent.putExtra("channelType", chatViewMenu.channelType);
        WKConversationMsg conversationMsg = WKIM.getInstance().getConversationManager().getWithChannel(chatViewMenu.channelID, chatViewMenu.channelType);
        WKMsg msg = null;
        int redDot = 0;
        long aroundMsgSeq = 0;
        if (conversationMsg != null) {
            redDot = conversationMsg.unreadCount;
            msg = WKIM.getInstance().getMsgManager().getWithClientMsgNO(conversationMsg.lastClientMsgNO);
            if (msg != null) {
                aroundMsgSeq = msg.orderSeq;
            }
        }
        if (chatViewMenu.tipMsgOrderSeq != 0) {
            // 强提醒某条消息
            intent.putExtra("tipsOrderSeq", chatViewMenu.tipMsgOrderSeq);
        } else {
            if (redDot > 0) {
                long orderSeq;
                int messageSeq = 0;
                if (msg != null) {
                    if (msg.messageSeq == 0) {
                        int maxMsgSeq = WKIM.getInstance().getMsgManager().getMaxMessageSeqWithChannel(chatViewMenu.channelID, chatViewMenu.channelType);
                        messageSeq = maxMsgSeq - redDot + 1;
                    } else {
                        messageSeq = msg.messageSeq - redDot + 1;
                    }
                    if (messageSeq <= 0) {
                        messageSeq = WKIM.getInstance().getMsgManager().getMinMessageSeqWithChannel(chatViewMenu.channelID, chatViewMenu.channelType);
                    }
                }
                orderSeq = WKIM.getInstance().getMsgManager().getMessageOrderSeq(messageSeq, chatViewMenu.channelID, chatViewMenu.channelType);
                intent.putExtra("unreadStartMsgOrderSeq", orderSeq);
                intent.putExtra("redDot", redDot);
            } else {
                WKUIConversationMsg uiMsg = WKIM.getInstance().getConversationManager().getUIConversationMsg(chatViewMenu.channelID, chatViewMenu.channelType);
                if (uiMsg != null && uiMsg.getRemoteMsgExtra() != null && uiMsg.getRemoteMsgExtra().keepMessageSeq != 0) {
                    long lastPreviewMsgOrderSeq = WKIM.getInstance().getMsgManager().getMessageOrderSeq(uiMsg.getRemoteMsgExtra().keepMessageSeq, chatViewMenu.channelID, chatViewMenu.channelType);
                    intent.putExtra("lastPreviewMsgOrderSeq", lastPreviewMsgOrderSeq);
                    intent.putExtra("keepOffsetY", uiMsg.getRemoteMsgExtra().keepOffsetY);
                }
            }
        }
        if (chatViewMenu.isNewTask) {
            intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        }
        if (WKReader.isNotEmpty(chatViewMenu.forwardMsgList)) {
            intent.putParcelableArrayListExtra("msgContentList", (ArrayList<? extends Parcelable>) chatViewMenu.forwardMsgList);
        }
        intent.putExtra("aroundMsgSeq", aroundMsgSeq);
        chatViewMenu.activity.startActivity(intent);
    }

    private void showChatPwdDialog(ChatViewMenu chatViewMenu, WKChannel channel) {
        NumPwdDialog.getInstance().showNumPwdDialog(chatViewMenu.activity, chatViewMenu.activity.getString(R.string.chat_pwd), chatViewMenu.activity.getString(R.string.input_chat_pwd), channel.channelName, new NumPwdDialog.IPwdInputResult() {
            @Override
            public void onResult(String numPwd) {

                String chatPwd = WKConfig.getInstance().getUserInfo() != null ? WKConfig.getInstance().getUserInfo().chat_pwd : null;
                if (chatPwd == null || !WKCommonUtils.digest(numPwd + WKConfig.getInstance().getUid()).equals(chatPwd)) {
                    int chatPwdCount = WKSharedPreferencesUtil.getInstance().getInt("wk_chat_pwd_count", 3);
                    if (chatPwdCount == 0) {
                        // 清空聊天记录
                        WKSharedPreferencesUtil.getInstance().putInt("wk_chat_pwd_count", 0);
                        WKIM.getInstance().getMsgManager().clearWithChannel(channel.channelID, channel.channelType);
                        WKToastUtils.getInstance().showToastNormal(chatViewMenu.activity.getString(R.string.chat_msg_is_cleard));
                        return;
                    }

                    String content = String.format(chatViewMenu.activity.getString(R.string.forget_chat_pwd), chatPwdCount, chatPwdCount);
                    WKDialogUtils.getInstance().showDialog(chatViewMenu.activity, chatViewMenu.activity.getString(R.string.chat_pwd_error), content, false, chatViewMenu.activity.getString(R.string.cancel), chatViewMenu.activity.getString(R.string.chat_pwd_reset_pwd), 0, Theme.colorAccount, index -> {
                        if (index == 1) {
                            EndpointManager.getInstance().invoke("show_set_chat_pwd", null);
                        }
                    });
                    WKSharedPreferencesUtil.getInstance().putInt("wk_chat_pwd_count", --chatPwdCount);
                } else {
                    WKSharedPreferencesUtil.getInstance().putInt("wk_chat_pwd_count", 3);
                    startChat(chatViewMenu);
                }

            }

            @Override
            public void forgetPwd() {
                EndpointManager.getInstance().invoke("show_set_chat_pwd", null);
            }
        });

    }

    /**
     * 判断当前时间是否在免打扰时段内
     */
    private boolean isInDoNotDisturbPeriod(UserInfoSetting setting) {
        if (setting == null || setting.dnd_on != 1) {
            return false;
        }
        String start = setting.dnd_start;
        String end = setting.dnd_end;
        if (TextUtils.isEmpty(start) || TextUtils.isEmpty(end)) {
            return false;
        }
        try {
            java.util.Calendar now = java.util.Calendar.getInstance();
            int currentMinutes = now.get(java.util.Calendar.HOUR_OF_DAY) * 60 + now.get(java.util.Calendar.MINUTE);
            String[] startParts = start.split(":");
            String[] endParts = end.split(":");
            int startMinutes = Integer.parseInt(startParts[0]) * 60 + Integer.parseInt(startParts[1]);
            int endMinutes = Integer.parseInt(endParts[0]) * 60 + Integer.parseInt(endParts[1]);
            if (startMinutes == endMinutes) {
                return false;
            }
            if (startMinutes < endMinutes) {
                // 同一天内，如 08:00 - 22:00
                return currentMinutes >= startMinutes && currentMinutes < endMinutes;
            } else {
                // 跨天，如 22:00 - 08:00
                return currentMinutes >= startMinutes || currentMinutes < endMinutes;
            }
        } catch (Exception e) {
            Log.e("WKIMUtils", "免打扰时段解析失败", e);
            return false;
        }
    }

    /**
     * 处理 RTC 通话信令消息
     */
    private void handleRTCSignal(WKMsg msg) {
        if (msg == null || msg.baseContentMsgModel == null) {
            return;
        }
        if (!(msg.baseContentMsgModel instanceof com.chat.uikit.trtc.RTCSignalContent)) {
            return;
        }
        com.chat.uikit.trtc.RTCSignalContent signalContent = (com.chat.uikit.trtc.RTCSignalContent) msg.baseContentMsgModel;
        String loginUID = WKConfig.getInstance().getUid();
        // 如果是自己发的，不处理
        if (msg.fromUID != null && msg.fromUID.equals(loginUID)) {
            return;
        }
        int signalType = signalContent.signalType;
        String fromUID = msg.fromUID;
        Log.e("WKIMUtils", "handleRTCSignal: signalType=" + signalType + ", fromUID=" + fromUID);
        String callerName = signalContent.callerName;
        if (callerName == null || callerName.isEmpty()) {
            WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(fromUID, WKChannelType.PERSONAL);
            if (channel != null) {
                if (!TextUtils.isEmpty(channel.channelRemark)) {
                    callerName = channel.channelRemark;
                } else {
                    callerName = channel.channelName;
                }
            }
            if (callerName == null || callerName.isEmpty()) {
                callerName = fromUID;
            }
        }
        int roomId = signalContent.roomId;
        int callType = signalContent.callType;

        if (signalType == com.chat.uikit.trtc.RTCSignalContent.SIGNAL_INVITE) {
            // 检查是否正在通话中，忙线则直接回复
            if (com.chat.uikit.trtc.TRTCCallActivity.getInstance() != null) {
                Log.e("WKIMUtils", "handleRTCSignal: busy, reply busy signal");
                // 回复忙线信令
                com.chat.uikit.trtc.RTCSignalContent busyContent = new com.chat.uikit.trtc.RTCSignalContent();
                busyContent.signalType = com.chat.uikit.trtc.RTCSignalContent.SIGNAL_BUSY;
                busyContent.callType = callType;
                busyContent.roomId = roomId;
                busyContent.callerId = loginUID;
                WKIM.getInstance().getMsgManager().sendMessage(busyContent, fromUID, WKChannelType.PERSONAL);
                // 发送忙线通话记录消息（utalk逻辑：由被叫方发送）
                com.chat.uikit.trtc.RTCMsgContent busyMsgContent = new com.chat.uikit.trtc.RTCMsgContent(callType, com.chat.uikit.trtc.RTCMsgContent.RESULT_BUSY, 0);
                WKIM.getInstance().getMsgManager().sendMessage(busyMsgContent, fromUID, WKChannelType.PERSONAL);
                return;
            }
            // 收到通话邀请，启动接听页面
            int sdkAppId = 1600159338;
            String secretKey = "b3132bc984dcaefdb93179dc33cc950a3ca184d03d0e32d4c2c99a73e7220b98";
            String userSig = com.chat.base.trtc.UserSigGenerator.genUserSig(sdkAppId, loginUID, secretKey);

            Intent intent = new Intent(WKBaseApplication.getInstance().getContext(), com.chat.uikit.trtc.WaitingAnswerActivity.class);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            intent.putExtra(com.chat.uikit.trtc.WaitingAnswerActivity.KEY_CALLER_ID, fromUID);
            intent.putExtra(com.chat.uikit.trtc.WaitingAnswerActivity.KEY_CALLER_NAME, callerName);
            intent.putExtra(com.chat.uikit.trtc.WaitingAnswerActivity.KEY_ROOM_ID, roomId);
            intent.putExtra(com.chat.uikit.trtc.WaitingAnswerActivity.KEY_CALL_TYPE, callType);
            intent.putExtra(com.chat.uikit.trtc.WaitingAnswerActivity.KEY_SDK_APP_ID, sdkAppId);
            intent.putExtra(com.chat.uikit.trtc.WaitingAnswerActivity.KEY_USER_SIG, userSig);
            intent.putExtra(com.chat.uikit.trtc.WaitingAnswerActivity.KEY_IS_VIDEO, callType == com.chat.base.trtc.TRTCType.VIDEO_CALL);
            WKBaseApplication.getInstance().getContext().startActivity(intent);

            // 读取用户通知设置
            UserInfoSetting callSetting = WKConfig.getInstance().getUserInfo() != null
                    ? WKConfig.getInstance().getUserInfo().setting : null;
            boolean callVibrate = callSetting == null || callSetting.shock_on != 0;
            boolean callPlaySound = callSetting == null || callSetting.voice_on != 0;
            // 免打扰时段检查
            if (isInDoNotDisturbPeriod(callSetting)) {
                callVibrate = false;
                callPlaySound = false;
            }
            // 注意：震动和铃声由 WaitingAnswerActivity 页面自行处理（更可靠）
            // 此处仅显示通知作为备用（页面无法启动时用户仍可通过通知接听）
            // 显示通知（尊重用户声音设置和免打扰时段）
            PushNotificationHelper.INSTANCE.notifyCall(
                    WKUIKitApplication.getInstance().getContext(),
                    2,
                    callerName,
                    WKBaseApplication.getInstance().getContext().getString(R.string.invite_call),
                    callPlaySound,
                    callVibrate
            );
        } else if (signalType == com.chat.uikit.trtc.RTCSignalContent.SIGNAL_CANCEL) {
            // 对方取消了通话，关闭接听页面
            NotificationCompatUtil.Companion.cancel(WKUIKitApplication.getInstance().getContext(), 2);
            Vibrator vibrator = (Vibrator) WKBaseApplication.getInstance().getContext().getSystemService(Context.VIBRATOR_SERVICE);
            vibrator.cancel();
            // 直接通知 WaitingAnswerActivity 关闭
            com.chat.uikit.trtc.WaitingAnswerActivity.notifyCancel();
        } else if (signalType == com.chat.uikit.trtc.RTCSignalContent.SIGNAL_REFUSE) {
            // 对方拒绝了通话，通知通话页面
            com.chat.uikit.trtc.TRTCCallActivity.notifySignal(com.chat.uikit.trtc.RTCSignalContent.SIGNAL_REFUSE);
        } else if (signalType == com.chat.uikit.trtc.RTCSignalContent.SIGNAL_ACCEPT) {
            // 对方接听了，通知通话页面
            com.chat.uikit.trtc.TRTCCallActivity.notifySignal(com.chat.uikit.trtc.RTCSignalContent.SIGNAL_ACCEPT);
        } else if (signalType == com.chat.uikit.trtc.RTCSignalContent.SIGNAL_HANGUP) {
            // 对方挂断了，通知通话页面
            com.chat.uikit.trtc.TRTCCallActivity.notifySignal(com.chat.uikit.trtc.RTCSignalContent.SIGNAL_HANGUP);
        } else if (signalType == com.chat.uikit.trtc.RTCSignalContent.SIGNAL_BUSY) {
            // 对方忙线中，通知通话页面
            com.chat.uikit.trtc.TRTCCallActivity.notifySignal(com.chat.uikit.trtc.RTCSignalContent.SIGNAL_BUSY);
        }
    }

    private void showNotification(WKMsg msg, int msgShowDetail, WKChannel channel, boolean playNewMsgMedia, boolean isVibrate) {
        UserInfoEntity userInfo = WKConfig.getInstance().getUserInfo();
        int msgNotice = (userInfo != null && userInfo.setting != null) ? userInfo.setting.new_msg_notice : 1;
        android.util.Log.d("WKBadgeDebug", "showNotification: msgNotice=" + msgNotice
                + ", playNewMsgMedia=" + playNewMsgMedia + ", isVibrate=" + isVibrate
                + ", channel=" + channel.channelID + ", msgShowDetail=" + msgShowDetail);
        if (msgNotice == 0) {
            android.util.Log.d("WKBadgeDebug", "showNotification: skipped because msgNotice==0");
            return;
        }
        if (playNewMsgMedia) {
            defaultMediaPlayer();
        }
        if (isVibrate) {
            vibrate();
        }
        String showTitle = TextUtils.isEmpty(channel.channelRemark) ? channel.channelName : channel.channelRemark;
        String showContent = WKBaseApplication.getInstance().getContext().getString(R.string.default_new_msg);
        if (msgShowDetail == 1 && msg.baseContentMsgModel != null && !TextUtils.isEmpty(msg.baseContentMsgModel.getDisplayContent())) {
            showContent = msg.baseContentMsgModel.getDisplayContent();
        }
        // 使用频道ID的hashCode作为通知ID，确保不同频道的消息都能发出声音提示
        // 同时传入总未读数作为角标数量
        int notifyId = Math.abs((channel.channelID + "_" + channel.channelType).hashCode());
        int badgeCount = WKUIKitApplication.getInstance().getTotalMsgCount() + 1;
        android.util.Log.d("WKBadgeDebug", "showNotification: calling notifyMessage, notifyId=" + notifyId + ", badgeCount=" + badgeCount + ", title=" + showTitle);
        PushNotificationHelper.INSTANCE.notifyMessage(
                WKUIKitApplication.getInstance().getContext(),
                notifyId,
                showTitle,
                showContent,
                badgeCount
        );
    }


    private void defaultMediaPlayer() {
        EndpointManager.getInstance().invoke("play_new_msg_Media", null);
    }

    private void vibrate() {
        Vibrator vibrator = (Vibrator) WKUIKitApplication.getInstance().getContext().getSystemService(Service.VIBRATOR_SERVICE);
        long[] pattern = {100, 200};
        vibrator.vibrate(pattern, -1);
    }

    public void removeListener() {
        WKIM.getInstance().getCMDManager().removeCmdListener("system");
        WKIM.getInstance().getMsgManager().removeNewMsgListener("system");
    }


}
