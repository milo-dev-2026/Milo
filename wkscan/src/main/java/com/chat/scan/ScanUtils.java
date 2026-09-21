package com.chat.scan;

import android.content.Intent;
import android.text.TextUtils;

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
import com.chat.base.net.IRequestResultListener;
import com.chat.base.utils.WKReader;
import com.chat.base.utils.WKToastUtils;
import com.chat.scan.entity.ScanResult;
import com.xinbida.wukongim.WKIM;
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
                    WKChannelMember mChannelMember = WKIM.getInstance().getChannelMembersManager().getMember(group_no, WKChannelType.GROUP, WKConfig.getInstance().getUid());
                    if (mChannelMember != null) {
                        if (mChannelMember.isDeleted == 0) {
                            ChatViewMenu chatViewMenu = new ChatViewMenu(activity, group_no, WKChannelType.GROUP, 0, true);
                            EndpointManager.getInstance().invoke(EndpointSID.chatView, chatViewMenu);
                            iHandleScanResult.dismissView();
                        } else {
                            WKToastUtils.getInstance().showToast(activity
                                    .getString(R.string.scan_remove_group));
                            iHandleScanResult.dismissView();
                        }
                    } else {
                        WKToastUtils.getInstance().showToast("您不是该群成员，无法加入");
                        iHandleScanResult.dismissView();
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
}
