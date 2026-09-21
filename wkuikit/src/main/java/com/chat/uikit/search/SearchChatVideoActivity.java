package com.chat.uikit.search;

import android.content.Context;
import android.content.Intent;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import androidx.recyclerview.widget.GridLayoutManager;

import com.chat.base.act.PlayVideoActivity;
import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKApiConfig;
import com.chat.base.msgitem.WKContentType;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActSearchChatVideoLayoutBinding;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKMsg;
import com.xinbida.wukongim.interfaces.IGetOrSyncHistoryMsgBack;
import com.xinbida.wukongim.msgmodel.WKVideoContent;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

public class SearchChatVideoActivity extends WKBaseActivity<ActSearchChatVideoLayoutBinding> {

    private String channelId;
    private int channelType;
    private SearchVideoAdapter adapter;
    private final List<WKMsg> videoMsgs = new ArrayList<>();

    public static void startVideoSearch(Context context, String channelId, int channelType) {
        Intent intent = new Intent(context, SearchChatVideoActivity.class);
        intent.putExtra("channel_id", channelId);
        intent.putExtra("channel_type", channelType);
        context.startActivity(intent);
    }

    @Override
    protected ActSearchChatVideoLayoutBinding getViewBinding() {
        return ActSearchChatVideoLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.video_messages);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        channelId = getIntent().getStringExtra("channel_id");
        channelType = getIntent().getIntExtra("channel_type", 1);

        adapter = new SearchVideoAdapter();
        GridLayoutManager layoutManager = new GridLayoutManager(this, 3);
        wkVBinding.videoRecyclerView.setLayoutManager(layoutManager);
        wkVBinding.videoRecyclerView.setAdapter(adapter);

        loadVideos();
    }

    @Override
    protected void initListener() {
        adapter.setOnItemClickListener((a, view, position) -> {
            if (position < videoMsgs.size()) {
                playVideo(videoMsgs.get(position));
            }
        });
    }

    private void loadVideos() {
        if (TextUtils.isEmpty(channelId)) {
            wkVBinding.loadingBar.setVisibility(View.GONE);
            wkVBinding.emptyView.setVisibility(View.VISIBLE);
            return;
        }

        wkVBinding.loadingBar.setVisibility(View.VISIBLE);
        WKIM.getInstance().getMsgManager().getOrSyncHistoryMessages(
                channelId,
                (byte) channelType,
                0,
                false,
                0,
                500,
                0,
                new IGetOrSyncHistoryMsgBack() {
                    @Override
                    public void onSyncing() {
                    }

                    @Override
                    public void onResult(List<WKMsg> list) {
                        runOnUiThread(() -> {
                            wkVBinding.loadingBar.setVisibility(View.GONE);
                            videoMsgs.clear();
                            if (list != null) {
                                for (WKMsg msg : list) {
                                    if (msg.type == WKContentType.WK_VIDEO) {
                                        videoMsgs.add(msg);
                                    }
                                }
                            }
                            adapter.setNewData(videoMsgs);
                            if (videoMsgs.isEmpty()) {
                                wkVBinding.emptyView.setVisibility(View.VISIBLE);
                            } else {
                                wkVBinding.emptyView.setVisibility(View.GONE);
                            }
                        });
                    }
                }
        );
    }

    private void playVideo(WKMsg msg) {
        WKVideoContent content = (WKVideoContent) msg.baseContentMsgModel;

        String playUrl = "";
        if (!TextUtils.isEmpty(content.localPath)) {
            File file = new File(content.localPath);
            if (file.exists()) playUrl = content.localPath;
        }
        if (TextUtils.isEmpty(playUrl) && !TextUtils.isEmpty(content.url)) {
            playUrl = WKApiConfig.getShowUrl(content.url);
        }

        String coverUrl = "";
        if (!TextUtils.isEmpty(content.coverLocalPath)) {
            File file = new File(content.coverLocalPath);
            if (file.exists()) coverUrl = content.coverLocalPath;
        } else if (!TextUtils.isEmpty(content.cover)) {
            coverUrl = WKApiConfig.getShowUrl(content.cover);
        }

        Intent intent = new Intent(this, PlayVideoActivity.class);
        intent.putExtra("url", playUrl);
        intent.putExtra("coverImg", coverUrl);
        intent.putExtra("clientMsgNo", msg.clientMsgNO);
        startActivity(intent);
    }
}
