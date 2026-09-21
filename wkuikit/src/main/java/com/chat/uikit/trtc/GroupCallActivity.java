package com.chat.uikit.trtc;

import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.trtc.TRTCManager;
import com.chat.base.trtc.TRTCType;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActGroupCallLayoutBinding;
import com.tencent.trtc.TRTCCloudDef;
import com.tencent.trtc.TRTCCloudListener;
import com.tencent.rtmp.ui.TXCloudVideoView;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.ArrayList;
import java.util.List;

public class GroupCallActivity extends WKBaseActivity<ActGroupCallLayoutBinding> {

    public static final String KEY_ROOM_ID = "room_id";
    public static final String KEY_CALL_TYPE = "call_type";
    public static final String KEY_GROUP_NAME = "group_name";
    public static final String KEY_PARTICIPANTS = "participants";
    public static final String KEY_CHANNEL_ID = "channel_id";
    public static final String KEY_SDK_APP_ID = "sdk_app_id";
    public static final String KEY_USER_SIG = "user_sig";
    public static final String KEY_USER_ID = "user_id";

    private List<Participant> participantList = new ArrayList<>();
    private ParticipantAdapter adapter;
    private Handler handler = new Handler(Looper.getMainLooper());
    private long startTime = 0;
    private boolean isMicOn = true;
    private boolean isSpeakerOn = true;
    private Runnable timerRunnable;
    private int roomId;
    private int callType = TRTCType.AUDIO_CALL;
    private String channelId;
    private String userId;
    private int sdkAppId;
    private String userSig;
    private boolean callConnected = false;

    @Override
    protected ActGroupCallLayoutBinding getViewBinding() {
        return ActGroupCallLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        String groupName = getIntent().getStringExtra(KEY_GROUP_NAME);
        titleTv.setText(groupName != null ? groupName : "群通话");
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        roomId = getIntent().getIntExtra(KEY_ROOM_ID, 0);
        callType = getIntent().getIntExtra(KEY_CALL_TYPE, TRTCType.AUDIO_CALL);
        channelId = getIntent().getStringExtra(KEY_CHANNEL_ID);
        userId = getIntent().getStringExtra(KEY_USER_ID);
        sdkAppId = getIntent().getIntExtra(KEY_SDK_APP_ID, 0);
        userSig = getIntent().getStringExtra(KEY_USER_SIG);

        participantList.add(new Participant("self", "我", false, true));

        String participants = getIntent().getStringExtra(KEY_PARTICIPANTS);
        if (participants != null && !participants.isEmpty()) {
            String[] uids = participants.split(",");
            for (String uid : uids) {
                if (!uid.equals(userId)) {
                    participantList.add(new Participant(uid.trim(), uid.trim(), false, true));
                }
            }
        }

        adapter = new ParticipantAdapter(participantList);
        wkVBinding.participantsRv.setLayoutManager(new GridLayoutManager(this, 2));
        wkVBinding.participantsRv.setAdapter(adapter);

        enterTRTCRoom();
        startTime = System.currentTimeMillis();
        startCallTimer();
    }

    private void enterTRTCRoom() {
        TRTCManager.getInstance().setListener(groupTRTCListener);
        TRTCManager.getInstance().enterRoom(
                this, sdkAppId, userId, userSig, roomId,
                callType, null, null
        );
    }

    @Override
    protected void initListener() {
        SingleClickUtil.onSingleClick(wkVBinding.micBtn, v -> {
            isMicOn = !isMicOn;
            TRTCManager.getInstance().toggleMic();
            wkVBinding.micIcon.setImageResource(isMicOn ? R.drawable.ic_mic_on : R.drawable.ic_mic_off);
            WKToastUtils.getInstance().showToastNormal(isMicOn ? "麦克风已开" : "麦克风已关");
        });

        SingleClickUtil.onSingleClick(wkVBinding.speakerBtn, v -> {
            isSpeakerOn = !isSpeakerOn;
            TRTCManager.getInstance().toggleSpeaker();
            wkVBinding.speakerIcon.setImageResource(isSpeakerOn ? R.drawable.ic_speaker_on : R.drawable.ic_speaker_off);
            WKToastUtils.getInstance().showToastNormal(isSpeakerOn ? "扬声器已开" : "扬声器已关");
        });

        SingleClickUtil.onSingleClick(wkVBinding.hangUpBtn, v -> {
            finishCall();
        });

        SingleClickUtil.onSingleClick(wkVBinding.minimizeBtn, v -> {
            FloatCallWindow.getInstance(this).show("群通话", false);
            finish();
        });
    }

