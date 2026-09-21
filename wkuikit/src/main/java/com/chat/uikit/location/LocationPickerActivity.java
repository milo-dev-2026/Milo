package com.chat.uikit.location;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.amap.api.location.AMapLocation;
import com.amap.api.location.AMapLocationClient;
import com.amap.api.location.AMapLocationClientOption;
import com.amap.api.maps.AMap;
import com.amap.api.maps.CameraUpdateFactory;
import com.amap.api.maps.MapView;
import com.amap.api.maps.model.CameraPosition;
import com.amap.api.maps.model.BitmapDescriptorFactory;
import com.amap.api.maps.model.LatLng;
import com.amap.api.maps.model.MarkerOptions;
import com.amap.api.services.core.LatLonPoint;
import com.amap.api.services.core.PoiItem;
import com.amap.api.services.geocoder.GeocodeResult;
import com.amap.api.services.geocoder.GeocodeSearch;
import com.amap.api.services.geocoder.RegeocodeQuery;
import com.amap.api.services.geocoder.RegeocodeResult;
import com.amap.api.services.poisearch.PoiResult;
import com.amap.api.services.poisearch.PoiSearch;
import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.systembar.WKStatusBarUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActLocationPickerLayoutBinding;
import com.xinbida.wukongim.WKIM;

import java.util.ArrayList;

/**
 * 位置选择页面
 */
