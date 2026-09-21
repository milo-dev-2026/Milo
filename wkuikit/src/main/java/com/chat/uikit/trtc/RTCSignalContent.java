package com.chat.uikit.trtc;

import com.chat.base.msgitem.WKRTCType;
import com.xinbida.wukongim.msgmodel.WKMessageContent;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * RTC 信令消息内容
 * 用于通话过程中的 Invite/Accept/Cancel/Hangup/Refuse 信令
 *
 * signalType: 信令类型
 *   0 = Invite   (邀请通话)
 *   1 = Accept   (接听通话)
 *   2 = Cancel   (取消通话)
 *   3 = Hangup   (挂断通话)
 *   4 = Refuse   (拒绝通话)
 *   5 = SwitchAudio (切换到语音)
 *   6 = SwitchVideo (切换到视频)
 *   7 = Busy     (忙线中)
 *
 * callType: 0=语音, 1=视频
 * roomId: 房间号
 */
public class RTCSignalContent extends WKMessageContent {

    public static final int SIGNAL_INVITE = 0;
    public static final int SIGNAL_ACCEPT = 1;
    public static final int SIGNAL_CANCEL = 2;
    public static final int SIGNAL_HANGUP = 3;
    public static final int SIGNAL_REFUSE = 4;
    public static final int SIGNAL_SWITCH_AUDIO = 5;
    public static final int SIGNAL_SWITCH_VIDEO = 6;
    public static final int SIGNAL_BUSY = 7;

    public int signalType;
    public int callType;
    public int roomId;
    public String callerId;
    public String callerName;

    public RTCSignalContent() {
        // 所有 RTC 信令统一使用一个 type，通过 signalType 区分具体信令
        this.type = WKRTCType.wk_video_call_received;
    }

    public RTCSignalContent(int signalType, int callType, int roomId,
                            String callerId, String callerName) {
        this();
        this.signalType = signalType;
        this.callType = callType;
        this.roomId = roomId;
        this.callerId = callerId;
        this.callerName = callerName;
    }

    @Override
    public WKMessageContent decodeMsg(JSONObject jsonObject) {
        if (jsonObject.has("signal_type")) {
            this.signalType = jsonObject.optInt("signal_type");
        }
        if (jsonObject.has("call_type")) {
            this.callType = jsonObject.optInt("call_type");
        }
        if (jsonObject.has("room_id")) {
            this.roomId = jsonObject.optInt("room_id");
        }
        if (jsonObject.has("caller_id")) {
            this.callerId = jsonObject.optString("caller_id");
        }
        if (jsonObject.has("caller_name")) {
            this.callerName = jsonObject.optString("caller_name");
        }
        if (jsonObject.has("type")) {
            this.type = jsonObject.optInt("type");
        }
        return this;
    }

    @Override
    public JSONObject encodeMsg() {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put("signal_type", this.signalType);
            jsonObject.put("call_type", this.callType);
            jsonObject.put("room_id", this.roomId);
            jsonObject.put("caller_id", this.callerId != null ? this.callerId : "");
            jsonObject.put("caller_name", this.callerName != null ? this.callerName : "");
            jsonObject.put("type", this.type);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return jsonObject;
    }

    @Override
    public String getDisplayContent() {
        return "";
    }
}
