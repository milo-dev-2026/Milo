package com.chat.base.msgitem;

/**
 * RTC 消息类型常量
 */
public class WKRTCType {
    public static final int WK_P2P_CALL = 9989;
    public static final int wk_video_switch_video = 9990;
    public static final int wk_video_switch_video_respond = 9991;
    public static final int wk_video_cancel = 9992;
    public static final int wk_video_switch_audio = 9993;
    public static final int wk_video_call_data = 9994;
    public static final int wk_video_call_missed = 9995;
    public static final int wk_video_call_received = 9996;
    public static final int wk_video_call_refuse = 9997;
    public static final int wk_video_call_accept = 9998;
    public static final int wk_video_call_hangup = 9999;

    public static boolean isRtcControlMessage(int type) {
        return type == wk_video_switch_video || type == wk_video_switch_video_respond || type == wk_video_switch_audio;
    }
}
