package com.chat.uikit.group;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import com.alibaba.fastjson.JSONObject;
import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKConfig;
import com.chat.base.msgitem.WKChannelMemberRole;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.ui.components.SwitchView;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActGroupManageLayoutBinding;
import com.chat.uikit.group.adapter.GroupManagerAdapter;
import com.chat.uikit.group.service.GroupModel;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannel;
import com.xinbida.wukongim.entity.WKChannelMember;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

/**
 * 群管理页面
 */
public class GroupManageActivity extends WKBaseActivity<ActGroupManageLayoutBinding> {
    private static final int REQUEST_CODE_ADD_ADMIN = 1001;
    private static final int REQUEST_CODE_TRANSFER_OWNER = 1002;
    private String groupNo;
    private WKChannel groupChannel;
    private int memberRole;
    private GroupManagerAdapter groupManagerAdapter;
    private String scrollTo;
    // 待生效的设置：API调用成功后暂存，防止SDK refresh回调旧值覆盖
    private final HashMap<String, Integer> pendingSettings = new HashMap<>();

    @Override
    protected ActGroupManageLayoutBinding getViewBinding() {
        return ActGroupManageLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.group_manage);
    }

    @Override
    protected void initPresenter() {
        groupNo = getIntent().getStringExtra("groupNo");
        if (TextUtils.isEmpty(groupNo)) {
            finish();
            return;
        }
        scrollTo = getIntent().getStringExtra("scroll_to");
    }

    @SuppressLint("SetTextI18n")
    @Override
    protected void initView() {
        wkVBinding.recyclerView.setLayoutManager(new androidx.recyclerview.widget.LinearLayoutManager(this));
        groupManagerAdapter = new GroupManagerAdapter(new ArrayList<>());
        wkVBinding.recyclerView.setAdapter(groupManagerAdapter);
        wkVBinding.refreshLayout.setEnableRefresh(false);
        wkVBinding.refreshLayout.setEnableLoadMore(false);
    }

    @Override
    protected void initListener() {
        // 入群审核开关
        wkVBinding.invitConfirmationSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                int value = isChecked ? 1 : 0;
                wkVBinding.invitConfirmationSwitch.setEnabled(false);
                GroupModel.getInstance().updateGroupSetting(groupNo, "invite", value, (code, msg) -> {
                    wkVBinding.invitConfirmationSwitch.setEnabled(true);
                    if (code == HttpResponseCode.success) {
                        updateChannelRemoteExtra("invite", value);
                        updateChannelInvite(value);
                        delayedFetchChannelInfo();
                    } else {
                        if (!TextUtils.isEmpty(msg))
                            WKToastUtils.getInstance().showToastNormal(msg);
                        wkVBinding.invitConfirmationSwitch.setChecked(!isChecked);
                    }
                });
            }
        });

        // 全员禁言
        wkVBinding.fullStaffBanSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                int value = isChecked ? 1 : 0;
                wkVBinding.fullStaffBanSwitch.setEnabled(false);
                GroupModel.getInstance().updateGroupSetting(groupNo, "forbidden", value, (code, msg) -> {
                    wkVBinding.fullStaffBanSwitch.setEnabled(true);
                    if (code == HttpResponseCode.success) {
                        updateChannelRemoteExtra("forbidden", value);
                        updateChannelForbidden(value);
                        delayedFetchChannelInfo();
                    } else {
                        if (!TextUtils.isEmpty(msg))
                            WKToastUtils.getInstance().showToastNormal(msg);
                        wkVBinding.fullStaffBanSwitch.setChecked(!isChecked);
                    }
                });
            }
        });

        // 禁止添加好友 - 参考 utalk：开启时自动联动开启"禁止临时会话"
        wkVBinding.forbiddenAddFriendSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                int value = isChecked ? 1 : 0;
                wkVBinding.forbiddenAddFriendSwitch.setEnabled(false);
                GroupModel.getInstance().updateGroupSetting(groupNo, "forbidden_add_friend", value, (code, msg) -> {
                    wkVBinding.forbiddenAddFriendSwitch.setEnabled(true);
                    if (code == HttpResponseCode.success) {
                        updateChannelRemoteExtra("forbidden_add_friend", value);
                        // 参考 utalk：开启"禁止添加好友"时自动开启"禁止临时会话"并禁用该开关
                        if (isChecked) {
                            updateChannelRemoteExtra("forbid_member_send_temp_msg", 1);
                            GroupModel.getInstance().updateGroupSetting(groupNo, "forbid_member_send_temp_msg", 1, (code2, msg2) -> {
                                if (code2 == HttpResponseCode.success) {
                                    wkVBinding.forbiddenTempMsgSwitch.setChecked(true);
                                    wkVBinding.forbiddenTempMsgSwitch.setEnabled(false);
                                    wkVBinding.forbiddenTempMsgSwitch.setAlpha(0.5f);
                                }
                            });
                        } else {
                            // 关闭"禁止添加好友"时恢复"禁止临时会话"开关为可点击
                            wkVBinding.forbiddenTempMsgSwitch.setEnabled(true);
                            wkVBinding.forbiddenTempMsgSwitch.setAlpha(1.0f);
                        }
                        delayedFetchChannelInfo();
                    } else {
                        if (!TextUtils.isEmpty(msg))
                            WKToastUtils.getInstance().showToastNormal(msg);
                        wkVBinding.forbiddenAddFriendSwitch.setChecked(!isChecked);
                    }
                });
            }
        });

        // 禁止临时会话
        wkVBinding.forbiddenTempMsgSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                int value = isChecked ? 1 : 0;
                wkVBinding.forbiddenTempMsgSwitch.setEnabled(false);
                GroupModel.getInstance().updateGroupSetting(groupNo, "forbid_member_send_temp_msg", value, (code, msg) -> {
                    wkVBinding.forbiddenTempMsgSwitch.setEnabled(true);
                    if (code == HttpResponseCode.success) {
                        updateChannelRemoteExtra("forbid_member_send_temp_msg", value);
                        delayedFetchChannelInfo();
                    } else {
                        if (!TextUtils.isEmpty(msg))
                            WKToastUtils.getInstance().showToastNormal(msg);
                        wkVBinding.forbiddenTempMsgSwitch.setChecked(!isChecked);
                    }
                });
            }
        });

        // 新成员查看历史消息 - 参考 utalk：语义反转
        // 开关 ON = 禁止新成员查看历史消息 → allow_view_history_msg=0
        // 开关 OFF = 允许新成员查看历史消息 → allow_view_history_msg=1
        wkVBinding.allowNewMembersViewHistorMesgSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                // 参考 utalk：开关 ON 时发送 allow_view_history_msg=0（不允许）
                int value = isChecked ? 0 : 1;
                wkVBinding.allowNewMembersViewHistorMesgSwitch.setEnabled(false);
                GroupModel.getInstance().updateGroupSetting(groupNo, "allow_view_history_msg", value, (code, msg) -> {
                    wkVBinding.allowNewMembersViewHistorMesgSwitch.setEnabled(true);
                    if (code == HttpResponseCode.success) {
                        updateChannelRemoteExtra("allow_view_history_msg", value);
                        delayedFetchChannelInfo();
                    } else {
                        if (!TextUtils.isEmpty(msg))
                            WKToastUtils.getInstance().showToastNormal(msg);
                        wkVBinding.allowNewMembersViewHistorMesgSwitch.setChecked(!isChecked);
                    }
                });
            }
        });

        // 群主转让
        wkVBinding.groupOwnerTransferLayout.setOnClickListener(v -> showTransferOwnerDialog());

        // 黑名单
        wkVBinding.blackListLayout.setOnClickListener(v -> {
            Intent intent = new Intent(this, GroupBlackListActivity.class);
            intent.putExtra("groupNo", groupNo);
            startActivity(intent);
        });

        // 退出成员
        wkVBinding.outUserLayout.setOnClickListener(v -> {
            Intent intent = new Intent(this, OutGroupMembersActivity.class);
            intent.putExtra("groupNo", groupNo);
            startActivity(intent);
        });

        // 添加管理员
        wkVBinding.addAdminLayout.setOnClickListener(v -> {
            // 构建已存在的管理员/群主 uid 列表，作为不可选项
            StringBuilder unSelectUids = new StringBuilder();
            List<WKChannelMember> managers = groupManagerAdapter.getData();
            if (managers != null) {
                for (int i = 0; i < managers.size(); i++) {
                    if (i > 0) unSelectUids.append(",");
                    unSelectUids.append(managers.get(i).memberUID);
                }
            }
            Intent intent = new Intent(this, com.chat.uikit.contacts.ChooseContactsActivity.class);
            intent.putExtra("type", 2);
            intent.putExtra("groupId", groupNo);
            intent.putExtra("unSelectUids", unSelectUids.toString());
            startActivityForResult(intent, REQUEST_CODE_ADD_ADMIN);
        });

        // 管理员列表点击 - 跳转用户详情
        groupManagerAdapter.setOnItemClickListener((adapter, view, position) -> {
            WKChannelMember member = (WKChannelMember) adapter.getItem(position);
            if (member != null) {
                Intent intent = new Intent(this, com.chat.uikit.user.UserDetailActivity.class);
                intent.putExtra("uid", member.memberUID);
                intent.putExtra("groupID", groupNo);
                startActivity(intent);
            }
        });

        // 管理员移除按钮
        groupManagerAdapter.setOnItemChildClickListener((adapter, view, position) -> {
            if (view.getId() == R.id.removeIv) {
                WKChannelMember member = (WKChannelMember) adapter.getItem(position);
                if (member != null) {
                    com.chat.base.utils.WKDialogUtils.getInstance().showDialog(this,
                            "移除管理员",
                            "确定移除\"" + (TextUtils.isEmpty(member.memberRemark) ? member.memberName : member.memberRemark) + "\"的管理员身份吗？",
                            true, "", "确定", 0,
                            getResources().getColor(R.color.red), index -> {
                                if (index == 1) {
                                    loadingPopup.show();
                                    List<String> removeUids = new ArrayList<>();
                                    removeUids.add(member.memberUID);
                                    GroupModel.getInstance().removeGroupManagers(groupNo, removeUids, (code, msg) -> {
                                        loadingPopup.dismiss();
                                        if (code == HttpResponseCode.success) {
                                            WKToastUtils.getInstance().showToastNormal("已移除管理员");
                                            GroupModel.getInstance().groupMembersSync(groupNo, (syncCode, syncMsg) -> {
                                                loadManagers();
                                            });
                                        } else {
                                            WKToastUtils.getInstance().showToastNormal("移除失败: " + msg);
                                        }
                                    });
                                }
                            });
                }
            }
        });

        // 监听频道信息更新
        WKIM.getInstance().getChannelManager().addOnRefreshChannelInfo("group_manage_refresh_channel", (channel, isEnd) -> {
            if (channel != null && channel.channelID.equalsIgnoreCase(groupNo) && channel.channelType == WKChannelType.GROUP) {
                groupChannel = channel;
                setData();
            }
        });
    }

    @Override
    protected void initData() {
        super.initData();
        groupChannel = WKIM.getInstance().getChannelManager().getChannel(groupNo, WKChannelType.GROUP);
        if (groupChannel != null) {
            setData();
        }
        // 获取管理员列表
        loadManagers();

        // 根据 scroll_to 参数滚动到对应区域
        if (!TextUtils.isEmpty(scrollTo)) {
            wkVBinding.scrollView.post(() -> {
                if ("admin".equals(scrollTo)) {
                    // 滚动到管理员区域
                    int[] location = new int[2];
                    wkVBinding.adminSectionTitle.getLocationOnScreen(location);
                    wkVBinding.scrollView.smoothScrollTo(0, location[1] - wkVBinding.scrollView.getTop());
                } else if ("top".equals(scrollTo)) {
                    // 滚动到顶部（默认就是顶部，这里确保一下）
                    wkVBinding.scrollView.scrollTo(0, 0);
                }
            });
        }
    }

    /**
     * 手动更新 SDK 中 channel 的 remoteExtraMap 字段
     * 解决 API 调用成功后，SDK channel 同步回调仍是旧值导致开关回弹的问题
     */
    private void updateChannelRemoteExtra(String key, int value) {
        // 先存入 pending，setData() 会优先读取这里
        pendingSettings.put(key, value);
        try {
            WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(groupNo, WKChannelType.GROUP);
            if (channel != null) {
                if (channel.remoteExtraMap == null) {
                    channel.remoteExtraMap = new HashMap<>();
                }
                channel.remoteExtraMap.put(key, value);
                WKIM.getInstance().getChannelManager().saveOrUpdateChannel(channel);
                groupChannel = channel;
            }
        } catch (Exception e) {
            android.util.Log.e("GroupManage", "updateRemoteExtra " + key + "=" + value + " error: " + e.getMessage());
        }
        // 立即刷新UI，确保开关状态正确
        refreshSwitchFromPending(key);
    }

    /**
     * 手动更新 SDK 标准字段 forbidden（全员禁言）
     */
    private void updateChannelForbidden(int value) {
        pendingSettings.put("__forbidden_std", value);
        try {
            WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(groupNo, WKChannelType.GROUP);
            if (channel != null) {
                channel.forbidden = value;
                WKIM.getInstance().getChannelManager().saveOrUpdateChannel(channel);
                groupChannel = channel;
            }
        } catch (Exception e) {
            android.util.Log.e("GroupManage", "updateForbidden " + value + " error: " + e.getMessage());
        }
    }

    /**
     * 手动更新 SDK 标准字段 invite（入群审核）
     */
    private void updateChannelInvite(int value) {
        pendingSettings.put("__invite_std", value);
        try {
            WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(groupNo, WKChannelType.GROUP);
            if (channel != null) {
                channel.invite = value;
                WKIM.getInstance().getChannelManager().saveOrUpdateChannel(channel);
                groupChannel = channel;
            }
        } catch (Exception e) {
            android.util.Log.e("GroupManage", "updateInvite " + value + " error: " + e.getMessage());
        }
    }

    /**
     * 延迟3秒后从服务器刷新频道信息，避免IM服务器同步延迟导致开关回弹
     */
    private final Handler fetchChannelHandler = new Handler(Looper.getMainLooper());
    private Runnable fetchChannelRunnable = null;

    private void delayedFetchChannelInfo() {
        if (fetchChannelRunnable != null) {
            fetchChannelHandler.removeCallbacks(fetchChannelRunnable);
        }
        fetchChannelRunnable = () -> {
            WKIM.getInstance().getChannelManager().fetchChannelInfo(groupNo, WKChannelType.GROUP);
            fetchChannelRunnable = null;
        };
        fetchChannelHandler.postDelayed(fetchChannelRunnable, 3000);
    }

    /**
     * 更新remote_extra中的自定义设置
     * 使用WuKongIM原生的PUT groups/{groupNo}接口，通过remote_extra字段更新
     */
    private void updateRemoteExtraSetting(String key, int value, String toastMsg, SwitchView switchView) {
        try {
            // 从当前channel获取remoteExtraMap，构建完整的remote_extra JSON
            HashMap<String, Object> remoteExtraMap = new HashMap<>();
            if (groupChannel != null && groupChannel.remoteExtraMap != null) {
                remoteExtraMap.putAll(groupChannel.remoteExtraMap);
            }
            // 应用pending中的值（确保使用最新值）
            for (String pendingKey : pendingSettings.keySet()) {
                if (!pendingKey.startsWith("__")) {
                    remoteExtraMap.put(pendingKey, pendingSettings.get(pendingKey));
                }
            }
            // 设置新值
            remoteExtraMap.put(key, value);

            // 转换为JSON字符串
            String remoteExtraJson = new org.json.JSONObject(remoteExtraMap).toString();
            android.util.Log.d("GroupManage", "updateRemoteExtraSetting key=" + key + " value=" + value + " json=" + remoteExtraJson);

            JSONObject jsonObject = new JSONObject();
            jsonObject.put("remote_extra", remoteExtraJson);

            GroupModel.getInstance().updateGroupInfo(groupNo, jsonObject, (code, msg) -> {
                android.util.Log.d("GroupManage", "updateRemoteExtraSetting结果 key=" + key + " code=" + code + " msg=" + msg);
                if (code == HttpResponseCode.success) {
                    WKToastUtils.getInstance().showToastNormal(toastMsg);
                    // 更新本地SDK数据
                    updateChannelRemoteExtra(key, value);
                    // 主动从服务器拉取最新频道信息，确保数据持久化
                    WKIM.getInstance().getChannelManager().fetchChannelInfo(groupNo, WKChannelType.GROUP);
                } else {
                    WKToastUtils.getInstance().showToastNormal(msg);
                    switchView.setChecked(!switchView.isChecked());
                }
            });
        } catch (Exception e) {
            android.util.Log.e("GroupManage", "updateRemoteExtraSetting error: " + e.getMessage());
            WKToastUtils.getInstance().showToastNormal("更新失败: " + e.getMessage());
            switchView.setChecked(!switchView.isChecked());
        }
    }

    /**
     * 根据 pending 中的值直接刷新某个开关的UI状态
     */
    private void refreshSwitchFromPending(String key) {
        Integer val = pendingSettings.get(key);
        if (val == null) return;
        boolean checked = val == 1;
        switch (key) {
            case "invite":
                wkVBinding.invitConfirmationSwitch.setChecked(checked);
                break;
            case "forbidden":
                wkVBinding.fullStaffBanSwitch.setChecked(checked);
                break;
            case "forbidden_add_friend":
                wkVBinding.forbiddenAddFriendSwitch.setChecked(checked);
                break;
            case "forbid_member_send_temp_msg":
                wkVBinding.forbiddenTempMsgSwitch.setChecked(checked);
                break;
            case "allow_view_history_msg":
                wkVBinding.allowNewMembersViewHistorMesgSwitch.setChecked(checked);
                break;
        }
    }

    private void setData() {
        // 获取当前用户角色 - 先从完整成员列表中查找，更可靠
        String loginUID = WKConfig.getInstance().getUid();
        List<WKChannelMember> allMembers = WKIM.getInstance().getChannelMembersManager().getMembers(groupNo, WKChannelType.GROUP);
        if (allMembers != null) {
            for (WKChannelMember m : allMembers) {
                if (m.memberUID.equals(loginUID)) {
                    memberRole = m.role;
                    break;
                }
            }
        }
        // 备份：如果列表中没找到，再尝试getMember
        if (memberRole == WKChannelMemberRole.normal) {
            WKChannelMember member = WKIM.getInstance().getChannelMembersManager().getMember(groupNo, WKChannelType.GROUP, loginUID);
            if (member != null) {
                memberRole = member.role;
            }
        }

        // 设置开关状态 - forbidden 和 invite 是 SDK 标准字段（WuKongIM 核心功能基于此字段）
        // 其他自定义设置存储在 remoteExtraMap 中
        // forbidden: 全员禁言
        boolean forbiddenEnabled = groupChannel.forbidden == 1;
        // 兜底：从 remote_extra 读取（兼容旧数据）
        if (!forbiddenEnabled && groupChannel.remoteExtraMap != null && groupChannel.remoteExtraMap.containsKey("forbidden")) {
            Object val = groupChannel.remoteExtraMap.get("forbidden");
            if (val instanceof Integer) {
                forbiddenEnabled = ((int) val) == 1;
            }
        }
        // pending 优先：防止 SDK refresh 旧值覆盖
        if (pendingSettings.containsKey("forbidden")) {
            forbiddenEnabled = pendingSettings.get("forbidden") == 1;
        }
        wkVBinding.fullStaffBanSwitch.setChecked(forbiddenEnabled);

        // 从remoteExtra获取其他设置
        if (groupChannel.remoteExtraMap != null) {
            // invite: 入群审核 - 优先使用标准字段
            boolean inviteVal = groupChannel.invite == 1;
            // 兜底：从 remote_extra 读取（兼容旧数据）
            if (!inviteVal && groupChannel.remoteExtraMap.containsKey("invite")) {
                Object val = groupChannel.remoteExtraMap.get("invite");
                if (val instanceof Integer) {
                    inviteVal = ((int) val) == 1;
                }
            }
            if (pendingSettings.containsKey("invite")) {
                inviteVal = pendingSettings.get("invite") == 1;
            }
            wkVBinding.invitConfirmationSwitch.setChecked(inviteVal);

            // forbidden_add_friend: 禁止添加好友
            boolean addFriendVal = false;
            if (groupChannel.remoteExtraMap.containsKey("forbidden_add_friend")) {
                Object val = groupChannel.remoteExtraMap.get("forbidden_add_friend");
                if (val instanceof Integer) {
                    addFriendVal = ((int) val) == 1;
                }
            }
            if (pendingSettings.containsKey("forbidden_add_friend")) {
                addFriendVal = pendingSettings.get("forbidden_add_friend") == 1;
            }
            wkVBinding.forbiddenAddFriendSwitch.setChecked(addFriendVal);

            // 参考 utalk：禁止添加好友开启时，禁止临时会话开关联动
            if (addFriendVal) {
                wkVBinding.forbiddenTempMsgSwitch.setChecked(true);
                wkVBinding.forbiddenTempMsgSwitch.setEnabled(false);
                wkVBinding.forbiddenTempMsgSwitch.setAlpha(0.5f);
            } else {
                wkVBinding.forbiddenTempMsgSwitch.setEnabled(true);
                wkVBinding.forbiddenTempMsgSwitch.setAlpha(1.0f);
            }

            // forbid_member_send_temp_msg: 禁止临时会话
            boolean tempMsgVal = false;
            if (groupChannel.remoteExtraMap.containsKey("forbid_member_send_temp_msg")) {
                Object val = groupChannel.remoteExtraMap.get("forbid_member_send_temp_msg");
                if (val instanceof Integer) {
                    tempMsgVal = ((int) val) == 1;
                }
            }
            if (pendingSettings.containsKey("forbid_member_send_temp_msg")) {
                tempMsgVal = pendingSettings.get("forbid_member_send_temp_msg") == 1;
            }
            wkVBinding.forbiddenTempMsgSwitch.setChecked(tempMsgVal);

            // allow_view_history_msg: 参考 utalk 语义反转
            // allow_view_history_msg=1 → 允许 → 开关 OFF
            // allow_view_history_msg=0 → 不允许 → 开关 ON
            boolean historyVal = true; // 默认允许（开关 OFF）
            if (groupChannel.remoteExtraMap.containsKey("allow_view_history_msg")) {
                Object val = groupChannel.remoteExtraMap.get("allow_view_history_msg");
                if (val instanceof Integer) {
                    // allow_view_history_msg=1 → 允许 → 开关 OFF (false)
                    // allow_view_history_msg=0 → 不允许 → 开关 ON (true)
                    historyVal = ((int) val) == 0;
                }
            }
            if (pendingSettings.containsKey("allow_view_history_msg")) {
                historyVal = pendingSettings.get("allow_view_history_msg") == 0;
            }
            wkVBinding.allowNewMembersViewHistorMesgSwitch.setChecked(historyVal);
        }

        // 角色权限控制
        boolean isOwner = memberRole == WKChannelMemberRole.admin;
        boolean isOwnerOrManager = isOwner || memberRole == WKChannelMemberRole.manager;

        // 群主专属功能（只有群主可见）
        if (!isOwner) {
            wkVBinding.groupOwnerTransferLayout.setVisibility(View.GONE);
            wkVBinding.addAdminLayout.setVisibility(View.GONE);
        }

        // 群主和管理员可见的功能
        if (!isOwnerOrManager) {
            wkVBinding.outUserLayout.setVisibility(View.GONE);
            wkVBinding.blackListLayout.setVisibility(View.GONE);
            wkVBinding.invitConfirmationSwitch.setEnabled(false);
            wkVBinding.fullStaffBanSwitch.setEnabled(false);
            wkVBinding.forbiddenAddFriendSwitch.setEnabled(false);
            wkVBinding.forbiddenTempMsgSwitch.setEnabled(false);
            wkVBinding.allowNewMembersViewHistorMesgSwitch.setEnabled(false);
        }
    }

    private void loadManagers() {
        // 加载管理员列表
        List<WKChannelMember> managers = new ArrayList<>();
        List<WKChannelMember> members = WKIM.getInstance().getChannelMembersManager().getMembers(groupNo, WKChannelType.GROUP);
        if (members != null) {
            for (WKChannelMember member : members) {
                if (member.role == WKChannelMemberRole.admin || member.role == WKChannelMemberRole.manager) {
                    managers.add(member);
                }
            }
        }
        // 本地为空时从服务器同步
        if (managers.isEmpty()) {
            GroupModel.getInstance().groupMembersSync(groupNo, (code, msg) -> {
                if (code == HttpResponseCode.success) {
                    // 同步完成后重新加载
                    List<WKChannelMember> syncedManagers = new ArrayList<>();
                    List<WKChannelMember> syncedMembers = WKIM.getInstance().getChannelMembersManager().getMembers(groupNo, WKChannelType.GROUP);
                    if (syncedMembers != null) {
                        for (WKChannelMember member : syncedMembers) {
                            if (member.role == WKChannelMemberRole.admin || member.role == WKChannelMemberRole.manager) {
                                syncedManagers.add(member);
                            }
                        }
                    }
                    groupManagerAdapter.setList(syncedManagers);
                }
            });
        } else {
            groupManagerAdapter.setList(managers);
        }
    }

    /**
     * 群主转让 - 跳转到选择联系人页面选择新群主
     */
    private void showTransferOwnerDialog() {
        Intent intent = new Intent(this, com.chat.uikit.contacts.ChooseContactsActivity.class);
        intent.putExtra("type", 2);
        intent.putExtra("groupId", groupNo);
        intent.putExtra("singleChoose", true);
        intent.putExtra("chooseBack", true);
        startActivityForResult(intent, REQUEST_CODE_TRANSFER_OWNER);
    }

    /**
     * 执行群主转让：调用专用transfer API
     */
    private void transferOwnership(String newOwnerUid, String newOwnerName) {
        loadingPopup.show();
        GroupModel.getInstance().transferGroup(groupNo, newOwnerUid, (code, msg) -> {
            loadingPopup.dismiss();
            if (code == HttpResponseCode.success) {
                WKToastUtils.getInstance().showToastNormal("群主已转让给" + newOwnerName);
                GroupModel.getInstance().groupMembersSync(groupNo, (syncCode, m) -> {});
                finish();
            } else {
                WKToastUtils.getInstance().showToastNormal("转让失败: " + msg);
            }
        });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_CODE_ADD_ADMIN && resultCode == RESULT_OK && data != null) {
            ArrayList<String> selectedIds = data.getStringArrayListExtra("selectedChannelIds");
            if (selectedIds != null && !selectedIds.isEmpty()) {
                addAdmins(selectedIds);
            }
        } else if (requestCode == REQUEST_CODE_TRANSFER_OWNER && resultCode == RESULT_OK && data != null) {
            String targetUid = data.getStringExtra("uid");
            if (!TextUtils.isEmpty(targetUid)) {
                // 从群成员信息中获取显示名称
                WKChannelMember member = WKIM.getInstance().getChannelMembersManager()
                        .getMember(groupNo, WKChannelType.GROUP, targetUid);
                String targetName = targetUid;
                if (member != null) {
                    targetName = TextUtils.isEmpty(member.memberRemark) ?
                            (TextUtils.isEmpty(member.memberName) ? targetUid : member.memberName)
                            : member.memberRemark;
                }
                final String finalTargetName = targetName;
                WKDialogUtils.getInstance().showDialog(this, "转让群主",
                        "确定将群主转让给\"" + finalTargetName + "\"吗？转让后你将变为普通成员。",
                        true, "", "确定转让", 0,
                        getResources().getColor(R.color.red), index -> {
                            if (index == 1) {
                                transferOwnership(targetUid, finalTargetName);
                            }
                        });
            }
        }
    }

    /**
     * 批量添加管理员 - 使用专用 managers API
     */
    private void addAdmins(List<String> uidList) {
        if (uidList == null || uidList.isEmpty()) return;
        loadingPopup.show();
        GroupModel.getInstance().addGroupManagers(groupNo, uidList, (code, msg) -> {
            loadingPopup.dismiss();
            if (code == HttpResponseCode.success) {
                WKToastUtils.getInstance().showToastNormal("成功添加管理员");
                GroupModel.getInstance().groupMembersSync(groupNo, (syncCode, syncMsg) -> {
                    loadManagers();
                });
            } else {
                WKToastUtils.getInstance().showToastNormal("添加失败: " + msg);
            }
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        WKIM.getInstance().getChannelManager().removeRefreshChannelInfo("group_manage_refresh_channel");
    }
}
