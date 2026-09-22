package com.chat.scan;

import android.app.Dialog;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.text.TextUtils;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.Window;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;

import com.chat.base.act.WKWebViewActivity;
import com.chat.base.base.WKBaseModel;
import com.chat.base.config.WKApiConfig;
import com.chat.base.config.WKConfig;
import com.chat.base.endpoint.EndpointCategory;
import com.chat.base.endpoint.EndpointManager;
import com.chat.base.endpoint.EndpointSID;
import com.chat.base.endpoint.entity.ChatViewMenu;
import com.chat.base.endpoint.entity.ScanResultMenu;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.net.IRequestResultListener;
import com.chat.base.ui.Theme;
import com.chat.base.ui.components.AvatarView;
import com.chat.base.utils.WKReader;
import com.chat.base.utils.WKToastUtils;
import com.chat.scan.entity.ScanResult;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannel;
import com.xinbida.wukongim.entity.WKChannelMember;
import com.xinbida.wukongim.entity.WKChannelType;

import org.json.JSONObject;

import java.net.MalformedURLException;
import java.net.URL;
import java.util.HashMap;
import java.util.List;

/**
 * 2020-04-19 16:05
 * 扫描处理
 */
class ScanUtils extends WKBaseModel {

    private IHandleScanResult iHandleScanResult;

    private ScanUtils() {

    }

    private static class ScanUtilsBinder {
        static final ScanUtils scanUtils = new ScanUtils();
    }

    static ScanUtils getInstance() {
        return ScanUtilsBinder.scanUtils;
    }

    void handleScanResult(AppCompatActivity activity, String result, @NonNull final IHandleScanResult iHandleScanResult) {
        this.iHandleScanResult = iHandleScanResult;
        if (TextUtils.isEmpty(result)) {
            iHandleScanResult.dismissView();
            return;
        }
        try {
            if (result.startsWith("HTTP") || result.startsWith("http") || result.startsWith("www") || result.startsWith("WWW")) {
                URL resultURL = new URL(result);
                URL baseURL = new URL(WKApiConfig.baseUrl + "qrcode/");
                URL authURL = new URL(WKApiConfig.authUrl + "qrcode/");
                if ((resultURL.getHost().equals(baseURL.getHost()) || resultURL.getHost().equals(authURL.getHost()))
                        && resultURL.getPath().contains(baseURL.getPath())) {
                    requestScanResult(activity, result);
                } else {
                    iHandleScanResult.showWebView(result);
                }
            } else if (result.startsWith("mtp://")) {
            } else {
                iHandleScanResult.showOtherContent(result);
            }
        } catch (MalformedURLException e) {
            e.printStackTrace();
            iHandleScanResult.showOtherContent(result);
        }

    }

    private void requestScanResult(AppCompatActivity activity, String url) {
        request(createService(ScanService.class).getScanResult(url), new IRequestResultListener<>() {
            @Override
            public void onSuccess(ScanResult result) {
                handleResult(activity, result);
            }

            @Override
            public void onFail(int code, String msg) {
                if (activity != null && !activity.isFinishing()) {
                    WKToastUtils.getInstance().showToast(TextUtils.isEmpty(msg) ? "扫码失败，请重试" : msg);
                }
                iHandleScanResult.dismissView();
            }
        });
    }

    interface IHandleScanResult {
        void showOtherContent(String content);

        void showWebView(String url);

        void dismissView();
    }

