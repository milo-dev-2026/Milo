package com.chat.base.net.ud;


import com.chat.base.base.WKBaseModel;
import com.chat.base.config.WKApiConfig;
import com.chat.base.net.CommonRequestParamInterceptor;
import com.chat.base.net.IRequestResultListener;
import com.chat.base.net.entity.CosPresignResultEntity;
import com.chat.base.net.entity.PresignResultEntity;
import com.chat.base.net.entity.UploadResultEntity;
import com.chat.base.utils.WKLogUtils;
import com.chat.base.utils.WKTimeUtils;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import io.reactivex.rxjava3.android.schedulers.AndroidSchedulers;
import io.reactivex.rxjava3.core.Observable;
import io.reactivex.rxjava3.disposables.Disposable;
import io.reactivex.rxjava3.schedulers.Schedulers;
import okhttp3.ConnectionPool;
import okhttp3.Dispatcher;
import okhttp3.MediaType;
import okhttp3.MultipartBody;
import okhttp3.OkHttpClient;
import okhttp3.RequestBody;
import okhttp3.ResponseBody;
import retrofit2.Retrofit;
import retrofit2.adapter.rxjava3.RxJava3CallAdapterFactory;

public class WKUploader extends WKBaseModel {
    private WKUploader() {
    }

    private static class UploadBinder {
        final static WKUploader upload = new WKUploader();
    }

    public static WKUploader getInstance() {
        return UploadBinder.upload;
    }

    private OkHttpClient uploadClient;
    private OkHttpClient directUploadClient; // 纯净客户端，用于MinIO直传（无拦截器避免干扰签名）
    private Retrofit uploadRetrofit;
    private ConnectionPool sharedConnectionPool;

    private Retrofit getUploadRetrofit() {
        if (uploadRetrofit == null) {
            synchronized (WKUploader.class) {
                if (sharedConnectionPool == null) {
                    sharedConnectionPool = new ConnectionPool(30, 5, TimeUnit.MINUTES);
                }
                Dispatcher sharedDispatcher = new Dispatcher();
                sharedDispatcher.setMaxRequests(20);
                sharedDispatcher.setMaxRequestsPerHost(10);
                if (uploadClient == null) {
                    uploadClient = new OkHttpClient.Builder()
                            .connectTimeout(10, TimeUnit.SECONDS)
                            .readTimeout(60, TimeUnit.SECONDS)
                            .writeTimeout(120, TimeUnit.SECONDS)
                            .retryOnConnectionFailure(true)
                            .connectionPool(sharedConnectionPool)
                            .dispatcher(sharedDispatcher)
                            .addInterceptor(new CommonRequestParamInterceptor())
                            .build();
                }
                if (directUploadClient == null) {
                    directUploadClient = new OkHttpClient.Builder()
                            .connectTimeout(10, TimeUnit.SECONDS)
                            .readTimeout(60, TimeUnit.SECONDS)
                            .writeTimeout(120, TimeUnit.SECONDS)
                            .retryOnConnectionFailure(true)
                            .connectionPool(sharedConnectionPool)
                            .dispatcher(sharedDispatcher)
                            .build();
                }
                uploadRetrofit = new Retrofit.Builder()
                        .baseUrl(WKApiConfig.baseUrl)
                        .client(uploadClient)
                        .addConverterFactory(com.chat.base.net.FastJsonConverterFactory.Companion.create())
                        .addCallAdapterFactory(RxJava3CallAdapterFactory.create())
                        .build();
            }
        }
        return uploadRetrofit;
    }

    private <T> T createUploadService(Class<T> service) {
        return getUploadRetrofit().create(service);
    }

