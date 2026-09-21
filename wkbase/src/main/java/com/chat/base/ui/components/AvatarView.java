package com.chat.base.ui.components;

import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.text.TextUtils;
import android.util.AttributeSet;
import android.view.Gravity;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.TextView;
import android.view.View;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.RequestOptions;
import com.chat.base.R;
import com.chat.base.config.WKApiConfig;
import com.chat.base.config.WKSystemAccount;
import com.chat.base.glide.GlideUtils;
import com.google.android.material.imageview.ShapeableImageView;
import com.xinbida.wukongim.entity.WKChannel;

/**
 * 头像View
 */
public class AvatarView extends FrameLayout {
    public ShapeableImageView imageView;
    public TextView defaultAvatarTv;
    public View spotView;
    public TextView onlineTv;
    private float size = 0;
    private static final int[] avatarColors = {
            0xFFE07A9F, 0xFFA97FD6, 0xFF7F92D6, 0xFF7FC8D6,
            0xFF7FD69F, 0xFFD6C87F, 0xFFD6977F, 0xFFD67F7F
    };

    public AvatarView(Context context) {
        super(context);
        init();
    }

    public AvatarView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public AvatarView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    private void init() {
        imageView = new ShapeableImageView(getContext());
        imageView.setScaleType(android.widget.ImageView.ScaleType.CENTER_CROP);
        imageView.setLayoutParams(new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        addView(imageView);

        defaultAvatarTv = new TextView(getContext());
        defaultAvatarTv.setGravity(Gravity.CENTER);
        defaultAvatarTv.setTextColor(Color.WHITE);
        defaultAvatarTv.getPaint().setFakeBoldText(true);
        LayoutParams tvParams = new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);
        defaultAvatarTv.setLayoutParams(tvParams);
        addView(defaultAvatarTv);

        // 在线状态小圆点
        spotView = new View(getContext());
        LayoutParams spotParams = new LayoutParams(dp2px(8), dp2px(8));
        spotParams.gravity = Gravity.END | Gravity.BOTTOM;
        spotParams.setMargins(0, 0, dp2px(2), dp2px(2));
        spotView.setLayoutParams(spotParams);
        GradientDrawable spotDrawable = new GradientDrawable();
        spotDrawable.setShape(GradientDrawable.OVAL);
        spotDrawable.setColor(0xFF4CD964);
        spotDrawable.setStroke(dp2px(1.5f), Color.WHITE);
        spotView.setBackground(spotDrawable);
        spotView.setVisibility(GONE);
        addView(spotView);

        // 在线/身份文字标识
        onlineTv = new TextView(getContext());
        LayoutParams onlineParams = new LayoutParams(LayoutParams.WRAP_CONTENT, dp2px(14));
        onlineParams.gravity = Gravity.END | Gravity.BOTTOM;
        onlineParams.setMargins(0, 0, dp2px(2), dp2px(2));
        onlineTv.setLayoutParams(onlineParams);
        onlineTv.setTextSize(10f);
        onlineTv.setGravity(Gravity.CENTER);
        onlineTv.setPadding(dp2px(4), 0, dp2px(4), 0);
        onlineTv.setVisibility(GONE);
        addView(onlineTv);
    }

    public void setStrokeWidth(float width) {}

    public void setStrokeColor(int color) {}

    public void setSize(float size) {
        this.size = size;
        ViewGroup.LayoutParams params = getLayoutParams();
        if (params == null) {
            params = new ViewGroup.LayoutParams(dp2px(size), dp2px(size));
        } else {
            params.width = dp2px(size);
            params.height = dp2px(size);
        }
        setLayoutParams(params);
        if (size > 0) {
            defaultAvatarTv.setTextSize(size / 3);
        }
    }

    public void setSize(float size, float v2) {
        setSize(size);
    }

    /**
     * 设置在线状态
     * @param isOnline true显示绿色小圆点，false隐藏
     */
    public void setOnline(boolean isOnline) {
        if (spotView != null) {
            spotView.setVisibility(isOnline ? VISIBLE : GONE);
        }
    }

    public void showAvatar(String channelID, byte type, String avatarCacheKey) {
        showAvatar(channelID, type, avatarCacheKey, true);
    }

    public void showAvatar(String channelID, byte type, boolean showDefault) {
        showAvatar(channelID, type, "", showDefault);
    }

    public void showAvatar(String channelID, byte type) {
        showAvatar(channelID, type, "", true);
    }

    public void showAvatar(WKChannel channel) {
        if (channel == null) return;
        showAvatar(channel.channelID, channel.channelType, channel.avatarCacheKey, channel.channelName, channel.channelRemark);
    }

    public void showAvatar(WKChannel channel, boolean b) {
        showAvatar(channel);
    }

    private void showAvatar(String channelID, byte type, String avatarCacheKey, boolean showDefault) {
        showAvatar(channelID, type, avatarCacheKey, channelID, "");
    }

    private void showAvatar(String channelID, byte type, String avatarCacheKey, String name, String remark) {
        String showName = TextUtils.isEmpty(remark) ? name : remark;
        if (TextUtils.isEmpty(showName)) {
            showName = channelID;
        }

        // 系统团队账号显示本地头像（文件助手保持原来的）
        if (type == com.xinbida.wukongim.entity.WKChannelType.PERSONAL && channelID.equals(WKSystemAccount.system_team)) {
            defaultAvatarTv.setVisibility(GONE);
            imageView.setVisibility(VISIBLE);
            Glide.with(getContext()).load(R.drawable.ic_system_avatar).into(imageView);
            return;
        }

        String url = WKApiConfig.getShowAvatar(channelID, type);
        if (!TextUtils.isEmpty(url)) {
            defaultAvatarTv.setVisibility(GONE);
            imageView.setVisibility(VISIBLE);
            GlideUtils.getInstance().showAvatarImg(getContext(), url, avatarCacheKey, imageView);
        } else {
            showDefaultAvatar(showName);
        }
    }

    private void showDefaultAvatar(String name) {
        imageView.setVisibility(GONE);
        defaultAvatarTv.setVisibility(VISIBLE);
        String firstChar = "";
        if (!TextUtils.isEmpty(name)) {
            firstChar = name.substring(0, 1).toUpperCase();
        }
        defaultAvatarTv.setText(firstChar);

        int colorIndex = Math.abs(name.hashCode()) % avatarColors.length;
        int bgColor = avatarColors[colorIndex];

        GradientDrawable bgDrawable = new GradientDrawable();
        bgDrawable.setShape(GradientDrawable.OVAL);
        bgDrawable.setColor(bgColor);
        defaultAvatarTv.setBackground(bgDrawable);
    }

    private int dp2px(float dp) {
        float density = getContext().getResources().getDisplayMetrics().density;
        return (int) (dp * density + 0.5f);
    }

    public static void clearCache(String str, byte type) {}
}
