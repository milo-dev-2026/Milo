package com.chat.base.net.ud;


import com.chat.base.net.entity.CosPresignResultEntity;
import com.chat.base.net.entity.PresignResultEntity;
import com.chat.base.net.entity.UploadResultEntity;

import io.reactivex.rxjava3.core.Observable;
import okhttp3.MultipartBody;
import okhttp3.RequestBody;
import okhttp3.ResponseBody;
import retrofit2.http.Body;
import retrofit2.http.GET;
import retrofit2.http.Multipart;
import retrofit2.http.POST;
import retrofit2.http.PUT;
import retrofit2.http.Part;
import retrofit2.http.Url;

public interface UploadService {
    @Multipart
    @POST
    Observable<UploadResultEntity> upload(@Url String url, @Part MultipartBody.Part file);

    @GET
    Observable<PresignResultEntity> presign(@Url String url);

    @PUT
    Observable<ResponseBody> putUpload(@Url String url, @Body RequestBody body);

    @POST("file/cos-presign")
    Observable<CosPresignResultEntity> cosBatchPresign(@Body CosPresignRequest request);

    class CosPresignRequest {
        public java.util.List<String> paths;
        public String type;

        public CosPresignRequest(java.util.List<String> paths, String type) {
            this.paths = paths;
            this.type = type;
        }
    }
}
