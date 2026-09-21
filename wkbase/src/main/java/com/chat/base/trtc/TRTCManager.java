package com.chat.base.trtc;

import android.content.Context;
import android.media.AudioManager;

import com.tencent.liteav.device.TXDeviceManager;
import com.tencent.rtmp.ui.TXCloudVideoView;
import com.tencent.trtc.TRTCCloud;
import com.tencent.trtc.TRTCCloudDef;
import com.tencent.trtc.TRTCCloudListener;

/**
 * TRTC 房间管理，封装进退房间和音视频控制
 */
public class TRTCManager {

    private static volatile TRTCManager instance;

    private TRTCCloud trtcCloud;
    private TXDeviceManager deviceManager;
    private boolean isMicMuted = false;
    private boolean isCameraOpen = true;
    private boolean isFrontCamera = true;
    private boolean isInRoom = false;
    private boolean isSpeakerOn = false;
    private Context appContext;
    private TRTCCloudListener pendingListener;

    // 通话状态（用于悬浮窗恢复）
    private boolean isCallActive = false;
    private int callType = 0; // 0=音频 1=视频
    private int sdkAppId;
    private String userId;
    private String targetUid;
    private String channelId;
    private int channelType;
    private int roomId;
    private String callerName;
    private String myName;
    private long callStartTime = 0;
    private boolean isCallee = false;

    private TRTCManager() {
    }

    public static TRTCManager getInstance() {
        if (instance == null) {
            synchronized (TRTCManager.class) {
                if (instance == null) {
                    instance = new TRTCManager();
                }
            }
        }
        return instance;
    }

    public void setListener(TRTCCloudListener listener) {
        if (trtcCloud != null) {
            trtcCloud.addListener(listener);
        } else {
            pendingListener = listener;
        }
    }

    public void removeListener(TRTCCloudListener listener) {
        if (trtcCloud != null) {
            trtcCloud.removeListener(listener);
        }
    }

    public void enterRoom(Context context, int sdkAppId, String userId, String userSig, int roomId,
                          int callType, TXCloudVideoView localView, TXCloudVideoView remoteView) {
        if (isInRoom) return;

        appContext = context.getApplicationContext();
        trtcCloud = TRTCCloud.sharedInstance(context);
        if (pendingListener != null) {
            trtcCloud.addListener(pendingListener);
            pendingListener = null;
        }
        deviceManager = trtcCloud.getDeviceManager();

        TRTCCloudDef.TRTCParams params = new TRTCCloudDef.TRTCParams();
        params.sdkAppId = sdkAppId;
        params.userId = userId;
        params.userSig = userSig;
        params.roomId = roomId;
        params.role = TRTCCloudDef.TRTCRoleAnchor;

        int scene = callType == TRTCType.VIDEO_CALL
                ? TRTCCloudDef.TRTC_APP_SCENE_VIDEOCALL
                : TRTCCloudDef.TRTC_APP_SCENE_AUDIOCALL;
        trtcCloud.enterRoom(params, scene);

        TRTCCloudDef.TRTCRenderParams renderParams = new TRTCCloudDef.TRTCRenderParams();
        renderParams.fillMode = TRTCCloudDef.TRTC_VIDEO_RENDER_MODE_FILL;

        if (callType == TRTCType.VIDEO_CALL && localView != null) {
            trtcCloud.setLocalRenderParams(renderParams);
            trtcCloud.startLocalPreview(true, localView);
        } else {
            trtcCloud.startLocalAudio(TRTCCloudDef.TRTC_AUDIO_QUALITY_DEFAULT);
        }

        if (callType == TRTCType.VIDEO_CALL && remoteView != null) {
            trtcCloud.setRemoteRenderParams("", TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG, renderParams);
        }

        isInRoom = true;
        isMicMuted = false;
        isCameraOpen = callType == TRTCType.VIDEO_CALL;
        isFrontCamera = true;
        // 拨号等待阶段默认开启扬声器，方便听到等待音
        // 通话接通后会自动切换到听筒模式（由 Activity 控制）
        isSpeakerOn = true;
        trtcCloud.setAudioRoute(TRTCCloudDef.TRTC_AUDIO_ROUTE_SPEAKER);
    }