    private void handleResult(AppCompatActivity activity, ScanResult result) {
        if (result == null) {
            iHandleScanResult.dismissView();
            return;
        }
        if (activity == null || activity.isFinishing()) {
            iHandleScanResult.dismissView();
            return;
        }
        String forward = result.forward;
        if ("h5".equals(forward)) {
            Intent intent = new Intent(WKScanApplication.getInstance().mContext.get(), WKWebViewActivity.class);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if (result.data != null && result.data.get("url") != null) {
                intent.putExtra("url", String.valueOf(result.data.get("url")));
            }
            WKScanApplication.getInstance().mContext.get().startActivity(intent);
            iHandleScanResult.dismissView();
        } else {
            String type = result.type;
            if (TextUtils.isEmpty(type)) {
                iHandleScanResult.dismissView();
                return;
            }
            JSONObject dataJson;
            try {
                dataJson = result.data != null ? new JSONObject(result.data) : new JSONObject();
            } catch (Exception e) {
                dataJson = new JSONObject();
            }
            if (type.equals("group")) {
                if (dataJson.has("group_no")) {
                    String group_no = dataJson.optString("group_no");
                    String group_name = dataJson.optString("group_name");
                    String group_avatar = dataJson.optString("group_avatar");
                    int member_count = dataJson.optInt("member_count", 0);
                    WKChannelMember mChannelMember = WKIM.getInstance().getChannelMembersManager().getMember(group_no, WKChannelType.GROUP, WKConfig.getInstance().getUid());
                    if (mChannelMember != null) {
                        if (mChannelMember.isDeleted == 0) {
                            // 已是群成员，直接进入聊天
                            ChatViewMenu chatViewMenu = new ChatViewMenu(activity, group_no, WKChannelType.GROUP, 0, true);
                            EndpointManager.getInstance().invoke(EndpointSID.chatView, chatViewMenu);
                            iHandleScanResult.dismissView();
                        } else {
                            WKToastUtils.getInstance().showToast(activity
                                    .getString(R.string.scan_remove_group));
                            iHandleScanResult.dismissView();
                        }
                    } else {
                        // 不是群成员，显示加入群聊确认弹窗
                        showJoinGroupDialog(activity, group_no, group_name, group_avatar, member_count);
                    }
                } else {
                    iHandleScanResult.dismissView();
                }

            } else {
                HashMap<String, Object> hashMap = new HashMap<>();
                hashMap.put("type", type);
                hashMap.put("data", dataJson);
                List<ScanResultMenu> list = EndpointManager.getInstance().invokes(EndpointCategory.wkScan, hashMap);
                boolean handled = false;
                if (WKReader.isNotEmpty(list)) {
                    for (int i = 0, size = list.size(); i < size; i++) {
                        boolean canHandle = list.get(i).iResultClick.invoke(hashMap);
                        if (canHandle) {
                            handled = true;
                            iHandleScanResult.dismissView();
                            break;
                        }
                    }
                }
                if (!handled) {
                    iHandleScanResult.dismissView();
                }
            }
        }
    }

