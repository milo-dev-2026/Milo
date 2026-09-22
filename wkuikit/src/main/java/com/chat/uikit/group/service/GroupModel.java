package com.chat.uikit.group.service;

import android.text.TextUtils;

import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.chat.base.base.WKBaseModel;
import com.chat.base.common.WKCommonModel;
import com.chat.base.config.WKApiConfig;
import com.chat.base.config.WKConfig;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.db.ApplyDB;
import com.chat.base.endpoint.EndpointCategory;
import com.chat.base.endpoint.EndpointManager;
import com.chat.base.entity.NewFriendEntity;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.net.ICommonListener;
import com.chat.base.net.IRequestResultListener;
import com.chat.base.net.entity.CommonResponse;
import com.chat.base.utils.AndroidUtilities;
import com.chat.base.utils.WKReader;
import com.chat.base.utils.WKTimeUtils;
import com.chat.base.net.ud.WKUploader;
import com.chat.uikit.group.GroupEntity;
import com.chat.uikit.group.service.entity.GroupMember;
import com.chat.uikit.group.service.entity.GroupQr;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannel;
import com.xinbida.wukongim.entity.WKChannelMember;
import com.xinbida.wukongim.entity.WKChannelMemberExtras;
import com.xinbida.wukongim.entity.WKChannelType;
import com.xinbida.wukongim.interfaces.IChannelMemberListResult;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import android.util.Log;
import okhttp3.RequestBody;

/**
 * 2019-11-30 10:25
 * 群相关处理
 */
public class GroupModel extends WKBaseModel {

    private GroupModel() {
    }

    private static class GroupModelBinder {
        private final static GroupModel groupModel = new GroupModel();
    }

    public static GroupModel getInstance() {
        return GroupModelBinder.groupModel;
    }