    /**
     * 直接上传文件（内部拼接上传路径，减少一层回调）
     */
    public void upload(String channelID, byte channelType, String filePath, Object tag, final IUploadBack iUploadBack) {
        try {
            if (filePath == null || filePath.isEmpty()) {
                if (iUploadBack != null) iUploadBack.onError();
                return;
            }
            File file = new File(filePath);
            if (!file.exists() || !file.isFile() || file.length() <= 0) {
                if (iUploadBack != null) iUploadBack.onError();
                return;
            }
            String tempFileName = file.getName();
            String prefix = tempFileName.substring(tempFileName.lastIndexOf(".") + 1);
            String random = UUID.randomUUID().toString().replace("-", "").substring(0, 8);
            String path = "/" + channelType + "/" + channelID + "/" + WKTimeUtils.getInstance().getCurrentMills() + "_" + random + "." + prefix;
            String uploadUrl = WKApiConfig.baseUrl + "file/upload?type=chat&path=" + path;

            MediaType mediaType = MediaType.Companion.parse("application/octet-stream");
            RequestBody fileBody = RequestBody.Companion.create(file, mediaType);
            FileRequestBody fileRequestBody = new FileRequestBody(fileBody, tag);
            MultipartBody.Part part = MultipartBody.Part.createFormData("file", file.getName(), fileRequestBody);
            request(createUploadService(UploadService.class).upload(uploadUrl, part), new IRequestResultListener<>() {
                @Override
                public void onSuccess(UploadResultEntity result) {
                    if (iUploadBack != null) {
                        iUploadBack.onSuccess(result.path);
                    }
                }

                @Override
                public void onFail(int code, String msg) {
                    WKLogUtils.e("WKUploader", "upload fail code=" + code + " msg=" + msg);
                    if (iUploadBack != null) {
                        iUploadBack.onError();
                    }
                }
            });
        } catch (Exception e) {
            WKLogUtils.e("WKUploader", "upload exception: " + e.getMessage());
            if (iUploadBack != null) {
                iUploadBack.onError();
            }
        }
    }

    public void upload(String uploadUrl, String filePath, final IUploadBack iUploadBack) {
        upload(uploadUrl, filePath, filePath, iUploadBack);
    }

    public void upload(String uploadUrl, String filePath, Object tag, final IUploadBack iUploadBack) {
        try {
            if (filePath == null || filePath.isEmpty()) {
                WKLogUtils.e("WKUploader", "filePath is empty");
                if (iUploadBack != null) {
                    iUploadBack.onError();
                }
                return;
            }
            File file = new File(filePath);
            if (!file.exists() || !file.isFile() || file.length() <= 0) {
                WKLogUtils.e("WKUploader", "file not exists or invalid: " + filePath);
                if (iUploadBack != null) {
                    iUploadBack.onError();
                }
                return;
            }
            MediaType mediaType = MediaType.Companion.parse("application/octet-stream");
            RequestBody fileBody = RequestBody.Companion.create(file, mediaType);
            FileRequestBody fileRequestBody = new FileRequestBody(fileBody, tag);
            MultipartBody.Part part = MultipartBody.Part.createFormData("file", file.getName(), fileRequestBody);
            request(createUploadService(UploadService.class).upload(uploadUrl, part), new IRequestResultListener<>() {
                @Override
                public void onSuccess(UploadResultEntity result) {
                    if (iUploadBack != null) {
                        iUploadBack.onSuccess(result.path);
                    }
                }

                @Override
                public void onFail(int code, String msg) {
                    WKLogUtils.e("WKUploader", "upload fail code=" + code + " msg=" + msg);
                    if (iUploadBack != null) {
                        iUploadBack.onError();
                    }
                }
            });
        } catch (Exception e) {
            WKLogUtils.e("WKUploader", "upload exception: " + e.getMessage());
            e.printStackTrace();
            if (iUploadBack != null) {
                iUploadBack.onError();
            }
        }
    }

    /**
     * 构造服务端中转上传地址。
     * <p>
     * 当前部署为「服务端中转」模式：客户端把文件 multipart POST 到业务服务
     * /v1/file/upload，服务端再写入 MinIO，返回形如
     * file/preview/chat/{channelType}/{channelID}/{ts}.jpg 的存储相对路径。
     * 因此无需先 GET 上传凭证，直接拼接上传地址即可，省一次网络往返。
     */
    public void getUploadFileUrl(String channelID, byte channelType, String localPath, final IGetUploadFileUrl iGetUploadFileUrl) {
        File f = new File(localPath);
        String tempFileName = f.getName();
        String prefix = tempFileName.substring(tempFileName.lastIndexOf(".") + 1);
        // 加入UUID随机后缀，防止并发上传时路径冲突导致文件覆盖
        String random = UUID.randomUUID().toString().replace("-", "").substring(0, 8);
        String path = "/" + channelType + "/" + channelID + "/" + WKTimeUtils.getInstance().getCurrentMills() + "_" + random + "." + prefix;
        String uploadUrl = WKApiConfig.baseUrl + "file/upload?type=chat&path=" + path;
        iGetUploadFileUrl.onResult(uploadUrl, path);
    }


