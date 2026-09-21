package com.chat.uikit.trtc;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.Ringtone;
import android.media.RingtoneManager;
import android.media.ToneGenerator;
import android.net.Uri;
import android.os.Bundle;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.util.Log;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.chat.base.ui.components.AvatarView;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsControllerCompat;

import com.chat.base.trtc.TRTCManager;
import com.chat.base.trtc.TRTCType;
import com.chat.uikit.R;
import com.tencent.trtc.TRTCCloudDef;
import com.tencent.trtc.TRTCCloudListener;
import com.tencent.rtmp.ui.TXCloudVideoView;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannelType;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.Locale;
import java.util.Random;
import java.util.concurrent.TimeUnit;

/**
 * P2P 单人通话界面
 */
public class TRTCCallActivity extends Activity {

    private static final String TAG = "TRTCCallActivity";

    private static WeakReference<TRTCCallActivity> instanceRef;

    public static TRTCCallActivity getInstance() {
        return instanceRef != null ? instanceRef.get() : null;
    }

    private static int pendingSignalType = -1;

    /**
     * 收到对方信令通知（由 WKIMUtils 调用）
     */
    public static void notifySignal(int signalType) {
        TRTCCallActivity activity = instanceRef != null ? instanceRef.get() : null;
        if (activity == null || activity.isFinishing() || activity.isDestroyed()) {
            // Activity 不可用（可能处于悬浮窗最小化状态），通过 TRTCManager 处理挂断
            if (signalType == RTCSignalContent.SIGNAL_HANGUP
                    || signalType == RTCSignalContent.SIGNAL_REFUSE
                    || signalType == RTCSignalContent.SIGNAL_CANCEL
                    || signalType == RTCSignalContent.SIGNAL_BUSY) {
                Log.d(TAG, "notifySignal: activity unavailable, handling signal " + signalType + " via static cleanup");
                pendingSignalType = signalType;
                // 隐藏悬浮窗
                CallFloatingManager.getInstance().hide();
                // 退出 TRTC 房间
                TRTCManager.getInstance().exitRoom();
                TRTCManager.getInstance().clearCallState();
            }
            return;
        }
        Log.d(TAG, "notifySignal: " + signalType);
        activity.runOnUiThread(() -> {
            switch (signalType) {
                case RTCSignalContent.SIGNAL_ACCEPT:
                    activity.callStatusTv.setText("对方已接听，连接中...");
                    break;
                case RTCSignalContent.SIGNAL_REFUSE:
                    if (activity.callState == CallState.WAITING) {
                        activity.stopWaitingRingtone();
                        activity.callStatusTv.setText("对方已拒绝");
                        if (activity.timeoutRunnable != null) activity.handler.removeCallbacks(activity.timeoutRunnable);
                        activity.callState = CallState.ENDED;
                        activity.handler.postDelayed(activity::finish, 1500);
                    }
                    break;
                case RTCSignalContent.SIGNAL_HANGUP:
                    if (activity.callState != CallState.ENDED) {
                        activity.stopWaitingRingtone();
                        activity.callStatusTv.setText("对方已挂断");
                        activity.callState = CallState.ENDED;
                        if (activity.durationRunnable != null) activity.handler.removeCallbacks(activity.durationRunnable);
                        // 播放挂断提示音
                        activity.playHangupTone();
                        activity.handler.postDelayed(activity::finishWithResult, 800);
                    }
                    break;
                case RTCSignalContent.SIGNAL_BUSY:
                    if (activity.callState == CallState.WAITING) {
                        activity.stopWaitingRingtone();
                        activity.callStatusTv.setText("对方忙线中");
                        if (activity.timeoutRunnable != null) activity.handler.removeCallbacks(activity.timeoutRunnable);
                        activity.callState = CallState.ENDED;
                        activity.handler.postDelayed(activity::finish, 1500);
                    }
                    break;
                default:
                    Log.w(TAG, "notifySignal: unknown signal type " + signalType);
                    break;
            }
        });
    }

