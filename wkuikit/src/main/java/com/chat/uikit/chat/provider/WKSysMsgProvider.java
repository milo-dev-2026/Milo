package com.chat.uikit.chat.provider;

import android.text.SpannableString;
import android.text.TextUtils;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;

import com.chad.library.adapter.base.viewholder.BaseViewHolder;
import com.chat.base.msgitem.WKChatBaseProvider;
import com.chat.base.msgitem.WKChatIteMsgFromType;
import com.chat.base.msgitem.WKContentType;
import com.chat.base.msgitem.WKUIChatMsgItemEntity;
import com.chat.base.ui.components.SystemMsgBackgroundColorSpan;
import com.chat.base.utils.AndroidUtilities;
import com.chat.uikit.R;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.text.MessageFormat;

/**
 * System message provider for type=1008 (setNewGroupAdmin)
 * Displays formatted text like "xxx已被添加为管理员"
 * The content template uses {0} placeholder, extra array contains user info
 */
public class WKSysMsgProvider extends WKChatBaseProvider {

    @Override
    protected View getChatViewItem(ViewGroup parentView, WKChatIteMsgFromType from) {
        return null;
    }

    @Override
    protected void setData(int adapterPosition, View parentView, WKUIChatMsgItemEntity uiChatMsgItemEntity, WKChatIteMsgFromType from) {
    }

    @Override
    public int getLayoutId() {
        return R.layout.chat_item_sys_msg_layout;
    }

    @Override
    public int getItemViewType() {
        return WKContentType.setNewGroupAdmin;
    }

    @Override
    public void convert(@NonNull BaseViewHolder helper, @NonNull WKUIChatMsgItemEntity item) {
        super.convert(helper, item);
        if (!TextUtils.isEmpty(item.wkMsg.content)) {
            try {
                JSONObject jsonObject = new JSONObject(item.wkMsg.content);
                String contentTemplate = jsonObject.optString("content");

                // Try to get extra data for user names to fill template placeholders
                JSONArray extraArray = jsonObject.optJSONArray("extra");
                if (extraArray != null && extraArray.length() > 0) {
                    Object[] args = new Object[extraArray.length()];
                    for (int i = 0; i < extraArray.length(); i++) {
                        JSONObject extraItem = extraArray.optJSONObject(i);
                        if (extraItem != null) {
                            String name = extraItem.optString("name");
                            if (TextUtils.isEmpty(name)) {
                                name = extraItem.optString("uid");
                            }
                            args[i] = name;
                        } else {
                            args[i] = "";
                        }
                    }
                    contentTemplate = MessageFormat.format(contentTemplate, args);
                }

                TextView textView = helper.getView(R.id.contentTv);
                textView.setShadowLayer(AndroidUtilities.dp(10), 0, 0, 0);
                SpannableString str = new SpannableString(contentTemplate);
                str.setSpan(
                        new SystemMsgBackgroundColorSpan(
                                ContextCompat.getColor(getContext(), R.color.colorSystemBg),
                                AndroidUtilities.dp(5),
                                AndroidUtilities.dp(10)
                        ), 0, contentTemplate.length(), 0);
                textView.setText(str);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
    }
}
