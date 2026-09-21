package com.chat.uikit.chat.pin;

import android.content.Intent;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.net.ICommonListener;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.WKReader;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityMessagePinBinding;
import com.chat.uikit.message.MsgModel;
import com.xinbida.wukongim.entity.WKMsg;

import java.util.ArrayList;
import java.util.List;

/**
 * 置顶消息列表页面
 */
public class MessagePinActivity extends WKBaseActivity<ActivityMessagePinBinding> {

    private String channelId;
    private byte channelType;
    private MessagePinAdapter adapter;
    private final List<WKMsg> pinnedMsgList = new ArrayList<>();
    private ItemTouchHelper itemTouchHelper;

    public static void start(android.content.Context context, String channelId, byte channelType) {
        Intent intent = new Intent(context, MessagePinActivity.class);
        intent.putExtra("channelId", channelId);
        intent.putExtra("channelType", channelType);
        context.startActivity(intent);
    }

    @Override
    protected ActivityMessagePinBinding getViewBinding() {
        return ActivityMessagePinBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.pinned_messages);
    }

    @Override
    protected void initPresenter() {
        channelId = getIntent().getStringExtra("channelId");
        channelType = getIntent().getByteExtra("channelType", (byte) 0);
    }

    @Override
    protected void initView() {
        adapter = new MessagePinAdapter(pinnedMsgList);
        wkVBinding.recyclerView.setLayoutManager(new LinearLayoutManager(this));
        wkVBinding.recyclerView.setAdapter(adapter);

        // 设置空布局
        View emptyView = getLayoutInflater().inflate(R.layout.empty_layout, null);
        adapter.setEmptyView(emptyView);

        // 初始化滑动删除
        initSwipeToDelete();
    }

    @Override
    protected void initListener() {
        //  item 点击 → 返回聊天页面并定位到该消息
        adapter.setOnItemClickListener((adapter, view, position) -> {
            WKMsg msg = (WKMsg) adapter.getItem(position);
            if (msg != null) {
                Intent intent = new Intent();
                intent.putExtra("clientMsgNO", msg.clientMsgNO);
                intent.putExtra("messageID", msg.messageID);
                setResult(RESULT_OK, intent);
                finish();
            }
        });

        // 取消全部置顶
        SingleClickUtil.onSingleClick(wkVBinding.cancelAllPins, v -> {
            if (WKReader.isEmpty(pinnedMsgList)) {
                WKToastUtils.getInstance().showToastNormal("暂无置顶消息");
                return;
            }
            WKDialogUtils.getInstance().showDialog(this, "",
                    getString(R.string.confirm_cancel_all_pins),
                    true, "", getString(R.string.cancel_all_pins),
                    0, ContextCompat.getColor(this, R.color.colorFA5151),
                    index -> {
                        if (index == 1) {
                            clearAllPinnedMessages();
                        }
                    });
        });
    }

    @Override
    protected void initData() {
        loadPinnedMessages();
    }

    /**
     * 加载置顶消息列表
     */
    private void loadPinnedMessages() {
        loadingPopup.show();
        MsgModel.getInstance().getPinnedMsgList(channelId, channelType, new MsgModel.IPinnedMsgListListener() {
            @Override
            public void onSuccess(List<WKMsg> msgList) {
                loadingPopup.dismiss();
                pinnedMsgList.clear();
                if (msgList != null) {
                    pinnedMsgList.addAll(msgList);
                }
                adapter.setList(pinnedMsgList);
            }

            @Override
            public void onFail(int code, String msg) {
                loadingPopup.dismiss();
                WKToastUtils.getInstance().showToastFail(msg);
            }
        });
    }

    /**
     * 取消单条消息置顶
     */
    private void unpinMessage(int position) {
        if (position < 0 || position >= pinnedMsgList.size()) return;
        WKMsg msg = pinnedMsgList.get(position);
        if (msg == null) return;

        MsgModel.getInstance().pinMsg(msg.messageID, msg.channelID, msg.channelType, msg.messageSeq, false, new ICommonListener() {
            @Override
            public void onResult(int code, String result) {
                if (code == HttpResponseCode.success) {
                    MsgModel.getInstance().syncExtraMsg(channelId, channelType);
                    pinnedMsgList.remove(position);
                    adapter.notifyItemRemoved(position);
                    WKToastUtils.getInstance().showToastNormal("已取消置顶");
                } else {
                    WKToastUtils.getInstance().showToastFail("取消置顶失败");
                    adapter.notifyItemChanged(position);
                }
            }
        });
    }

    /**
     * 清除所有置顶消息
     */
    private void clearAllPinnedMessages() {
        loadingPopup.show();
        MsgModel.getInstance().clearPinnedMsg(channelId, channelType, new ICommonListener() {
            @Override
            public void onResult(int code, String result) {
                loadingPopup.dismiss();
                if (code == HttpResponseCode.success) {
                    MsgModel.getInstance().syncExtraMsg(channelId, channelType);
                    pinnedMsgList.clear();
                    adapter.setList(pinnedMsgList);
                    WKToastUtils.getInstance().showToastNormal("已取消所有置顶");
                } else {
                    WKToastUtils.getInstance().showToastFail("操作失败");
                }
            }
        });
    }

    /**
     * 初始化滑动删除
     */
    private void initSwipeToDelete() {
        ItemTouchHelper.SimpleCallback swipeCallback = new ItemTouchHelper.SimpleCallback(0, ItemTouchHelper.LEFT) {
            @Override
            public boolean onMove(@NonNull RecyclerView recyclerView,
                                  @NonNull RecyclerView.ViewHolder viewHolder,
                                  @NonNull RecyclerView.ViewHolder target) {
                return false;
            }

            @Override
            public void onSwiped(@NonNull RecyclerView.ViewHolder viewHolder, int direction) {
                int position = viewHolder.getAdapterPosition();
                if (direction == ItemTouchHelper.LEFT) {
                    // 确认删除
                    WKDialogUtils.getInstance().showDialog(MessagePinActivity.this, "",
                            "确定取消置顶该消息？",
                            true, "", "取消置顶",
                            0, ContextCompat.getColor(MessagePinActivity.this, R.color.colorFA5151),
                            index -> {
                                if (index == 1) {
                                    unpinMessage(position);
                                } else {
                                    adapter.notifyItemChanged(position);
                                }
                            });
                }
            }
        };

        itemTouchHelper = new ItemTouchHelper(swipeCallback);
        itemTouchHelper.attachToRecyclerView(wkVBinding.recyclerView);
    }

    @Override
    protected void onDestroy() {
        if (itemTouchHelper != null) {
            itemTouchHelper.attachToRecyclerView(null);
        }
        super.onDestroy();
    }
}
