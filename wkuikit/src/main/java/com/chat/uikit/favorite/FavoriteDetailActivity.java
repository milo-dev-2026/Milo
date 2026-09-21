package com.chat.uikit.favorite;

import android.content.Intent;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import com.bumptech.glide.Glide;
import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActFavoriteDetailLayoutBinding;

public class FavoriteDetailActivity extends WKBaseActivity<ActFavoriteDetailLayoutBinding> {

    public static final String KEY_FAV_ID = "fav_id";
    public static final String KEY_FAV_TYPE = "fav_type";
    public static final String KEY_FAV_CONTENT = "fav_content";
    public static final String KEY_FAV_EXTRA = "fav_extra";
    public static final String KEY_FAV_SENDER = "fav_sender";
    public static final String KEY_FAV_TIME = "fav_time";
    public static final String KEY_FAV_CONVERSATION = "fav_conversation";

    private long favId;
    private int favType;

    @Override
    protected ActFavoriteDetailLayoutBinding getViewBinding() {
        return ActFavoriteDetailLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText("收藏详情");
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        Intent intent = getIntent();
        favId = intent.getLongExtra(KEY_FAV_ID, 0);
        favType = intent.getIntExtra(KEY_FAV_TYPE, FavoriteItem.TYPE_TEXT);
        String content = intent.getStringExtra(KEY_FAV_CONTENT);
        String extra = intent.getStringExtra(KEY_FAV_EXTRA);
        String sender = intent.getStringExtra(KEY_FAV_SENDER);
        String time = intent.getStringExtra(KEY_FAV_TIME);
        String conversation = intent.getStringExtra(KEY_FAV_CONVERSATION);

        wkVBinding.senderNameTv.setText(sender != null ? sender : "");
        wkVBinding.timeTv.setText(time != null ? time : "");
        if (conversation != null && !conversation.isEmpty()) {
            wkVBinding.fromConversationTv.setText("来自: " + conversation);
        } else {
            wkVBinding.fromConversationTv.setText("来自: 聊天");
        }

        switch (favType) {
            case FavoriteItem.TYPE_TEXT:
            case FavoriteItem.TYPE_LINK:
                wkVBinding.contentTv.setVisibility(View.VISIBLE);
                wkVBinding.contentTv.setText(content != null ? content : "");
                break;
            case FavoriteItem.TYPE_IMAGE:
                wkVBinding.imageIv.setVisibility(View.VISIBLE);
                String imgUrl = extra != null && !extra.isEmpty() ? extra : content;
                if (imgUrl != null && !imgUrl.isEmpty()) {
                    Glide.with(this).load(imgUrl).into(wkVBinding.imageIv);
                }
                break;
            case FavoriteItem.TYPE_VIDEO:
                wkVBinding.contentTv.setVisibility(View.VISIBLE);
                wkVBinding.contentTv.setText(content != null ? content : "[视频]");
                break;
            case FavoriteItem.TYPE_VOICE:
                wkVBinding.contentTv.setVisibility(View.VISIBLE);
                wkVBinding.contentTv.setText(content != null ? content : "[语音]");
                break;
            case FavoriteItem.TYPE_LOCATION:
                wkVBinding.contentTv.setVisibility(View.VISIBLE);
                wkVBinding.contentTv.setText(content != null ? content : "[位置]");
                break;
            case FavoriteItem.TYPE_FILE:
                wkVBinding.contentTv.setVisibility(View.VISIBLE);
                wkVBinding.contentTv.setText(content != null ? content : "[文件]");
                break;
            default:
                wkVBinding.contentTv.setVisibility(View.VISIBLE);
                wkVBinding.contentTv.setText(content != null ? content : "");
        }
    }

    @Override
    protected void initListener() {
        SingleClickUtil.onSingleClick(wkVBinding.imageIv, v -> {
            String imgUrl = getIntent().getStringExtra(KEY_FAV_EXTRA);
            if (imgUrl == null || imgUrl.isEmpty()) {
                imgUrl = getIntent().getStringExtra(KEY_FAV_CONTENT);
            }
            Intent intent = new Intent(this, DetailImgActivity.class);
            intent.putExtra(DetailImgActivity.KEY_IMG_URL, imgUrl);
            intent.putExtra(DetailImgActivity.KEY_SENDER, getIntent().getStringExtra(KEY_FAV_SENDER));
            intent.putExtra(DetailImgActivity.KEY_TIME, getIntent().getStringExtra(KEY_FAV_TIME));
            startActivity(intent);
        });

        SingleClickUtil.onSingleClick(wkVBinding.contentTv, v -> {
            if (favType == FavoriteItem.TYPE_TEXT || favType == FavoriteItem.TYPE_LINK) {
                Intent intent = new Intent(this, DetailTextActivity.class);
                intent.putExtra(DetailTextActivity.KEY_TEXT_CONTENT, getIntent().getStringExtra(KEY_FAV_CONTENT));
                intent.putExtra(DetailTextActivity.KEY_SENDER, getIntent().getStringExtra(KEY_FAV_SENDER));
                intent.putExtra(DetailTextActivity.KEY_TIME, getIntent().getStringExtra(KEY_FAV_TIME));
                startActivity(intent);
            }
        });

        SingleClickUtil.onSingleClick(wkVBinding.forwardBtn, v -> {
            Intent intent = new Intent(FavoriteDetailActivity.this, FavoriteSelectActivity.class);
            intent.putExtra(KEY_FAV_ID, favId);
            startActivity(intent);
        });

        SingleClickUtil.onSingleClick(wkVBinding.deleteBtn, v -> {
            WKDialogUtils.getInstance().showDialog(this, "删除收藏", "确定删除这条收藏吗？",
                    true, "取消", "删除", 0, 0, index -> {
                        if (index == 1) {
                            FavoriteStorageManager.getInstance(getApplicationContext()).removeFavorite(favId);
                            WKToastUtils.getInstance().showToastNormal("已删除");
                            setResult(RESULT_OK);
                            finish();
                        }
                    });
        });
    }
}
