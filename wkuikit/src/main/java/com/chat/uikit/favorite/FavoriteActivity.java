package com.chat.uikit.favorite;

import android.app.Dialog;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.PopupWindow;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActFavoriteLayoutBinding;
import com.scwang.smart.refresh.layout.api.RefreshLayout;
import com.scwang.smart.refresh.layout.listener.OnRefreshLoadMoreListener;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannel;
import com.xinbida.wukongim.entity.WKMsg;
import com.xinbida.wukongim.msgmodel.WKImageContent;
import com.xinbida.wukongim.msgmodel.WKMessageContent;
import com.xinbida.wukongim.msgmodel.WKTextContent;
import com.xinbida.wukongim.msgmodel.WKVideoContent;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

public class FavoriteActivity extends WKBaseActivity<ActFavoriteLayoutBinding> {

    private List<FavoriteItem> favoriteList = new ArrayList<>();
    private FavoriteAdapter adapter;
    private TextView multiSelectTv;
    private String channelId = "";
    private byte channelType = 1;
    private WKChannel channel;

    @Override
    protected ActFavoriteLayoutBinding getViewBinding() {
        return ActFavoriteLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.my_favorite);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        multiSelectTv = findViewById(R.id.multiSelectTv);

        channelId = getIntent().getStringExtra("channelId");
        channelType = getIntent().getByteExtra("channelType", (byte) 1);
        if (channelId != null && !channelId.isEmpty()) {
            channel = WKIM.getInstance().getChannelManager().getChannel(channelId, channelType);
        }

        LinearLayoutManager layoutManager = new LinearLayoutManager(this);
        wkVBinding.recyclerView.setLayoutManager(layoutManager);
        adapter = new FavoriteAdapter(favoriteList);
        wkVBinding.recyclerView.setAdapter(adapter);

