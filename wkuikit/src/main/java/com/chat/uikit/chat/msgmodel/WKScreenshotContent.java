package com.chat.uikit.chat.msgmodel;

import androidx.annotation.NonNull;

import com.chat.base.msgitem.WKContentType;
import com.xinbida.wukongim.msgmodel.WKMessageContent;

import org.json.JSONObject;

/**
 * 截图提醒消息内容（type=WKContentType.screenshot=20）
 * 以居中系统提示形式展示在会话窗口内，不再产生独立会话提醒/文本气泡。
 * 群聊显示「xxx截图了页面」，单聊显示「对方已截图」。
 */
public class WKScreenshotContent extends WKMessageContent {

    public String text;
    // 截图消息发送者 uid：接收端用它可靠区分「自己截图 / 对方截图」，不依赖 msg.fromUID
    public String fromUid;

    public WKScreenshotContent() {
        type = WKContentType.screenshot;
    }

    public WKScreenshotContent(String text) {
        this();
        this.text = text;
    }

    @NonNull
    @Override
    public JSONObject encodeMsg() {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put("text", text != null ? text : "");
            jsonObject.put("type", type);
            jsonObject.put("from", fromUid != null ? fromUid : "");
        } catch (Exception e) {
            e.printStackTrace();
        }
        return jsonObject;
    }

    @Override
    public WKMessageContent decodeMsg(JSONObject jsonObject) {
        if (jsonObject == null) return this;
        text = jsonObject.optString("text");
        fromUid = jsonObject.optString("from");
        return this;
    }

    @Override
    public String getDisplayContent() {
        return text != null ? text : "";
    }

    @Override
    public String getSearchableWord() {
        return text != null ? text : "";
    }
}
