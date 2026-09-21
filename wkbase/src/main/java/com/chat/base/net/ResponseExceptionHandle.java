package com.chat.base.net;

import android.text.TextUtils;
import android.util.Log;

import com.chat.base.utils.WKLogUtils;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.Objects;

import retrofit2.HttpException;

/**
 * 2020-07-20 14:23
 * 请求异常处理
 */
public class ResponseExceptionHandle {
    private ResponseExceptionHandle() {
    }

    private static class ResponseExceptionHandleBinder {
        final static ResponseExceptionHandle response = new ResponseExceptionHandle();
    }

    public static ResponseExceptionHandle getInstance() {
        return ResponseExceptionHandleBinder.response;
    }

    public ResponseThrowable handleException(Throwable e) {
        ResponseThrowable responeThrowable = null;
        if (e instanceof HttpException) {
            HttpException httpException = (HttpException) e;

            responeThrowable = new ResponseThrowable(e, httpException.code());
            switch (httpException.code()) {
                case 400:
                    try {
                        String errorStr = Objects.requireNonNull(Objects.requireNonNull(httpException.response()).errorBody()).string();
                        if (!TextUtils.isEmpty(errorStr)) {
                            try {
                                Log.e("错误信息：", errorStr);
                                JSONObject jsonObject = new JSONObject(errorStr);
                                int status = jsonObject.optInt("status");
                                String msg = jsonObject.optString("msg");
                                responeThrowable.setMessage(msg);
                                responeThrowable.setErrJson(errorStr);
                                responeThrowable.setStatus(status);
                                Log.e("请求错误：", status + "|" + msg);
                            } catch (JSONException ex) {
                                WKLogUtils.e("解析请求【400】不是json结构");
                            }
                        } else {
                            responeThrowable.setMessage("");
                            responeThrowable.setStatus(400);
                        }
                    } catch (IOException ex) {
                        WKLogUtils.e("解析请求【400】结果错误");
                    }
                    break;
                case 401:
                    try {
                        String errorStr = Objects.requireNonNull(Objects.requireNonNull(httpException.response()).errorBody()).string();
                        Log.e("401错误详情：", errorStr);
                        if (!TextUtils.isEmpty(errorStr)) {
                            try {
                                JSONObject jsonObject = new JSONObject(errorStr);
                                String msg = jsonObject.optString("msg");
                                if (!TextUtils.isEmpty(msg)) {
                                    responeThrowable.setMessage(msg);
                                } else {
                                    responeThrowable.setMessage("认证失败");
                                }
                                responeThrowable.setErrJson(errorStr);
                            } catch (JSONException ex) {
                                responeThrowable.setMessage("认证失败");
                            }
                        } else {
                            responeThrowable.setMessage("认证失败");
                        }
                    } catch (IOException ex) {
                        responeThrowable.setMessage("认证失败");
                    }
                    break;
                case 404:
                    responeThrowable.setMessage("请求地址不存在");
                    break;
                case 429:
                    try {
                        String errorStr = Objects.requireNonNull(Objects.requireNonNull(httpException.response()).errorBody()).string();
                        if (!TextUtils.isEmpty(errorStr)) {
                            try {
                                Log.e("错误信息：", errorStr);
                                JSONObject jsonObject = new JSONObject(errorStr);
                                String msg = jsonObject.optString("msg");
                                if (!TextUtils.isEmpty(msg)) {
                                    responeThrowable.setMessage(msg);
                                } else {
                                    responeThrowable.setMessage("请求过于频繁，请稍后再试");
                                }
                                responeThrowable.setErrJson(errorStr);
                                Log.e("请求错误429：", msg);
                            } catch (JSONException ex) {
                                responeThrowable.setMessage("请求过于频繁，请稍后再试");
                                WKLogUtils.e("解析请求【429】不是json结构");
                            }
                        } else {
                            responeThrowable.setMessage("请求过于频繁，请稍后再试");
                        }
                    } catch (IOException ex) {
                        responeThrowable.setMessage("请求过于频繁，请稍后再试");
                        WKLogUtils.e("解析请求【429】结果错误");
                    }
                    break;
                case 504:
                    responeThrowable.setMessage("网络连接失败");
                    break;
                default:
                    try {
                        String errorStr = Objects.requireNonNull(Objects.requireNonNull(httpException.response()).errorBody()).string();
                        if (!TextUtils.isEmpty(errorStr)) {
                            try {
                                JSONObject jsonObject = new JSONObject(errorStr);
                                String msg = jsonObject.optString("msg");
                                if (!TextUtils.isEmpty(msg)) {
                                    responeThrowable.setMessage(msg);
                                } else {
                                    responeThrowable.setMessage("请求失败，请稍后重试");
                                }
                                responeThrowable.setErrJson(errorStr);
                            } catch (JSONException ex) {
                                responeThrowable.setMessage("请求失败，请稍后重试");
                            }
                        } else {
                            responeThrowable.setMessage("请求失败，请稍后重试");
                        }
                    } catch (IOException ex) {
                        responeThrowable.setMessage("请求失败，请稍后重试");
                    }
                    break;
            }
        } else if (e instanceof RuntimeException) {
            Log.e("服务器运行时错误：", e.getMessage());
            // 修复：RuntimeException 也需要创建 ResponseThrowable，否则 onFail 不会被调用，导致 loading 一直显示
            responeThrowable = new ResponseThrowable(e, HttpResponseCode.error);
            String errMsg = e.getMessage();
            if (TextUtils.isEmpty(errMsg)) {
                errMsg = "请求失败，请稍后重试";
            }
            responeThrowable.setMessage(errMsg);
        } else {
            // 其他未知异常也创建 ResponseThrowable，确保 onFail 总是被调用
            responeThrowable = new ResponseThrowable(e, HttpResponseCode.error);
            String errMsg = e.getMessage();
            if (TextUtils.isEmpty(errMsg)) {
                errMsg = "请求失败，请稍后重试";
            }
            responeThrowable.setMessage(errMsg);
        }
        return responeThrowable;
    }
}
