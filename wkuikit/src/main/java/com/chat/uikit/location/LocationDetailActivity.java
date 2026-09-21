package com.chat.uikit.location;

import android.app.AlertDialog;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;

import com.amap.api.maps.AMap;
import com.amap.api.maps.CameraUpdateFactory;
import com.amap.api.maps.MapView;
import com.amap.api.maps.model.BitmapDescriptorFactory;
import com.amap.api.maps.model.LatLng;
import com.amap.api.maps.model.MarkerOptions;
import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.systembar.WKStatusBarUtils;
import com.chat.uikit.R;
import com.chat.uikit.chat.ChooseChatActivity;
import com.chat.uikit.databinding.ActLocationDetailLayoutBinding;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannel;

import java.util.ArrayList;
import java.util.List;

public class LocationDetailActivity extends WKBaseActivity<ActLocationDetailLayoutBinding> {

    public static final String EXTRA_TITLE = "title";
    public static final String EXTRA_ADDRESS = "address";
    public static final String EXTRA_LATITUDE = "lat";
    public static final String EXTRA_LONGITUDE = "lng";
    public static final String EXTRA_IMG = "img";

    private static final String AMAP_PACKAGE_NAME = "com.autonavi.minimap";
    private static final int REQUEST_CHOOSE_CHAT = 1001;

    private MapView mapView;
    private AMap aMap;

    private String title;
    private String address;
    private double latitude;
    private double longitude;
    private String imageUrl;

    @Override
    protected ActLocationDetailLayoutBinding getViewBinding() {
        return ActLocationDetailLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
    }

    @Override
    protected void initData(Bundle savedInstanceState) {
        title = getIntent().getStringExtra(EXTRA_TITLE);
        address = getIntent().getStringExtra(EXTRA_ADDRESS);
        latitude = getIntent().getDoubleExtra(EXTRA_LATITUDE, 0);
        longitude = getIntent().getDoubleExtra(EXTRA_LONGITUDE, 0);
        imageUrl = getIntent().getStringExtra(EXTRA_IMG);

        mapView = wkVBinding.mapView;
        mapView.onCreate(savedInstanceState);
        aMap = mapView.getMap();
        aMap.getUiSettings().setZoomControlsEnabled(false);
        aMap.getUiSettings().setMyLocationButtonEnabled(false);

        if (latitude != 0 && longitude != 0) {
            LatLng latLng = new LatLng(latitude, longitude);
            aMap.addMarker(new MarkerOptions()
                    .anchor(0.5f, 1.0f)
                    .position(latLng)
                    .icon(BitmapDescriptorFactory.fromResource(R.drawable.ic_location_pin_red)));
            mapView.post(() -> aMap.animateCamera(CameraUpdateFactory.newLatLngZoom(latLng, 18), 300, null));
        }
    }

    @Override
    protected void initView() {
        int statusBarHeight = WKStatusBarUtils.getStatusBarHeight(this);
        android.view.ViewGroup.LayoutParams params = wkVBinding.statusBarView.getLayoutParams();
        if (params != null) {
            params.height = statusBarHeight;
            wkVBinding.statusBarView.setLayoutParams(params);
        }

        wkVBinding.backIv.setOnClickListener(v -> finish());

        wkVBinding.titleTv.setText("地点");

        wkVBinding.shareIv.setOnClickListener(v -> openShareChooser());

        if (!TextUtils.isEmpty(title)) {
            wkVBinding.locationNameTv.setText(title);
        } else {
            wkVBinding.locationNameTv.setText("位置");
        }

        if (!TextUtils.isEmpty(address)) {
            wkVBinding.locationAddressTv.setText(address);
        }

        wkVBinding.navigateIv.setOnClickListener(v -> openNavigationActionSheet());
    }

    private void openShareChooser() {
        Intent intent = new Intent(this, ChooseChatActivity.class);
        intent.putExtra("isChoose", false);
        startActivityForResult(intent, REQUEST_CHOOSE_CHAT);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_CHOOSE_CHAT && resultCode == RESULT_OK && data != null) {
            ArrayList<WKChannel> selectedList = data.getParcelableArrayListExtra("list");
            if (selectedList != null && !selectedList.isEmpty()) {
                shareLocationToChats(selectedList);
            }
        }
    }

    private void shareLocationToChats(List<WKChannel> channels) {
        if (aMap == null || channels == null || channels.isEmpty()) return;

        final boolean[] sent = {false};
        aMap.getMapScreenShot(new AMap.OnMapScreenShotListener() {
            @Override
            public void onMapScreenShot(Bitmap bitmap) {
                if (sent[0]) return;
                sent[0] = true;
                String localPath = null;
                if (bitmap != null) {
                    localPath = com.chat.base.utils.WKFileUtils.getInstance().saveBitmap("wkIM", bitmap);
                }

                for (WKChannel channel : channels) {
                    WKLocationContent content = new WKLocationContent(
                            longitude, latitude, address, title);
                    content.localPath = localPath;
                    WKIM.getInstance().getMsgManager().sendMessage(content, channel.channelID, channel.channelType);
                }

                showToast("已发送");
                finish();
            }

            @Override
            public void onMapScreenShot(Bitmap bitmap, int status) {
            }
        });
    }

    private void openNavigationActionSheet() {
        if (latitude == 0 && longitude == 0) return;
        openAmapNavigation();
    }

    private void openAmapNavigation() {
        if (isAmapInstalled()) {
            try {
                String uri = "androidamap://navi?sourceApplication=chat&poiname="
                        + (TextUtils.isEmpty(title) ? "目的地" : title)
                        + "&lat=" + latitude + "&lon=" + longitude + "&dev=0&style=2";
                Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(uri));
                intent.setPackage(AMAP_PACKAGE_NAME);
                intent.addCategory(Intent.CATEGORY_DEFAULT);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(intent);
                return;
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        openAmapWebNavigation();
    }

    private void openAmapWebNavigation() {
        try {
            String url = "https://uri.amap.com/navigation?to=" + longitude + "," + latitude
                    + "," + (TextUtils.isEmpty(title) ? "目的地" : title)
                    + "&mode=car&src=chat";
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
        } catch (Exception e) {
            showToast("无法打开导航");
        }
    }

    private boolean isAmapInstalled() {
        try {
            PackageInfo packageInfo = getPackageManager().getPackageInfo(AMAP_PACKAGE_NAME, 0);
            return packageInfo != null;
        } catch (PackageManager.NameNotFoundException e) {
            return false;
        }
    }

    private void showDownloadDialog() {
        new AlertDialog.Builder(this)
                .setTitle("提示")
                .setMessage("需要安装高德地图才能导航，是否立即下载？")
                .setPositiveButton("立即下载", (dialog, which) -> {
                    try {
                        Intent intent = new Intent(Intent.ACTION_VIEW,
                                Uri.parse("market://details?id=" + AMAP_PACKAGE_NAME));
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                        startActivity(intent);
                    } catch (Exception e) {
                        try {
                            Intent intent = new Intent(Intent.ACTION_VIEW,
                                    Uri.parse("https://mobile.amap.com/"));
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                            startActivity(intent);
                        } catch (Exception e2) {
                            showToast("无法打开应用市场，请自行下载高德地图");
                        }
                    }
                })
                .setNegativeButton("取消", null)
                .show();
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (mapView != null) mapView.onResume();
    }

    @Override
    protected void onPause() {
        super.onPause();
        if (mapView != null) mapView.onPause();
    }

    @Override
    protected void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        if (mapView != null) mapView.onSaveInstanceState(outState);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (mapView != null) mapView.onDestroy();
    }
}