    private final TRTCCloudListener groupTRTCListener = new TRTCCloudListener() {
        @Override
        public void onError(int errCode, String errMsg, Bundle extraInfo) {
            runOnUiThread(() -> WKToastUtils.getInstance().showToastNormal("通话错误: " + errMsg));
        }

        @Override
        public void onEnterRoom(long elapsed) {
            callConnected = true;
        }

        @Override
        public void onExitRoom(int reason) {}

        @Override
        public void onRemoteUserEnterRoom(String remoteUserId) {
            runOnUiThread(() -> {
                boolean found = false;
                for (Participant p : participantList) {
                    if (p.uid.equals(remoteUserId)) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    participantList.add(new Participant(remoteUserId, remoteUserId, false, true));
                    adapter.notifyDataSetChanged();
                }
            });
        }

        @Override
        public void onRemoteUserLeaveRoom(String remoteUserId, int reason) {
            runOnUiThread(() -> {
                participantList.removeIf(p -> p.uid.equals(remoteUserId));
                adapter.notifyDataSetChanged();
            });
        }

        @Override
        public void onUserVideoAvailable(String userId, boolean available) {}

        @Override
        public void onUserAudioAvailable(String userId, boolean available) {
            runOnUiThread(() -> {
                for (Participant p : participantList) {
                    if (p.uid.equals(userId)) {
                        p.isSpeaking = available;
                        break;
                    }
                }
                adapter.notifyDataSetChanged();
            });
        }

        @Override
        public void onNetworkQuality(TRTCCloudDef.TRTCQuality localQuality,
                                     ArrayList<TRTCCloudDef.TRTCQuality> remoteQuality) {}
    };

    private void startCallTimer() {
        timerRunnable = new Runnable() {
            @Override
            public void run() {
                long elapsed = System.currentTimeMillis() - startTime;
                long minutes = elapsed / 60000;
                long seconds = (elapsed % 60000) / 1000;
                wkVBinding.durationTv.setText(String.format("%02d:%02d", minutes, seconds));
                handler.postDelayed(this, 1000);
            }
        };
        handler.post(timerRunnable);
    }

    private void finishCall() {
        if (timerRunnable != null) {
            handler.removeCallbacks(timerRunnable);
        }
        TRTCManager.getInstance().removeListener(groupTRTCListener);
        TRTCManager.getInstance().exitRoom();
        WKToastUtils.getInstance().showToastNormal("通话结束");
        finish();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (timerRunnable != null) {
            handler.removeCallbacks(timerRunnable);
        }
        TRTCManager.getInstance().removeListener(groupTRTCListener);
        TRTCManager.getInstance().exitRoom();
    }

    public static class Participant {
        public String uid;
        public String name;
        public boolean isSpeaking;
        public boolean isMicOn;

        public Participant(String uid, String name, boolean isSpeaking, boolean isMicOn) {
            this.uid = uid;
            this.name = name;
            this.isSpeaking = isSpeaking;
            this.isMicOn = isMicOn;
        }
    }

    private static class ParticipantAdapter extends RecyclerView.Adapter<ParticipantAdapter.ViewHolder> {
        private List<Participant> list;

        ParticipantAdapter(List<Participant> list) {
            this.list = list;
        }

        @NonNull
        @Override
        public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
            View view = LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.item_call_member, parent, false);
            return new ViewHolder(view);
        }

        @Override
        public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
            Participant p = list.get(position);
            holder.nameTv.setText(p.name);
            if (p.isSpeaking) {
                holder.itemView.setBackgroundResource(R.drawable.corner_bg_8);
            }
        }

        @Override
        public int getItemCount() {
            return list.size();
        }

        static class ViewHolder extends RecyclerView.ViewHolder {
            TextView nameTv;

            ViewHolder(View itemView) {
                super(itemView);
                nameTv = itemView.findViewById(R.id.nameTv);
            }
        }
    }
}
