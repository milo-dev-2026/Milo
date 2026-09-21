package com.chat.uikit.search;

import android.content.Context;
import android.content.Intent;
import android.text.TextUtils;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.GridLayoutManager;

import com.chad.library.adapter.base.BaseQuickAdapter;
import com.chad.library.adapter.base.viewholder.BaseViewHolder;
import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKApiConfig;
import com.chat.base.glide.GlideUtils;
import com.chat.base.msgitem.WKContentType;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActImageHistoryLayoutBinding;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKMsg;
import com.xinbida.wukongim.interfaces.IGetOrSyncHistoryMsgBack;
import com.xinbida.wukongim.msgmodel.WKImageContent;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

public class ImageMessageHistoryActivity extends WKBaseActivity<ActImageHistoryLayoutBinding> {

    private String channelId;
    private int channelType;
    private ImageAdapter adapter;
    private final List<WKMsg> imageMsgs = new ArrayList<>();

    public static void start(Context context, String channelId, int channelType) {
        Intent intent = new Intent(context, ImageMessageHistoryActivity.class);
        intent.putExtra("channel_id", channelId);
        intent.putExtra("channel_type", channelType);
        context.startActivity(intent);
    }

    @Override
    protected ActImageHistoryLayoutBinding getViewBinding() {
        return ActImageHistoryLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.image_history);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        channelId = getIntent().getStringExtra("channel_id");
        channelType = getIntent().getIntExtra("channel_type", 1);

        adapter = new ImageAdapter();
        wkVBinding.imageRecyclerView.setLayoutManager(
                new androidx.recyclerview.widget.GridLayoutManager(this, 3));
        wkVBinding.imageRecyclerView.setAdapter(adapter);

        loadImages();
    }

    @Override
    protected void initListener() {
    }

    private void loadImages() {
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
                            imageMsgs.clear();
                            if (list != null) {
                                for (WKMsg msg : list) {
                                    if (msg.type == WKContentType.WK_IMAGE) {
                                        imageMsgs.add(msg);
                                    }
                                }
                            }
                            adapter.setList(imageMsgs);
                            wkVBinding.emptyView.setVisibility(imageMsgs.isEmpty() ? View.VISIBLE : View.GONE);
                        });
                    }
                }
        );
    }

    private static class ImageAdapter extends BaseQuickAdapter<WKMsg, BaseViewHolder> {
        public ImageAdapter() {
            super(R.layout.item_image_grid_layout);
        }

        @Override
        protected void convert(@NonNull BaseViewHolder helper, WKMsg item) {
            ImageView imageIv = helper.getView(R.id.imageIv);
            if (!(item.baseContentMsgModel instanceof WKImageContent)) return;
            WKImageContent content = (WKImageContent) item.baseContentMsgModel;

            String url = "";
            if (!TextUtils.isEmpty(content.localPath)) {
                File file = new File(content.localPath);
                if (file.exists()) url = content.localPath;
            } else if (!TextUtils.isEmpty(content.url)) {
                url = WKApiConfig.getShowUrl(content.url);
            }

            if (!TextUtils.isEmpty(url)) {
                GlideUtils.getInstance().showImg(helper.itemView.getContext(), url, imageIv);
            } else {
                imageIv.setImageResource(R.drawable.default_view_bg);
            }
        }
    }
}
