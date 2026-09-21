package com.chat.uikit.security.service;

import com.alibaba.fastjson.JSONObject;
import com.chat.base.net.entity.CommonResponse;

import io.reactivex.rxjava3.core.Observable;
import retrofit2.http.Body;
import retrofit2.http.DELETE;
import retrofit2.http.POST;
import retrofit2.http.PUT;

/**
 * 账号安全相关接口
 * 走 5001 端口认证服务
 */
public interface SecurityService {

    /**
     * 发送绑定手机验证码
     */
    @POST("user/sms/bindcode")
    Observable<CommonResponse> sendBindPhoneCode(@Body JSONObject jsonObject);

    /**
     * 绑定手机
     */
    @POST("user/bindphone")
    Observable<CommonResponse> bindPhone(@Body JSONObject jsonObject);

    /**
     * 发送绑定邮箱验证码
     */
    @POST("user/email/bindcode")
    Observable<CommonResponse> sendBindEmailCode(@Body JSONObject jsonObject);

    /**
     * 绑定邮箱
     */
    @POST("user/bindemail")
    Observable<CommonResponse> bindEmail(@Body JSONObject jsonObject);

    /**
     * 登录态下通过邮箱验证码修改密码
     */
    @POST("user/email/pwdchange")
    Observable<CommonResponse> emailChangePwd(@Body JSONObject jsonObject);

    /**
     * 发送忘记密码邮箱验证码（复用已有逻辑，用于登录态修改密码）
     */
    @POST("user/email/forgetpwd")
    Observable<CommonResponse> sendEmailForgetPwdCode(@Body JSONObject jsonObject);

    /**
     * 发送修改密码手机验证码
     */
    @POST("user/sms/pwdchangecode")
    Observable<CommonResponse> sendChangePwdPhoneCode(@Body JSONObject jsonObject);

    /**
     * 登录态下通过手机验证码修改密码
     */
    @POST("user/sms/pwdchange")
    Observable<CommonResponse> smsChangePwd(@Body JSONObject jsonObject);

    /**
     * 登录态下验证登录密码
     */
    @POST("user/verify_login_pwd")
    Observable<CommonResponse> verifyLoginPwd(@Body JSONObject jsonObject);

    /**
     * 发送注销账号手机验证码
     */
    @POST("user/sms/destroycode")
    Observable<CommonResponse> sendDestroyPhoneCode(@Body JSONObject jsonObject);

    /**
     * 发送注销账号邮箱验证码
     */
    @POST("user/email/destroycode")
    Observable<CommonResponse> sendDestroyEmailCode(@Body JSONObject jsonObject);

    /**
     * 注销账号
     */
    @POST("user/destroy")
    Observable<CommonResponse> destroyAccount(@Body JSONObject jsonObject);

    /**
     * 设置锁屏密码
     */
    @POST("user/lockscreenpwd")
    Observable<CommonResponse> setLockScreenPwd(@Body JSONObject jsonObject);

    /**
     * 关闭锁屏密码
     */
    @DELETE("user/lockscreenpwd")
    Observable<CommonResponse> deleteLockScreenPwd();

    /**
     * 更新自动锁屏时间
     */
    @PUT("user/lock_after_minute")
    Observable<CommonResponse> updateLockAfterMinute(@Body JSONObject jsonObject);
}
