package com.chat.uikit.trtc;

import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.Ringtone;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.CountDownTimer;
import android.os.Vibrator;
import android.provider.Settings;
import android.view.View;
import android.view.Window;

import androidx.appcompat.app.AppCompatActivity;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsControllerCompat;

import com.chat.base.config.WKConfig;
import com.chat.base.trtc.TRTCType;
import com.chat.base.utils.NotificationCompatUtil;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActWaitingAnswerLayoutBinding;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannelType;

import java.lang.ref.WeakReference;

/**
 * 被叫方接听页面
 */
public class WaitingAnswerActivity extends AppCompatActivity {

    private static WeakReference<WaitingAnswerActivity> instanceRef;

    public static void notifyCancel() {
        WaitingAnswerActivity activity = instanceRef != null ? instanceRef.get() : null;
        if (activity != null && !activity.isFinishing() && !activity.isDestroyed()) {
            activity.runOnUiThread(() -> {
                activity.cancelNotificationAndVibrate();
                activity.finish();
            });
        }
    }

    public static final String KEY_CALLER_NAME = "caller_name";
    public static final String KEY_CALLER_ID = "caller_id";
    public static final String KEY_ROOM_ID = "room_id";
    public static final String KEY_CALL_TYPE = "call_type";
    public static final String KEY_SDK_APP_ID = "sdk_app_id";
    public static final String KEY_USER_SIG = "user_sig";
    public static final String KEY_IS_VIDEO = "is_video";

    private ActWaitingAnswerLayoutBinding binding;
    private CountDownTimer timeoutTimer;
    private Vibrator vibrator;
    private Ringtone incomingRingtone;
    private MediaPlayer incomingMediaPlayer;

    private String callerId;
    private String callerName;
    private int roomId;
    private int callType;
    private int sdkAppId;
    private String userSig;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        instanceRef = new WeakReference<>(this);
        // 状态栏透明并与页面同色，适配灵动岛
        Window window = getWindow();
        WindowCompat.setDecorFitsSystemWindows(window, false);
        window.setStatusBarColor(Color.TRANSPARENT);
        WindowInsetsControllerCompat controller = WindowCompat.getInsetsController(window, window.getDecorView());
        if (controller != null) {
            controller.setAppearanceLightStatusBars(false);
        }
        binding = ActWaitingAnswerLayoutBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        callerId = getIntent().getStringExtra(KEY_CALLER_ID);
        callerName = getIntent().getStringExtra(KEY_CALLER_NAME);
        roomId = getIntent().getIntExtra(KEY_ROOM_ID, 0);
        callType = getIntent().getIntExtra(KEY_CALL_TYPE, TRTCType.AUDIO_CALL);
        sdkAppId = getIntent().getIntExtra(KEY_SDK_APP_ID, 0);
        userSig = getIntent().getStringExtra(KEY_USER_SIG);
        boolean isVideo = getIntent().getBooleanExtra(KEY_IS_VIDEO, false);

        binding.nameTv.setText(callerName != null ? callerName : "未知用户");
        binding.otherTv.setText(isVideo ? "邀请你视频通话" : "邀请你语音通话");

        // 加载来电方头像
        if (callerId != null && !callerId.isEmpty()) {
            com.chat.base.glide.GlideUtils.getInstance().showAvatarImg(
                    this, callerId, (byte) 1, "avatar", binding.avatarIv);
        }

        binding.answerIv.setOnClickListener(v -> answerCall());
        binding.hangUpIv.setOnClickListener(v -> refuseCall());

        binding.answerIv.setImageResource(isVideo ? R.mipmap.ic_video_answer : R.mipmap.ic_audio_answer);

        // 震动（尊重用户震动设置和免打扰时段）
        boolean shouldVibrate = true;
        try {
            com.chat.base.entity.UserInfoSetting setting = WKConfig.getInstance().getUserInfo() != null
                    ? WKConfig.getInstance().getUserInfo().setting : null;
            if (setting != null) {
                if (setting.shock_on == 0) {
                    shouldVibrate = false;
                }
                // 免打扰时段检查
                if (setting.dnd_on == 1 && setting.dnd_start != null && setting.dnd_end != null) {
                    java.util.Calendar now = java.util.Calendar.getInstance();
                    int currentMinutes = now.get(java.util.Calendar.HOUR_OF_DAY) * 60 + now.get(java.util.Calendar.MINUTE);
                    String[] sp = setting.dnd_start.split(":");
                    String[] ep = setting.dnd_end.split(":");
                    int startMin = Integer.parseInt(sp[0]) * 60 + Integer.parseInt(sp[1]);
                    int endMin = Integer.parseInt(ep[0]) * 60 + Integer.parseInt(ep[1]);
                    boolean inDnd = (startMin < endMin)
                            ? (currentMinutes >= startMin && currentMinutes < endMin)
                            : (currentMinutes >= startMin || currentMinutes < endMin);
                    if (inDnd) shouldVibrate = false;
                }
            }
        } catch (Exception ignored) {
        }
        if (shouldVibrate) {
            vibrator = (Vibrator) getSystemService(Context.VIBRATOR_SERVICE);
            long[] pattern = {0, 1000, 1000};
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                vibrator.vibrate(pattern, 0, new android.media.AudioAttributes.Builder()
                        .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setUsage(android.media.AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                        .build());
            } else {
                vibrator.vibrate(pattern, 0);
            }
        }

