package com.chat.uikit.search;

import android.content.Context;
import android.content.Intent;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.chad.library.adapter.base.BaseQuickAdapter;
import com.chad.library.adapter.base.viewholder.BaseViewHolder;
import com.chat.base.base.WKBaseActivity;
import com.chat.base.msgitem.WKContentType;
import com.chat.base.ui.components.AvatarView;
import com.chat.base.utils.WKTimeUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActRecordSearchLayoutBinding;
import com.google.android.material.tabs.TabLayout;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannelType;
import com.xinbida.wukongim.entity.WKMsg;
import com.xinbida.wukongim.interfaces.IGetOrSyncHistoryMsgBack;

import java.util.ArrayList;
import java.util.List;

public class RecordActivity extends WKBaseActivity<ActRecordSearchLayoutBinding> {

    private String channelId;
    private int channelType;
    private final String[] tabNames = {"全部", "文件", "链接", "名片", "语音", "@我"};
    private final int[] filterTypes = {-1, WKContentType.WK_FILE, -2, WKContentType.WK_CARD, WKContentType.WK_VOICE, -3};

    private RecordAdapter adapter;
    private final List<WKMsg> recordMsgs = new ArrayList<>();
    private int currentFilterIndex = 0;

    public static void start(Context context, String channelId, int channelType) {
        Intent intent = new Intent(context, RecordActivity.class);
        intent.putExtra("channel_id", channelId);
        intent.putExtra("channel_type", channelType);
        context.startActivity(intent);
    }

    @Override
    protected ActRecordSearchLayoutBinding getViewBinding() {
        return ActRecordSearchLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.chat_records);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        channelId = getIntent().getStringExtra("channel_id");
        channelType = getIntent().getIntExtra("channel_type", 1);

        adapter = new RecordAdapter();
        wkVBinding.recordRecyclerView.setLayoutManager(new LinearLayoutManager(this));
        wkVBinding.recordRecyclerView.setAdapter(adapter);

        for (String tabName : tabNames) {
            wkVBinding.tabLayout.addTab(wkVBinding.tabLayout.newTab().setText(tabName));
        }

        loadRecords();
    }

    @Override
    protected void initListener() {
        wkVBinding.tabLayout.addOnTabSelectedListener(new TabLayout.OnTabSelectedListener() {
            @Override
            public void onTabSelected(TabLayout.Tab tab) {
                currentFilterIndex = tab.getPosition();
                loadRecords();
            }

            @Override
            public void onTabUnselected(TabLayout.Tab tab) {
            }

            @Override
            public void onTabReselected(TabLayout.Tab tab) {
            }
        });
    }

    private void loadRecords() {
        if (TextUtils.isEmpty(channelId)) {
            wkVBinding.emptyView.setVisibility(View.VISIBLE);
            return;
        }

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
                            recordMsgs.clear();
                            if (list != null) {
                                int filterType = filterTypes[currentFilterIndex];
                                for (WKMsg msg : list) {
                                    if (filterType == -1) {
                                        recordMsgs.add(msg);
                                    } else if (filterType == -2) {
                                        if (msg.baseContentMsgModel != null
                                                && msg.baseContentMsgModel.getDisplayContent() != null
                                                && msg.baseContentMsgModel.getDisplayContent().contains("http")) {
                                            recordMsgs.add(msg);
                                        }
                                    } else if (filterType == -3) {
                                        if (msg.baseContentMsgModel != null && msg.baseContentMsgModel.mentionAll > 0) {
                                            recordMsgs.add(msg);
                                        }
                                    } else {
                                        if (msg.type == filterType) {
                                            recordMsgs.add(msg);
                                        }
                                    }
                                }
                            }
                            adapter.setList(recordMsgs);
                            wkVBinding.emptyView.setVisibility(recordMsgs.isEmpty() ? View.VISIBLE : View.GONE);
                        });
                    }
                }
        );
    }

    private static class RecordAdapter extends BaseQuickAdapter<WKMsg, BaseViewHolder> {
        public RecordAdapter() {
            super(R.layout.item_record_msg_layout);
        }

        @Override
        protected void convert(@NonNull BaseViewHolder helper, WKMsg item) {
            AvatarView avatarView = helper.getView(R.id.avatarView);
            avatarView.showAvatar(item.fromUID, WKChannelType.PERSONAL);

            helper.setText(R.id.senderNameTv, item.fromUID != null ? item.fromUID : "");
            helper.setText(R.id.contentTv, item.baseContentMsgModel != null ? item.baseContentMsgModel.getDisplayContent() : "");
            helper.setText(R.id.timeTv, WKTimeUtils.getInstance().getTimeString(item.timestamp));
        }
    }
}
