package com.chat.uikit.security.service;

import com.alibaba.fastjson.JSONObject;
import com.chat.base.base.WKBaseModel;
import com.chat.base.net.ICommonListener;
import com.chat.base.net.IRequestResultListener;
import com.chat.base.net.entity.CommonResponse;

/**
 * 账号安全 Model
 */
public class SecurityModel extends WKBaseModel {

    private SecurityModel() {
    }

    private static class SecurityModelBinder {
        private static final SecurityModel instance = new SecurityModel();
    }

    public static SecurityModel getInstance() {
        return SecurityModelBinder.instance;
    }

    /**
     * 发送绑定手机验证码
     */
    public void sendBindPhoneCode(String zone, String phone, final ICommonListener listener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("zone", zone);
        jsonObject.put("phone", phone);
        request(createAuthService(SecurityService.class).sendBindPhoneCode(jsonObject), new IRequestResultListener<CommonResponse>() {
            @Override
            public void onSuccess(CommonResponse result) {
                listener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                listener.onResult(code, msg);
            }
        });
    }

    /**
     * 绑定手机
     */
    public void bindPhone(String zone, String phone, String code, final ICommonListener listener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("zone", zone);
        jsonObject.put("phone", phone);
        jsonObject.put("code", code);
        request(createAuthService(SecurityService.class).bindPhone(jsonObject), new IRequestResultListener<CommonResponse>() {
            @Override
            public void onSuccess(CommonResponse result) {
                listener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                listener.onResult(code, msg);
            }
        });
    }

    /**
     * 发送绑定邮箱验证码
     */
    public void sendBindEmailCode(String email, final ICommonListener listener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("email", email);
        request(createAuthService(SecurityService.class).sendBindEmailCode(jsonObject), new IRequestResultListener<CommonResponse>() {
            @Override
            public void onSuccess(CommonResponse result) {
                listener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                listener.onResult(code, msg);
            }
        });
    }

    /**
     * 绑定邮箱
     */
    public void bindEmail(String email, String code, final ICommonListener listener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("email", email);
        jsonObject.put("code", code);
        request(createAuthService(SecurityService.class).bindEmail(jsonObject), new IRequestResultListener<CommonResponse>() {
            @Override
            public void onSuccess(CommonResponse result) {
                listener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                listener.onResult(code, msg);
            }
        });
    }

    /**
     * 发送修改密码邮箱验证码
     */
    public void sendChangePwdEmailCode(String email, final ICommonListener listener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("email", email);
        request(createAuthService(SecurityService.class).sendEmailForgetPwdCode(jsonObject), new IRequestResultListener<CommonResponse>() {
            @Override
            public void onSuccess(CommonResponse result) {
                listener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                listener.onResult(code, msg);
            }
        });
    }

    /**
     * 登录态下通过邮箱验证码修改密码
     */
    public void changePwdByEmail(String email, String code, String pwd, final ICommonListener listener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("email", email);
        jsonObject.put("code", code);
        jsonObject.put("pwd", pwd);
        request(createAuthService(SecurityService.class).emailChangePwd(jsonObject), new IRequestResultListener<CommonResponse>() {
            @Override
            public void onSuccess(CommonResponse result) {
                listener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                listener.onResult(code, msg);
            }
        });
    }

    /**
     * 发送修改密码手机验证码
     */
    public void sendChangePwdPhoneCode(String zone, String phone, final ICommonListener listener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("zone", zone);
        jsonObject.put("phone", phone);
        request(createAuthService(SecurityService.class).sendChangePwdPhoneCode(jsonObject), new IRequestResultListener<CommonResponse>() {
            @Override
            public void onSuccess(CommonResponse result) {
                listener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                listener.onResult(code, msg);
            }
        });
    }

    /**
     * 登录态下通过手机验证码修改密码
     */
    public void changePwdByPhone(String zone, String phone, String code, String pwd, final ICommonListener listener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("zone", zone);
        jsonObject.put("phone", phone);
        jsonObject.put("code", code);
        jsonObject.put("pwd", pwd);
        request(createAuthService(SecurityService.class).smsChangePwd(jsonObject), new IRequestResultListener<CommonResponse>() {
            @Override
            public void onSuccess(CommonResponse result) {
                listener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                listener.onResult(code, msg);
            }
        });
    }

    /**
     * 登录态下验证登录密码
     */
    public void verifyLoginPwd(String pwd, final ICommonListener listener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("pwd", pwd);
        request(createAuthService(SecurityService.class).verifyLoginPwd(jsonObject), new IRequestResultListener<CommonResponse>() {
            @Override
            public void onSuccess(CommonResponse result) {
                listener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                listener.onResult(code, msg);
            }
        });
    }

    /**
     * 设置锁屏密码
     */
    public void setLockScreenPwd(String pwd, final ICommonListener listener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("pwd", pwd);
        request(createAuthService(SecurityService.class).setLockScreenPwd(jsonObject), new IRequestResultListener<CommonResponse>() {
            @Override
            public void onSuccess(CommonResponse result) {
                listener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                listener.onResult(code, msg);
            }
        });
    }

    /**
     * 关闭锁屏密码
     */
    public void deleteLockScreenPwd(final ICommonListener listener) {
        request(createAuthService(SecurityService.class).deleteLockScreenPwd(), new IRequestResultListener<CommonResponse>() {
            @Override
            public void onSuccess(CommonResponse result) {
                listener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                listener.onResult(code, msg);
            }
        });
    }

    /**
     * 更新自动锁屏时间
     */
    public void updateLockAfterMinute(int minute, final ICommonListener listener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("minute", minute);
        request(createAuthService(SecurityService.class).updateLockAfterMinute(jsonObject), new IRequestResultListener<CommonResponse>() {
            @Override
            public void onSuccess(CommonResponse result) {
                listener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                listener.onResult(code, msg);
            }
        });
    }

    /**
     * 发送注销账号手机验证码
     */
    public void sendDestroyPhoneCode(String zone, String phone, final ICommonListener listener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("zone", zone);
        jsonObject.put("phone", phone);
        request(createAuthService(SecurityService.class).sendDestroyPhoneCode(jsonObject), new IRequestResultListener<CommonResponse>() {
            @Override
            public void onSuccess(CommonResponse result) {
                listener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                listener.onResult(code, msg);
            }
        });
    }

    /**
     * 发送注销账号邮箱验证码
     */
    public void sendDestroyEmailCode(String email, final ICommonListener listener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("email", email);
        request(createAuthService(SecurityService.class).sendDestroyEmailCode(jsonObject), new IRequestResultListener<CommonResponse>() {
            @Override
            public void onSuccess(CommonResponse result) {
                listener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                listener.onResult(code, msg);
            }
        });
    }

    /**
     * 注销账号
     */
    public void destroyAccount(String account, String code, String type, String zone, final ICommonListener listener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("account", account);
        jsonObject.put("code", code);
        jsonObject.put("type", type);
        jsonObject.put("zone", zone);
        request(createAuthService(SecurityService.class).destroyAccount(jsonObject), new IRequestResultListener<CommonResponse>() {
            @Override
            public void onSuccess(CommonResponse result) {
                listener.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                listener.onResult(code, msg);
            }
        });
    }
}