    /**
     * 创建群组
     *
     * @param name 群名
     * @param ids  成员
     */
    public void createGroup(String name, List<String> ids, List<String> names, final IGroupInfo iGroupInfo) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("name", name);
        JSONArray jsonArray = new JSONArray();
        jsonArray.addAll(ids);
        jsonObject.put("members", jsonArray);
        JSONArray jsonArray1 = new JSONArray();
        jsonArray1.addAll(names);
        jsonObject.put("member_names", jsonArray1);
        jsonObject.put("msg_auto_delete", WKConfig.getInstance().getUserInfo() != null ? WKConfig.getInstance().getUserInfo().msg_expire_second : 0);
        request(createService(GroupService.class).createGroup(jsonObject), new IRequestResultListener<>() {
            @Override
            public void onSuccess(GroupEntity groupEntity) {
                WKChannel channel = new WKChannel();
                channel.channelID = groupEntity.group_no;
                channel.channelType = WKChannelType.GROUP;
                channel.channelName = groupEntity.name;
                WKIM.getInstance().getChannelManager().saveOrUpdateChannel(channel);
                iGroupInfo.onResult(HttpResponseCode.success, "", groupEntity);
            }

            @Override
            public void onFail(int code, String msg) {
                iGroupInfo.onResult(code, msg, null);
            }
        });
    }

    public interface IGroupInfo {
        void onResult(int code, String msg, GroupEntity groupEntity);
    }

    /**
     * 添加群成员
     *
     * @param groupNo 群号
     * @param ids     成员
     */
    public void addGroupMembers(String groupNo, List<String> ids, List<String> names, final ICommonListener iCommonListener) {
        JSONObject jsonObject = new JSONObject();
        JSONArray jsonArray = new JSONArray();
        jsonArray.addAll(ids);
        jsonObject.put("members", jsonArray);
        JSONArray nameArr = new JSONArray();
        nameArr.addAll(names);
        jsonObject.put("names", nameArr);
        request(createService(GroupService.class).addGroupMembers(groupNo, jsonObject), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                iCommonListener.onResult(code, msg);
            }
        });
    }

    /**
     * 邀请加入群聊
     *
     * @param groupNo         群编号
     * @param ids             用户id
     * @param iCommonListener 返回
     */
    public void inviteGroupMembers(String groupNo, List<String> ids, final ICommonListener iCommonListener) {
        JSONObject jsonObject1 = new JSONObject();
        JSONArray jsonArray = new JSONArray();
        jsonArray.addAll(ids);
        jsonObject1.put("uids", jsonArray);
        jsonObject1.put("remark", "");
        request(createService(GroupService.class).inviteGroupMembers(groupNo, jsonObject1), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                iCommonListener.onResult(code, msg);
            }
        });
    }


    /**
     * 通过群二维码加入群聊
     *
     * @param groupNo         群编号
     * @param iCommonListener 返回
     */
    public void joinGroupByQr(String groupNo, final ICommonListener iCommonListener) {
        String uid = WKConfig.getInstance().getUid();
        String name = WKConfig.getInstance().getUserInfo() != null ? WKConfig.getInstance().getUserInfo().name : "";
        List<String> ids = new ArrayList<>();
        ids.add(uid);
        List<String> names = new ArrayList<>();
        names.add(name);
        addGroupMembers(groupNo, ids, names, (code, msg) -> {
            if (code == HttpResponseCode.success) {
                // 加入成功后，同步群成员信息和频道信息
                groupMembersSync(groupNo, null);
                WKCommonModel.getInstance().getChannel(groupNo, WKChannelType.GROUP, null);
            }
            if (iCommonListener != null) {
                iCommonListener.onResult(code, msg);
            }
        });
    }


    /**
     * 获取群详情
     *
     * @param groupNo     群编号
     * @param iGetChannel 返回
     */
    public void getGroupInfo(String groupNo, final WKCommonModel.IGetChannel iGetChannel) {
        WKCommonModel.getInstance().getChannel(groupNo, WKChannelType.GROUP, (code, msg, entity) -> {
            if (iGetChannel != null) {
                iGetChannel.onResult(code, msg, entity);
            }
        });
    }


    public void getChannelMembers(String groupNO, String keyword, int page, int limit, IChannelMemberListResult iChannelMemberListResult) {
        request(createService(GroupService.class).groupMembers(groupNO, keyword, page, limit), new IRequestResultListener<>() {
            @Override
            public void onSuccess(List<GroupMember> result) {
                List<WKChannelMember> list = serialize(result);
                iChannelMemberListResult.onResult(list);
            }

            @Override
            public void onFail(int code, String msg) {
                if (iChannelMemberListResult != null) {
                    iChannelMemberListResult.onResult(new ArrayList<>());
                }
            }
        });
    }

    /**
     * 同步群成员
     *
     * @param groupNo 群编号
     */
    public synchronized void groupMembersSync(String groupNo, final ICommonListener iCommonListener) {
        groupMembersSyncInternal(groupNo, iCommonListener, 0);
    }

    private void groupMembersSyncInternal(String groupNo, final ICommonListener iCommonListener, int depth) {
        if (depth > 50) {
            if (iCommonListener != null) iCommonListener.onResult(HttpResponseCode.success, "");
            return;
        }
        long version = WKIM.getInstance().getChannelMembersManager().getMaxVersion(groupNo, WKChannelType.GROUP);
        request(createService(GroupService.class).syncGroupMembers(groupNo, 1000, version), new IRequestResultListener<>() {
            @Override
            public void onSuccess(List<GroupMember> list) {
                if (WKReader.isNotEmpty(list)) {
                    List<WKChannelMember> members = serialize(list);
                    WKIM.getInstance().getChannelMembersManager().save(members);
                    final int nextDepth = depth + 1;
                    AndroidUtilities.runOnUIThread(() -> groupMembersSyncInternal(groupNo, iCommonListener, nextDepth), 500);
                } else {
                    if (iCommonListener != null)
                        iCommonListener.onResult(HttpResponseCode.success, "");
                }
            }

            @Override
            public void onFail(int code, String msg) {
                if (iCommonListener != null) iCommonListener.onResult(code, msg);
            }
        });

    }

    private List<WKChannelMember> serialize(List<GroupMember> list) {
        List<WKChannelMember> members = new ArrayList<>();
        if (WKReader.isEmpty(list)) {
            return members;
        }
        for (int i = 0, size = list.size(); i < size; i++) {
            GroupMember gm = list.get(i);
            if (gm == null) continue;
            WKChannelMember member = new WKChannelMember();
            member.memberUID = gm.uid;
            member.memberRemark = gm.remark;
            member.memberName = gm.name;
            member.channelID = gm.group_no;
            member.channelType = WKChannelType.GROUP;
            member.isDeleted = gm.is_deleted;
            member.version = gm.version;
            member.role = gm.role;
            member.status = gm.status;
            member.memberInviteUID = gm.invite_uid;
            member.robot = gm.robot;
            member.forbiddenExpirationTime = gm.forbidden_expir_time;
            if (member.robot == 1 && !TextUtils.isEmpty(gm.username)) {
                member.memberName = gm.username;
            }
            member.updatedAt = gm.updated_at;
            member.createdAt = gm.created_at;
            HashMap<String, Object> hashMap = new HashMap<>();
            hashMap.put(WKChannelMemberExtras.WKCode, gm.vercode);
            member.extraMap = hashMap;
            members.add(member);
        }
        return members;
    }

    /**
     * 修改群设置
     *
     * @param groupNo         群编号
     * @param key             修改字段
     * @param value           修改值
     * @param iCommonListener 返回
     */
    public void updateGroupSetting(String groupNo, String key, int value, final ICommonListener iCommonListener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put(key, value);
        RequestBody body = RequestBody.create(
            okhttp3.MediaType.parse("application/json; charset=utf-8"), jsonObject.toJSONString());
        request(createService(GroupService.class).updateGroupSetting(groupNo, body), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                iCommonListener.onResult(code, msg);
            }
        });
    }

    public void updateGroupSetting(String groupNo, String key, String value, final ICommonListener iCommonListener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put(key, value);
        RequestBody body = RequestBody.create(
            okhttp3.MediaType.parse("application/json; charset=utf-8"), jsonObject.toJSONString());
        request(createService(GroupService.class).updateGroupSetting(groupNo, body), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                iCommonListener.onResult(code, msg);
            }
        });
    }

    // 用户级群设置字段（保存到通讯录、免打扰、置顶、显示昵称等）
    private static final java.util.Set<String> MY_SETTING_KEYS = new java.util.HashSet<>(
        java.util.Arrays.asList("save", "mute", "top", "show_nick", "remark",
            "chat_pwd_on", "revoke_remind", "screenshot", "receipt",
            "flame", "flame_second", "join_group_remind")
    );

    /**
     * 判断某个设置项是否属于用户级别（应调用 mysetting 接口）
     */
    public boolean isMySettingKey(String key) {
        return MY_SETTING_KEYS.contains(key);
    }

    /**
     * 更新用户个人群设置（保存到通讯录、免打扰、置顶等）
     * 调用 /v1/groups/{groupNo}/mysetting 接口
     */
    public void updateMyGroupSetting(String groupNo, String key, int value, final ICommonListener iCommonListener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put(key, value);
        RequestBody body = RequestBody.create(
            okhttp3.MediaType.parse("application/json; charset=utf-8"), jsonObject.toJSONString());
        request(createService(GroupService.class).updateMyGroupSetting(groupNo, body), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                // 成功后更新本地WKIM频道缓存，确保UI立即反映变化
                if (result.status == HttpResponseCode.success) {
                    updateLocalChannelSetting(groupNo, key, value);
                }
                iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                iCommonListener.onResult(code, msg);
            }
        });
    }

    public void updateMyGroupSetting(String groupNo, String key, String value, final ICommonListener iCommonListener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put(key, value);
        RequestBody body = RequestBody.create(
            okhttp3.MediaType.parse("application/json; charset=utf-8"), jsonObject.toJSONString());
        request(createService(GroupService.class).updateMyGroupSetting(groupNo, body), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                iCommonListener.onResult(code, msg);
            }
        });
    }

    /**
     * 更新本地WKIM频道缓存中的设置值（用于用户级设置更新后立即生效）
     */
    private void updateLocalChannelSetting(String groupNo, String key, int value) {
        com.xinbida.wukongim.entity.WKChannel channel =
            com.xinbida.wukongim.WKIM.getInstance().getChannelManager().getChannel(groupNo, com.xinbida.wukongim.entity.WKChannelType.GROUP);
        if (channel == null) return;
        boolean needSave = true;
        switch (key) {
            case "save":
                channel.save = value;
                break;
            case "mute":
                channel.mute = value;
                break;
            case "top":
                channel.top = value;
                break;
            case "show_nick":
                channel.showNick = value;
                break;
            case "receipt":
                channel.receipt = value;
                break;
            case "flame":
                channel.flame = value;
                break;
            case "flame_second":
                channel.flameSecond = value;
                break;
            default:
                needSave = false;
                break;
        }
        if (needSave) {
            com.xinbida.wukongim.WKIM.getInstance().getChannelManager().saveOrUpdateChannel(channel);
        }
    }

    /**
     * 修改群信息（通用版本，支持任意JSONObject参数）
     * 用于更新标准字段（如forbidden、invite）和remote_extra等
     *
     * @param groupNo         群编号
     * @param jsonObject      请求参数
     * @param iCommonListener 返回
     */
    public void updateGroupInfo(String groupNo, JSONObject jsonObject, final ICommonListener iCommonListener) {
        RequestBody body = RequestBody.create(
            okhttp3.MediaType.parse("application/json; charset=utf-8"), jsonObject.toJSONString());
        request(createService(GroupService.class).updateGroupInfo(groupNo, body), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                iCommonListener.onResult(code, msg);
            }
        });
    }

    /**
     * 修改群信息
     *
     * @param groupNo         群编号
     * @param key             修改字段
     * @param value           修改值
     * @param iCommonListener 返回
     */
    public void updateGroupInfo(String groupNo, String key, String value, final ICommonListener iCommonListener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put(key, value);
        RequestBody body = RequestBody.create(
            okhttp3.MediaType.parse("application/json; charset=utf-8"), jsonObject.toJSONString());
        request(createService(GroupService.class).updateGroupInfo(groupNo, body), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                iCommonListener.onResult(code, msg);
            }
        });
    }

    /**
     * 删除群成员
     *
     * @param groupNo         群编号
     * @param uidList         用户ID
     * @param iCommonListener 返回
     */
    public void deleteGroupMembers(String groupNo, List<String> uidList, List<String> names, final ICommonListener iCommonListener) {
        JSONObject jsonObject = new JSONObject();
        JSONArray jsonArray = new JSONArray();
        jsonArray.addAll(uidList);
        jsonObject.put("members", jsonArray);
        JSONArray nameArr = new JSONArray();
        nameArr.addAll(names);
        jsonObject.put("names", nameArr);
        request(createService(GroupService.class).deleteGroupMembers(groupNo, jsonObject), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                List<WKChannelMember> list = new ArrayList<>();
                for (int i = 0, size = uidList.size(); i < size; i++) {
                    WKChannelMember member = new WKChannelMember();
                    member.isDeleted = 1;
                    member.channelID = groupNo;
                    member.channelType = WKChannelType.GROUP;
                    member.memberUID = uidList.get(i);
                    list.add(member);
                }
                WKIM.getInstance().getChannelMembersManager().delete(list);
                iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                iCommonListener.onResult(code, msg);
            }
        });
    }

    /**
     * 修改群成员信息
     *
     * @param groupNo         群号
     * @param uid             用户ID
     * @param key             主键
     * @param value           修改值
     * @param iCommonListener 返回
     */
    public void updateGroupMemberInfo(String groupNo, String uid, String key, String value, final ICommonListener iCommonListener) {
        JSONObject jsonObject1 = new JSONObject();
        jsonObject1.put(key, value);
        request(createService(GroupService.class).updateGroupMemberInfo(groupNo, uid, jsonObject1), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                if (key.equalsIgnoreCase("remark")) {
                    //sdk层数据库修改
                    WKIM.getInstance().getChannelMembersManager().updateRemarkName(groupNo, WKChannelType.GROUP, uid, value);
                }
                iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                iCommonListener.onResult(code, msg);
            }
        });
    }

    /**
     * 群二维码
     *
     * @param groupID  群号
     * @param iGroupQr 返回
     */
    void getGroupQr(String groupID, final IGroupQr iGroupQr) {
        request(createService(GroupService.class).getGroupQr(groupID), new IRequestResultListener<>() {
            @Override
            public void onSuccess(GroupQr result) {
                iGroupQr.onResult(HttpResponseCode.success, "", result.day, result.qrcode, result.expire);
            }

            @Override
            public void onFail(int code, String msg) {
                iGroupQr.onResult(code, msg, 0, "", "");
            }
        });

    }

    public interface IGroupQr {
        void onResult(int code, String msg, int day, String qrCode, String expire);
    }

    /**
     * 我保存的群聊
     *
     * @param iGetMyGroups 返回
     */
    void getMyGroups(final IGetMyGroups iGetMyGroups) {
        request(createService(GroupService.class).getMyGroups(), new IRequestResultListener<>() {
            @Override
            public void onSuccess(List<GroupEntity> result) {
                iGetMyGroups.onResult(HttpResponseCode.success, "", result);
            }

            @Override
            public void onFail(int code, String msg) {
                iGetMyGroups.onResult(code, msg, new ArrayList<>());
            }
        });
    }

    public interface IGetMyGroups {
        void onResult(int code, String msg, List<GroupEntity> list);
    }

    public void exitGroup(String groupNo, final ICommonListener iCommonListener) {
        request(createService(GroupService.class).exitGroup(groupNo), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                iCommonListener.onResult(HttpResponseCode.success, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                iCommonListener.onResult(code, msg);
            }
        });
    }

    /**
     * 解散群组
     *
     * @param groupNo         群编号
     * @param iCommonListener 返回
     */
    public void disbandGroup(String groupNo, final ICommonListener iCommonListener) {
        request(createService(GroupService.class).disbandGroup(groupNo), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                iCommonListener.onResult(HttpResponseCode.success, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                iCommonListener.onResult(code, msg);
            }
        });
    }

    /**
     * 上传群头像
     *
     * @param groupNo      群编号
     * @param filePath     头像文件路径
     * @param iUploadBack  上传回调
     */
    public void uploadGroupAvatar(String groupNo, String filePath, final IUploadBack iUploadBack) {
        String url = WKApiConfig.baseUrl + "groups/" + groupNo + "/avatar?uuid=" + WKTimeUtils.getInstance().getCurrentMills();
        WKUploader.getInstance().upload(url, filePath, new WKUploader.IUploadBack() {
            @Override
            public void onSuccess(String url) {
                iUploadBack.onResult(HttpResponseCode.success);
            }

            @Override
            public void onError() {
                iUploadBack.onResult(HttpResponseCode.error);
            }
        });
    }

    public interface IUploadBack {
        void onResult(int code);
    }

    public void addGroupManagers(String groupNo, List<String> uids, final ICommonListener iCommonListener) {
        JSONObject jsonObject = new JSONObject();
        JSONArray jsonArray = new JSONArray();
        for (String uid : uids) {
            jsonArray.add(uid);
        }
        jsonObject.put("uids", jsonArray);
        String jsonStr = jsonObject.toJSONString();
        Log.d("GroupModel", "addGroupManagers JSON: " + jsonStr);
        RequestBody body = RequestBody.create(
            okhttp3.MediaType.parse("application/json; charset=utf-8"), jsonStr);
        request(createService(GroupService.class).addGroupManagers(groupNo, body), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                Log.d("GroupModel", "addGroupManagers failed: code=" + code + " msg=" + msg);
                iCommonListener.onResult(code, msg);
            }
        });
    }

    public void removeGroupManagers(String groupNo, List<String> uids, final ICommonListener iCommonListener) {
        JSONObject jsonObject = new JSONObject();
        JSONArray jsonArray = new JSONArray();
        for (String uid : uids) {
            jsonArray.add(uid);
        }
        jsonObject.put("uids", jsonArray);
        String jsonStr = jsonObject.toJSONString();
        Log.d("GroupModel", "removeGroupManagers JSON: " + jsonStr);
        RequestBody body = RequestBody.create(
            okhttp3.MediaType.parse("application/json; charset=utf-8"), jsonStr);
        request(createService(GroupService.class).removeGroupManagers(groupNo, body), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                iCommonListener.onResult(code, msg);
            }
        });
    }

    public void transferGroup(String groupNo, String uid, final ICommonListener iCommonListener) {
        request(createService(GroupService.class).transferGroup(groupNo, uid), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                iCommonListener.onResult(code, msg);
            }
        });
    }

    public void blacklistMember(String groupNo, String action, String uid, final ICommonListener iCommonListener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("uid", uid);
        request(createService(GroupService.class).blacklistMember(groupNo, action, jsonObject), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                iCommonListener.onResult(code, msg);
            }
        });
    }

    public void forbidMember(String groupNo, String uid, long expire, final ICommonListener iCommonListener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("uid", uid);
        jsonObject.put("expire", expire);
        request(createService(GroupService.class).forbidMember(groupNo, jsonObject), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                iCommonListener.onResult(code, msg);
            }
        });
    }

    /**
     * 通过入群申请
     *
     * @param groupNo 群号
     * @param uid     申请人UID
     * @param token   申请token
     */
    public void approveGroupApply(String groupNo, String uid, String token, final ICommonListener iCommonListener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("group_no", groupNo);
        jsonObject.put("uid", uid);
        jsonObject.put("token", token);
        request(createService(GroupService.class).approveGroupApply(jsonObject), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                iCommonListener.onResult(code, msg);
            }
        });
    }

    /**
     * 拒绝入群申请
     *
     * @param groupNo 群号
     * @param uid     申请人UID
     * @param token   申请token
     * @param remark  拒绝备注
     */
    public void rejectGroupApply(String groupNo, String uid, String token, String remark, final ICommonListener iCommonListener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("group_no", groupNo);
        jsonObject.put("uid", uid);
        jsonObject.put("token", token);
        jsonObject.put("remark", remark);
        request(createService(GroupService.class).rejectGroupApply(jsonObject), new IRequestResultListener<>() {
            @Override
            public void onSuccess(CommonResponse result) {
                iCommonListener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                iCommonListener.onResult(code, msg);
            }
        });
    }

    /**
     * 保存入群申请消息
     *
     * @param contentJson 消息json
     */
    public void saveGroupApplyMsg(String contentJson) {
        if (TextUtils.isEmpty(contentJson)) return;

        NewFriendEntity newFriendEntity = JSONObject.parseObject(contentJson, NewFriendEntity.class);
        if (newFriendEntity == null) return;

        newFriendEntity.type = 1; // 入群申请
        NewFriendEntity existEntity = ApplyDB.getInstance().query(newFriendEntity.apply_uid);
        if (existEntity != null && !TextUtils.isEmpty(existEntity.apply_uid)) {
            existEntity.status = 0;
            existEntity.token = newFriendEntity.token;
            existEntity.remark = newFriendEntity.remark;
            existEntity.type = 1;
            existEntity.group_no = newFriendEntity.group_no;
            existEntity.group_name = newFriendEntity.group_name;
            existEntity.created_at = WKTimeUtils.getInstance().getNowDate1();
            ApplyDB.getInstance().update(existEntity);
        } else {
            newFriendEntity.created_at = WKTimeUtils.getInstance().getNowDate1();
            ApplyDB.getInstance().insert(newFriendEntity);
        }
        int new_friend_count = WKSharedPreferencesUtil.getInstance().getInt(WKConfig.getInstance().getUid() + "_new_friend_count");
        new_friend_count++;
        WKSharedPreferencesUtil.getInstance().putInt(WKConfig.getInstance().getUid() + "_new_friend_count", new_friend_count);
        EndpointManager.getInstance().invokes(EndpointCategory.wkRefreshMailList, null);
    }

}
