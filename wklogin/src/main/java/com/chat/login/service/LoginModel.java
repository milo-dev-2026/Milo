package com.chat.login.service;


import android.text.TextUtils;

import com.alibaba.fastjson.JSONObject;
import com.chat.base.base.WKBaseModel;
import com.chat.base.config.WKApiConfig;
import com.chat.base.config.WKConfig;
import com.chat.base.config.WKConstants;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.entity.UserInfoEntity;
import com.chat.base.net.FastJsonConverterFactory;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.net.ICommonListener;
import com.chat.base.net.IRequestResultErrorInfoListener;
import com.chat.base.net.IRequestResultListener;
import com.chat.base.net.OkHttpUtils;
import com.chat.base.net.entity.CommonResponse;
import com.chat.base.net.ud.WKUploader;
import com.chat.base.utils.WKDeviceUtils;
import com.chat.base.utils.WKTimeUtils;

import retrofit2.Retrofit;
import retrofit2.adapter.rxjava3.RxJava3CallAdapterFactory;
import com.chat.login.entity.CountryCodeEntity;
import com.chat.login.entity.ThirdAuthCode;
import com.chat.login.entity.ThirdLoginResult;
import com.chat.login.entity.VerfiCodeResult;

import org.json.JSONException;

import java.util.List;

/**
 * 2019-11-19 17:49
 * 登录model
 */
public class LoginModel extends WKBaseModel {
    private static Retrofit authRetrofit;

    private LoginModel() {
    }

    private static class LoginModelBinder {
        private static final LoginModel loginModel = new LoginModel();
    }

    public static LoginModel getInstance() {
        return LoginModelBinder.loginModel;
    }

    /**
     * 获取认证服务的 Retrofit 实例（指向验证码/注册服务）
     */
    private static Retrofit getAuthRetrofit() {
        if (authRetrofit == null) {
            synchronized (LoginModel.class) {
                if (authRetrofit == null) {
                    authRetrofit = new Retrofit.Builder()
                            .baseUrl(WKApiConfig.authUrl)
                            .client(OkHttpUtils.getInstance().getOkHttpClient())
                            .addConverterFactory(FastJsonConverterFactory.Companion.create())
                            .addCallAdapterFactory(RxJava3CallAdapterFactory.create())
                            .build();
                }
            }
        }
        return authRetrofit;
    }

    public static void resetAuthRetrofit() {
        synchronized (LoginModel.class) {
            authRetrofit = null;
        }
    }

    /**
     * 创建认证服务接口实例（走 5001 端口）
     */
    protected static <T> T createAuthService(Class<T> service) {
        return getAuthRetrofit().create(service);
    }