    public void exitRoom() {
        if (trtcCloud == null) return;

        trtcCloud.stopLocalPreview();
        trtcCloud.stopLocalAudio();
        trtcCloud.exitRoom();
        TRTCCloud.destroySharedInstance();
        trtcCloud = null;
        deviceManager = null;
        isInRoom = false;
        pendingListener = null;
    }

    public void toggleMic() {
        if (trtcCloud == null) return;
        isMicMuted = !isMicMuted;
        trtcCloud.muteLocalAudio(isMicMuted);
    }

    public boolean isMicMuted() {
        return isMicMuted;
    }

    public void toggleCamera(TXCloudVideoView localView) {
        if (trtcCloud == null) return;
        isCameraOpen = !isCameraOpen;
        if (isCameraOpen) {
            trtcCloud.startLocalPreview(isFrontCamera, localView);
        } else {
            trtcCloud.stopLocalPreview();
        }
    }

    public boolean isCameraOpen() {
        return isCameraOpen;
    }

    public void switchCamera() {
        if (deviceManager == null) return;
        isFrontCamera = !isFrontCamera;
        deviceManager.switchCamera(isFrontCamera);
    }

    public void startRemoteView(String userId, TXCloudVideoView remoteView) {
        if (trtcCloud == null) return;
        trtcCloud.startRemoteView(userId, TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG, remoteView);
    }

    public void stopRemoteView(String userId) {
        if (trtcCloud == null) return;
        trtcCloud.stopRemoteView(userId, TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG);
    }

    public boolean isInRoom() {
        return isInRoom;
    }

    public void toggleSpeaker() {
        if (trtcCloud == null) return;
        isSpeakerOn = !isSpeakerOn;
        if (isSpeakerOn) {
            trtcCloud.setAudioRoute(TRTCCloudDef.TRTC_AUDIO_ROUTE_SPEAKER);
        } else {
            trtcCloud.setAudioRoute(TRTCCloudDef.TRTC_AUDIO_ROUTE_EARPIECE);
        }
    }

    public boolean isSpeakerOn() {
        return isSpeakerOn;
    }

    public void setSpeakerOn(boolean on) {
        if (trtcCloud == null) {
            isSpeakerOn = on;
            return;
        }
        isSpeakerOn = on;
        if (isSpeakerOn) {
            trtcCloud.setAudioRoute(TRTCCloudDef.TRTC_AUDIO_ROUTE_SPEAKER);
        } else {
            trtcCloud.setAudioRoute(TRTCCloudDef.TRTC_AUDIO_ROUTE_EARPIECE);
        }
    }

    // ===== 通话状态保存（悬浮窗恢复用） =====
    public void setCallActive(boolean active, int type, int appId, String uid, String target,
                              String channel, int chType, int room, String name, String myName, boolean callee) {
        isCallActive = active;
        callType = type;
        sdkAppId = appId;
        userId = uid;
        targetUid = target;
        channelId = channel;
        channelType = chType;
        roomId = room;
        callerName = name;
        this.myName = myName;
        isCallee = callee;
    }

    public boolean isCallActive() { return isCallActive; }
    public int getCallType() { return callType; }
    public int getSdkAppId() { return sdkAppId; }
    public String getUserId() { return userId; }
    public String getTargetUid() { return targetUid; }
    public String getChannelId() { return channelId; }
    public int getChannelType() { return channelType; }
    public int getRoomId() { return roomId; }
    public String getCallerName() { return callerName; }
    public String getMyName() { return myName; }
    public long getCallStartTime() { return callStartTime; }
    public boolean isCallee() { return isCallee; }

    public void setCallStartTime(long time) { callStartTime = time; }

    public void clearCallState() {
        isCallActive = false;
        callStartTime = 0;
    }
}
