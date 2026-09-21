package com.chat.uikit.search.service;

import com.chat.uikit.search.SearchUserEntity;

import io.reactivex.rxjava3.core.Observable;
import retrofit2.http.GET;
import retrofit2.http.Query;

public interface SearchService {
    @GET("user/search")
    Observable<SearchUserEntity> searchUser(@Query("keyword") String keyword);
}
