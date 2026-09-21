package com.chat.base.endpoint.entity;

import android.app.Activity;

public class CallingViewMenu {
    public Activity activity;
    public Object callInfo;

    public CallingViewMenu(Activity activity, Object callInfo) {
        this.activity = activity;
        this.callInfo = callInfo;
    }
}
