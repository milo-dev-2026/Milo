package com.chat.uikit.message;

import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;

import androidx.annotation.Nullable;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.chat.base.base.WKBaseModel;
import com.chat.base.config.WKApiConfig;
import com.chat.base.config.WKConfig;
import com.chat.base.config.WKConstants;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.db.WKBaseCMD;
import com.chat.base.db.WKBaseCMDManager;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.net.ICommonListener;
import com.chat.base.net.IRequestResultListener;
import com.chat.base.net.entity.CommonResponse;
import com.chat.base.net.ud.WKDownloader;
import com.chat.base.net.ud.WKProgressManager;
import com.chat.base.net.ud.WKUploader;
import com.chat.base.utils.WKLogUtils;
import com.chat.base.utils.WKReader;
import com.chat.base.utils.WKTimeUtils;
import com.chat.uikit.WKUIKitApplication;
import com.chat.uikit.enity.SensitiveWords;
import com.chat.uikit.enity.WKSyncReminder;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannel;
import com.xinbida.wukongim.entity.WKChannelType;
import com.xinbida.wukongim.entity.WKConversationMsg;
import com.xinbida.wukongim.entity.WKConversationMsgExtra;
import com.xinbida.wukongim.entity.WKMsg;
import com.xinbida.wukongim.entity.WKReminder;
import com.xinbida.wukongim.entity.WKSyncChannelMsg;
import com.xinbida.wukongim.entity.WKSyncChat;
import com.xinbida.wukongim.entity.WKSyncConvMsgExtra;
import com.xinbida.wukongim.entity.WKSyncExtraMsg;
import com.xinbida.wukongim.entity.WKSyncMsg;
import com.xinbida.wukongim.interfaces.ISyncChannelMsgBack;
import com.xinbida.wukongim.interfaces.ISyncConversationChatBack;
import com.xinbida.wukongim.message.type.WKMsgContentType;
import com.xinbida.wukongim.message.type.WKSendMsgResult;

import org.json.JSONException;

import java.util.ArrayList;
import java.util.List;
import java.util.Timer;
import java.util.TimerTask;

/**
 * 2019-11-24 14:18
 * 消息管理
 */
public class MsgModel extends WKBaseModel {
    private MsgModel() {

    }

    private int last_message_seq;

    private static class MsgModelBinder {
        final static MsgModel msgModel = new MsgModel();
    }

    public static MsgModel getInstance() {
        return MsgModelBinder.msgModel;
    }

    private Timer timer;

    public void stopTimer() {
        if (timer != null) {
            timer.cancel();
            timer.purge();
            timer = null;
        }
    }

    public synchronized void startCheckFlameMsgTimer() {
        if (timer == null) {
            timer = new Timer();
            timer.schedule(new TimerTask() {
                @Override
                public void run() {
                    deleteFlameMsg();
                }
            }, 100, 1000);
        }
    }

    public void deleteFlameMsg() {
        if (!WKConstants.isLogin()) return;
        List<WKMsg> list = WKIM.getInstance().getMsgManager().getWithFlame();
        if (WKReader.isEmpty(list)) return;
        List<String> deleteClientMsgNoList = new ArrayList<>();
        List<WKMsg> deleteMsgList = new ArrayList<>();
        boolean isStopTimer = true;
        for (WKMsg msg : list) {
            if (msg.flame == 1 && msg.viewed == 1) {
                long time = WKTimeUtils.getInstance().getCurrentMills() - msg.viewedAt;
                if (time / 1000 > msg.flameSecond || msg.flameSecond == 0) {
                    deleteClientMsgNoList.add(msg.clientMsgNO);
                    deleteMsgList.add(msg);
                }
                isStopTimer = false;
            }
        }
        if (isStopTimer && timer != null) {
            timer.cancel();
            timer.purge();
            timer = null;
        }
        deleteMsg(deleteMsgList, null);
        WKIM.getInstance().getMsgManager().deleteWithClientMsgNos(deleteClientMsgNoList);
    }

