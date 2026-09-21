package com.chat.base.trtc;

/**
 * TRTC 通话类型常量
 */
public class TRTCType {
    /** 语音通话 */
    public static final int AUDIO_CALL = 0;
    /** 视频通话 */
    public static final int VIDEO_CALL = 1;

    /** 通话角色 - 主叫 */
    public static final int ROLE_CALLER = 0;
    /** 通话角色 - 被叫 */
    public static final int ROLE_CALLEE = 1;

    public static boolean isVideoCall(int callType) {
        return callType == VIDEO_CALL;
    }

    public static String getCallTypeText(int callType) {
        return callType == VIDEO_CALL ? "视频通话" : "语音通话";
    }
}
