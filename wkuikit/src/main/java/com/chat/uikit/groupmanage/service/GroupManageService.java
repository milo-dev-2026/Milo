package com.chat.uikit.groupmanage.service;

import com.alibaba.fastjson.JSONObject;
import com.chat.base.net.entity.CommonResponse;

import io.reactivex.rxjava3.core.Observable;
import retrofit2.http.Body;
import retrofit2.http.HTTP;
import retrofit2.http.POST;
import retrofit2.http.Path;

/**
 * 群管理员管理 Retrofit API 接口
 * 后端API:
 * - POST /v1/groups/{group_no}/managers  添加管理员
 * - DELETE /v1/groups/{group_no}/managers  移除管理员
 */
public interface GroupManageService {

    /**
     * 添加管理员
     *
     * @param groupNo    群编号
     * @param jsonObject 包含 uids 数组
     */
    @POST("groups/{groupNo}/managers")
    Observable<CommonResponse> addManagers(@Path("groupNo") String groupNo, @Body JSONObject jsonObject);

    /**
     * 移除管理员
     *
     * @param groupNo    群编号
     * @param jsonObject 包含 uid 字段
     */
    @HTTP(method = "DELETE", path = "groups/{groupNo}/managers", hasBody = true)
    Observable<CommonResponse> removeManager(@Path("groupNo") String groupNo, @Body JSONObject jsonObject);
}