    public static final String EXTRA_USER_ID = "user_id";
    public static final String EXTRA_TARGET_UID = "target_uid";
    public static final String EXTRA_CHANNEL_ID = "channel_id";
    public static final String EXTRA_CHANNEL_TYPE = "channel_type";
    public static final String EXTRA_ROOM_ID = "room_id";
    public static final String EXTRA_CALLER_NAME = "caller_name";
    public static final String EXTRA_MY_NAME = "my_name";
    public static final String EXTRA_CALL_TYPE = "call_type";
    public static final String EXTRA_SDK_APP_ID = "sdk_app_id";
    public static final String EXTRA_USER_SIG = "user_sig";

    private TXCloudVideoView remoteVideoView;
    private TXCloudVideoView localVideoView;
    private TextView callerNameTv;
    private TextView callStatusTv;
    private TextView callDurationTv;
    private ImageView btnMuteMic;
    private ImageView btnSpeaker;

    private String userId;
    private String targetUid;
    private String channelId;
    private int channelType = WKChannelType.PERSONAL;
    private int roomId;
    private String callerName; // 显示用：对方的名字
    private String myName;     // 自己的名字，用于发送信令
    private int callType;
    private int sdkAppId;
    private String userSig;

    private boolean isMicMuted = false;
    private boolean isSpeakerOn = false;
    private boolean isCameraOpen = true;
    private boolean isCallee = false;

    private enum CallState { WAITING, CONNECTED, ENDED }
    private CallState callState = CallState.WAITING;