    public interface IGetUploadFileUrl {
        void onResult(String url, String fileUrl);
    }

    public interface IUploadBack {
        void onSuccess(String url);

        void onError();
    }

    // ==================== MinIO 预签名直传 ====================

    /**
     * MinIO 预签名直传：先从后端获取预签名PUT URL，再直接上传到MinIO，绕过应用服务器
     * 速度比 multipart 中转快 30%~50%
     * 失败时自动回退到原 multipart 上传方式
     *
     * @param channelID   频道ID
     * @param channelType 频道类型
     * @param localPath   本地文件路径
     * @param tag         进度回调标记
     * @param iUploadBack 上传回调
     */
    public void uploadPresign(String channelID, byte channelType, String localPath, Object tag, final IUploadBack iUploadBack) {
        if (localPath == null || localPath.isEmpty()) {
            WKLogUtils.e("WKUploader", "uploadPresign: filePath is empty");
            if (iUploadBack != null) iUploadBack.onError();
            return;
        }
        File file = new File(localPath);
        if (!file.exists() || !file.isFile() || file.length() <= 0) {
            WKLogUtils.e("WKUploader", "uploadPresign: file not exists");
            if (iUploadBack != null) iUploadBack.onError();
            return;
        }

        // 构造文件路径
        String fileName = file.getName();
        String ext = fileName.substring(fileName.lastIndexOf(".") + 1);
        String random = UUID.randomUUID().toString().replace("-", "").substring(0, 8);
        String path = "/" + channelType + "/" + channelID + "/" + WKTimeUtils.getInstance().getCurrentMills() + "_" + random + "." + ext;

        // 1. 请求预签名 URL
        String presignUrl = WKApiConfig.baseUrl + "file/presign?type=chat&path=" + path;
        WKLogUtils.d("WKUploader", "uploadPresign: get presign url: " + presignUrl);

        Disposable disposable = createUploadService(UploadService.class).presign(presignUrl)
                .subscribeOn(Schedulers.io())
                .observeOn(Schedulers.io())
                .subscribe(presignResult -> {
                    if (presignResult == null || presignResult.upload_url == null || presignResult.upload_url.isEmpty()) {
                        WKLogUtils.w("WKUploader", "uploadPresign: empty upload_url, fallback to multipart");
                        uploadFallback(channelID, channelType, localPath, tag, iUploadBack);
                        return;
                    }
                    // 2. 用 PUT 方式直传 MinIO
                    doPutUpload(presignResult, localPath, tag, iUploadBack);
                }, throwable -> {
                    WKLogUtils.w("WKUploader", "uploadPresign: get presign failed, fallback: " + throwable.getMessage());
                    uploadFallback(channelID, channelType, localPath, tag, iUploadBack);
                });
    }