    private void ackMsg() {
        request(createService(MsgService.class).ackMsg(last_message_seq), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {

            }

            @Override
            public void onFail(int code, String msg) {

            }
        });
    }

    /**
     * 删除消息
     */
    public void deleteMsg(List<WKMsg> list, final ICommonListener iCommonListener) {
        if (WKReader.isEmpty(list)) return;
        JSONArray jsonArray = new JSONArray();
        for (WKMsg msg : list) {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("message_id", msg.messageID);
            jsonObject.put("channel_id", msg.channelID);
            jsonObject.put("channel_type", msg.channelType);
            jsonObject.put("message_seq", msg.messageSeq);
            jsonArray.add(jsonObject);
        }
        request(createService(MsgService.class).deleteMsg(jsonArray), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                if (iCommonListener != null)
                    iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                if (iCommonListener != null)
                    iCommonListener.onResult(code, msg);
            }
        });
    }

    public void offsetMsg(String channelID, byte channelType, ICommonListener iCommonListener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("channel_id", channelID);
        jsonObject.put("channel_type", channelType);
        int msgSeq = WKIM.getInstance().getMsgManager().getMaxMessageSeqWithChannel(channelID, channelType);
        jsonObject.put("message_seq", msgSeq);
        request(createService(MsgService.class).offsetMsg(jsonObject), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                if (iCommonListener != null)
                    iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                if (iCommonListener != null)
                    iCommonListener.onResult(code, msg);
            }
        });
    }

    /**
     * 撤回消息
     *
     * @param msgId           消息ID
     * @param channelID       频道ID
     * @param channelType     频道类型
     * @param iCommonListener 返回
     */
    public void revokeMsg(String msgId, String channelID, byte channelType, String clientMsgNo, final ICommonListener iCommonListener) {
        request(createService(MsgService.class).revokeMsg(msgId, channelID, channelType, clientMsgNo), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                iCommonListener.onResult(code, msg);
            }
        });
    }

    /**
     * 置顶/取消置顶消息
     */
    public void pinMsg(String messageId, String channelID, byte channelType, long messageSeq, boolean notifyAll, final ICommonListener iCommonListener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("message_id", messageId);
        jsonObject.put("channel_id", channelID);
        jsonObject.put("channel_type", channelType);
        jsonObject.put("message_seq", messageSeq);
        jsonObject.put("notify_all", notifyAll);
        request(createService(MsgService.class).pinMsg(jsonObject), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                iCommonListener.onResult(code, msg);
            }
        });
    }

    /**
     * 清除频道所有置顶消息
     */
    public void clearPinnedMsg(String channelID, byte channelType, final ICommonListener iCommonListener) {
        JSONObject syncObj = new JSONObject();
        syncObj.put("channel_id", channelID);
        syncObj.put("channel_type", channelType);
        syncObj.put("version", 0);
        request(createService(MsgService.class).syncPinnedMsg(syncObj), new IRequestResultListener<JSONObject>() {
            @Override
            public void onSuccess(JSONObject result) {
                long maxVersion = 0;
                try {
                    android.util.Log.d("PinDebug", "syncPinned response: " + result.toJSONString());
                    JSONArray pinnedArr = result.getJSONArray("pinned_messages");
                    if (pinnedArr != null) {
                        for (int i = 0; i < pinnedArr.size(); i++) {
                            JSONObject pinObj = pinnedArr.getJSONObject(i);
                            if (pinObj.containsKey("version")) {
                                long v = pinObj.getLongValue("version");
                                if (v > maxVersion) maxVersion = v;
                            }
                        }
                    }
                } catch (Exception e) {
                    android.util.Log.d("PinDebug", "parse syncPinned error: " + e.getMessage());
                }
                final long finalMaxVersion = maxVersion;
                android.util.Log.d("PinDebug", "syncPinned maxVersion=" + finalMaxVersion);
                JSONObject clearObj = new JSONObject();
                clearObj.put("channel_id", channelID);
                clearObj.put("channel_type", channelType);
                clearObj.put("version", finalMaxVersion);
                request(createService(MsgService.class).clearPinnedMsg(clearObj), new IRequestResultListener<>() {
                    @Override
                    public void onSuccess(CommonResponse result) {
                        android.util.Log.d("PinDebug", "clearPinnedMsg success with version=" + finalMaxVersion);
                        iCommonListener.onResult(result.status, result.msg);
                    }

                    @Override
                    public void onFail(int code, String msg) {
                        android.util.Log.d("PinDebug", "clearPinnedMsg fail: code=" + code + " msg=" + msg);
                        iCommonListener.onResult(code, msg);
                    }
                });
            }

            @Override
            public void onFail(int code, String msg) {
                android.util.Log.d("PinDebug", "syncPinned fail: code=" + code + " msg=" + msg);
                JSONObject clearObj = new JSONObject();
                clearObj.put("channel_id", channelID);
                clearObj.put("channel_type", channelType);
                clearObj.put("version", 0);
                request(createService(MsgService.class).clearPinnedMsg(clearObj), new IRequestResultListener<>() {
                    @Override
                    public void onSuccess(CommonResponse result) {
                        iCommonListener.onResult(result.status, result.msg);
                    }

                    @Override
                    public void onFail(int code, String msg) {
                        iCommonListener.onResult(code, msg);
                    }
                });
            }
        });
    }

    /**
     * 获取置顶消息列表
     */
    public void getPinnedMsgList(String channelID, byte channelType, final IPinnedMsgListListener listener) {
        JSONObject syncObj = new JSONObject();
        syncObj.put("channel_id", channelID);
        syncObj.put("channel_type", channelType);
        syncObj.put("version", 0);
        request(createService(MsgService.class).syncPinnedMsg(syncObj), new IRequestResultListener<JSONObject>() {
            @Override
            public void onSuccess(JSONObject result) {
                List<WKMsg> msgList = new ArrayList<>();
                List<String> missingIds = new ArrayList<>();
                try {
                    JSONArray pinnedArr = result.getJSONArray("pinned_messages");
                    if (pinnedArr != null && pinnedArr.size() > 0) {
                        for (int i = 0; i < pinnedArr.size(); i++) {
                            JSONObject pinObj = pinnedArr.getJSONObject(i);
                            String messageId = pinObj.getString("message_id");
                            if (!TextUtils.isEmpty(messageId)) {
                                WKMsg msg = WKIM.getInstance().getMsgManager().getWithMessageID(messageId);
                                if (msg != null) {
                                    if (msg.remoteExtra == null) {
                                        msg.remoteExtra = new com.xinbida.wukongim.entity.WKMsgExtra();
                                    }
                                    msg.remoteExtra.isPinned = 1;
                                    msgList.add(msg);
                                } else {
                                    missingIds.add(messageId);
                                }
                            }
                        }
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
                if (missingIds.isEmpty()) {
                    if (listener != null) {
                        listener.onSuccess(msgList);
                    }
                } else {
                    syncMissingPinnedMessages(channelID, channelType, missingIds, msgList, listener);
                }
            }

            @Override
            public void onFail(int code, String msg) {
                if (listener != null) {
                    listener.onFail(code, msg);
                }
            }
        });
    }

    private void syncMissingPinnedMessages(String channelID, byte channelType, List<String> messageIds, List<WKMsg> existingMsgs, IPinnedMsgListListener listener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("channel_id", channelID);
        jsonObject.put("channel_type", channelType);
        jsonObject.put("message_ids", messageIds);
        request(createService(MsgService.class).getMessagesByIds(jsonObject), new IRequestResultListener<JSONObject>() {
            @Override
            public void onSuccess(JSONObject result) {
                try {
                    JSONArray msgArr = result.getJSONArray("messages");
                    if (msgArr != null) {
                        for (int i = 0; i < msgArr.size(); i++) {
                            try {
                                JSONObject msgObj = msgArr.getJSONObject(i);
                                WKMsg msg = new WKMsg();
                                msg.messageID = msgObj.getString("message_id");
                                msg.clientMsgNO = msgObj.getString("client_msg_no");
                                msg.fromUID = msgObj.getString("from_uid");
                                msg.channelID = msgObj.getString("channel_id");
                                msg.channelType = channelType;
                                msg.messageSeq = (int) msgObj.getLongValue("message_seq");
                                msg.timestamp = msgObj.getLongValue("timestamp");
                                if (msg.remoteExtra == null) {
                                    msg.remoteExtra = new com.xinbida.wukongim.entity.WKMsgExtra();
                                }
                                msg.remoteExtra.isPinned = 1;
                                existingMsgs.add(0, msg);
                            } catch (Exception ignored) {
                            }
                        }
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
                if (listener != null) {
                    listener.onSuccess(existingMsgs);
                }
            }

            @Override
            public void onFail(int code, String msg) {
                if (listener != null) {
                    listener.onFail(code, msg);
                }
            }
        });
    }

    public interface IPinnedMsgListListener {
        void onSuccess(List<WKMsg> msgList);
        void onFail(int code, String msg);
    }

    /**
     * 同步红点
     *
     * @param channelId   频道ID
     * @param channelType 频道类型
     */
    public void clearUnread(String channelId, byte channelType, int unreadCount, ICommonListener iCommonListener) {
        if (unreadCount < 0) unreadCount = 0;
        WKIM.getInstance().getConversationManager().updateRedDot(channelId, channelType, unreadCount);
        com.alibaba.fastjson.JSONObject jsonObject = new com.alibaba.fastjson.JSONObject();
        jsonObject.put("channel_id", channelId);
        jsonObject.put("channel_type", channelType);
        jsonObject.put("unread", unreadCount);
        request(createService(MsgService.class).clearUnread(jsonObject), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                if (iCommonListener != null)
                    iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
            }
        });
    }

    /**
     * 上报消息已读
     * @param channelID 频道ID
     * @param channelType 频道类型
     * @param msgIds 消息ID列表
     */
    public void readMsg(String channelID, byte channelType, List<com.chat.base.endpoint.entity.ReadedMessageReq> msgIds, int maxLargeMessageSeq) {
        if (TextUtils.isEmpty(channelID) || msgIds == null || msgIds.isEmpty()) {
            android.util.Log.d("WKReceiptDebug", "readMsg: skipped, channelID=" + channelID + ", msgIds=" + (msgIds != null ? msgIds.size() : 0));
            return;
        }
        android.util.Log.d("WKReceiptDebug", "readMsg: channelID=" + channelID + ", channelType=" + channelType + ", msgIds=" + msgIds.size() + ", maxLargeMessageSeq=" + maxLargeMessageSeq);
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("channel_id", channelID);
        jsonObject.put("channel_type", channelType);
        JSONArray messageIdArray = new JSONArray();
        JSONArray messagesArray = new JSONArray();
        for (com.chat.base.endpoint.entity.ReadedMessageReq req : msgIds) {
            messageIdArray.add(req.message_id);
            JSONObject msgObj = new JSONObject();
            msgObj.put("message_id", req.message_id);
            msgObj.put("from_uid", req.from_uid);
            msgObj.put("message_seq", req.message_seq);
            messagesArray.add(msgObj);
        }
        jsonObject.put("message_ids", messageIdArray);
        jsonObject.put("messages", messagesArray);
        jsonObject.put("max_large_message_seq", maxLargeMessageSeq);
        request(createService(MsgService.class).readedMsg(jsonObject), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                android.util.Log.d("WKReceiptDebug", "readMsg: onSuccess, result=" + result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                android.util.Log.d("WKReceiptDebug", "readMsg: onFail, code=" + code + ", msg=" + msg);
            }
        });
    }

    /**
     * 修改语音已读
     *
     * @param messageID 服务器消息ID
     */
    public void updateVoiceStatus(String messageID, String channel_id, byte channel_type, int message_seq) {
        if (TextUtils.isEmpty(messageID)) {
            return;
        }
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("message_id", messageID);
        jsonObject.put("channel_id", channel_id);
        jsonObject.put("channel_type", channel_type);
        jsonObject.put("message_seq", message_seq);
        request(createService(MsgService.class).updateVoiceStatus(jsonObject), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
            }

            @Override
            public void onFail(int code, String msg) {
            }
        });
    }

    public void getChatIp(IChatIp iChatIp) {
        request(createService(MsgService.class).getImIp(WKConfig.getInstance().getUid()), new IRequestResultListener<>() {
            @Override
            public void onSuccess(Ipentity result) {
                if (result != null && !TextUtils.isEmpty(result.tcp_addr)) {
                    String[] strings = result.tcp_addr.split(":");
                    iChatIp.onResult(HttpResponseCode.success, strings[0], strings[1]);
                }
            }

            @Override
            public void onFail(int code, String msg) {
                iChatIp.onResult(code, "", "0");
            }
        });
    }

    public interface IChatIp {
        void onResult(int code, String ip, String port);
    }

    public void typing(String channelID, byte channelType) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("channel_id", channelID);
        jsonObject.put("channel_type", channelType);
        request(createService(MsgService.class).typing(jsonObject), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {

            }

            @Override
            public void onFail(int code, String msg) {

            }
        });
    }

    private WKSyncMsg getWKSyncMsg(SyncMsg syncMsg) {
        WKMsg msg = new WKMsg();
        WKSyncMsg WKSyncMsg = new WKSyncMsg();
        msg.status = WKSendMsgResult.send_success;
        msg.messageID = syncMsg.message_id;
        msg.messageSeq = syncMsg.message_seq;
        msg.clientMsgNO = syncMsg.client_msg_no;
        msg.fromUID = syncMsg.from_uid;
        msg.channelID = syncMsg.channel_id;
        msg.channelType = syncMsg.channel_type;
        msg.voiceStatus = syncMsg.voice_status;
        msg.timestamp = syncMsg.timestamp;
        msg.isDeleted = syncMsg.is_delete;
        msg.remoteExtra.unreadCount = syncMsg.unread_count;
        msg.remoteExtra.readedCount = syncMsg.readed_count;
        msg.remoteExtra.extraVersion = syncMsg.extra_version;
        if (syncMsg.payload != null)
            msg.content = JSONObject.toJSONString(syncMsg.payload);
        if (syncMsg.payload != null && syncMsg.payload.containsKey("type")) {
            Object typeObject = syncMsg.payload.get("type");
            if (typeObject != null) {
                if (typeObject instanceof Number) {
                    msg.type = ((Number) typeObject).intValue();
                } else {
                    try {
                        msg.type = Integer.parseInt(typeObject.toString());
                    } catch (NumberFormatException ignored) {
                    }
                }
            }
        }
        WKSyncMsg.wkMsg = msg;
        WKSyncMsg.red_dot = syncMsg.header.red_dot;
        WKSyncMsg.sync_once = syncMsg.header.sync_once;
        WKSyncMsg.no_persist = syncMsg.header.no_persist;
        return WKSyncMsg;
    }

    /**
     * 同步会话
     *
     * @param last_msg_seqs 最后一条消息的msgseq数组
     * @param msg_count     同步消息条数
     * @param version       最大版本号
     */
    public void syncChat(String last_msg_seqs, int msg_count, long version, ISyncConversationChatBack iSyncConversationChatBack) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("last_msg_seqs", last_msg_seqs);
        jsonObject.put("msg_count", msg_count);
        jsonObject.put("version", version);
        jsonObject.put("device_uuid", WKConstants.getDeviceUUID());
        request(createService(MsgService.class).syncChat(jsonObject), new IRequestResultListener<>() {
            @Override
            public void onSuccess(WKSyncChat result) {
                if (result != null && !TextUtils.isEmpty(result.uid) && result.uid.equals(WKConfig.getInstance().getUid())) {
                    if (WKReader.isNotEmpty(result.conversations)) {
                        WKUIKitApplication.getInstance().isRefreshChatActivityMessage = true;
                    }
                    iSyncConversationChatBack.onBack(result);
                    last_message_seq = 0;
                    syncCmdMsgs(0);
                    ackDeviceUUID();
                    syncReminder();
                } else {
                    iSyncConversationChatBack.onBack(null);
                }
            }

            @Override
            public void onFail(int code, String msg) {
                iSyncConversationChatBack.onBack(null);
            }
        });
    }

    public void ackDeviceUUID() {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("device_uuid", WKConstants.getDeviceUUID());
        request(createService(MsgService.class).ackCoverMsg(jsonObject), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {

            }

            @Override
            public void onFail(int code, String msg) {

            }
        });
    }

    /**
     * 同步某个频道的消息
     *
     * @param channelID           频道ID
     * @param channelType         频道类型
     * @param startMessageSeq     最小messageSeq
     * @param endMessageSeq       最大messageSeq
     * @param limit               获取条数
     * @param pullMode            拉取模式 0:向下拉取 1:向上拉取
     * @param iSyncChannelMsgBack 返回
     */
    public void syncChannelMsg(String channelID, byte channelType, long startMessageSeq, long endMessageSeq, int limit, int pullMode, final ISyncChannelMsgBack iSyncChannelMsgBack) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("channel_id", channelID);
        jsonObject.put("channel_type", channelType);
        jsonObject.put("start_message_seq", startMessageSeq);
        jsonObject.put("end_message_seq", endMessageSeq);
        jsonObject.put("limit", limit);
        jsonObject.put("pull_mode", pullMode);
        jsonObject.put("device_uuid", WKConstants.getDeviceUUID());
        request(createService(MsgService.class).syncChannelMsg(jsonObject), new IRequestResultListener<>() {
            @Override
            public void onSuccess(WKSyncChannelMsg result) {
                iSyncChannelMsgBack.onBack(result);
                ackDeviceUUID();
            }

            @Override
            public void onFail(int code, String msg) {
                iSyncChannelMsgBack.onBack(null);
            }
        });
    }

    /**
     * 同步cmd消息
     *
     * @param max_message_seq 最大消息编号
     */
    private void syncCmdMsgs(long max_message_seq) {

        JSONObject jsonObject1 = new JSONObject();
        jsonObject1.put("limit", 500);
        jsonObject1.put("max_message_seq", max_message_seq);
        request(createService(MsgService.class).syncMsg(jsonObject1), new IRequestResultListener<>() {
            @Override
            public void onSuccess(List<SyncMsg> list) {
                if (WKReader.isNotEmpty(list)) {
                    List<WKBaseCMD> cmdList = new ArrayList<>();
                    for (int i = 0, size = list.size(); i < size; i++) {
                        WKSyncMsg WKSyncMsg = getWKSyncMsg(list.get(i));
                        WKBaseCMD WKBaseCmd = new WKBaseCMD();
                        if (WKSyncMsg.wkMsg.type == WKMsgContentType.WK_INSIDE_MSG) {
                            WKBaseCmd.client_msg_no = WKSyncMsg.wkMsg.clientMsgNO;
                            WKBaseCmd.created_at = WKSyncMsg.wkMsg.createdAt;
                            WKBaseCmd.message_id = WKSyncMsg.wkMsg.messageID;
                            WKBaseCmd.message_seq = WKSyncMsg.wkMsg.messageSeq;
                            WKBaseCmd.timestamp = WKSyncMsg.wkMsg.timestamp;
                            try {
                                org.json.JSONObject jsonObject = new org.json.JSONObject(WKSyncMsg.wkMsg.content);
                                if (jsonObject.has("cmd")) {
                                    WKBaseCmd.cmd = jsonObject.optString("cmd");
                                }
                                if (jsonObject.has("sign")) {
                                    WKBaseCmd.sign = jsonObject.optString("sign");
                                }
                                if (jsonObject.has("param")) {
                                    org.json.JSONObject paramJson = jsonObject.optJSONObject("param");
                                    if (paramJson != null) {
                                        if (!paramJson.has("channel_id") && !TextUtils.isEmpty(WKSyncMsg.wkMsg.channelID)) {
                                            paramJson.put("channel_id", WKSyncMsg.wkMsg.channelID);
                                        }
                                        if (!paramJson.has("channel_type")) {
                                            paramJson.put("channel_type", WKSyncMsg.wkMsg.channelType);
                                        }
                                        WKBaseCmd.param = paramJson.toString();
                                    }
                                }
                            } catch (JSONException e) {
                                WKLogUtils.e("MsgModel", "cmd messages not json struct");
                            }
                            cmdList.add(WKBaseCmd);
                        }
                        if (WKSyncMsg.wkMsg.messageSeq > last_message_seq) {
                            last_message_seq = WKSyncMsg.wkMsg.messageSeq;
                        }
                    }
                    //保存cmd
                    WKBaseCMDManager.getInstance().addCmd(cmdList);
                    if (last_message_seq != 0) {
                        ackMsg();
                    }
                    syncCmdMsgs(last_message_seq);
                } else {
                    if (last_message_seq != 0) {
                        ackMsg();
                    }
                    //处理cmd
                    WKBaseCMDManager.getInstance().handleCmd();
                }
            }

            @Override
            public void onFail(int code, String msg) {
                if (last_message_seq != 0) {
                    ackMsg();
                    WKBaseCMDManager.getInstance().handleCmd();
                }
            }
        });
    }

    /**
     * 同步某个会话的扩展消息
     *
     * @param channelID   频道ID
     * @param channelType 频道类型
     */
    public void syncExtraMsg(String channelID, byte channelType) {
        syncExtraMsg(channelID, channelType, null);
    }

    public void syncExtraMsg(String channelID, byte channelType, Runnable onComplete) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("channel_id", channelID);
        jsonObject.put("channel_type", channelType);
        long maxExtraVersion = WKIM.getInstance().getMsgManager().getMsgExtraMaxVersionWithChannel(channelID, channelType);
        jsonObject.put("extra_version", maxExtraVersion);
        jsonObject.put("limit", 100);
        String deviceUUID = WKConstants.getDeviceUUID();
        jsonObject.put("source", deviceUUID);
        request(createService(MsgService.class).syncExtraMsg(jsonObject), new IRequestResultListener<>() {
            @Override
            public void onSuccess(List<WKSyncExtraMsg> result) {
                if (WKReader.isNotEmpty(result)) {
                    for (WKSyncExtraMsg extra : result) {
                        android.util.Log.d("WKReceiptDebug",
                            "syncExtraMsg: " + extra.toString());
                    }
                    WKIM.getInstance().getMsgManager().saveRemoteExtraMsg(new WKChannel(channelID, channelType), result);
                    new Handler(Looper.getMainLooper()).postDelayed(() -> syncExtraMsg(channelID, channelType, onComplete), 500);
                } else {
                    if (onComplete != null) {
                        new Handler(Looper.getMainLooper()).post(onComplete);
                    }
                }
            }

            @Override
            public void onFail(int code, String msg) {
                if (onComplete != null) {
                    new Handler(Looper.getMainLooper()).post(onComplete);
                }
            }
        });
    }


    // 同步敏感词
    public void syncSensitiveWords() {
        if (TextUtils.isEmpty(WKConfig.getInstance().getToken())) return;
        long version = WKSharedPreferencesUtil.getInstance().getLong("wk_sensitive_words_version");
        request(createService(MsgService.class).syncSensitiveWords(version), new IRequestResultListener<>() {
            @Override
            public void onSuccess(SensitiveWords result) {
                WKSharedPreferencesUtil.getInstance().putLong("wk_sensitive_words_version", result.version);
                if (!TextUtils.isEmpty(result.tips)) {
                    WKUIKitApplication.getInstance().sensitiveWords = result;
                    String json = JSON.toJSONString(result);
                    WKSharedPreferencesUtil.getInstance().putSP("wk_sensitive_words", json);
                }
            }

            @Override
            public void onFail(int code, String msg) {

            }
        });
    }

    public void editMsg(String msgID, int msgSeq, String channelID, byte channelType, String content, ICommonListener iCommonListener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("message_id", msgID);
        jsonObject.put("message_seq", msgSeq);
        jsonObject.put("channel_id", channelID);
        jsonObject.put("channel_type", channelType);
        jsonObject.put("content_edit", content);
        request(createService(MsgService.class).editMsg(jsonObject), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                if (iCommonListener != null)
                    iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                if (iCommonListener != null)
                    iCommonListener.onResult(code, msg);
            }
        });
    }

    public void syncReminder() {
        long version = WKIM.getInstance().getReminderManager().getMaxVersion();
        List<String> channelIDs = new ArrayList<>();
        List<WKConversationMsg> list = WKIM.getInstance().getConversationManager().getWithChannelType(WKChannelType.GROUP);
        for (WKConversationMsg mConversationMsg : list) {
            channelIDs.add(mConversationMsg.channelID);
        }
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("version", version);
        jsonObject.put("limit", 200);
        jsonObject.put("channel_ids", channelIDs);
        request(createService(MsgService.class).syncReminder(jsonObject), new IRequestResultListener<>() {
            @Override
            public void onSuccess(List<WKSyncReminder> result) {
                if (WKReader.isNotEmpty(result)) {
                    String loginUID = WKConfig.getInstance().getUid();
                    List<WKReminder> list = new ArrayList<>();
                    for (WKSyncReminder reminder : result) {
                        WKReminder WKReminder = syncReminderToReminder(reminder);
                        if (!TextUtils.isEmpty(reminder.publisher) && reminder.publisher.equals(loginUID)) {
                            WKReminder.done = 1;
                        }
                        list.add(WKReminder);
                    }
                    WKIM.getInstance().getReminderManager().saveOrUpdateReminders(list);

                }

            }

            @Override
            public void onFail(int code, String msg) {

            }
        });
    }

    public void doneReminder(List<Long> list) {
        if (WKReader.isEmpty(list)) return;
        request(createService(MsgService.class).doneReminder(list), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {

            }

            @Override
            public void onFail(int code, String msg) {

            }
        });
    }

    public void updateCoverExtra(String channelID, byte channelType, long browseTo, long keepMsgSeq, int keepOffsetY, String draft) {
        WKConversationMsgExtra extra = new WKConversationMsgExtra();
        extra.draft = draft;
        extra.keepOffsetY = keepOffsetY;
        extra.keepMessageSeq = keepMsgSeq;
        extra.channelID = channelID;
        extra.channelType = channelType;
        extra.browseTo = browseTo;
        if (!TextUtils.isEmpty(draft)) {
            extra.draftUpdatedAt = WKTimeUtils.getInstance().getCurrentSeconds();
        }
        WKIM.getInstance().getConversationManager().updateMsgExtra(extra);

        JSONObject jsonObject = new JSONObject();
        jsonObject.put("browse_to", browseTo);
        jsonObject.put("keep_message_seq", keepMsgSeq);
        jsonObject.put("keep_offset_y", keepOffsetY);
        jsonObject.put("draft", draft);
        request(createService(MsgService.class).updateCoverExtra(channelID, channelType, jsonObject), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {

            }

            @Override
            public void onFail(int code, String msg) {

            }
        });
    }

    public void syncCoverExtra() {
        long version = WKIM.getInstance().getConversationManager().getMsgExtraMaxVersion();
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("version", version);
        request(createService(MsgService.class).syncCoverExtra(jsonObject), new IRequestResultListener<>() {
            @Override
            public void onSuccess(List<WKSyncConvMsgExtra> result) {
                WKIM.getInstance().getConversationManager().saveSyncMsgExtras(result);
            }

            @Override
            public void onFail(int code, String msg) {

            }
        });
    }

    private WKReminder syncReminderToReminder(WKSyncReminder syncReminder) {
        WKReminder reminder = new WKReminder();
        reminder.reminderID = syncReminder.id;
        reminder.channelID = syncReminder.channel_id;
        reminder.channelType = syncReminder.channel_type;
        reminder.messageSeq = syncReminder.message_seq;
        reminder.type = syncReminder.reminder_type;
        reminder.isLocate = syncReminder.is_locate;
        reminder.text = syncReminder.text;
        reminder.version = syncReminder.version;
        reminder.messageID = syncReminder.message_id;
        reminder.uid = syncReminder.uid;
        reminder.done = syncReminder.done;
        reminder.data = syncReminder.data;
        reminder.publisher = syncReminder.publisher;
        return reminder;
    }

    public void backupMsg(String filePath, ICommonListener iCommonListener) {
        String url = WKApiConfig.baseUrl + "message/backup";
        WKUploader.getInstance().upload(url, filePath, new WKUploader.IUploadBack() {
            @Override
            public void onSuccess(String url) {
                iCommonListener.onResult(HttpResponseCode.success, "");
            }

            @Override
            public void onError() {
                iCommonListener.onResult(HttpResponseCode.error, "");
            }
        });
    }

    public void recovery(final IRecovery iRecovery) {
        String uid = WKConfig.getInstance().getUid();
        String url = WKApiConfig.baseUrl + "message/recovery";
        String path = WKConstants.messageBackupDir + uid + "_recovery.json";
        WKDownloader.Companion.getInstance().download(url, path, new WKProgressManager.IProgress() {
            @Override
            public void onProgress(@Nullable Object tag, int progress) {

            }

            @Override
            public void onSuccess(@Nullable Object tag, @Nullable String path) {
                iRecovery.onSuccess(path);
            }

            @Override
            public void onFail(@Nullable Object tag, @Nullable String msg) {
                iRecovery.onFail();
            }
        });
    }

    public interface IRecovery {
        void onSuccess(String path);

        void onFail();
    }
}