public class LocationPickerActivity extends WKBaseActivity<ActLocationPickerLayoutBinding>
        implements GeocodeSearch.OnGeocodeSearchListener, PoiSearch.OnPoiSearchListener {

    public static final String KEY_CHANNEL_ID = "channel_id";
    public static final String KEY_CHANNEL_TYPE = "channel_type";
    public static final String KEY_IS_PICK_MODE = "is_pick_mode";
    public static final String KEY_LOCATION_NAME = "location_name";
    public static final String KEY_LOCATION_ADDRESS = "location_address";
    public static final String KEY_LOCATION_LAT = "location_lat";
    public static final String KEY_LOCATION_LNG = "location_lng";
    private static final int REQUEST_LOCATION_PERMISSION = 1001;
    private static final int REQUEST_SEARCH_LOCATION = 1002;

    private String channelID;
    private byte channelType;
    private boolean isPickMode = false;

    private MapView mapView;
    private AMap aMap;
    private AMapLocationClient locationClient;
    private GeocodeSearch geocodeSearch;

    private PoiAdapter poiAdapter;
    private PoiSearch poiSearch;

    private LatLng currentLatLng;
    private String currentTitle = "";
    private String currentAddress = "";
    private int selectedPoiPosition = 0;
    private boolean isProgrammaticMove = false;

    @Override
    protected ActLocationPickerLayoutBinding getViewBinding() {
        return ActLocationPickerLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
    }

    @Override
    protected void initData(Bundle savedInstanceState) {
        channelID = getIntent().getStringExtra(KEY_CHANNEL_ID);
        channelType = getIntent().getByteExtra(KEY_CHANNEL_TYPE, (byte) 1);
        isPickMode = getIntent().getBooleanExtra(KEY_IS_PICK_MODE, false);

        mapView = wkVBinding.mapView;
        mapView.onCreate(savedInstanceState);
        aMap = mapView.getMap();

        aMap.getUiSettings().setZoomControlsEnabled(false);
        aMap.getUiSettings().setMyLocationButtonEnabled(false);

        aMap.setOnCameraChangeListener(new AMap.OnCameraChangeListener() {
            @Override
            public void onCameraChange(CameraPosition position) {
            }

            @Override
            public void onCameraChangeFinish(CameraPosition position) {
                if (isProgrammaticMove) return;
                currentLatLng = position.target;
                selectedPoiPosition = 0;
                doReverseGeocode(currentLatLng);
                searchNearbyPoi();
            }
        });

        try {
            geocodeSearch = new GeocodeSearch(this);
            geocodeSearch.setOnGeocodeSearchListener(this);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    protected void initView() {
        // 设置状态栏占位高度
        int statusBarHeight = WKStatusBarUtils.getStatusBarHeight(this);
        android.view.ViewGroup.LayoutParams params = wkVBinding.statusBarView.getLayoutParams();
        if (params != null) {
            params.height = statusBarHeight;
            wkVBinding.statusBarView.setLayoutParams(params);
        }

        // 返回按钮
        wkVBinding.backIv.setOnClickListener(v -> finish());

        // 发送/确定按钮
        if (isPickMode) {
            wkVBinding.btnSend.setText("确定");
        }
        wkVBinding.btnSend.setOnClickListener(v -> {
            if (isPickMode) {
                pickLocation();
            } else {
                sendLocation();
            }
        });

        // 定位按钮
        wkVBinding.btnLocate.setOnClickListener(v -> checkPermissionAndLocate());

        // 搜索框（点击跳转搜索页面）
        wkVBinding.searchEditText.setFocusable(false);
        wkVBinding.searchEditText.setOnClickListener(v -> openSearchPage());
        wkVBinding.searchLayout.setOnClickListener(v -> openSearchPage());

        // POI 列表
        poiAdapter = new PoiAdapter();
        poiAdapter.setOnItemClickListener((adapter, view, position) -> {
            PoiItem item = (PoiItem) adapter.getItem(position);
            if (item != null) {
                selectedPoiPosition = position;
                currentTitle = item.getTitle();
                currentAddress = getFullAddress(item);
                currentLatLng = new LatLng(item.getLatLonPoint().getLatitude(), item.getLatLonPoint().getLongitude());
                aMap.clear();
                aMap.addMarker(new MarkerOptions()
                        .anchor(0.5f, 1.0f)
                        .position(currentLatLng)
                        .icon(BitmapDescriptorFactory.fromResource(R.drawable.ic_location_pin_red)));
                isProgrammaticMove = true;
                mapView.post(() -> {
                    aMap.animateCamera(CameraUpdateFactory.newLatLngZoom(currentLatLng, 18), 300, new AMap.CancelableCallback() {
                        @Override
                        public void onFinish() {
                            mapView.postDelayed(() -> isProgrammaticMove = false, 200);
                        }

                        @Override
                        public void onCancel() {
                            isProgrammaticMove = false;
                        }
                    });
                });
                poiAdapter.setSelectedPosition(selectedPoiPosition);
            }
        });
        wkVBinding.poiRecyclerView.setLayoutManager(new LinearLayoutManager(this));
        wkVBinding.poiRecyclerView.setAdapter(poiAdapter);
    }

    @Override
    protected void initData() {
        // 每次打开都请求定位权限并定位
        checkPermissionAndLocate();
    }

    /**
     * 检查权限并定位
     */
    private void checkPermissionAndLocate() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
                != PackageManager.PERMISSION_GRANTED
                || ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION)
                != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this,
                    new String[]{
                            Manifest.permission.ACCESS_FINE_LOCATION,
                            Manifest.permission.ACCESS_COARSE_LOCATION
                    },
                    REQUEST_LOCATION_PERMISSION);
        } else {
            initLocation();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_LOCATION_PERMISSION) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                initLocation();
            } else {
                showToast("定位权限被拒绝，无法获取当前位置");
            }
        }
    }

    /**
     * 打开搜索页面
     */
    private void openSearchPage() {
        Intent intent = new Intent(this, SearchLocationActivity.class);
        intent.putExtra(SearchLocationActivity.KEY_CHANNEL_ID, channelID);
        intent.putExtra(SearchLocationActivity.KEY_CHANNEL_TYPE, channelType);
        intent.putExtra(SearchLocationActivity.KEY_IS_PICK_MODE, isPickMode);
        if (currentLatLng != null) {
            intent.putExtra("latitude", currentLatLng.latitude);
            intent.putExtra("longitude", currentLatLng.longitude);
        }
        startActivityForResult(intent, REQUEST_SEARCH_LOCATION);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_SEARCH_LOCATION && resultCode == RESULT_OK) {
            if (isPickMode && data != null) {
                // 选择模式下，将搜索页面选择的位置结果返回给调用方
                String name = data.getStringExtra(SearchLocationActivity.KEY_LOCATION_NAME);
                String address = data.getStringExtra(SearchLocationActivity.KEY_LOCATION_ADDRESS);
                double lat = data.getDoubleExtra(SearchLocationActivity.KEY_LOCATION_LAT, 0);
                double lng = data.getDoubleExtra(SearchLocationActivity.KEY_LOCATION_LNG, 0);
                Intent resultIntent = new Intent();
                resultIntent.putExtra(KEY_LOCATION_NAME, name);
                resultIntent.putExtra(KEY_LOCATION_ADDRESS, address);
                resultIntent.putExtra(KEY_LOCATION_LAT, lat);
                resultIntent.putExtra(KEY_LOCATION_LNG, lng);
                setResult(RESULT_OK, resultIntent);
            }
            finish();
        }
    }

    private void initLocation() {
        try {
            if (locationClient == null) {
                locationClient = new AMapLocationClient(this.getApplicationContext());
            }
            AMapLocationClientOption option = new AMapLocationClientOption();
            option.setLocationMode(AMapLocationClientOption.AMapLocationMode.Hight_Accuracy);
            option.setOnceLocation(true);
            option.setOnceLocationLatest(true);
            option.setNeedAddress(true);
            option.setGpsFirst(true);
            option.setHttpTimeOut(30000);
            locationClient.setLocationOption(option);
            locationClient.setLocationListener(location -> {
                if (location != null && location.getErrorCode() == 0) {
                    currentLatLng = new LatLng(location.getLatitude(), location.getLongitude());
                    aMap.moveCamera(CameraUpdateFactory.newLatLngZoom(currentLatLng, 17));
                    if (!TextUtils.isEmpty(location.getAddress())) {
                        currentAddress = location.getAddress();
                        currentTitle = TextUtils.isEmpty(location.getPoiName()) ? "我的位置" : location.getPoiName();
                    } else {
                        doReverseGeocode(currentLatLng);
                    }
                    searchNearbyPoi();
                }
            });
            startLocation();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void startLocation() {
        if (locationClient != null) {
            locationClient.startLocation();
        }
    }

    private void doReverseGeocode(LatLng latLng) {
        if (geocodeSearch == null || latLng == null) return;
        try {
            RegeocodeQuery query = new RegeocodeQuery(
                    new LatLonPoint(latLng.latitude, latLng.longitude),
                    200,
                    GeocodeSearch.AMAP
            );
            geocodeSearch.getFromLocationAsyn(query);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void searchNearbyPoi() {
        if (currentLatLng == null) return;
        try {
            PoiSearch.Query query = new PoiSearch.Query("", "", "");
            query.setPageSize(30);
            query.setPageNum(0);
            poiSearch = new PoiSearch(this, query);
            poiSearch.setOnPoiSearchListener(this);
            poiSearch.setBound(
                    new PoiSearch.SearchBound(
                            new LatLonPoint(currentLatLng.latitude, currentLatLng.longitude),
                            3000
                    )
            );
            poiSearch.searchPOIAsyn();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private String getFullAddress(PoiItem item) {
        StringBuilder detail = new StringBuilder();
        if (!TextUtils.isEmpty(item.getProvinceName())) {
            detail.append(item.getProvinceName());
        }
        if (!TextUtils.isEmpty(item.getCityName())) {
            detail.append(item.getCityName());
        }
        if (!TextUtils.isEmpty(item.getAdName())) {
            detail.append(item.getAdName());
        }
        if (!TextUtils.isEmpty(item.getSnippet())) {
            detail.append(item.getSnippet());
        }
        return detail.toString();
    }

    private void sendLocation() {
        if (currentLatLng == null) return;

        if (selectedPoiPosition >= 0 && poiAdapter.getData().size() > selectedPoiPosition) {
            PoiItem item = poiAdapter.getData().get(selectedPoiPosition);
            if (item != null) {
                currentTitle = item.getTitle();
                currentAddress = getFullAddress(item);
                currentLatLng = new LatLng(item.getLatLonPoint().getLatitude(), item.getLatLonPoint().getLongitude());
            }
        }

        final WKLocationContent content = new WKLocationContent(
                currentLatLng.longitude,
                currentLatLng.latitude,
                currentAddress,
                currentTitle
        );

        final boolean[] sent = {false};
        aMap.getMapScreenShot(new AMap.OnMapScreenShotListener() {
            @Override
            public void onMapScreenShot(Bitmap bitmap) {
                if (sent[0]) return;
                sent[0] = true;
                if (bitmap != null) {
                    String path = com.chat.base.utils.WKFileUtils.getInstance().saveBitmap("wkIM", bitmap);
                    content.localPath = path;
                }
                WKIM.getInstance().getMsgManager().sendMessage(content, channelID, channelType);
                runOnUiThread(() -> {
                    Toast.makeText(LocationPickerActivity.this, "已发送", Toast.LENGTH_SHORT).show();
                    finish();
                });
            }

            @Override
            public void onMapScreenShot(Bitmap bitmap, int status) {
            }
        });
    }

    /**
     * 选择模式 - 返回位置结果
     */
    private void pickLocation() {
        if (currentLatLng == null) return;

        if (selectedPoiPosition >= 0 && poiAdapter.getData().size() > selectedPoiPosition) {
            PoiItem item = poiAdapter.getData().get(selectedPoiPosition);
            if (item != null) {
                currentTitle = item.getTitle();
                currentAddress = getFullAddress(item);
                currentLatLng = new LatLng(item.getLatLonPoint().getLatitude(), item.getLatLonPoint().getLongitude());
            }
        }

        Intent resultIntent = new Intent();
        resultIntent.putExtra(KEY_LOCATION_NAME, currentTitle);
        resultIntent.putExtra(KEY_LOCATION_ADDRESS, currentAddress);
        resultIntent.putExtra(KEY_LOCATION_LAT, currentLatLng.latitude);
        resultIntent.putExtra(KEY_LOCATION_LNG, currentLatLng.longitude);
        setResult(RESULT_OK, resultIntent);
        finish();
    }

    // === GeocodeSearch callback ===
    @Override
    public void onRegeocodeSearched(RegeocodeResult result, int code) {
        if (code == 1000 && result != null && result.getRegeocodeAddress() != null) {
            String address = result.getRegeocodeAddress().getFormatAddress();
            if (!TextUtils.isEmpty(address)) {
                currentAddress = address;
                if (TextUtils.isEmpty(currentTitle)) {
                    currentTitle = result.getRegeocodeAddress().getBuilding() != null
                            ? result.getRegeocodeAddress().getBuilding()
                            : "我的位置";
                }
            }
        }
    }

    @Override
    public void onGeocodeSearched(GeocodeResult result, int code) {
    }

    // === PoiSearch callback ===
    @Override
    public void onPoiSearched(PoiResult result, int code) {
        if (code == 1000 && result != null && result.getPois() != null && !result.getPois().isEmpty()) {
            selectedPoiPosition = 0;
            PoiItem firstItem = result.getPois().get(0);
            currentTitle = firstItem.getTitle();
            currentAddress = getFullAddress(firstItem);
            poiAdapter.setNewInstance(result.getPois());
            poiAdapter.setSelectedPosition(0);
        } else {
            poiAdapter.setNewInstance(new ArrayList<>());
        }
    }

    @Override
    public void onPoiItemSearched(PoiItem item, int code) {
    }

    // === Lifecycle ===
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
        if (locationClient != null) {
            locationClient.onDestroy();
            locationClient = null;
        }
        if (geocodeSearch != null) {
            geocodeSearch.setOnGeocodeSearchListener(null);
        }
    }

    /**
     * POI 列表适配器
     */
    private class PoiAdapter extends com.chad.library.adapter.base.BaseQuickAdapter<PoiItem, com.chad.library.adapter.base.viewholder.BaseViewHolder> {

        private int selectedPosition = 0;

        public PoiAdapter() {
            super(R.layout.item_poi_layout);
        }

        public void setSelectedPosition(int position) {
            this.selectedPosition = position;
            notifyDataSetChanged();
        }

        @Override
        protected void convert(@NonNull com.chad.library.adapter.base.viewholder.BaseViewHolder helper, PoiItem item) {
            helper.setText(R.id.poiNameTv, item.getTitle());
            helper.setText(R.id.poiAddressTv, getFullAddress(item));
            helper.setGone(R.id.poiAddressTv, TextUtils.isEmpty(getFullAddress(item)));

            // 显示/隐藏选中标记
            ImageView checkIv = helper.getView(R.id.poiCheckIv);
            int position = helper.getAdapterPosition();
            if (position == selectedPosition) {
                checkIv.setVisibility(View.VISIBLE);
            } else {
                checkIv.setVisibility(View.GONE);
            }
        }
    }
}
