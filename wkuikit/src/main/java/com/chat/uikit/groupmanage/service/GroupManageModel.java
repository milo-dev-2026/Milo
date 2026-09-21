package com.chat.uikit.groupmanage.service;

import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.chat.base.base.WKBaseModel;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.net.ICommonListener;
import com.chat.base.net.IRequestResultListener;
import com.chat.base.net.entity.CommonResponse;

import java.util.List;

/**
 * 群管理员管理 Model
 * 负责调用 GroupManageService 的 Retrofit 接口
 */
public class GroupManageModel extends WKBaseModel {

    private GroupManageModel() {
    }

    private static class GroupManageModelBinder {
        private final static GroupManageModel model = new GroupManageModel();
    }

    public static GroupManageModel getInstance() {
        return GroupManageModelBinder.model;
    }

    /**
     * 添加管理员
     *
     * @param groupNo         群编号
     * @param uids            要添加为管理员的用户UID列表
     * @param iCommonListener 回调
     */
    public void addManagers(String groupNo, List<String> uids, final ICommonListener iCommonListener) {
        JSONObject jsonObject = new JSONObject();
        JSONArray jsonArray = new JSONArray();
        jsonArray.addAll(uids);
        jsonObject.put("uids", jsonArray);
        request(createService(GroupManageService.class).addManagers(groupNo, jsonObject), new IRequestResultListener<>() {
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
     * 移除管理员
     *
     * @param groupNo         群编号
     * @param uid             要移除的管理员UID
     * @param iCommonListener 回调
     */
    public void removeManager(String groupNo, String uid, final ICommonListener iCommonListener) {
        JSONObject jsonObject = new JSONObject();
        JSONArray jsonArray = new JSONArray();
        jsonArray.add(uid);
        jsonObject.put("uids", jsonArray);
        request(createService(GroupManageService.class).removeManager(groupNo, jsonObject), new IRequestResultListener<>() {
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
}