    /**
     * PUT 直传文件到 MinIO
     */
    private void doPutUpload(PresignResultEntity presignResult, String localPath, Object tag, final IUploadBack iUploadBack) {
        try {
            File file = new File(localPath);
            MediaType mediaType = MediaType.parse("application/octet-stream");
            RequestBody fileBody = RequestBody.create(file, mediaType);
            FileRequestBody progressBody = new FileRequestBody(fileBody, tag);

            // 注意：预签名 URL 是完整的 MinIO 地址，不走我们的 API 域名
            // 用 directUploadClient（纯净，无拦截器），避免额外header干扰MinIO签名
            okhttp3.Request request = new okhttp3.Request.Builder()
                    .url(presignResult.upload_url)
                    .put(progressBody)
                    .build();

            directUploadClient.newCall(request).enqueue(new okhttp3.Callback() {
                @Override
                public void onFailure(okhttp3.Call call, java.io.IOException e) {
                    WKLogUtils.e("WKUploader", "putUpload failed: " + e.getMessage());
                    if (iUploadBack != null) {
                        android.os.Handler mainHandler = new android.os.Handler(android.os.Looper.getMainLooper());
                        mainHandler.post(iUploadBack::onError);
                    }
                }

                @Override
                public void onResponse(okhttp3.Call call, okhttp3.Response response) throws java.io.IOException {
                    boolean success = response.isSuccessful();
                    String bodyStr = "";
                    if (response.body() != null) {
                        try { bodyStr = response.body().string(); } catch (Exception ignored) {}
                    }
                    WKLogUtils.d("WKUploader", "putUpload code=" + response.code() + " success=" + success);

                    if (success && iUploadBack != null) {
                        // 返回与现有格式兼容的 path
                        String resultPath = presignResult.path != null ? presignResult.path : presignResult.url;
                        android.os.Handler mainHandler = new android.os.Handler(android.os.Looper.getMainLooper());
                        mainHandler.post(() -> iUploadBack.onSuccess(resultPath));
                    } else if (iUploadBack != null) {
                        android.os.Handler mainHandler = new android.os.Handler(android.os.Looper.getMainLooper());
                        mainHandler.post(iUploadBack::onError);
                    }
                }
            });
        } catch (Exception e) {
            WKLogUtils.e("WKUploader", "doPutUpload exception: " + e.getMessage());
            if (iUploadBack != null) iUploadBack.onError();
        }
    }

    /**
     * 回退到原 multipart 上传方式
     */
    private void uploadFallback(String channelID, byte channelType, String localPath, Object tag, IUploadBack iUploadBack) {
        getUploadFileUrl(channelID, channelType, localPath, (uploadUrl, fileUrl) ->
                upload(uploadUrl, localPath, tag, iUploadBack));
    }

    // ==================== 腾讯云COS批量直传 ====================

    /**
     * COS批量直传：将多个文件（m3u8 + ts分片 + 封面）直接上传到COS，绕过应用服务器。
     * <p>
     * 流程：
     * 1. 向后端请求所有文件的预签名PUT URL（一次请求）
     * 2. 并行PUT上传所有文件到COS
     * 3. 全部成功后回调
     *
     * @param channelID    频道ID
     * @param channelType  频道类型
     * @param files         要上传的文件列表（m3u8, ts分片, 封面等）
     * @param basePath      COS存储基础路径（如 video/{channelType}/{channelID}/{timestamp}/）
     * @param tag           进度回调标记
     * @param callback      上传回调
     */
    public void uploadCosBatch(String channelID, byte channelType,
                                List<File> files, String basePath,
                                Object tag, CosBatchUploadCallback callback) {
        if (files == null || files.isEmpty()) {
            if (callback != null) callback.onError(new RuntimeException("No files to upload"));
            return;
        }

        // 构造COS存储路径列表
        List<String> cosPaths = new ArrayList<>();
        for (File f : files) {
            cosPaths.add(basePath + f.getName());
        }

        WKLogUtils.d("WKUploader", "uploadCosBatch: " + files.size() + " files, basePath=" + basePath);

        // 1. 请求批量预签名URL
        Disposable disposable = createUploadService(UploadService.class)
                .cosBatchPresign(new UploadService.CosPresignRequest(cosPaths, "chat"))
                .subscribeOn(Schedulers.io())
                .observeOn(Schedulers.io())
                .subscribe(presignResult -> {
                    if (presignResult == null || presignResult.urls == null || presignResult.urls.isEmpty()) {
                        WKLogUtils.e("WKUploader", "uploadCosBatch: empty presign response");
                        if (callback != null) callback.onError(new RuntimeException("Empty presign response"));
                        return;
                    }

                    // 2. 并行PUT上传所有文件
                    doCosBatchPutUpload(presignResult, files, cosPaths, tag, callback);
                }, throwable -> {
                    WKLogUtils.e("WKUploader", "uploadCosBatch: presign failed: " + throwable.getMessage());
                    if (callback != null) callback.onError(throwable);
                });
    }

