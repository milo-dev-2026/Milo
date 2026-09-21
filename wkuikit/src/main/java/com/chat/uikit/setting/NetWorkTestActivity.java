package com.chat.uikit.setting;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.AsyncTask;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKApiConfig;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityNetworkTestBinding;

import java.net.InetAddress;
import java.net.Socket;

public class NetWorkTestActivity extends WKBaseActivity<ActivityNetworkTestBinding> {

    private boolean isTesting = false;

    @Override
    protected ActivityNetworkTestBinding getViewBinding() {
        return ActivityNetworkTestBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.network_diagnosis);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        updateNetworkStatus();
    }

    private void updateNetworkStatus() {
        ConnectivityManager cm = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
        if (cm != null) {
            NetworkInfo activeNetwork = cm.getActiveNetworkInfo();
            if (activeNetwork != null && activeNetwork.isConnectedOrConnecting()) {
                wkVBinding.networkStatusTv.setText(R.string.network_connected);
                int type = activeNetwork.getType();
                if (type == ConnectivityManager.TYPE_WIFI) {
                    wkVBinding.networkTypeTv.setText(getString(R.string.network_type_wifi));
                } else if (type == ConnectivityManager.TYPE_MOBILE) {
                    wkVBinding.networkTypeTv.setText(getString(R.string.network_type_mobile));
                } else {
                    wkVBinding.networkTypeTv.setText(getString(R.string.network_type_other));
                }
            } else {
                wkVBinding.networkStatusTv.setText(R.string.network_disconnected);
                wkVBinding.networkTypeTv.setText(getString(R.string.network_type_none));
            }
        } else {
            wkVBinding.networkStatusTv.setText(R.string.network_disconnected);
            wkVBinding.networkTypeTv.setText(getString(R.string.network_type_none));
        }
    }

    @Override
    protected void initListener() {
        SingleClickUtil.onSingleClick(wkVBinding.startTestBtn, v -> {
            if (isTesting) return;
            startNetworkTest();
        });
    }

    private void startNetworkTest() {
        isTesting = true;
        wkVBinding.testProgressPb.setVisibility(android.view.View.VISIBLE);
        wkVBinding.dnsResultTv.setText(R.string.testing);
        wkVBinding.tcpResultTv.setText("");
        wkVBinding.wsResultTv.setText("");
        wkVBinding.latencyResultTv.setText("");

        AsyncTask.execute(() -> {
            final long[] dnsTime = {0};
            final long[] tcpTime = {0};
            final long[] wsTime = {0};
            final boolean[] dnsOk = {false};
            final boolean[] tcpOk = {false};
            final boolean[] wsOk = {false};

            try {
                long start = System.currentTimeMillis();
                String host = "www.baidu.com";
                String apiHost = WKApiConfig.baseUrl;
                if (apiHost != null && !apiHost.isEmpty()) {
                    try {
                        java.net.URL url = new java.net.URL(apiHost);
                        host = url.getHost();
                    } catch (Exception ignored) {
                    }
                }
                InetAddress.getByName(host);
                dnsTime[0] = System.currentTimeMillis() - start;
                dnsOk[0] = true;
            } catch (Exception e) {
                dnsOk[0] = false;
            }

            try {
                long start = System.currentTimeMillis();
                Socket socket = new Socket();
                java.net.InetSocketAddress address = new java.net.InetSocketAddress("www.baidu.com", 80);
                socket.connect(address, 5000);
                socket.close();
                tcpTime[0] = System.currentTimeMillis() - start;
                tcpOk[0] = true;
            } catch (Exception e) {
                tcpOk[0] = false;
            }

            try {
                long start = System.currentTimeMillis();
                java.net.URL url = new java.net.URL("https://www.baidu.com");
                java.net.HttpURLConnection conn = (java.net.HttpURLConnection) url.openConnection();
                conn.setConnectTimeout(5000);
                conn.setReadTimeout(5000);
                conn.getResponseCode();
                wsTime[0] = System.currentTimeMillis() - start;
                wsOk[0] = true;
                conn.disconnect();
            } catch (Exception e) {
                wsOk[0] = false;
            }

            final long totalLatency = dnsTime[0] + tcpTime[0] + wsTime[0];

            runOnUiThread(() -> {
                isTesting = false;
                wkVBinding.testProgressPb.setVisibility(android.view.View.GONE);
                updateNetworkStatus();

                if (dnsOk[0]) {
                    wkVBinding.dnsResultTv.setText(dnsTime[0] + "ms");
                    wkVBinding.dnsResultTv.setTextColor(getResources().getColor(R.color.color_main));
                } else {
                    wkVBinding.dnsResultTv.setText(R.string.test_failed);
                    wkVBinding.dnsResultTv.setTextColor(getResources().getColor(R.color.red));
                }

                if (tcpOk[0]) {
                    wkVBinding.tcpResultTv.setText(tcpTime[0] + "ms");
                    wkVBinding.tcpResultTv.setTextColor(getResources().getColor(R.color.color_main));
                } else {
                    wkVBinding.tcpResultTv.setText(R.string.test_failed);
                    wkVBinding.tcpResultTv.setTextColor(getResources().getColor(R.color.red));
                }

                if (wsOk[0]) {
                    wkVBinding.wsResultTv.setText(wsTime[0] + "ms");
                    wkVBinding.wsResultTv.setTextColor(getResources().getColor(R.color.color_main));
                } else {
                    wkVBinding.wsResultTv.setText(R.string.test_failed);
                    wkVBinding.wsResultTv.setTextColor(getResources().getColor(R.color.red));
                }

                if (dnsOk[0] && tcpOk[0] && wsOk[0]) {
                    wkVBinding.latencyResultTv.setText(totalLatency + "ms");
                    wkVBinding.latencyResultTv.setTextColor(getResources().getColor(R.color.color_main));
                    WKToastUtils.getInstance().showToastNormal(getString(R.string.network_test_passed));
                } else {
                    wkVBinding.latencyResultTv.setText(R.string.test_failed);
                    wkVBinding.latencyResultTv.setTextColor(getResources().getColor(R.color.red));
                    WKToastUtils.getInstance().showToastNormal(getString(R.string.network_test_failed));
                }
            });
        });
    }
}
