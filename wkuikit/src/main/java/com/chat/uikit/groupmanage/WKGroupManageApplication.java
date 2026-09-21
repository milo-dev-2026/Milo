package com.chat.uikit.groupmanage;

import android.content.Context;
import android.content.Intent;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.core.content.ContextCompat;

import com.chat.base.WKBaseApplication;
import com.chat.base.config.WKConfig;
import com.chat.base.endpoint.EndpointManager;
import com.chat.base.endpoint.entity.ChatSettingCellMenu;
import com.chat.base.msgitem.WKChannelMemberRole;
import com.chat.base.utils.AndroidUtilities;
import com.chat.uikit.R;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannelMember;
import com.xinbida.wukongim.entity.WKChannelType;

/**
 * 群管理模块Application
 * 负责:
 * 1. 注册 group_manager_view endpoint
 * 2. 当当前用户在群中的role为群主(1)或管理员(2)时，显示"群管理"入口
 * 3. 普通成员(role=0)不显示入口
 */
public class WKGroupManageApplication {

    private static volatile WKGroupManageApplication instance;
    private Context context;

    private WKGroupManageApplication() {
    }

    public static WKGroupManageApplication getInstance() {
        if (instance == null) {
            synchronized (WKGroupManageApplication.class) {
                if (instance == null) {
                    instance = new WKGroupManageApplication();
                }
            }
        }
        return instance;
    }

    public void init(Context context) {
        if (context == null) return;
        this.context = context.getApplicationContext();
        EndpointManager.getInstance().setMethod("group_manager_view", object -> {
            if (object instanceof ChatSettingCellMenu) {
                ChatSettingCellMenu menu = (ChatSettingCellMenu) object;
                return getGroupManagerView(menu.getChannelID(), menu.getChannelType(), menu.getParentLayout());
            }
            return null;
        });
    }

    /**
     * 获取群管理入口视图
     * 当当前用户在群中的role!=0(非普通成员)时，返回"群管理"入口视图
     *
     * @param groupNo     群编号
     * @param channelType 频道类型
     * @param parentView  父视图
     * @return 群管理入口视图，普通成员返回null
     */
    private View getGroupManagerView(String groupNo, byte channelType, ViewGroup parentView) {
        if (groupNo == null || channelType != WKChannelType.GROUP) {
            return null;
        }

        // 获取当前用户在群中的角色
        WKChannelMember member = WKIM.getInstance().getChannelMembersManager()
                .getMember(groupNo, WKChannelType.GROUP, WKConfig.getInstance().getUid());
        if (member == null) {
            return null;
        }

        // 普通成员(role=0)不显示群管理入口
        if (member.role == WKChannelMemberRole.normal) {
            return null;
        }

        // 群主或管理员显示"群管理"入口
        Context ctx = parentView != null ? parentView.getContext() : (context != null ? context : WKBaseApplication.getInstance().getContext());
        if (ctx == null) return null;

        // 创建"群管理"行布局
        LinearLayout layout = new LinearLayout(ctx);
        layout.setOrientation(LinearLayout.HORIZONTAL);
        layout.setGravity(Gravity.CENTER_VERTICAL);
        layout.setBackgroundResource(android.R.color.white);
        int paddingH = AndroidUtilities.dp(16);
        int paddingV = AndroidUtilities.dp(15);
        layout.setPadding(paddingH, paddingV, paddingH, paddingV);

        // "群管理"文字
        TextView textView = new TextView(ctx);
        textView.setText(R.string.group_manage);
        textView.setTextColor(ContextCompat.getColor(ctx, R.color.colorDark));
        textView.setTextSize(16);
        LinearLayout.LayoutParams textParams = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        textView.setLayoutParams(textParams);
        layout.addView(textView);

        // 右箭头
        ImageView arrow = new ImageView(ctx);
        arrow.setImageResource(R.mipmap.ic_arrow_right);
        int arrowSize = AndroidUtilities.dp(14);
        LinearLayout.LayoutParams arrowParams = new LinearLayout.LayoutParams(arrowSize, arrowSize);
        arrow.setLayoutParams(arrowParams);
        layout.addView(arrow);

        // 点击跳转到群管理页面
        layout.setOnClickListener(v -> {
            Intent intent = new Intent(ctx, GroupManageActivity.class);
            intent.putExtra("groupNo", groupNo);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            ctx.startActivity(intent);
        });

        return layout;
    }
}
