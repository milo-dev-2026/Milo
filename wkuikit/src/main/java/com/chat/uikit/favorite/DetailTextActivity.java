package com.chat.uikit.favorite;

import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityDetailTextBinding;

public class DetailTextActivity extends WKBaseActivity<ActivityDetailTextBinding> {

    public static final String KEY_TEXT_CONTENT = "text_content";
    public static final String KEY_SENDER = "sender";
    public static final String KEY_TIME = "time";

    private String textContent;
    private long favId;

    @Override
    protected ActivityDetailTextBinding getViewBinding() {
        return ActivityDetailTextBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.detail_text);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        Intent intent = getIntent();
        textContent = intent.getStringExtra(KEY_TEXT_CONTENT);
        String sender = intent.getStringExtra(KEY_SENDER);
        String time = intent.getStringExtra(KEY_TIME);
        favId = intent.getLongExtra(FavoriteDetailActivity.KEY_FAV_ID, 0);

        if (sender != null) {
            wkVBinding.senderNameTv.setText(sender);
        }
        if (time != null) {
            wkVBinding.timeTv.setText(time);
        }
        if (textContent != null) {
            wkVBinding.contentTv.setText(textContent);
        }
    }

    @Override
    protected void initListener() {
        SingleClickUtil.onSingleClick(wkVBinding.copyBtn, v -> {
            if (textContent != null && !textContent.isEmpty()) {
                ClipboardManager clipboard = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
                ClipData clip = ClipData.newPlainText("text", textContent);
                clipboard.setPrimaryClip(clip);
                WKToastUtils.getInstance().showToastNormal(getString(R.string.favorite_copyed));
            } else {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.copy_failed));
            }
        });

        SingleClickUtil.onSingleClick(wkVBinding.forwardBtn, v -> {
            Intent intent = new Intent(this, FavoriteSelectActivity.class);
            intent.putExtra(FavoriteDetailActivity.KEY_FAV_ID, favId);
            startActivity(intent);
        });
    }
}
