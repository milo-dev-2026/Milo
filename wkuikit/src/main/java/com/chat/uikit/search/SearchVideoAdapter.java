package com.chat.uikit.search;

import android.text.TextUtils;
import android.widget.ImageView;

import androidx.annotation.NonNull;

import com.chad.library.adapter.base.BaseQuickAdapter;
import com.chad.library.adapter.base.viewholder.BaseViewHolder;
import com.chat.base.config.WKApiConfig;
import com.chat.base.glide.GlideUtils;
import com.chat.uikit.R;
import com.xinbida.wukongim.entity.WKMsg;
import com.xinbida.wukongim.msgmodel.WKVideoContent;

import java.io.File;

public class SearchVideoAdapter extends BaseQuickAdapter<WKMsg, BaseViewHolder> {

    public SearchVideoAdapter() {
        super(R.layout.item_search_video_layout);
    }

    @Override
    protected void convert(@NonNull BaseViewHolder helper, WKMsg item) {
        if (!(item.baseContentMsgModel instanceof WKVideoContent)) return;
        WKVideoContent content = (WKVideoContent) item.baseContentMsgModel;

        String coverUrl = "";
        if (!TextUtils.isEmpty(content.coverLocalPath)) {
            File file = new File(content.coverLocalPath);
            if (file.exists()) coverUrl = content.coverLocalPath;
        } else if (!TextUtils.isEmpty(content.cover)) {
            coverUrl = WKApiConfig.getShowUrl(content.cover);
        }

        ImageView coverIv = helper.getView(R.id.videoCoverIv);
        if (!TextUtils.isEmpty(coverUrl)) {
            GlideUtils.getInstance().showImg(helper.itemView.getContext(), coverUrl, coverIv);
        } else {
            coverIv.setImageResource(R.drawable.default_view_bg);
        }

        if (content.second > 0) {
            helper.setVisible(R.id.durationTv, true);
            helper.setText(R.id.durationTv, formatDuration(content.second));
        } else {
            helper.setVisible(R.id.durationTv, false);
        }
    }

    private String formatDuration(long seconds) {
        long min = seconds / 60;
        long sec = seconds % 60;
        return String.format("%02d:%02d", min, sec);
    }
}
