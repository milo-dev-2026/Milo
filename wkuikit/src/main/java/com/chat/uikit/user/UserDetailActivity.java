package com.chat.uikit.user;

import android.annotation.SuppressLint;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.text.SpannableString;
import android.text.Spanned;
import android.text.TextUtils;
import android.view.MotionEvent;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.core.content.ContextCompat;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKApiConfig;
import com.chat.base.config.WKConfig;
import com.chat.base.msgitem.WKChannelMemberRole;
import com.chat.base.config.WKConstants;
import com.chat.base.config.WKSystemAccount;
import com.chat.base.endpoint.EndpointCategory;
import com.chat.base.endpoint.EndpointManager;
import com.chat.base.endpoint.entity.ChatViewMenu;
import com.chat.base.endpoint.entity.UserDetailViewMenu;
import com.chat.base.entity.PopupMenuItem;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.ui.Theme;
import com.chat.base.ui.components.NormalClickableContent;
import com.chat.base.ui.components.NormalClickableSpan;
import com.chat.base.utils.LayoutHelper;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.WKReader;
import com.chat.base.utils.WKTimeUtils;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.chat.manager.WKIMUtils;
import com.chat.uikit.contacts.service.FriendModel;
import com.chat.uikit.databinding.ActUserDetailLayoutBinding;
import com.chat.uikit.db.WKContactsDB;
import com.chat.uikit.message.MsgModel;
import com.chat.uikit.user.service.UserModel;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannel;
import com.xinbida.wukongim.entity.WKChannelMember;
import com.xinbida.wukongim.entity.WKChannelMemberExtras;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * 2020-03-19 22:06
 * 个人资料
 */
public class UserDetailActivity extends WKBaseActivity<ActUserDetailLayoutBinding> {
    String uid;
    String groupID;
    private String vercode;
    private WKChannel userChannel;