    /**
     * 并行PUT上传所有文件到COS
     */
    private void doCosBatchPutUpload(CosPresignResultEntity presignResult,
                                      List<File> files, List<String> cosPaths,
                                      Object tag, CosBatchUploadCallback callback) {
        int total = files.size();
        AtomicInteger successCount = new AtomicInteger(0);
        AtomicInteger failCount = new AtomicInteger(0);
        CountDownLatch latch = new CountDownLatch(total);
        String cdnDomain = presignResult.cdn_domain;
        List<String> failedPaths = new ArrayList<>();

        for (int i = 0; i < total; i++) {
            File file = files.get(i);
            String cosPath = cosPaths.get(i);
            String presignedUrl = presignResult.urls.get(cosPath);

            if (presignedUrl == null || presignedUrl.isEmpty()) {
                WKLogUtils.e("WKUploader", "uploadCosBatch: no presign URL for " + cosPath);
                failCount.incrementAndGet();
                latch.countDown();
                continue;
            }

            final String currentPath = cosPath;

            try {
                MediaType mediaType = MediaType.parse("application/octet-stream");
                RequestBody fileBody = RequestBody.create(file, mediaType);
                FileRequestBody progressBody = new FileRequestBody(fileBody, tag);

                okhttp3.Request request = new okhttp3.Request.Builder()
                        .url(presignedUrl)
                        .put(progressBody)
                        .build();

                directUploadClient.newCall(request).enqueue(new okhttp3.Callback() {
                    @Override
                    public void onFailure(okhttp3.Call call, java.io.IOException e) {
                        WKLogUtils.e("WKUploader", "COS PUT failed: " + currentPath + " - " + e.getMessage());
                        synchronized (failedPaths) {
                            failedPaths.add(currentPath);
                        }
                        failCount.incrementAndGet();
                        latch.countDown();
                    }

                    @Override
                    public void onResponse(okhttp3.Call call, okhttp3.Response response) throws java.io.IOException {
                        boolean success = response.isSuccessful();
                        if (response.body() != null) {
                            try { response.body().close(); } catch (Exception ignored) {}
                        }
                        WKLogUtils.d("WKUploader", "COS PUT " + currentPath + " code=" + response.code() + " success=" + success);

                        if (success) {
                            successCount.incrementAndGet();
                        } else {
                            synchronized (failedPaths) {
                                failedPaths.add(currentPath);
                            }
                            failCount.incrementAndGet();
                        }
                        latch.countDown();
                    }
                });
            } catch (Exception e) {
                WKLogUtils.e("WKUploader", "COS PUT exception: " + cosPath + " - " + e.getMessage());
                synchronized (failedPaths) {
                    failedPaths.add(currentPath);
                }
                failCount.incrementAndGet();
                latch.countDown();
            }
        }

        // 等待所有上传完成
        try {
            latch.await(120, TimeUnit.SECONDS); // 最多等2分钟
        } catch (InterruptedException e) {
            WKLogUtils.e("WKUploader", "uploadCosBatch: latch interrupted");
        }

        int succeeded = successCount.get();
        int failed = failCount.get();
        WKLogUtils.d("WKUploader", "uploadCosBatch done: success=" + succeeded + " failed=" + failed + "/" + total);

        android.os.Handler mainHandler = new android.os.Handler(android.os.Looper.getMainLooper());

        if (failed == 0) {
            // 全部成功，构造访问URL
            String m3u8Path = null;
            for (String p : cosPaths) {
                if (p.endsWith(".m3u8")) {
                    m3u8Path = p;
                    break;
                }
            }
            String accessUrl;
            if (cosPaths.isEmpty()) {
                mainHandler.post(() -> callback.onError(new RuntimeException("No files uploaded")));
                return;
            }
            if (cdnDomain != null && !cdnDomain.isEmpty()) {
                accessUrl = cdnDomain + "/chat/" + (m3u8Path != null ? m3u8Path : cosPaths.get(0));
            } else {
                accessUrl = "file/preview/chat/" + (m3u8Path != null ? m3u8Path : cosPaths.get(0));
            }
            mainHandler.post(() -> callback.onSuccess(accessUrl, cosPaths));
        } else {
            mainHandler.post(() -> callback.onError(new RuntimeException(failed + "/" + total + " files failed")));
        }
    }

    /**
     * COS批量上传回调
     */
    public interface CosBatchUploadCallback {
        /**
         * 全部文件上传成功
         * @param accessUrl m3u8文件的访问URL
         * @param cosPaths  所有已上传的COS路径列表
         */
        void onSuccess(String accessUrl, List<String> cosPaths);

        void onError(Throwable e);
    }
}