        loadFavorites();
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (adapter != null) {
            loadFavorites();
        }
    }

    @Override
    protected void initListener() {
        wkVBinding.refreshLayout.setOnRefreshLoadMoreListener(new OnRefreshLoadMoreListener() {
            @Override
            public void onRefresh(RefreshLayout refreshLayout) {
                loadFavorites();
                refreshLayout.finishRefresh(500);
            }

            @Override
            public void onLoadMore(RefreshLayout refreshLayout) {
                refreshLayout.finishLoadMore(500);
            }
        });

        multiSelectTv.setOnClickListener(v -> {
            if (adapter.isMultiSelect()) {
                exitMultiSelectMode();
            } else {
                enterMultiSelectMode();
            }
        });

        adapter.setOnItemClickListener(position -> {
            if (position < 0 || position >= favoriteList.size()) return;
            if (adapter.isMultiSelect()) {
                updateBottomBarState();
            } else {
                showForwardDialog(Collections.singletonList(favoriteList.get(position)));
            }
        });

        adapter.setOnItemLongClickListener(position -> {
            showItemPopup(position);
        });

        wkVBinding.forwardLayout.setOnClickListener(v -> {
            forwardSelectedFavorites();
        });

        wkVBinding.deleteLayout.setOnClickListener(v -> {
            confirmDeleteSelectedFavorites();
        });
    }

    private void showItemPopup(int position) {
        if (position < 0 || position >= favoriteList.size()) return;
        View popupView = LayoutInflater.from(this).inflate(R.layout.pop_favorite, null);
        PopupWindow popupWindow = new PopupWindow(popupView,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT, true);
        popupWindow.setOutsideTouchable(true);
        popupWindow.setBackgroundDrawable(null);
        popupWindow.setElevation(8f);
        popupView.measure(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED);

        popupView.findViewById(R.id.button1).setOnClickListener(v -> {
            popupWindow.dismiss();
            if (position < 0 || position >= favoriteList.size()) return;
            showForwardDialog(Collections.singletonList(favoriteList.get(position)));
        });

        popupView.findViewById(R.id.button2).setOnClickListener(v -> {
            popupWindow.dismiss();
            if (position < 0 || position >= favoriteList.size()) return;
            confirmDeleteFavoriteAt(position);
        });

        popupView.findViewById(R.id.button3).setOnClickListener(v -> {
            popupWindow.dismiss();
            if (position < 0 || position >= favoriteList.size()) return;
            enterMultiSelectMode();
            favoriteList.get(position).isSelected = true;
            adapter.notifyItemChanged(position);
            updateBottomBarState();
        });

        View anchorView = wkVBinding.recyclerView.getLayoutManager()
                .findViewByPosition(position);
        if (anchorView != null) {
            int popupWidth = popupView.getMeasuredWidth();
            int popupHeight = popupView.getMeasuredHeight();
            int[] location = new int[2];
            anchorView.getLocationOnScreen(location);
            int x = location[0] + anchorView.getWidth() / 2 - popupWidth / 2;
            int y = location[1] + anchorView.getHeight() / 2 - popupHeight / 2;
            popupWindow.showAtLocation(anchorView, Gravity.NO_GRAVITY, x, y);
        } else {
            popupWindow.showAtLocation(wkVBinding.recyclerView, Gravity.CENTER, 0, 0);
        }
    }

    private void enterMultiSelectMode() {
        adapter.setMultiSelect(true);
        multiSelectTv.setText("取消");
        wkVBinding.llShareanddelete.setVisibility(View.VISIBLE);
        updateBottomBarState();
    }

    private void exitMultiSelectMode() {
        adapter.setMultiSelect(false);
        multiSelectTv.setText("多选");
        wkVBinding.llShareanddelete.setVisibility(View.GONE);
    }

    private void updateBottomBarState() {
        boolean hasChecked = adapter.hasCheckedItem();
        wkVBinding.forwardLayout.setAlpha(hasChecked ? 1.0f : 0.4f);
        wkVBinding.forwardLayout.setEnabled(hasChecked);
        wkVBinding.deleteLayout.setAlpha(hasChecked ? 1.0f : 0.4f);
        wkVBinding.deleteLayout.setEnabled(hasChecked);
    }

    private void confirmDeleteFavoriteAt(int position) {
        if (position < 0 || position >= favoriteList.size()) return;
        View dialogView = LayoutInflater.from(this).inflate(R.layout.chat_favorite_delete_confirm, null);
        Dialog dialog = new Dialog(this);
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        dialog.getWindow().setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
        dialog.setContentView(dialogView);

        Window window = dialog.getWindow();
        window.setLayout(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        window.setGravity(Gravity.BOTTOM);
        window.setWindowAnimations(android.R.style.Animation_InputMethod);

        TextView titleTv = dialogView.findViewById(R.id.titleTv);
        titleTv.setText("确认删除这条收藏吗？");

        dialogView.findViewById(R.id.cancelBtn).setOnClickListener(v -> dialog.dismiss());
        dialogView.findViewById(R.id.confirmBtn).setOnClickListener(v -> {
            dialog.dismiss();
            deleteFavoriteAt(position);
        });
        dialog.show();
    }

    private void confirmDeleteSelectedFavorites() {
        List<FavoriteItem> toDelete = new ArrayList<>();
        for (FavoriteItem item : favoriteList) {
            if (item.isSelected) toDelete.add(item);
        }
        if (toDelete.isEmpty()) {
            WKToastUtils.getInstance().showToastNormal("请选择要删除的收藏");
            return;
        }
        View dialogView = LayoutInflater.from(this).inflate(R.layout.chat_favorite_delete_confirm, null);
        Dialog dialog = new Dialog(this);
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        dialog.getWindow().setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
        dialog.setContentView(dialogView);

        Window window = dialog.getWindow();
        window.setLayout(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        window.setGravity(Gravity.BOTTOM);
        window.setWindowAnimations(android.R.style.Animation_InputMethod);

        TextView titleTv = dialogView.findViewById(R.id.titleTv);
        titleTv.setText("确认删除选中的" + toDelete.size() + "项收藏吗？");

        dialogView.findViewById(R.id.cancelBtn).setOnClickListener(v -> dialog.dismiss());
        dialogView.findViewById(R.id.confirmBtn).setOnClickListener(v -> {
            dialog.dismiss();
            for (FavoriteItem item : toDelete) {
                FavoriteStorageManager.getInstance(getApplicationContext()).removeFavorite(item.id);
                favoriteList.remove(item);
            }
            adapter.notifyDataSetChanged();
            exitMultiSelectMode();
            WKToastUtils.getInstance().showToastNormal("已删除" + toDelete.size() + "项");
        });
        dialog.show();
    }

    private void deleteFavoriteAt(int position) {
        if (position < 0 || position >= favoriteList.size()) return;
        FavoriteItem item = favoriteList.get(position);
        FavoriteStorageManager.getInstance(getApplicationContext()).removeFavorite(item.id);
        favoriteList.remove(position);
        adapter.notifyItemRemoved(position);
        if (position < favoriteList.size()) {
            adapter.notifyItemRangeChanged(position, favoriteList.size() - position);
        }
        WKToastUtils.getInstance().showToastNormal("已移除");
    }

    private void forwardSelectedFavorites() {
        List<FavoriteItem> toForward = new ArrayList<>();
        for (FavoriteItem item : favoriteList) {
            if (item.isSelected) toForward.add(item);
        }
        if (toForward.isEmpty()) {
            WKToastUtils.getInstance().showToastNormal("请选择要转发的收藏");
            return;
        }
        showForwardDialog(toForward);
    }

    private void showForwardDialog(List<FavoriteItem> items) {
        if (items == null || items.isEmpty()) return;
        if (channelId == null || channelId.isEmpty()) {
            WKToastUtils.getInstance().showToastNormal("无法获取会话信息");
            return;
        }
        Dialog dialog = new Dialog(this);
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        dialog.getWindow().setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
        View view = LayoutInflater.from(this).inflate(R.layout.chat_favorite_forward_dialog, null);
        dialog.setContentView(view);

        Window window = dialog.getWindow();
        window.setLayout(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        window.setGravity(Gravity.BOTTOM);
        window.setWindowAnimations(android.R.style.Animation_InputMethod);

        TextView titleBar = view.findViewById(R.id.title_bar);
        titleBar.setText("发送给");

        LinearLayout headLl = view.findViewById(R.id.headLl);
        headLl.setVisibility(View.VISIBLE);

        com.chat.base.ui.components.AvatarView avatarView = view.findViewById(R.id.avatarView);
        avatarView.setVisibility(View.VISIBLE);
        avatarView.setSize(40);
        if (channel != null) {
            avatarView.showAvatar(channel);
        }

        TextView nameTv = view.findViewById(R.id.nameTv);
        final String friendName;
        if (channel != null && channel.channelName != null && !channel.channelName.isEmpty()) {
            friendName = channel.channelName;
        } else {
            friendName = "当前好友";
        }
        nameTv.setText(friendName);
        nameTv.setVisibility(View.VISIBLE);

        ImageView imageView = view.findViewById(R.id.imageView);
        ImageView playIv = view.findViewById(R.id.playIv);
        TextView contentTv = view.findViewById(R.id.contentTv);

        final boolean isMulti = items.size() > 1;
        if (isMulti) {
            contentTv.setVisibility(View.VISIBLE);
            contentTv.setText("【逐条转发】共" + items.size() + "条消息");
        } else {
            FavoriteItem item = items.get(0);
            if (item.type == FavoriteItem.TYPE_IMAGE) {
                contentTv.setVisibility(View.GONE);
                imageView.setVisibility(View.VISIBLE);
                String imgUrl = item.extra;
                if (imgUrl != null && !imgUrl.isEmpty()) {
                    imgUrl = com.chat.base.config.WKApiConfig.getShowUrl(imgUrl);
                    int[] dims = com.chat.base.utils.ImageUtils.getInstance()
                            .getImageWidthAndHeightToTalk(item.width, item.height);
                    ViewGroup.LayoutParams lp = imageView.getLayoutParams();
                    lp.width = dims[0];
                    lp.height = dims[1];
                    imageView.setLayoutParams(lp);
                    com.chat.base.glide.GlideUtils.getInstance().showImg(this, imgUrl, dims[0], dims[1], imageView);
                } else {
                    imageView.setImageResource(com.chat.base.R.drawable.default_view_bg);
                }
            } else if (item.type == FavoriteItem.TYPE_VIDEO) {
                contentTv.setVisibility(View.GONE);
                imageView.setVisibility(View.VISIBLE);
                playIv.setVisibility(View.VISIBLE);
                String imgUrl = item.extra;
                if (imgUrl != null && !imgUrl.isEmpty()) {
                    imgUrl = com.chat.base.config.WKApiConfig.getShowUrl(imgUrl);
                    int[] dims = com.chat.base.utils.ImageUtils.getInstance()
                            .getImageWidthAndHeightToTalk(item.width, item.height);
                    ViewGroup.LayoutParams lp = imageView.getLayoutParams();
                    lp.width = dims[0];
                    lp.height = dims[1];
                    imageView.setLayoutParams(lp);
                    com.chat.base.glide.GlideUtils.getInstance().showImg(this, imgUrl, dims[0], dims[1], imageView);
                } else {
                    imageView.setImageResource(com.chat.base.R.drawable.default_view_bg);
                }
            } else {
                contentTv.setVisibility(View.VISIBLE);
                contentTv.setText(item.content != null ? item.content : "");
            }
        }

        view.findViewById(R.id.clearBtn).setOnClickListener(v -> dialog.dismiss());

        view.findViewById(R.id.sureBtn).setOnClickListener(v -> {
            dialog.dismiss();
            for (FavoriteItem item : items) {
                sendFavoriteToChannel(item);
            }
            if (isMulti) {
                exitMultiSelectMode();
            }
            WKToastUtils.getInstance().showToastNormal("已发送给" + friendName);
            finish();
        });

        dialog.show();
    }

    private void sendFavoriteToChannel(FavoriteItem item) {
        if (channelId == null || channelId.isEmpty()) return;
        try {
            WKMessageContent content = null;
            if (item.type == FavoriteItem.TYPE_TEXT || item.type == FavoriteItem.TYPE_LINK) {
                content = new WKTextContent(item.content != null ? item.content : "");
            } else if (item.type == FavoriteItem.TYPE_IMAGE) {
                String path = item.extra;
                if (path != null && !path.isEmpty()) {
                    path = com.chat.base.config.WKApiConfig.getShowUrl(path);
                    if (path.startsWith("http://") || path.startsWith("https://")) {
                        WKImageContent imageContent = new WKImageContent();
                        imageContent.url = path;
                        imageContent.width = item.width;
                        imageContent.height = item.height;
                        content = imageContent;
                    } else {
                        java.io.File file = new java.io.File(path);
                        if (file.exists()) {
                            WKImageContent imageContent = new WKImageContent(path);
                            imageContent.width = item.width;
                            imageContent.height = item.height;
                            content = imageContent;
                        } else {
                            content = new WKTextContent(item.content != null ? item.content : "[图片]");
                        }
                    }
                } else {
                    content = new WKTextContent(item.content != null ? item.content : "[图片]");
                }
            } else if (item.type == FavoriteItem.TYPE_VIDEO) {
                String coverPath = item.extra;
                String videoUrl = item.videoUrl;
                if (coverPath != null && !coverPath.isEmpty()) {
                    coverPath = com.chat.base.config.WKApiConfig.getShowUrl(coverPath);
                }
                if (videoUrl != null && !videoUrl.isEmpty()) {
                    videoUrl = com.chat.base.config.WKApiConfig.getShowUrl(videoUrl);
                }
                WKVideoContent videoContent = new WKVideoContent();
                if (videoUrl != null && !videoUrl.isEmpty()
                        && (videoUrl.startsWith("http://") || videoUrl.startsWith("https://"))) {
                    videoContent.url = videoUrl;
                    videoContent.cover = coverPath;
                    videoContent.width = item.width;
                    videoContent.height = item.height;
                    content = videoContent;
                } else if (coverPath != null && !coverPath.isEmpty()
                        && (coverPath.startsWith("http://") || coverPath.startsWith("https://"))) {
                    videoContent.cover = coverPath;
                    videoContent.width = item.width;
                    videoContent.height = item.height;
                    content = videoContent;
                } else if (coverPath != null && !coverPath.isEmpty()) {
                    java.io.File file = new java.io.File(coverPath);
                    if (file.exists()) {
                        videoContent.localPath = coverPath;
                        videoContent.width = item.width;
                        videoContent.height = item.height;
                        content = videoContent;
                    } else {
                        content = new WKTextContent(item.content != null ? item.content : "[视频]");
                    }
                } else {
                    content = new WKTextContent(item.content != null ? item.content : "[视频]");
                }
            } else if (item.type == FavoriteItem.TYPE_LOCATION) {
                String contentStr = item.content != null ? item.content : "";
                if (contentStr.startsWith("[位置] ")) {
                    contentStr = contentStr.substring(4).trim();
                }
                String extra = item.extra != null ? item.extra : "";
                double lng = 0, lat = 0;
                String address = "";
                String title = "";
                String imgUrl = "";
                // extra格式: "lng,lat|imgUrl|address|title"（兼容旧格式 "lng,lat|imgUrl" 和 "lng,lat"）
                String[] extraParts = extra.split("\\|");
                String coordPart = extraParts.length > 0 ? extraParts[0] : "";
                if (extraParts.length >= 2) {
                    imgUrl = extraParts[1];
                }
                if (extraParts.length >= 4) {
                    // 新格式：有 address 和 title
                    address = extraParts[2];
                    title = extraParts[3];
                }
                // 兼容旧格式：从contentStr中提取
                if ((address.isEmpty() || title.isEmpty()) && !contentStr.isEmpty()) {
                    address = contentStr;
                    title = contentStr;
                }
                if (coordPart.contains(",")) {
                    try {
                        String[] parts = coordPart.split(",");
                        lng = Double.parseDouble(parts[0].trim());
                        lat = Double.parseDouble(parts[1].trim());
                    } catch (NumberFormatException e) {
                        e.printStackTrace();
                    }
                }
                com.chat.uikit.location.WKLocationContent locContent = new com.chat.uikit.location.WKLocationContent(lng, lat, address, title);
                if (imgUrl != null && !imgUrl.isEmpty()) {
                    locContent.url = imgUrl;
                }
                content = locContent;
            } else {
                content = new WKTextContent(item.content != null ? item.content : "");
            }
            if (content != null) {
                WKMsg wkMsg = new WKMsg();
                wkMsg.channelID = channelId;
                wkMsg.channelType = channelType;
                wkMsg.type = content.type;
                wkMsg.baseContentMsgModel = content;
                if (channel != null) {
                    wkMsg.setChannelInfo(channel);
                }
                com.chat.uikit.chat.manager.WKSendMsgUtils.getInstance().sendMessage(wkMsg);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void loadFavorites() {
        favoriteList.clear();
        List<FavoriteItem> stored = FavoriteStorageManager.getInstance(getApplicationContext()).getAllFavorites();
        favoriteList.addAll(stored);
        adapter.notifyDataSetChanged();
        if (favoriteList.isEmpty()) {
            wkVBinding.emptyView.setVisibility(View.VISIBLE);
            wkVBinding.recyclerView.setVisibility(View.GONE);
        } else {
            wkVBinding.emptyView.setVisibility(View.GONE);
            wkVBinding.recyclerView.setVisibility(View.VISIBLE);
        }
    }

    @Override
    public void backListener(int type) {
        if (adapter != null && adapter.isMultiSelect()) {
            exitMultiSelectMode();
        } else {
            super.backListener(type);
        }
    }

    @Override
    public void onBackPressed() {
        if (adapter != null && adapter.isMultiSelect()) {
            exitMultiSelectMode();
        } else {
            super.onBackPressed();
        }
    }
}