    @Override
    protected ActUserDetailLayoutBinding getViewBinding() {
        return ActUserDetailLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.user_card);
    }

    @Override
    protected void initPresenter() {
        initParams(getIntent());
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        initParams(intent);
        initView();
        initListener();
        initData();
    }

    private void initParams(Intent mIntent) {
        uid = mIntent.getStringExtra("uid");
        if (TextUtils.isEmpty(uid)) {
            finish();
            return;
        }
        if (uid.equals(WKSystemAccount.system_file_helper)) {
            Intent intent = new Intent(this, WKFileHelperActivity.class);
            startActivity(intent);
            finish();
            return;
        }
        if (uid.equals(WKSystemAccount.system_team)) {
            Intent intent = new Intent(this, WKSystemTeamActivity.class);
            startActivity(intent);
            finish();
            return;
        }
        if (uid.equals(WKConfig.getInstance().getUid())) {
            Intent intent = new Intent(this, MyInfoActivity.class);
            startActivity(intent);
            finish();
            return;
        }
        if (mIntent.hasExtra("groupID")) {
            groupID = mIntent.getStringExtra("groupID");
        } else {
            groupID = "";
        }
        if (mIntent.hasExtra("vercode")) {
            vercode = mIntent.getStringExtra("vercode");
        } else {
            vercode = "";
        }
        userChannel = WKIM.getInstance().getChannelManager().getChannel(uid, WKChannelType.PERSONAL);
        if (!TextUtils.isEmpty(groupID)) {
            WKChannelMember member = WKIM.getInstance().getChannelMembersManager().getMember(groupID, WKChannelType.GROUP, uid);
            if (member != null && member.extraMap != null && member.extraMap.containsKey(WKChannelMemberExtras.WKCode)) {
                vercode = (String) member.extraMap.get(WKChannelMemberExtras.WKCode);
            }
            if (member != null && !TextUtils.isEmpty(member.memberRemark)) {
                wkVBinding.inGroupNameLayout.setVisibility(View.VISIBLE);
                wkVBinding.inGroupNameTv.setText(member.memberRemark);
            }
            if (member != null && !TextUtils.isEmpty(member.memberInviteUID) && member.isDeleted == 0) {
                String name = "";
                WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(member.memberInviteUID, WKChannelType.PERSONAL);
                if (channel != null) {
                    name = TextUtils.isEmpty(channel.channelRemark) ? channel.channelName : channel.channelRemark;
                }
                if (TextUtils.isEmpty(name)) {
                    WKChannelMember member1 = WKIM.getInstance().getChannelMembersManager().getMember(groupID, WKChannelType.GROUP, member.memberInviteUID);
                    if (member1 != null) {
                        name = TextUtils.isEmpty(member1.memberRemark) ? member1.memberName : member1.memberRemark;
                    }
                }
                if (!TextUtils.isEmpty(name)) {
                    wkVBinding.joinGroupWayLayout.setVisibility(View.VISIBLE);
                    String showTime = "";
                    if (!TextUtils.isEmpty(member.createdAt) && member.createdAt.contains(" ")) {
                        showTime = member.createdAt.split(" ")[0];
                    }
                    String content = String.format("%s %s", showTime, String.format(getString(R.string.invite_join_group), name));
                    wkVBinding.joinGroupWayTv.setText(content);
                    int index = content.indexOf(name);
                    SpannableString span = new SpannableString(content);
                    if (index >= 0 && index + name.length() <= content.length()) {
                        span.setSpan(new NormalClickableSpan(false, Theme.colorAccount, new NormalClickableContent(NormalClickableContent.NormalClickableTypes.Other, ""), view -> {

                        }), index, index + name.length(), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
                    }
                    wkVBinding.joinGroupWayTv.setText(span);
                }
            }
        } else {
            wkVBinding.joinGroupWayLayout.setVisibility(View.GONE);
        }

    }

    @Override
    protected void initView() {
        wkVBinding.applyBtn.getBackground().setTint(Theme.colorAccount);
        wkVBinding.avatarView.setSize(50);
        wkVBinding.appIdNumLeftTv.setText(String.format(getString(R.string.app_idnum), getString(R.string.app_name)));
        wkVBinding.refreshLayout.setEnableOverScrollDrag(true);
        wkVBinding.refreshLayout.setEnableLoadMore(false);
        wkVBinding.refreshLayout.setEnableRefresh(false);
        // 隐藏朋友圈、更多信息（投诉入口保留可见）
        wkVBinding.publishCircleMomentLayout.setVisibility(View.GONE);
        wkVBinding.reviewCircleMomentLayout.setVisibility(View.GONE);
        wkVBinding.reviewCircleManagementLayout.setVisibility(View.GONE);
        wkVBinding.complaintLayout.setVisibility(View.VISIBLE);
        wkVBinding.layoutcircleInformation.setVisibility(View.GONE);
        wkVBinding.otherLayout.removeAllViews();
        List<View> list = EndpointManager.getInstance().invokes(EndpointCategory.wkUserDetailView, new UserDetailViewMenu(this, wkVBinding.otherLayout, uid, groupID));
        if (WKReader.isNotEmpty(list)) {
            for (int i = 0; i < list.size(); i++) {
                if (list.get(i) != null)
                    wkVBinding.otherLayout.addView(list.get(i));
            }
        }
        if (wkVBinding.otherLayout.getChildCount() > 0) {
            LinearLayout view = new LinearLayout(this);
            view.setBackgroundColor(ContextCompat.getColor(this, R.color.homeColor));
            view.setLayoutParams(LayoutHelper.createLinear(LayoutHelper.MATCH_PARENT, 15));
            wkVBinding.otherLayout.addView(view);
        }
    }


    @SuppressLint("ClickableViewAccessibility")
    @Override
    protected void initListener() {
        if (!TextUtils.isEmpty(groupID) && !uid.equals(WKConfig.getInstance().getUid())) {
            WKIM.getInstance().getChannelManager().addOnRefreshChannelInfo("user_detail_refresh_channel", (channel, isEnd) -> {
                if (channel != null && channel.channelID.equals(groupID) && channel.channelType == WKChannelType.GROUP) {
                    getUserInfo();
                    wkVBinding.avatarView.showAvatar(channel);
                }
            });
        }

        wkVBinding.pushBlackLayout.setOnClickListener(v -> {

            if (userChannel == null) return;
            String title = getString(userChannel.status == 2 ? R.string.pull_out_black_list : R.string.push_black_list);
            String content = getString(userChannel.status == 2 ? R.string.pull_out_black_list_tips : R.string.join_black_list_tips);

            WKDialogUtils.getInstance().showDialog(this, title, content, true, "", "", 0, 0, index -> {
                if (index == 1) {
                    if (userChannel.status != 2)
                        UserModel.getInstance().addBlackList(uid, (code, msg) -> {
                            if (code == HttpResponseCode.success) {
                                finish();
                            } else showToast(msg);
                        });
                    else UserModel.getInstance().removeBlackList(uid, (code, msg) -> {
                        if (code == HttpResponseCode.success) {
                            finish();
                        } else showToast(msg);
                    });

                }
            });

        });
        setonLongClick(wkVBinding.nameTv, wkVBinding.nameTv);
        setonLongClick(wkVBinding.identityLayout, wkVBinding.appIdNumTv);
        setonLongClick(wkVBinding.nickNameLayout, wkVBinding.nickNameTv);

        //频道资料刷新
        WKIM.getInstance().getChannelManager().addOnRefreshChannelInfo("user_detail_refresh_channel1", (channel, isEnd) -> {
            if (channel != null && channel.channelID.equals(uid) && channel.channelType == WKChannelType.PERSONAL) {
                userChannel = WKIM.getInstance().getChannelManager().getChannel(uid, WKChannelType.PERSONAL);
                setData();
            }
        });
        SingleClickUtil.onSingleClick(wkVBinding.applyBtn, v -> WKDialogUtils.getInstance().showInputDialog(UserDetailActivity.this, getString(R.string.apply), getString(R.string.input_remark), "", getString(R.string.input_remark), 20, text -> FriendModel.getInstance().applyAddFriend(uid, vercode, text, (code, msg) -> {
            if (code == HttpResponseCode.success) {
                wkVBinding.applyBtn.setText(R.string.applyed);
                wkVBinding.applyBtn.setAlpha(0.2f);
                wkVBinding.applyBtn.setEnabled(false);
            } else showToast(msg);
        })));
        SingleClickUtil.onSingleClick(wkVBinding.sendMsgBtn, v -> {
            WKIMUtils.getInstance().startChatActivity(new ChatViewMenu(this, uid, WKChannelType.PERSONAL, 0, true));
            finish();
        });
        // 语音通话
        SingleClickUtil.onSingleClick(wkVBinding.sendVideoBtn, v -> {
            try {
                String userId = WKConfig.getInstance().getUid();
                if (userId == null || userId.isEmpty()) {
                    WKToastUtils.getInstance().showToastNormal("用户未登录");
                    return;
                }
                String callerName = "";
                if (userChannel != null) {
                    callerName = TextUtils.isEmpty(userChannel.channelRemark) ? userChannel.channelName : userChannel.channelRemark;
                }
                if (callerName == null || callerName.isEmpty()) {
                    callerName = "用户";
                }
                int roomId = (int) (System.currentTimeMillis() / 1000);
                int callType = com.chat.base.trtc.TRTCType.AUDIO_CALL;
                int sdkAppId = 1600159338;
                String secretKey = "b3132bc984dcaefdb93179dc33cc950a3ca184d03d0e32d4c2c99a73e7220b98";
                String userSig = com.chat.base.trtc.UserSigGenerator.genUserSig(sdkAppId, userId, secretKey);
                WKConfig.getInstance().setTrtcSdkAppId(sdkAppId);
                WKConfig.getInstance().setTrtcUserSig(userSig);
                Intent intent = new Intent(this, com.chat.uikit.trtc.TRTCCallActivity.class);
                intent.putExtra(com.chat.uikit.trtc.TRTCCallActivity.EXTRA_USER_ID, userId);
                intent.putExtra(com.chat.uikit.trtc.TRTCCallActivity.EXTRA_TARGET_UID, uid);
                intent.putExtra(com.chat.uikit.trtc.TRTCCallActivity.EXTRA_CHANNEL_ID, uid);
                intent.putExtra(com.chat.uikit.trtc.TRTCCallActivity.EXTRA_CHANNEL_TYPE, WKChannelType.PERSONAL);
                intent.putExtra(com.chat.uikit.trtc.TRTCCallActivity.EXTRA_ROOM_ID, roomId);
                intent.putExtra(com.chat.uikit.trtc.TRTCCallActivity.EXTRA_CALLER_NAME, callerName);
                intent.putExtra(com.chat.uikit.trtc.TRTCCallActivity.EXTRA_CALL_TYPE, callType);
                intent.putExtra(com.chat.uikit.trtc.TRTCCallActivity.EXTRA_SDK_APP_ID, sdkAppId);
                intent.putExtra(com.chat.uikit.trtc.TRTCCallActivity.EXTRA_USER_SIG, userSig);
                startActivity(intent);
            } catch (Exception e) {
                e.printStackTrace();
                WKToastUtils.getInstance().showToastNormal("通话发起失败");
            }
        });
        wkVBinding.deleteLayout.setOnClickListener(v -> {
            String content = String.format(getString(R.string.delete_friends_tips), wkVBinding.nameTv.getText().toString());
            WKDialogUtils.getInstance().showDialog(this, getString(R.string.delete_friends), content, true, "", getString(R.string.delete), 0, ContextCompat.getColor(this, R.color.red), index -> {
                if (index == 1) {
                    UserModel.getInstance().deleteUser(uid, (code, msg) -> {
                        if (code == HttpResponseCode.success) {
                            WKIM.getInstance().getConversationManager().deleteWitchChannel(uid, WKChannelType.PERSONAL);
                            MsgModel.getInstance().offsetMsg(uid, WKChannelType.PERSONAL, null);
                            WKIM.getInstance().getMsgManager().clearWithChannel(uid, WKChannelType.PERSONAL);
                            WKContactsDB.getInstance().updateFriendStatus(uid, 0);
                            WKIM.getInstance().getChannelManager().updateFollow(uid, WKChannelType.PERSONAL, 0);
                            EndpointManager.getInstance().invoke(WKConstants.refreshContacts, null);
                            EndpointManager.getInstance().invokes(EndpointCategory.wkExitChat, new WKChannel(uid, WKChannelType.PERSONAL));
                            finish();
                        } else showToast(msg);
                    });
                }
            });
        });
        SingleClickUtil.onSingleClick(wkVBinding.remarkLayout, v -> {
            Intent intent = new Intent(this, SetUserRemarkActivity.class);
            intent.putExtra("uid", uid);
            intent.putExtra("oldStr", userChannel == null ? "" : userChannel.channelRemark);
            chooseResultLac.launch(intent);
        });
        wkVBinding.avatarView.setOnClickListener(v -> showImg());

        wkVBinding.complaintLayout.setOnClickListener(v -> {
            Intent intent = new Intent(UserDetailActivity.this, ComplaintActivity.class);
            intent.putExtra("uid", uid);
            intent.putExtra("name", wkVBinding.nameTv.getText().toString());
            startActivity(intent);
        });
    }

    private void showCopy(View view, float[] coordinate, String content) {
        List<PopupMenuItem> list = new ArrayList<>();
        list.add(new PopupMenuItem(getString(R.string.copy), R.mipmap.msg_copy, () -> {
            view.setBackgroundColor(ContextCompat.getColor(this, R.color.transparent));
            ClipboardManager cm = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
            ClipData mClipData = ClipData.newPlainText("Label", content);
            if (cm != null) {
                cm.setPrimaryClip(mClipData);
            }
            WKToastUtils.getInstance().showToastNormal(getString(R.string.copyed));
        }));
        view.setBackgroundColor(ContextCompat.getColor(this, R.color.color999));
        WKDialogUtils.getInstance().showScreenPopup(view, coordinate, list, () -> view.setBackgroundColor(ContextCompat.getColor(UserDetailActivity.this, R.color.transparent)));
    }

    @Override
    protected void initData() {
        super.initData();
        setData();
        getUserInfo();
    }

    private void setData() {
        wkVBinding.avatarView.showAvatar(uid, WKChannelType.PERSONAL);
        if (uid.equals(WKConfig.getInstance().getUid())) hideTitleRightView();
        if (userChannel != null) {
            boolean isSpecial = com.chat.base.utils.SpecialUserUtils.isSpecialUser(uid) || com.chat.base.utils.SpecialUserUtils.isSpecialUserByName(userChannel.channelName);
            if (isSpecial) {
                com.chat.base.utils.SpecialUserUtils.setSpecialUserBadges(wkVBinding.specialBadgeLayout, 12f);
            } else {
                wkVBinding.specialBadgeLayout.setVisibility(View.GONE);
            }
            if (!TextUtils.isEmpty(userChannel.channelRemark)) {
                wkVBinding.nickNameLayout.setVisibility(View.VISIBLE);
                if (isSpecial) {
                    wkVBinding.nickNameTv.setTextColor(android.graphics.Color.RED);
                    wkVBinding.nickNameTv.setText(userChannel.channelName);
                    wkVBinding.nameTv.setTextColor(android.graphics.Color.RED);
                    wkVBinding.nameTv.setText(userChannel.channelRemark);
                } else {
                    wkVBinding.nickNameTv.setText(userChannel.channelName);
                    wkVBinding.nameTv.setText(userChannel.channelRemark);
                }
            } else {
                if (isSpecial) {
                    wkVBinding.nameTv.setTextColor(android.graphics.Color.RED);
                    wkVBinding.nameTv.setText(userChannel.channelName);
                } else {
                    wkVBinding.nameTv.setText(userChannel.channelName);
                }
                wkVBinding.nickNameLayout.setVisibility(View.GONE);
            }
        } else {
            wkVBinding.deleteLayout.setVisibility(View.GONE);
            wkVBinding.sendMsgBtn.setVisibility(View.GONE);
            wkVBinding.sendVideoBtn.setVisibility(View.GONE);
            wkVBinding.llGotochat.setVisibility(View.GONE);
        }
    }

    private void getUserInfo() {
        WKIM.getInstance().getChannelManager().fetchChannelInfo(uid, WKChannelType.PERSONAL);
        UserModel.getInstance().getUserInfo(uid, groupID, (code, msg, userInfo) -> {
            if (code == HttpResponseCode.success) {
                if (userInfo != null) {
                    if (!TextUtils.isEmpty(userInfo.vercode)) {
                        vercode = userInfo.vercode;
                    }
                    WKChannel channel = WKIM.getInstance().getChannelManager().getChannel(uid, WKChannelType.PERSONAL);
                    if (channel != null) {
                        boolean needUpdate = false;
                        if (!TextUtils.isEmpty(userInfo.name) && !userInfo.name.equals(channel.channelName)) {
                            channel.channelName = userInfo.name;
                            needUpdate = true;
                        }
                        if (needUpdate) {
                            WKIM.getInstance().getChannelManager().saveOrUpdateChannel(channel);
                        }
                    }
                    String displayName = TextUtils.isEmpty(userInfo.remark) ? userInfo.name : userInfo.remark;
                    boolean isSpecial = com.chat.base.utils.SpecialUserUtils.isSpecialUser(uid) || com.chat.base.utils.SpecialUserUtils.isSpecialUserByName(displayName) || com.chat.base.utils.SpecialUserUtils.isSpecialUserByName(userInfo.name);
                    if (isSpecial) {
                        com.chat.base.utils.SpecialUserUtils.setSpecialUserBadges(wkVBinding.specialBadgeLayout, 12f);
                        wkVBinding.nameTv.setTextColor(android.graphics.Color.RED);
                        wkVBinding.nameTv.setText(displayName);
                        wkVBinding.nickNameTv.setTextColor(android.graphics.Color.RED);
                        wkVBinding.nickNameTv.setText(userInfo.name);
                    } else {
                        wkVBinding.specialBadgeLayout.setVisibility(View.GONE);
                        wkVBinding.nameTv.setText(displayName);
                        wkVBinding.nickNameTv.setText(userInfo.name);
                    }
                    wkVBinding.nickNameLayout.setVisibility(TextUtils.isEmpty(userInfo.remark) ? View.GONE : View.VISIBLE);
                    if (TextUtils.isEmpty(userInfo.short_no)) {
                        wkVBinding.identityLayout.setVisibility(View.GONE);
                    } else {
                        wkVBinding.identityLayout.setVisibility(View.VISIBLE);
                        wkVBinding.appIdNumTv.setText(userInfo.short_no);
                    }
                    // 显示个性签名（优先从userInfo.sign，其次从channel extra）
                    String signature = userInfo.sign;
                    if (TextUtils.isEmpty(signature) && channel != null && channel.remoteExtraMap != null) {
                        Object sigObj = channel.remoteExtraMap.get("signature");
                        if (sigObj != null) {
                            signature = String.valueOf(sigObj);
                        }
                    }
                    if (!TextUtils.isEmpty(signature)) {
                        wkVBinding.personalSignatureLL.setVisibility(View.VISIBLE);
                        wkVBinding.personalSignatureTv.setText(signature);
                        wkVBinding.personalSignatureV.setVisibility(View.VISIBLE);
                    } else {
                        wkVBinding.personalSignatureLL.setVisibility(View.GONE);
                        wkVBinding.personalSignatureV.setVisibility(View.GONE);
                    }
                    if (!TextUtils.isEmpty(userInfo.source_desc)) {
                        wkVBinding.sourceFromTv.setText(userInfo.source_desc);
                        wkVBinding.fromLayout.setVisibility(View.VISIBLE);
                    } else {
                        wkVBinding.fromLayout.setVisibility(View.GONE);
                    }

                    if (userInfo.status == 2) {
                        wkVBinding.blacklistTv.setText(R.string.pull_out_black_list);
                    } else {
                        wkVBinding.blacklistTv.setText(R.string.push_black_list);
                    }
                    wkVBinding.sendMsgBtn.setVisibility(userInfo.follow == 1 ? View.VISIBLE : View.GONE);
                    wkVBinding.sendVideoBtn.setVisibility(userInfo.follow == 1 ? View.VISIBLE : View.GONE);
                    wkVBinding.llGotochat.setVisibility(userInfo.follow == 1 ? View.VISIBLE : View.GONE);
                    wkVBinding.llGototempchat.setVisibility(userInfo.follow == 1 ? View.GONE : View.VISIBLE);
                    wkVBinding.applyBtn.setVisibility(userInfo.follow == 1 ? View.GONE : View.VISIBLE);
                    wkVBinding.deleteLayout.setVisibility(userInfo.follow == 1 ? View.VISIBLE : View.GONE);
                    wkVBinding.blacklistDescTv.setVisibility(userInfo.status == 2 ? View.VISIBLE : View.GONE);

                    // 禁止添加好友逻辑
                    if (!TextUtils.isEmpty(groupID)) {
                        WKChannel groupChannel = WKIM.getInstance().getChannelManager().getChannel(groupID, WKChannelType.GROUP);
                        boolean isForbiddenAddFriend = false;
                        if (groupChannel != null && groupChannel.remoteExtraMap != null) {
                            Object val = groupChannel.remoteExtraMap.get("forbidden_add_friend");
                            if (val instanceof Integer) {
                                isForbiddenAddFriend = (int) val == 1;
                            }
                        }
                        if (isForbiddenAddFriend) {
                            WKChannelMember loginMember = WKIM.getInstance().getChannelMembersManager().getMember(groupID, WKChannelType.GROUP, WKConfig.getInstance().getUid());
                            WKChannelMember targetMember = WKIM.getInstance().getChannelMembersManager().getMember(groupID, WKChannelType.GROUP, uid);
                            boolean isLoginNormal = loginMember == null || loginMember.role == WKChannelMemberRole.normal;
                            boolean isTargetNormal = targetMember == null || targetMember.role == WKChannelMemberRole.normal;
                            if (isLoginNormal && isTargetNormal) {
                                // milo号显示为*******
                                if (!TextUtils.isEmpty(userInfo.short_no)) {
                                    wkVBinding.identityLayout.setVisibility(View.VISIBLE);
                                    wkVBinding.appIdNumTv.setText("*******");
                                }
                                // 隐藏添加好友按钮
                                wkVBinding.applyBtn.setVisibility(View.GONE);
                                wkVBinding.llGototempchat.setVisibility(View.GONE);
                                // 隐藏发消息等可能触发添加好友的按钮
                                wkVBinding.sendMsgBtn.setVisibility(View.GONE);
                                wkVBinding.sendVideoBtn.setVisibility(View.GONE);
                                wkVBinding.llGotochat.setVisibility(View.GONE);
                            }
                        }
                    }

                    if (!TextUtils.isEmpty(userInfo.join_group_invite_uid)){
                        wkVBinding.joinGroupWayLayout.setVisibility(View.VISIBLE);
                        String content = String.format("%s %s", userInfo.join_group_time, String.format(getString(R.string.invite_join_group), userInfo.join_group_invite_name));
                        wkVBinding.joinGroupWayTv.setText(content);
                        int index = content.indexOf(userInfo.join_group_invite_name);
                        SpannableString span = new SpannableString(content);
                        span.setSpan(new NormalClickableSpan(false, Theme.colorAccount, new NormalClickableContent(NormalClickableContent.NormalClickableTypes.Other, ""), view -> {

                        }), index, index + userInfo.join_group_invite_name.length(), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
                        wkVBinding.joinGroupWayTv.setText(span);
                    }
                }
            } else {
                showToast(msg);
            }
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        WKIM.getInstance().getChannelManager().removeRefreshChannelInfo("user_detail_refresh_channel");
        WKIM.getInstance().getChannelManager().removeRefreshChannelInfo("user_detail_refresh_channel1");
    }


    private void showImg() {
        if (wkVBinding.avatarView == null || wkVBinding.avatarView.imageView == null) return;
        String uri = WKApiConfig.getAvatarUrl(uid) + "?key=" + WKTimeUtils.getInstance().getCurrentMills();
        List<Object> tempImgList = new ArrayList<>();
        List<ImageView> imageViewList = new ArrayList<>();
        imageViewList.add(wkVBinding.avatarView.imageView);
        tempImgList.add(WKApiConfig.getShowUrl(uri));
        int index = 0;
        WKDialogUtils.getInstance().showImagePopup(this, tempImgList, imageViewList, wkVBinding.avatarView.imageView, index, new ArrayList<>(), null, null);
        WKIM.getInstance().getChannelManager().updateAvatarCacheKey(uid, WKChannelType.PERSONAL, UUID.randomUUID().toString().replaceAll("-", ""));
    }

    ActivityResultLauncher<Intent> chooseResultLac = registerForActivityResult(new ActivityResultContracts.StartActivityForResult(), result -> {
        if (result.getResultCode() == RESULT_OK) {
            getUserInfo();
        }
    });

    @SuppressLint("ClickableViewAccessibility")
    private void setonLongClick(View view, TextView textView) {
        final float[][] location = {new float[2]};
        view.setOnTouchListener((var view12, var motionEvent) -> {
            if (motionEvent.getAction() == MotionEvent.ACTION_DOWN) {
                location[0] = new float[]{motionEvent.getRawX(), motionEvent.getRawY()};
            }
            return false;
        });
        view.setOnLongClickListener(view1 -> {
            showCopy(textView, location[0], textView.getText().toString());
            return true;
        });
    }
}