    private final Handler handler = new Handler(Looper.getMainLooper());
    private long callStartTime = 0;
    private Runnable durationRunnable;
    private Runnable timeoutRunnable;
    private Ringtone waitingRingtone;
    private MediaPlayer waitingMediaPlayer;
    private ToneGenerator toneGenerator;
    private AudioManager audioManager;
    private int originalAudioMode = AudioManager.MODE_NORMAL;
    private int originalRingerMode = AudioManager.RINGER_MODE_NORMAL;
    private boolean audioFocusGranted = false;
    private final AudioManager.OnAudioFocusChangeListener audioFocusListener = new AudioManager.OnAudioFocusChangeListener() {
        @Override
        public void onAudioFocusChange(int focusChange) {
            switch (focusChange) {
                case AudioManager.AUDIOFOCUS_LOSS:
                case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT:
                    // 失去音频焦点，暂停音频
                    Log.d(TAG, "Audio focus lost: " + focusChange);
                    audioFocusGranted = false;
                    break;
                case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK:
                    // 短暂失去焦点，降低音量
                    Log.d(TAG, "Audio focus duck");
                    break;
                case AudioManager.AUDIOFOCUS_GAIN:
                    // 重新获得焦点，恢复音频
                    Log.d(TAG, "Audio focus gained");
                    audioFocusGranted = true;
                    if (audioManager != null) {
                        audioManager.setMode(AudioManager.MODE_IN_COMMUNICATION);
                        TRTCManager.getInstance().setSpeakerOn(isSpeakerOn);
                    }
                    break;
            }
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        instanceRef = new WeakReference<>(this);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        // 状态栏透明并与页面同色，适配灵动岛
        Window window = getWindow();
        WindowCompat.setDecorFitsSystemWindows(window, false);
        window.setStatusBarColor(Color.TRANSPARENT);
        WindowInsetsControllerCompat controller = WindowCompat.getInsetsController(window, window.getDecorView());
        if (controller != null) {
            controller.setAppearanceLightStatusBars(false);
        }
        setContentView(R.layout.act_trtc_call_layout);

        initViews();

        // 如果通话正在进行中（从悬浮窗恢复），直接恢复状态
        if (TRTCManager.getInstance().isCallActive()) {
            restoreFromFloatingState();
        } else {
            parseIntent();
            loadAvatar();
            checkPermissionsAndStart();
        }
    }

    private void restoreFromFloatingState() {
        TRTCManager mgr = TRTCManager.getInstance();
        callType = mgr.getCallType();
        sdkAppId = mgr.getSdkAppId();
        userId = mgr.getUserId();
        targetUid = mgr.getTargetUid();
        channelId = mgr.getChannelId();
        channelType = mgr.getChannelType();
        roomId = mgr.getRoomId();
        callerName = mgr.getCallerName();
        myName = mgr.getMyName();
        isCallee = mgr.isCallee();
        callStartTime = mgr.getCallStartTime();

        callerNameTv.setText(callerName != null ? callerName : "");
        loadAvatar();

        TRTCManager.getInstance().setListener(trtcCloudListener);

        // 恢复音频管理器并确保音频模式正确
        audioManager = (AudioManager) getSystemService(Context.AUDIO_SERVICE);
        if (audioManager != null) {
            originalAudioMode = audioManager.getMode();
            originalRingerMode = audioManager.getRingerMode();
            // 重新请求音频焦点
            int focusResult = audioManager.requestAudioFocus(
                    audioFocusListener,
                    AudioManager.STREAM_VOICE_CALL,
                    AudioManager.AUDIOFOCUS_GAIN
            );
            audioFocusGranted = (focusResult == AudioManager.AUDIOFOCUS_REQUEST_GRANTED);
            audioManager.setMode(AudioManager.MODE_IN_COMMUNICATION);
            Log.d(TAG, "restoreFromFloatingState: audio focus restored: " + focusResult);
        }

        // 根据是否已接通判断状态
        if (callStartTime > 0) {
            // 通话已经接通，显示通话中状态和计时
            callState = CallState.CONNECTED;
            callStatusTv.setText("通话中");
            callDurationTv.setVisibility(View.VISIBLE);
            startDurationTimer();
        } else {
            // 还在等待接听状态，显示状态文字
            callState = CallState.WAITING;
            callStatusTv.setText(isCallee ? "正在接听..." : "正在等待对方接受邀请...");
            callDurationTv.setVisibility(View.GONE);
            // 重新启动超时计时器（剩余时间）
            startRemainingTimeout();
        }

        // 恢复按钮状态
        isMicMuted = TRTCManager.getInstance().isMicMuted();
        isSpeakerOn = TRTCManager.getInstance().isSpeakerOn();
        updateMicButton();
        updateSpeakerButton();
        // 确保扬声器路由正确
        TRTCManager.getInstance().setSpeakerOn(isSpeakerOn);
    }

    private void startRemainingTimeout() {
        // 从悬浮窗恢复时，给一个较短的超时（避免重复计时），实际信令超时由对端控制
        timeoutRunnable = () -> {
            if (callState == CallState.WAITING) {
                callStatusTv.setText("无人接听");
                callState = CallState.ENDED;
                handler.postDelayed(this::finishWithResult, 1500);
            }
        };
        handler.postDelayed(timeoutRunnable, 30000);
    }

    private void initViews() {
        remoteVideoView = findViewById(R.id.remoteVideoView);
        localVideoView = findViewById(R.id.localVideoView);
        callerNameTv = findViewById(R.id.callerNameTv);
        callStatusTv = findViewById(R.id.callStatusTv);
        callDurationTv = findViewById(R.id.callDurationTv);
        btnMuteMic = findViewById(R.id.btnMuteMic);
        btnSpeaker = findViewById(R.id.btnSpeaker);
        ImageView btnHangUp = findViewById(R.id.btnHangUp);
        ImageView minimizeIv = findViewById(R.id.minimizeIv);

        minimizeIv.setOnClickListener(v -> minimizeToFloating());

        btnMuteMic.setOnClickListener(v -> {
            TRTCManager.getInstance().toggleMic();
            isMicMuted = TRTCManager.getInstance().isMicMuted();
            updateMicButton();
            Toast.makeText(this, isMicMuted ? "已静音" : "已取消静音", Toast.LENGTH_SHORT).show();
        });

        btnSpeaker.setOnClickListener(v -> {
            TRTCManager.getInstance().toggleSpeaker();
            isSpeakerOn = TRTCManager.getInstance().isSpeakerOn();
            updateSpeakerButton();
            Toast.makeText(this, isSpeakerOn ? "免提已开启" : "免提已关闭", Toast.LENGTH_SHORT).show();
        });

        btnHangUp.setOnClickListener(v -> onHangUp());

        // 初始化按钮状态（默认：关闭静音、关闭免提 → 灰色图标）
        updateMicButton();
        updateSpeakerButton();
    }

    /**
     * 更新麦克风按钮图标
     * 逻辑：静音关闭（麦克风开）→ 灰色图标（功能关闭态）
     *       静音开启（麦克风关）→ 蓝色带斜杠图标（功能开启态）
     */
    private void updateMicButton() {
        if (btnMuteMic == null) return;
        if (isMicMuted) {
            // 静音已开启 → 蓝色带斜杠图标
            btnMuteMic.setImageResource(R.drawable.icon_mic_muted);
        } else {
            // 静音已关闭（麦克风正常）→ 灰色图标
            btnMuteMic.setImageResource(R.drawable.icon_mic_gray);
        }
    }

    /**
     * 更新扬声器按钮图标
     * 逻辑：免提关闭 → 灰色图标（功能关闭态）
     *       免提开启 → 蓝色图标（功能开启态）
     */
    private void updateSpeakerButton() {
        if (btnSpeaker == null) return;
        if (isSpeakerOn) {
            // 免提已开启 → 蓝色图标
            btnSpeaker.setImageResource(R.drawable.icon_speaker_active);
        } else {
            // 免提已关闭 → 灰色图标
            btnSpeaker.setImageResource(R.drawable.icon_speaker_gray);
        }
    }

    // 在parseIntent之后调用，加载头像
    private void loadAvatar() {
        AvatarView avatarView = findViewById(R.id.avatarView);
        if (avatarView != null && targetUid != null) {
            avatarView.showAvatar(targetUid, (byte) 1); // WKChannelType.PERSONAL = 1
        }
    }

    private void parseIntent() {
        userId = getIntent().getStringExtra(EXTRA_USER_ID);
        targetUid = getIntent().getStringExtra(EXTRA_TARGET_UID);
        channelId = getIntent().getStringExtra(EXTRA_CHANNEL_ID);
        channelType = getIntent().getIntExtra(EXTRA_CHANNEL_TYPE, WKChannelType.PERSONAL);
        roomId = getIntent().getIntExtra(EXTRA_ROOM_ID, new Random().nextInt(100000) + 1);
        callerName = getIntent().getStringExtra(EXTRA_CALLER_NAME);
        myName = getIntent().getStringExtra(EXTRA_MY_NAME);
        callType = getIntent().getIntExtra(EXTRA_CALL_TYPE, TRTCType.AUDIO_CALL);
        sdkAppId = getIntent().getIntExtra(EXTRA_SDK_APP_ID, 0);
        userSig = getIntent().getStringExtra(EXTRA_USER_SIG);
        isCallee = getIntent().getBooleanExtra("is_callee", false);
    }

    private void checkPermissionsAndStart() {
        String[] permissions = callType == TRTCType.VIDEO_CALL
                ? new String[]{Manifest.permission.RECORD_AUDIO, Manifest.permission.CAMERA}
                : new String[]{Manifest.permission.RECORD_AUDIO};

        boolean allGranted = true;
        for (String perm : permissions) {
            if (ContextCompat.checkSelfPermission(this, perm) != PackageManager.PERMISSION_GRANTED) {
                allGranted = false;
                break;
            }
        }
        if (allGranted) startCall();
        else ActivityCompat.requestPermissions(this, permissions, 1001);
    }

    private void startCall() {
        callerNameTv.setText(callerName != null ? callerName : "");
        callStatusTv.setText(isCallee ? "正在接听..." : "正在等待对方接受邀请...");

        // 语音通话模式，隐藏视频View
        localVideoView.setVisibility(View.GONE);
        remoteVideoView.setVisibility(View.GONE);

        Log.d(TAG, "startCall: sdkAppId=" + sdkAppId + ", userId=" + userId + ", roomId=" + roomId + ", userSig length=" + (userSig != null ? userSig.length() : 0));

        // 先配置音频模式，再进入房间，确保进入房间后立即能听到对方音频
        audioManager = (AudioManager) getSystemService(Context.AUDIO_SERVICE);
        if (audioManager != null) {
            originalAudioMode = audioManager.getMode();
            originalRingerMode = audioManager.getRingerMode();
            // 请求音频焦点，确保后台通话保持音频
            int focusResult = audioManager.requestAudioFocus(
                    audioFocusListener,
                    AudioManager.STREAM_VOICE_CALL,
                    AudioManager.AUDIOFOCUS_GAIN
            );
            audioFocusGranted = (focusResult == AudioManager.AUDIOFOCUS_REQUEST_GRANTED);
            Log.d(TAG, "Audio focus request result: " + focusResult + " granted=" + audioFocusGranted);
            audioManager.setMode(AudioManager.MODE_IN_COMMUNICATION);
        }

        TRTCManager.getInstance().setListener(trtcCloudListener);

        TXCloudVideoView localView = callType == TRTCType.VIDEO_CALL ? localVideoView : null;
        TXCloudVideoView remoteView = callType == TRTCType.VIDEO_CALL ? remoteVideoView : null;

        TRTCManager.getInstance().enterRoom(
                this, sdkAppId, userId, userSig, roomId,
                callType, localView, remoteView
        );

        if (isCallee) {
            sendSignal(RTCSignalContent.SIGNAL_ACCEPT);
            callStatusTv.setText("通话中");
            onCallConnected();
        } else {
            // 主叫方：播放等待铃声
            startWaitingRingtone();
            sendSignal(RTCSignalContent.SIGNAL_INVITE);
            timeoutRunnable = () -> {
                if (callState == CallState.WAITING) {
                    callStatusTv.setText("无人接听");
                    stopWaitingRingtone();
                    sendSignal(RTCSignalContent.SIGNAL_CANCEL);
                    handler.postDelayed(this::finishWithResult, 1500);
                }
            };
            handler.postDelayed(timeoutRunnable, 45000);
        }
    }

    private void startWaitingRingtone() {
        try {
            if (waitingMediaPlayer == null) {
                waitingMediaPlayer = new MediaPlayer();
                // 必须在 prepare 之前设置音频流类型
                waitingMediaPlayer.setAudioStreamType(AudioManager.STREAM_RING);
                waitingMediaPlayer.setLooping(true);
                waitingMediaPlayer.setVolume(1.0f, 1.0f);
                // 设置数据源
                android.content.res.AssetFileDescriptor afd = getResources().openRawResourceFd(R.raw.newrtc);
                if (afd != null) {
                    waitingMediaPlayer.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
                    afd.close();
                }
                waitingMediaPlayer.prepare();
                waitingMediaPlayer.start();
                Log.d(TAG, "Waiting ringtone started (MediaPlayer, STREAM_RING, looping)");
            }
        } catch (Exception e) {
            Log.e(TAG, "Failed to play waiting ringtone: " + e.getMessage());
            // 备用方案：使用系统铃声
            try {
                Uri ringtoneUri = RingtoneManager.getActualDefaultRingtoneUri(this, RingtoneManager.TYPE_RINGTONE);
                if (ringtoneUri == null) {
                    ringtoneUri = Settings.System.DEFAULT_RINGTONE_URI;
                }
                waitingRingtone = RingtoneManager.getRingtone(this, ringtoneUri);
                if (waitingRingtone != null) {
                    waitingRingtone.setStreamType(AudioManager.STREAM_RING);
                    waitingRingtone.play();
                    Log.d(TAG, "Waiting ringtone started (fallback Ringtone)");
                }
            } catch (Exception e2) {
                Log.e(TAG, "Fallback ringtone also failed: " + e2.getMessage());
            }
        }
    }

    private void stopWaitingRingtone() {
        if (waitingMediaPlayer != null) {
            try {
                if (waitingMediaPlayer.isPlaying()) {
                    waitingMediaPlayer.stop();
                }
                waitingMediaPlayer.release();
                Log.d(TAG, "Waiting ringtone stopped (MediaPlayer)");
            } catch (Exception e) {
                Log.e(TAG, "Failed to stop MediaPlayer ringtone: " + e.getMessage());
            }
            waitingMediaPlayer = null;
        }
        if (waitingRingtone != null) {
            try {
                if (waitingRingtone.isPlaying()) {
                    waitingRingtone.stop();
                }
                Log.d(TAG, "Waiting ringtone stopped (Ringtone)");
            } catch (Exception e) {
                Log.e(TAG, "Failed to stop ringtone: " + e.getMessage());
            }
            waitingRingtone = null;
        }
    }

    /**
     * 播放挂断提示音（短促的"嘟"声）
     */
    private void playHangupTone() {
        try {
            if (toneGenerator == null) {
                toneGenerator = new ToneGenerator(AudioManager.STREAM_VOICE_CALL, ToneGenerator.MAX_VOLUME / 2);
            }
            // 播放短促的挂断提示音（忙音，200ms）
            toneGenerator.startTone(ToneGenerator.TONE_SUP_BUSY, 200);
            Log.d(TAG, "Hangup tone played");
        } catch (Exception e) {
            Log.e(TAG, "Failed to play hangup tone: " + e.getMessage());
        }
    }

    private void sendSignal(int signalType) {
        RTCSignalContent signal = new RTCSignalContent(
                signalType, callType, roomId, userId, myName != null ? myName : ""
        );
        WKIM.getInstance().getMsgManager().sendMessage(signal, channelId, (byte) channelType);
        Log.d(TAG, "Signal sent: " + signalType);
    }

    private void onCallConnected() {
        if (callState != CallState.WAITING) return;
        callState = CallState.CONNECTED;
        callStatusTv.setText("通话中");
        callStartTime = System.currentTimeMillis();
        TRTCManager.getInstance().setCallStartTime(callStartTime);
        callDurationTv.setVisibility(View.VISIBLE);
        startDurationTimer();
        if (timeoutRunnable != null) handler.removeCallbacks(timeoutRunnable);
        // 接通后停止等待铃声
        stopWaitingRingtone();
        // 确保头像显示
        loadAvatar();
        // 通话接通后保持扬声器开启
        isSpeakerOn = true;
        TRTCManager.getInstance().setSpeakerOn(true);
        updateSpeakerButton();
        // 如果是最小化状态，更新悬浮窗显示
        if (isMinimized && CallFloatingManager.getInstance().isShowing()) {
            CallFloatingManager.getInstance().updateTime(callDurationTv.getText().toString());
        }
    }

    private void onHangUp() {
        stopWaitingRingtone();
        // 播放挂断提示音
        playHangupTone();
        if (callState == CallState.CONNECTED) {
            sendSignal(RTCSignalContent.SIGNAL_HANGUP);
        } else if (callState == CallState.WAITING) {
            sendSignal(RTCSignalContent.SIGNAL_CANCEL);
        }
        handler.postDelayed(this::finishWithResult, 200);
    }

    private void finishWithResult() {
        stopWaitingRingtone();
        if (audioManager != null) {
            audioManager.abandonAudioFocus(audioFocusListener);
            audioFocusGranted = false;
            audioManager.setMode(originalAudioMode);
            audioManager.setRingerMode(originalRingerMode);
        }
        if (callState == CallState.CONNECTED && callStartTime > 0) {
            int duration = (int) ((System.currentTimeMillis() - callStartTime) / 1000);
            sendCallResultMessage(RTCMsgContent.RESULT_NORMAL, duration);
        } else if (callState == CallState.WAITING) {
            sendCallResultMessage(RTCMsgContent.RESULT_CANCEL, 0);
        }
        callState = CallState.ENDED;
        isMinimized = false; // 确保正常结束时退出房间
        finish();
    }

    private void sendCallResultMessage(int resultType, int duration) {
        // 通话结束，发送通话记录消息给对方（utalk逻辑：由结束方发送，双方都能看到）
        try {
            RTCMsgContent content = new RTCMsgContent(callType, resultType, duration);
            WKIM.getInstance().getMsgManager().sendMessage(content, channelId, (byte) channelType);
            Log.d(TAG, "Call result message sent: resultType=" + resultType + ", isCallee=" + isCallee);
        } catch (Exception e) {
            Log.e(TAG, "sendCallResultMessage error: " + e.getMessage(), e);
        }
    }

    private void startDurationTimer() {
        durationRunnable = new Runnable() {
            @Override
            public void run() {
                long elapsed = System.currentTimeMillis() - callStartTime;
                long minutes = TimeUnit.MILLISECONDS.toMinutes(elapsed);
                long seconds = TimeUnit.MILLISECONDS.toSeconds(elapsed) % 60;
                String timeStr = String.format(Locale.getDefault(), "%02d:%02d", minutes, seconds);
                callDurationTv.setText(timeStr);
                // 同步更新悬浮窗
                if (isMinimized) {
                    CallFloatingManager.getInstance().updateTime(timeStr);
                }
                handler.postDelayed(this, 1000);
            }
        };
        handler.post(durationRunnable);
    }

    private final TRTCCloudListener trtcCloudListener = new TRTCCloudListener() {
        @Override
        public void onError(int errCode, String errMsg, Bundle extraInfo) {
            runOnUiThread(() -> {
                callStatusTv.setText("通话错误: " + errMsg);
                handler.postDelayed(TRTCCallActivity.this::finishWithResult, 1500);
            });
        }

        @Override
        public void onEnterRoom(long elapsed) {
            runOnUiThread(() -> {
                callStatusTv.setText(isCallee ? "通话中" : "正在等待对方接受邀请...");
                // 拨号等待阶段默认开启扬声器，方便听到等待音
                isSpeakerOn = true;
                updateSpeakerButton();
                // 保存通话状态到单例（用于悬浮窗恢复）
                TRTCManager.getInstance().setCallActive(true, callType, sdkAppId, userId, targetUid,
                        channelId, channelType, roomId, callerName, myName, isCallee);
            });
        }

        @Override
        public void onExitRoom(int reason) {}

        @Override
        public void onRemoteUserEnterRoom(String remoteUserId) {
            runOnUiThread(() -> onCallConnected());
        }

        @Override
        public void onRemoteUserLeaveRoom(String remoteUserId, int reason) {
            runOnUiThread(() -> {
                if (callState == CallState.ENDED) return; // 已处理过则跳过
                callState = CallState.ENDED;
                callStatusTv.setText("对方已离开");
                stopWaitingRingtone();
                if (durationRunnable != null) handler.removeCallbacks(durationRunnable);
                // 播放挂断提示音
                playHangupTone();
                handler.postDelayed(TRTCCallActivity.this::finishWithResult, 800);
            });
        }

        @Override
        public void onUserVideoAvailable(String userId, boolean available) {
            runOnUiThread(() -> {
                if (available && callType == TRTCType.VIDEO_CALL) {
                    TRTCManager.getInstance().startRemoteView(userId, remoteVideoView);
                }
            });
        }

        @Override
        public void onUserAudioAvailable(String userId, boolean available) {}

        @Override
        public void onNetworkQuality(TRTCCloudDef.TRTCQuality localQuality,
                                     ArrayList<TRTCCloudDef.TRTCQuality> remoteQuality) {}
    };

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions,
                                           @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == 1001) {
            boolean allGranted = true;
            for (int result : grantResults) {
                if (result != PackageManager.PERMISSION_GRANTED) {
                    allGranted = false;
                    break;
                }
            }
            if (allGranted) startCall();
            else {
                Toast.makeText(this, "需要麦克风和摄像头权限才能进行通话", Toast.LENGTH_SHORT).show();
                finish();
            }
        }
    }

    private boolean isMinimized = false;

    private void minimizeToFloating() {
        if (isMinimized) return;
        // 检查悬浮窗权限
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !android.provider.Settings.canDrawOverlays(this)) {
            android.widget.Toast.makeText(this, "请先开启悬浮窗权限", android.widget.Toast.LENGTH_SHORT).show();
            Intent intent = new Intent(android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    android.net.Uri.parse("package:" + getPackageName()));
            startActivity(intent);
            return;
        }
        isMinimized = true;
        // 通话接通前显示状态文字，接通后显示时长
        String status;
        if (callState == CallState.CONNECTED && callStartTime > 0) {
            status = callDurationTv.getText().toString();
        } else {
            status = callStatusTv.getText().toString();
        }
        CallFloatingManager.getInstance().show(this, callerName, status, new CallFloatingManager.FloatingClickListener() {
            @Override
            public void onFloatingClick() {
                // 点击悬浮窗，重新启动通话页面
                if (CallFloatingManager.getInstance().getAppContext() != null) {
                    Intent intent = new Intent(CallFloatingManager.getInstance().getAppContext(), TRTCCallActivity.class);
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    CallFloatingManager.getInstance().getAppContext().startActivity(intent);
                }
            }
        });
        // 结束Activity，自然回到上一个页面（聊天窗口）
        finish();
    }

    private void restoreFromFloating() {
        if (!isMinimized) return;
        isMinimized = false;
        CallFloatingManager.getInstance().hide();
        // 恢复 Activity 到前台
        Intent intent = new Intent(this, TRTCCallActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
        startActivity(intent);
    }

    @Override
    protected void onResume() {
        super.onResume();
        // 从悬浮窗恢复时，隐藏悬浮窗
        if (isMinimized) {
            isMinimized = false;
            CallFloatingManager.getInstance().hide();
        }
        // 恢复通话音频模式
        if (audioManager != null && callState == CallState.CONNECTED) {
            audioManager.setMode(AudioManager.MODE_IN_COMMUNICATION);
            if (!audioFocusGranted) {
                int focusResult = audioManager.requestAudioFocus(
                        audioFocusListener,
                        AudioManager.STREAM_VOICE_CALL,
                        AudioManager.AUDIOFOCUS_GAIN
                );
                audioFocusGranted = (focusResult == AudioManager.AUDIOFOCUS_REQUEST_GRANTED);
                Log.d(TAG, "onResume: re-request audio focus: " + focusResult);
            }
            TRTCManager.getInstance().setSpeakerOn(isSpeakerOn);
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        // 切到后台时保持通话音频，不释放音频焦点
        // 只确保不在等待状态时释放铃声
        if (callState == CallState.WAITING) {
            stopWaitingRingtone();
        }
    }

    @Override
    protected void onStop() {
        super.onStop();
        // App进入后台，保持通话音频焦点不释放
        // 确保TRTC继续在后台渲染音频
        Log.d(TAG, "onStop: app backgrounded, keeping audio focus for call");
    }

    @Override
    protected void onStart() {
        super.onStart();
        // 从后台恢复，确保音频模式正确
        if (audioManager != null && callState == CallState.CONNECTED) {
            audioManager.setMode(AudioManager.MODE_IN_COMMUNICATION);
            TRTCManager.getInstance().setSpeakerOn(isSpeakerOn);
            Log.d(TAG, "onStart: restored from background, audio mode set");
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        instanceRef = null;
        if (durationRunnable != null) handler.removeCallbacks(durationRunnable);
        if (timeoutRunnable != null) handler.removeCallbacks(timeoutRunnable);
        handler.removeCallbacksAndMessages(null);
        TRTCManager.getInstance().removeListener(trtcCloudListener);
        stopWaitingRingtone();
        if (toneGenerator != null) {
            try {
                toneGenerator.release();
            } catch (Exception e) {
                Log.e(TAG, "Failed to release toneGenerator", e);
            }
            toneGenerator = null;
        }

        if (isMinimized) {
            // 最小化状态：保持音频焦点和 TRTC 房间不释放，悬浮窗保持通话
            Log.d(TAG, "onDestroy: minimized state, keeping audio focus and TRTC room");
        } else {
            // 正常结束：释放音频焦点并退出房间
            if (audioManager != null) {
                audioManager.abandonAudioFocus(audioFocusListener);
                audioFocusGranted = false;
                audioManager.setMode(originalAudioMode);
                audioManager.setRingerMode(originalRingerMode);
            }
            CallFloatingManager.getInstance().hide();
            TRTCManager.getInstance().exitRoom();
            TRTCManager.getInstance().clearCallState();
        }
    }
}
