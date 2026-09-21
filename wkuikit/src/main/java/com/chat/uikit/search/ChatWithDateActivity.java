package com.chat.uikit.search;

import android.content.Context;
import android.content.Intent;
import android.text.TextUtils;
import android.view.View;
import android.widget.CalendarView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.chad.library.adapter.base.BaseQuickAdapter;
import com.chad.library.adapter.base.viewholder.BaseViewHolder;
import com.chat.base.base.WKBaseActivity;
import com.chat.base.msgitem.WKContentType;
import com.chat.base.utils.WKTimeUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActChatWithDateLayoutBinding;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKMsg;
import com.xinbida.wukongim.interfaces.IGetOrSyncHistoryMsgBack;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

public class ChatWithDateActivity extends WKBaseActivity<ActChatWithDateLayoutBinding> {

    private String channelId;
    private int channelType;
    private MsgAdapter adapter;
    private final List<WKMsg> msgList = new ArrayList<>();
    private long selectedDateMillis;

    public static void start(Context context, String channelId, int channelType) {
        Intent intent = new Intent(context, ChatWithDateActivity.class);
        intent.putExtra("channel_id", channelId);
        intent.putExtra("channel_type", channelType);
        context.startActivity(intent);
    }

    @Override
    protected ActChatWithDateLayoutBinding getViewBinding() {
        return ActChatWithDateLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.search_by_date);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        channelId = getIntent().getStringExtra("channel_id");
        channelType = getIntent().getIntExtra("channel_type", 1);

        adapter = new MsgAdapter();
        wkVBinding.msgRecyclerView.setLayoutManager(new LinearLayoutManager(this));
        wkVBinding.msgRecyclerView.setAdapter(adapter);

        Calendar cal = Calendar.getInstance();
        cal.set(Calendar.HOUR_OF_DAY, 0);
        cal.set(Calendar.MINUTE, 0);
        cal.set(Calendar.SECOND, 0);
        cal.set(Calendar.MILLISECOND, 0);
        selectedDateMillis = cal.getTimeInMillis();

        wkVBinding.calendarView.setOnDateChangeListener(new CalendarView.OnDateChangeListener() {
            @Override
            public void onSelectedDayChange(@NonNull CalendarView view, int year, int month, int dayOfMonth) {
                Calendar c = Calendar.getInstance();
                c.set(year, month, dayOfMonth, 0, 0, 0);
                c.set(Calendar.MILLISECOND, 0);
                selectedDateMillis = c.getTimeInMillis();
                loadMessagesByDate();
            }
        });

        loadMessagesByDate();
    }

    @Override
    protected void initListener() {
    }

    private void loadMessagesByDate() {
        if (TextUtils.isEmpty(channelId)) {
            wkVBinding.emptyView.setVisibility(View.VISIBLE);
            return;
        }

        Calendar endCal = Calendar.getInstance();
        endCal.setTimeInMillis(selectedDateMillis);
        endCal.add(Calendar.DAY_OF_MONTH, 1);

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
                            msgList.clear();
                            if (list != null) {
                                for (WKMsg msg : list) {
                                    if (msg.timestamp >= selectedDateMillis
                                            && msg.timestamp < endCal.getTimeInMillis()) {
                                        msgList.add(msg);
                                    }
                                }
                            }
                            adapter.setList(msgList);
                            wkVBinding.emptyView.setVisibility(msgList.isEmpty() ? View.VISIBLE : View.GONE);
                        });
                    }
                }
        );
    }

    private static class MsgAdapter extends BaseQuickAdapter<WKMsg, BaseViewHolder> {
        public MsgAdapter() {
            super(R.layout.item_record_msg_layout);
        }

        @Override
        protected void convert(@NonNull BaseViewHolder helper, WKMsg item) {
            helper.setText(R.id.senderNameTv, item.fromUID != null ? item.fromUID : "");
            helper.setText(R.id.contentTv, item.baseContentMsgModel != null ? item.baseContentMsgModel.getDisplayContent() : "");
            helper.setText(R.id.timeTv, WKTimeUtils.getInstance().getTimeString(item.timestamp));
        }
    }
}