    /**
     * 登录
     *
     * @param name           账号
     * @param pwd            密码
     * @param iLoginListener 返回
     */
    void loginApp(String name, String pwd, final ILoginListener iLoginListener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("username", name);
        jsonObject.put("password", pwd);
        JSONObject deviceJson = new JSONObject();
        deviceJson.put("device_id", WKConstants.getDeviceID());
        deviceJson.put("device_name", WKDeviceUtils.getInstance().getDeviceName());
        deviceJson.put("device_model", WKDeviceUtils.getInstance().getSystemModel());
        jsonObject.put("device", deviceJson);

        // 登录接口走认证服务（authUrl），与注册/验证码/注册检测同一服务，token 通用
        requestAndErrorBack(createAuthService(LoginService.class).login(jsonObject), new IRequestResultErrorInfoListener<UserInfoEntity>() {
            @Override
            public void onSuccess(UserInfoEntity userInfo) {
                if (userInfo != null) {
                    saveLoginInfo(userInfo);
                    iLoginListener.onResult(HttpResponseCode.success, "", userInfo);
                }
            }

            @Override
            public void onFail(int code, String msg, String errJson) {
                UserInfoEntity userInfoEntity = new UserInfoEntity();
                if (code == 110 && !TextUtils.isEmpty(errJson)) {
                    try {
                        org.json.JSONObject jsonObject1 = new org.json.JSONObject(errJson);
                        userInfoEntity.phone = jsonObject1.optString("phone");
                        userInfoEntity.uid = jsonObject1.optString("uid");
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                }

                iLoginListener.onResult(code, msg, userInfoEntity);
            }
        });
    }

    public interface ILoginListener {
        void onResult(int code, String errorMsg, UserInfoEntity userInfo);
    }

    /**
     * pc登录确认
     *
     * @param auth_code 认证码
     * @param listener  返回
     */
    public void webLogin(String auth_code, final ICommonListener listener) {
        request(createAuthService(LoginService.class).webLoginConfirm(auth_code), new IRequestResultListener<CommonResponse>() {
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

    void getCountries(IChooseCountryCode iChooseCountryCode) {
        request(createAuthService(LoginService.class).getCountries(), new IRequestResultListener<List<CountryCodeEntity>>() {
            @Override
            public void onSuccess(List<CountryCodeEntity> result) {
                iChooseCountryCode.onResult(HttpResponseCode.success, "", result);
            }

            @Override
            public void onFail(int code, String msg) {
                iChooseCountryCode.onResult(code, msg, null);
            }
        });
    }

    public interface IChooseCountryCode {
        void onResult(int code, String msg, List<CountryCodeEntity> list);
    }


    void registerCode(String zone, String phone, final IGetVerCodeListener iGetVerfi) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("zone", zone);
        jsonObject.put("phone", phone);
        request(createAuthService(LoginService.class).registerCode(jsonObject), new IRequestResultListener<VerfiCodeResult>() {
            @Override
            public void onSuccess(VerfiCodeResult result) {
                iGetVerfi.onResult(HttpResponseCode.success, "", result.exist);
            }

            @Override
            public void onFail(int code, String msg) {
                iGetVerfi.onResult(code, msg, 0);
            }
        });
    }

    void isRegister(String zone, String account, int accountType, final IGetVerCodeListener listener) {
        JSONObject jsonObject = new JSONObject();
        // 参考utalk，使用account字段统一传账号（手机号/邮箱）
        jsonObject.put("account", account);
        if (accountType == 0) {
            jsonObject.put("zone", zone);
            jsonObject.put("phone", account);
        } else {
            jsonObject.put("email", account);
        }
        // 注册检测走认证服务（authUrl），与登录/注册同一服务，token 通用
        request(createAuthService(LoginService.class).isRegister(jsonObject), new IRequestResultListener<VerfiCodeResult>() {
            @Override
            public void onSuccess(VerfiCodeResult result) {
                int exist = result.exist;
                listener.onResult(HttpResponseCode.success, "", exist);
            }

            @Override
            public void onFail(int code, String msg) {
                // 接口失败时不默认"未注册"，返回错误提示
                listener.onResult(code, msg, -1);
            }
        });
    }

    void forgetPwd(String zone, String phone, final IGetVerCodeListener iGetVerCodeListener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("zone", zone);
        jsonObject.put("phone", phone);
        request(createAuthService(LoginService.class).forgetPwd(jsonObject), new IRequestResultListener<CommonResponse>() {
            @Override
            public void onSuccess(CommonResponse result) {
                iGetVerCodeListener.onResult(HttpResponseCode.success, "", 0);
            }

            @Override
            public void onFail(int code, String msg) {
                iGetVerCodeListener.onResult(code, msg, 0);
            }
        });
    }

    void resetPwd(String zone, String phone, String code, String pwd, final ICommonListener iCommonListener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("zone", zone);
        jsonObject.put("phone", phone);
        jsonObject.put("code", code);
        jsonObject.put("pwd", pwd);
        request(createAuthService(LoginService.class).pwdForget(jsonObject), new IRequestResultListener<CommonResponse>() {
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

    public interface IGetVerCodeListener {
        void onResult(int code, String msg, int exit);
    }

    void registerApp(String code, String zone, String name, String phone, String password,String inviteCode, final ILoginListener iLoginListener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("code", code);
        jsonObject.put("zone", zone);
        jsonObject.put("name", name);
        jsonObject.put("phone", phone);
        jsonObject.put("password", password);
        jsonObject.put("invite_code", inviteCode);
        JSONObject deviceJson = new JSONObject();
        deviceJson.put("device_id", WKConstants.getDeviceID());
        deviceJson.put("device_name", WKDeviceUtils.getInstance().getDeviceName());
        deviceJson.put("device_model", WKDeviceUtils.getInstance().getSystemModel());
        jsonObject.put("device", deviceJson);
        request(createAuthService(LoginService.class).register(jsonObject), new IRequestResultListener<UserInfoEntity>() {
            @Override
            public void onSuccess(UserInfoEntity userInfo) {
                if (userInfo != null) {
                    saveLoginInfo(userInfo);
                    iLoginListener.onResult(HttpResponseCode.success, "", userInfo);
                }
            }

            @Override
            public void onFail(int code, String msg) {
                iLoginListener.onResult(code, msg, null);
            }
        });
    }

    void emailRegisterCode(String email, final IGetVerCodeListener listener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("email", email);
        request(createAuthService(LoginService.class).emailRegisterCode(jsonObject), new IRequestResultListener<VerfiCodeResult>() {
            @Override
            public void onSuccess(VerfiCodeResult result) {
                listener.onResult(HttpResponseCode.success, "", result.exist);
            }

            @Override
            public void onFail(int code, String msg) {
                listener.onResult(code, msg, 0);
            }
        });
    }

    void emailRegisterApp(String code, String email, String password, String inviteCode, final ILoginListener iLoginListener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("code", code);
        jsonObject.put("email", email);
        jsonObject.put("password", password);
        jsonObject.put("invite_code", inviteCode);
        JSONObject deviceJson = new JSONObject();
        deviceJson.put("device_id", WKConstants.getDeviceID());
        deviceJson.put("device_name", WKDeviceUtils.getInstance().getDeviceName());
        deviceJson.put("device_model", WKDeviceUtils.getInstance().getSystemModel());
        jsonObject.put("device", deviceJson);
        request(createAuthService(LoginService.class).emailRegister(jsonObject), new IRequestResultListener<UserInfoEntity>() {
            @Override
            public void onSuccess(UserInfoEntity userInfo) {
                if (userInfo != null) {
                    saveLoginInfo(userInfo);
                    iLoginListener.onResult(HttpResponseCode.success, "", userInfo);
                }
            }

            @Override
            public void onFail(int code, String msg) {
                iLoginListener.onResult(code, msg, null);
            }
        });
    }

    void emailForgetPwd(String email, final IGetVerCodeListener listener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("email", email);
        request(createAuthService(LoginService.class).emailForgetPwd(jsonObject), new IRequestResultListener<CommonResponse>() {
            @Override
            public void onSuccess(CommonResponse result) {
                listener.onResult(HttpResponseCode.success, "", 0);
            }

            @Override
            public void onFail(int code, String msg) {
                listener.onResult(code, msg, 0);
            }
        });
    }

    void emailResetPwd(String email, String code, String pwd, final ICommonListener listener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("email", email);
        jsonObject.put("code", code);
        jsonObject.put("pwd", pwd);
        request(createAuthService(LoginService.class).emailPwdForget(jsonObject), new IRequestResultListener<CommonResponse>() {
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


    public void uploadAvatar(String filePath, final IUploadBack iUploadBack) {
        String url = WKApiConfig.authUrl + "user/avatar?uuid=" + WKTimeUtils.getInstance().getCurrentMills();
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

    public void updateUserInfo(String key, String value, final ICommonListener iCommonLisenter) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put(key, value);
        // 用户信息更新走认证服务（authUrl），与登录注册同一服务，token 通用
        request(createAuthService(LoginService.class).updateUserInfo(jsonObject), new IRequestResultListener<CommonResponse>() {
            @Override
            public void onSuccess(CommonResponse result) {
                iCommonLisenter.onResult(result.status, result.msg);
            }

            @Override
            public void onFail(int code, String msg) {
                iCommonLisenter.onResult(code, msg);
            }
        });
    }

    public void sendLoginAuthVerifCode(String uid, final ICommonListener iCommonListener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("uid", uid);
        request(createAuthService(LoginService.class).sendLoginAuthVerifCode(jsonObject), new IRequestResultListener<CommonResponse>() {
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
     * 设备锁安全校验-检查手机号是否正确
     *
     * @param uid            用户ID
     * @param code           验证码
     * @param iLoginListener 返回
     */
    void checkLoginAuth(String uid, String code, final ILoginListener iLoginListener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put("uid", uid);
        jsonObject.put("code", code);
        request(createAuthService(LoginService.class).checkLoginAuth(jsonObject), new IRequestResultListener<UserInfoEntity>() {
            @Override
            public void onSuccess(UserInfoEntity userInfo) {
                if (userInfo != null) {
                    saveLoginInfo(userInfo);
                    iLoginListener.onResult(HttpResponseCode.success, "", userInfo);
                }
            }

            @Override
            public void onFail(int code, String msg) {
                iLoginListener.onResult(code, msg, null);
            }
        });
    }

    public void quitPc(final ICommonListener iCommonListener) {
        request(createAuthService(LoginService.class).quitPc(), new IRequestResultListener<CommonResponse>() {
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


    public void updateUserSetting(String key, int value, final ICommonListener iCommonListener) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put(key, value);
        request(createAuthService(LoginService.class).setting(jsonObject), new IRequestResultListener<CommonResponse>() {
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

    public void getAuthCode(final IAuthCode iAuthCode) {
        request(createAuthService(LoginService.class).getAuthCode(), new IRequestResultListener<>() {
            @Override
            public void onSuccess(ThirdAuthCode result) {
                iAuthCode.onResult(HttpResponseCode.success, "", result.getAuthcode());
            }

            @Override
            public void onFail(int code, String msg) {
                iAuthCode.onResult(code, msg, "");
            }
        });
    }

    public interface IAuthCode {
        void onResult(int code, String msg, String authCode);
    }

    public void getAuthCodeStatus(String authCode, final ICommonListener iCommonListener) {
        request(createAuthService(LoginService.class).getAuthStatus(authCode), new IRequestResultListener<ThirdLoginResult>() {
            @Override
            public void onSuccess(ThirdLoginResult result) {
                if (result.getStatus() == 1 && result.getResult() != null) {
                    saveLoginInfo(result.getResult());
                    iCommonListener.onResult(HttpResponseCode.success, "");
                }
            }

            @Override
            public void onFail(int code, String msg) {
                iCommonListener.onResult(code, msg);
            }
        });
    }

    private void saveLoginInfo(UserInfoEntity userInfo) {
        WKConfig.getInstance().saveUserInfo(userInfo);
        WKConfig.getInstance().setToken(userInfo.token);
        if (!TextUtils.isEmpty(userInfo.im_token)) {
            WKConfig.getInstance().setImToken(userInfo.im_token);
        } else WKConfig.getInstance().setImToken(userInfo.token);
        WKConfig.getInstance().setUid(userInfo.uid);
        WKConfig.getInstance().setUserName(userInfo.name);
        if (!TextUtils.isEmpty(userInfo.short_no)) {
            WKConfig.getInstance().setShortNo(userInfo.short_no);
        }
        // 如果用户信息中包含手机号，同步保存到绑定状态
        if (!TextUtils.isEmpty(userInfo.phone)) {
            String boundPhone = WKSharedPreferencesUtil.getInstance().getSP("bind_phone");
            if (TextUtils.isEmpty(boundPhone)) {
                WKSharedPreferencesUtil.getInstance().putSP("bind_phone", userInfo.phone);
            }
        }
    }
}