    /**
     * 显示加入群聊确认弹窗
     */
    private void showJoinGroupDialog(AppCompatActivity activity, String groupNo,
                                    String groupName, String groupAvatar, int memberCount) {
        // 先获取群信息（确保数据完整）
        WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(groupNo, WKChannelType.GROUP);
        String name = TextUtils.isEmpty(groupName) ? (channel != null ? channel.channelName : "") : groupName;
        String avatar = TextUtils.isEmpty(groupAvatar) ? (channel != null ? channel.avatar : "") : groupAvatar;
        int count = memberCount;
        if (count == 0 && channel != null) {
            count = WKIM.getInstance().getChannelMembersManager().getMemberCount(groupNo, WKChannelType.GROUP);
        }
        final String finalName = name;
        final String finalAvatar = avatar;

        Dialog dialog = new Dialog(activity, android.R.style.Theme_Translucent_NoTitleBar);
        View view = LayoutInflater.from(activity).inflate(R.layout.dialog_join_group, null);
        dialog.setContentView(view);
        dialog.setCanceledOnTouchOutside(true);
        dialog.setCancelable(true);

        Window window = dialog.getWindow();
        if (window != null) {
            window.setGravity(Gravity.CENTER);
            window.setLayout(android.view.ViewGroup.LayoutParams.MATCH_PARENT, android.view.ViewGroup.LayoutParams.WRAP_CONTENT);
            android.view.WindowManager.LayoutParams lp = window.getAttributes();
            lp.width = (int) (activity.getResources().getDisplayMetrics().widthPixels * 0.82);
            window.setAttributes(lp);
        }

        // 毛玻璃背景
        View bgView = view.findViewById(R.id.bgView);
        GradientDrawable bgDrawable = new GradientDrawable();
        bgDrawable.setShape(GradientDrawable.RECTANGLE);
        bgDrawable.setCornerRadius(dp2px(activity, 16));
        bgDrawable.setColor(Color.argb(245, 255, 255, 255));
        bgView.setBackground(bgDrawable);

        // 群头像
        AvatarView avatarView = view.findViewById(R.id.avatarView);
        avatarView.showAvatar(groupNo, WKChannelType.GROUP, "");

        // 群名称
        TextView nameTv = view.findViewById(R.id.nameTv);
        nameTv.setText(TextUtils.isEmpty(finalName) ? "群聊" : finalName);

        // 成员数量
        TextView countTv = view.findViewById(R.id.countTv);
        if (count > 0) {
            countTv.setText(count + " 位成员");
            countTv.setVisibility(View.VISIBLE);
        } else {
            countTv.setVisibility(View.GONE);
        }

        // 取消按钮
        TextView cancelTv = view.findViewById(R.id.cancelTv);
        GradientDrawable cancelDrawable = new GradientDrawable();
        cancelDrawable.setShape(GradientDrawable.RECTANGLE);
        cancelDrawable.setCornerRadius(dp2px(activity, 22));
        cancelDrawable.setColor(Color.parseColor("#FFEEEEEE"));
        cancelTv.setBackground(cancelDrawable);
        cancelTv.setOnClickListener(v -> dialog.dismiss());

        // 加入群聊按钮（蓝色背景 + 白色文字）
        TextView joinTv = view.findViewById(R.id.joinTv);
        GradientDrawable btnDrawable = new GradientDrawable();
        btnDrawable.setShape(GradientDrawable.RECTANGLE);
        btnDrawable.setCornerRadius(dp2px(activity, 22));
        btnDrawable.setColor(Theme.colorAccount);
        joinTv.setBackground(btnDrawable);
        joinTv.setTextColor(Color.WHITE);

        final boolean[] isJoining = {false};
        joinTv.setOnClickListener(v -> {
            if (isJoining[0]) return;
            isJoining[0] = true;
            joinTv.setText("加入中...");

            // 通过反射调用 GroupModel.getInstance().joinGroupByQr
            try {
                Class<?> groupModelClass = Class.forName("com.chat.uikit.group.service.GroupModel");
                java.lang.reflect.Method getInstanceMethod = groupModelClass.getMethod("getInstance");
                Object groupModel = getInstanceMethod.invoke(null);
                java.lang.reflect.Method joinMethod = groupModelClass.getMethod("joinGroupByQr", String.class, Class.forName("com.chat.base.net.ICommonListener"));
                joinMethod.invoke(groupModel, groupNo, (com.chat.base.net.ICommonListener) (code, msg) -> {
                    activity.runOnUiThread(() -> {
                        isJoining[0] = false;
                        joinTv.setText("加入群聊");
                        if (code == HttpResponseCode.success) {
                            WKToastUtils.getInstance().showToast("加入成功");
                            dialog.dismiss();
                            iHandleScanResult.dismissView();
                            // 延迟进入聊天，确保数据同步
                            view.postDelayed(() -> {
                                ChatViewMenu chatViewMenu = new ChatViewMenu(activity, groupNo, WKChannelType.GROUP, 0, true);
                                EndpointManager.getInstance().invoke(EndpointSID.chatView, chatViewMenu);
                            }, 300);
                        } else {
                            WKToastUtils.getInstance().showToast(TextUtils.isEmpty(msg) ? "加入失败，请重试" : msg);
                        }
                    });
                });
            } catch (Exception e) {
                activity.runOnUiThread(() -> {
                    isJoining[0] = false;
                    joinTv.setText("加入群聊");
                    WKToastUtils.getInstance().showToast("加入失败，请重试");
                    android.util.Log.e("ScanUtils", "joinGroupByQr error: " + e.getMessage(), e);
                });
            }
        });

        dialog.show();
    }

    private int dp2px(AppCompatActivity activity, float dp) {
        return (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, dp,
                activity.getResources().getDisplayMetrics());
    }
}
