package com.chat.base.net;

import android.os.Build;
import android.text.TextUtils;

import com.chat.base.WKBaseApplication;
import com.chat.base.config.WKConfig;
import com.chat.base.net.sign.SignatureUtils;

import org.jetbrains.annotations.NotNull;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import okhttp3.Interceptor;
import okhttp3.MediaType;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import okio.Buffer;

/**
 * 公共请求参数拦截器
 * 包含签名验证（x-signature）
 */
public class CommonRequestParamInterceptor implements Interceptor {

    @NotNull
    @Override
    public Response intercept(Chain chain) throws IOException {
        Request request = chain.request();
        // 对multipart/form-data文件上传跳过body读取，避免将整个文件读入内存
        boolean isMultipart = false;
        if (request.body() != null && request.body().contentType() != null) {
            String ct = request.body().contentType().toString().toLowerCase();
            isMultipart = ct.contains("multipart");
        }
        String bodyStr = isMultipart ? "" : readRequestBody(request);

        Request.Builder builder = request.newBuilder();

        // 如果有请求体且是可读取的类型，重新写入请求体（确保一致性）
        if (!TextUtils.isEmpty(bodyStr) && isReadableContentType(request.body())) {
            MediaType mediaType = null;
            if (request.body() != null) {
                mediaType = request.body().contentType();
            }
            builder.method(request.method(), RequestBody.create(mediaType, bodyStr));
            request = builder.build();
            builder = request.newBuilder();
        }

        Map<String, String> commonParams = getCommonParams(request, bodyStr);
        for (Map.Entry<String, String> entry : commonParams.entrySet()) {
            if (!TextUtils.isEmpty(entry.getValue())) {
                builder.addHeader(entry.getKey(), entry.getValue());
            }
        }
        request = builder.build();
        return chain.proceed(request);
    }

    private Map<String, String> getCommonParams(Request request, String bodyStr) {
        Map<String, String> params = new HashMap<>();
        String token = WKConfig.getInstance().getToken();
        String nonce = UUID.randomUUID().toString();
        String timestamp = String.valueOf(System.currentTimeMillis());

        params.put("token", token);
        params.put("model", Build.MODEL);
        params.put("os", "Android");
        params.put("appid", WKBaseApplication.getInstance().appID);
        params.put("version", WKBaseApplication.getInstance().versionName);
        params.put("brand-app-id", WKBaseApplication.getInstance().appID);
        params.put("package", WKBaseApplication.getInstance().httpPackageName);
        params.put("x-package", WKBaseApplication.getInstance().httpPackageName);
        params.put("x-app-version", WKBaseApplication.getInstance().versionName);
        params.put("x-api-key", "1");
        params.put("x-device", Build.DEVICE);
        params.put("x-timestamp", timestamp);
        params.put("x-nonce", nonce);
        params.put("x-signature", generateSignature(request, timestamp, nonce, token, bodyStr));

        return params;
    }

    /**
     * 生成x-signature签名
     * POST: bodyJson + "&" + timestamp + "&" + nonce (+ "&" + token if not empty)
     * GET: queryString + "&" + timestamp + "&" + nonce (+ "&" + token if not empty)
     */
    private String generateSignature(Request request, String timestamp, String nonce, String token, String bodyStr) {
        String signStr;
        if ("GET".equals(request.method())) {
            String url = request.url().toString();
            int queryIndex = url.indexOf('?');
            if (queryIndex != -1 && queryIndex < url.length() - 1) {
                String query = url.substring(queryIndex + 1);
                if (query.isEmpty()) {
                    signStr = timestamp + "&" + nonce;
                } else {
                    signStr = query + "&" + timestamp + "&" + nonce;
                }
            } else {
                signStr = timestamp + "&" + nonce;
            }
        } else {
            String contentType = request.header("Content-Type");
            if (bodyStr == null) bodyStr = "";
            // 修复：使用 contains 而不是 equals，因为 content-type 可能包含 charset（如 "application/json; charset=utf-8"）
            boolean isJsonType = contentType == null || contentType.toLowerCase().contains("application/json");
            if (isJsonType && !bodyStr.isEmpty()) {
                signStr = bodyStr + "&" + timestamp + "&" + nonce;
            } else {
                signStr = "{}&" + timestamp + "&" + nonce;
            }
        }
        if (!TextUtils.isEmpty(token)) {
            signStr = signStr + "&" + token;
        }
        return SignatureUtils.getInstance().sign(signStr);
    }

    private String readRequestBody(Request request) {
        if (request.body() == null) {
            return "";
        }
        try {
            RequestBody body = request.body();
            if (body == null) return "";
            Buffer buffer = new Buffer();
            body.writeTo(buffer);
            return buffer.readUtf8();
        } catch (Exception e) {
            return "";
        }
    }

    private boolean isReadableContentType(RequestBody requestBody) {
        if (requestBody == null) {
            return false;
        }
        MediaType contentType = requestBody.contentType();
        if (contentType == null) {
            return true;
        }
        String lowerCase = contentType.toString().toLowerCase();
        return lowerCase.contains("application/json")
                || lowerCase.contains("text/plain")
                || lowerCase.contains("x-www-form-urlencoded");
    }
}