        // 播放来电铃声（使用 MediaPlayer 确保循环播放可靠）
        try {
            incomingMediaPlayer = new MediaPlayer();
            // 必须在 prepare 之前设置音频流类型
            incomingMediaPlayer.setAudioStreamType(AudioManager.STREAM_RING);
            incomingMediaPlayer.setLooping(true);
            incomingMediaPlayer.setVolume(1.0f, 1.0f);
            // 设置数据源
            android.content.res.AssetFileDescriptor afd = getResources().openRawResourceFd(R.raw.newrtc);
            if (afd != null) {
                incomingMediaPlayer.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
                afd.close();
            }
            incomingMediaPlayer.prepare();
            incomingMediaPlayer.start();
            android.util.Log.d("WaitingAnswer", "Incoming ringtone started (MediaPlayer, STREAM_RING, looping)");
        } catch (Exception e) {
            android.util.Log.e("WaitingAnswer", "MediaPlayer ringtone failed: " + e.getMessage());
            playFallbackRingtone();
        }

        timeoutTimer = new CountDownTimer(45000, 1000) {
            @Override
            public void onTick(long millisUntilFinished) {
            }

            @Override
            public void onFinish() {
                // 超时自动拒绝
                sendSignal(RTCSignalContent.SIGNAL_REFUSE);
                sendCallResultMessage(RTCMsgContent.RESULT_MISSED, 0);
                cancelNotificationAndVibrate();
                finish();
            }
        };
        timeoutTimer.start();

        overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
    }

    private void answerCall() {
        cancelNotificationAndVibrate();
        if (timeoutTimer != null) {
            timeoutTimer.cancel();
        }

        // 发送接听信令
        sendSignal(RTCSignalContent.SIGNAL_ACCEPT);

        String myUid = WKConfig.getInstance().getUid();
        String myName = WKConfig.getInstance().getUserName();
        if (myName == null || myName.isEmpty()) {
            myName = "用户";
        }
        Intent intent = new Intent(this, TRTCCallActivity.class);
        intent.putExtra(TRTCCallActivity.EXTRA_USER_ID, myUid);
        intent.putExtra(TRTCCallActivity.EXTRA_TARGET_UID, callerId);
        intent.putExtra(TRTCCallActivity.EXTRA_CALLER_NAME, callerName);
        intent.putExtra(TRTCCallActivity.EXTRA_MY_NAME, myName);
        intent.putExtra(TRTCCallActivity.EXTRA_ROOM_ID, roomId);
        intent.putExtra(TRTCCallActivity.EXTRA_CALL_TYPE, callType);
        intent.putExtra(TRTCCallActivity.EXTRA_SDK_APP_ID, sdkAppId);
        intent.putExtra(TRTCCallActivity.EXTRA_USER_SIG, userSig);
        intent.putExtra("is_callee", true);
        startActivity(intent);
        finish();
    }

    private void refuseCall() {
        cancelNotificationAndVibrate();
        if (timeoutTimer != null) {
            timeoutTimer.cancel();
        }
        // 发送拒绝信令
        sendSignal(RTCSignalContent.SIGNAL_REFUSE);
        // 发送通话记录消息
        sendCallResultMessage(RTCMsgContent.RESULT_DECLINED, 0);
        android.util.Log.d("WaitingAnswer", "refuseCall: sent decline message to " + callerId);
        finish();
    }

    private void sendSignal(int signalType) {
        try {
            String myUid = WKConfig.getInstance().getUid();
            RTCSignalContent signal = new RTCSignalContent(
                    signalType, callType, roomId, myUid, ""
            );
            WKIM.getInstance().getMsgManager().sendMessage(signal, callerId, WKChannelType.PERSONAL);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void sendCallResultMessage(int resultType, int duration) {
        // 通话结束，发送通话记录消息给对方（utalk逻辑：由结束方发送，双方都能看到）
        try {
            RTCMsgContent content = new RTCMsgContent(callType, resultType, duration);
            WKIM.getInstance().getMsgManager().sendMessage(content, callerId, WKChannelType.PERSONAL);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void cancelNotificationAndVibrate() {
        // 停止 MediaPlayer 铃声
        if (incomingMediaPlayer != null) {
            try {
                if (incomingMediaPlayer.isPlaying()) {
                    incomingMediaPlayer.stop();
                }
                incomingMediaPlayer.release();
                android.util.Log.d("WaitingAnswer", "Incoming ringtone stopped (MediaPlayer)");
            } catch (Exception e) {
                e.printStackTrace();
            }
            incomingMediaPlayer = null;
        }
        // 停止备用 Ringtone
        if (incomingRingtone != null) {
            try {
                if (incomingRingtone.isPlaying()) {
                    incomingRingtone.stop();
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
            incomingRingtone = null;
        }
        if (vibrator != null) {
            try {
                vibrator.cancel();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        try {
            NotificationCompatUtil.Companion.cancel(this, 2);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /**
     * 备用方案：使用系统铃声
     */
    private void playFallbackRingtone() {
        try {
            Uri ringtoneUri = RingtoneManager.getActualDefaultRingtoneUri(this, RingtoneManager.TYPE_RINGTONE);
            if (ringtoneUri == null) {
                ringtoneUri = Settings.System.DEFAULT_RINGTONE_URI;
            }
            incomingRingtone = RingtoneManager.getRingtone(this, ringtoneUri);
            if (incomingRingtone != null) {
                incomingRingtone.setStreamType(AudioManager.STREAM_RING);
                incomingRingtone.play();
                android.util.Log.d("WaitingAnswer", "Fallback ringtone started");
            }
        } catch (Exception e) {
            android.util.Log.e("WaitingAnswer", "Fallback ringtone also failed: " + e.getMessage());
        }
    }

    @Override
    public void finish() {
        instanceRef = null;
        cancelNotificationAndVibrate();
        if (timeoutTimer != null) {
            timeoutTimer.cancel();
        }
        super.finish();
        overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
    }
}
