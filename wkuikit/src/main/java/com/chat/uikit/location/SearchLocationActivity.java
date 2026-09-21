package com.chat.uikit.location;

import android.content.Intent;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.amap.api.location.AMapLocation;
import com.amap.api.location.AMapLocationClient;
import com.amap.api.location.AMapLocationClientOption;
import com.amap.api.maps.AMap;
import com.amap.api.maps.CameraUpdateFactory;
import com.amap.api.maps.MapView;
import com.amap.api.maps.model.CameraPosition;
import com.amap.api.maps.model.LatLng;
import com.amap.api.services.core.LatLonPoint;
import com.amap.api.services.core.PoiItem;
import com.amap.api.services.poisearch.PoiResult;
import com.amap.api.services.poisearch.PoiSearch;
import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.systembar.WKStatusBarUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActSearchLocationLayoutBinding;
import com.xinbida.wukongim.WKIM;

import java.util.ArrayList;

/**
 * 位置搜索页面
 * 交互：输入关键词 → 显示POI列表 → 点击POI → 显示地图预览（可缩放）→ 点击发送直接发送
 */
public class SearchLocationActivity extends WKBaseActivity<ActSearchLocationLayoutBinding>
        implements PoiSearch.OnPoiSearchListener {

    public static final String KEY_CHANNEL_ID = "channel_id";
    public static final String KEY_CHANNEL_TYPE = "channel_type";
    public static final String KEY_IS_PICK_MODE = "is_pick_mode";
    public static final String KEY_LOCATION_NAME = "location_name";
    public static final String KEY_LOCATION_ADDRESS = "location_address";
    public static final String KEY_LOCATION_LAT = "location_lat";
    public static final String KEY_LOCATION_LNG = "location_lng";

    private String channelID;
    private byte channelType;
    private boolean isPickMode = false;
    private double currentLatitude;
    private double currentLongitude;
    private String currentCity = "";

    private MapView mapView;
    private AMap aMap;
    private AMapLocationClient locationClient;

    private PoiAdapter poiAdapter;
    private PoiSearch poiSearch;
    private String searchKeyword = "";
    private PoiItem selectedPoiItem;

    // 搜索阶段：0=附近5公里，1=城市范围，2=全国范围
    private int searchPhase = 0;
    private int activeRequestId = 0;
    private boolean isProgrammaticMove = false;

    @Override
    protected ActSearchLocationLayoutBinding getViewBinding() {
        return ActSearchLocationLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
    }

    @Override
    protected void initData(Bundle savedInstanceState) {
        channelID = getIntent().getStringExtra(KEY_CHANNEL_ID);
        channelType = getIntent().getByteExtra(KEY_CHANNEL_TYPE, (byte) 1);
        isPickMode = getIntent().getBooleanExtra(KEY_IS_PICK_MODE, false);
        currentLatitude = getIntent().getDoubleExtra("latitude", 0);
        currentLongitude = getIntent().getDoubleExtra("longitude", 0);
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
        wkVBinding.btnSend.setText(isPickMode ? "确定" : "发送");
        wkVBinding.btnSend.setOnClickListener(v -> sendLocation());

        // 搜索框
        wkVBinding.searchEditText.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                searchKeyword = s.toString().trim();
                if (!TextUtils.isEmpty(searchKeyword)) {
                    searchPhase = 0;
                    activeRequestId++;
                    doSearch(searchKeyword, searchPhase, activeRequestId);
                    wkVBinding.emptyLayout.setVisibility(View.GONE);
                    wkVBinding.poiRecyclerView.setVisibility(View.VISIBLE);
                    wkVBinding.mapPreviewLayout.setVisibility(View.GONE);
                    updateSendButton(false);
                } else {
                    poiAdapter.setNewInstance(new ArrayList<>());
                    wkVBinding.emptyLayout.setVisibility(View.VISIBLE);
                    wkVBinding.poiRecyclerView.setVisibility(View.GONE);
                    wkVBinding.mapPreviewLayout.setVisibility(View.GONE);
                    selectedPoiItem = null;
                    updateSendButton(false);
                }
            }

            @Override
            public void afterTextChanged(Editable s) {}
        });

        // POI 列表
        poiAdapter = new PoiAdapter();
        poiAdapter.setOnItemClickListener((adapter, view, position) -> {
            PoiItem item = (PoiItem) adapter.getItem(position);
            if (item != null) {
                selectedPoiItem = item;
                poiAdapter.setSelectedPosition(position);
                hideKeyboard();
                showMapPreview(item);
            }
        });
        wkVBinding.poiRecyclerView.setLayoutManager(new LinearLayoutManager(this));
        wkVBinding.poiRecyclerView.setAdapter(poiAdapter);

        // 初始化地图（在Activity onCreate中调用）
        mapView = wkVBinding.mapView;
        mapView.onCreate(getIntent().getExtras() != null ? getIntent().getExtras() : new Bundle());
        aMap = mapView.getMap();
        aMap.getUiSettings().setZoomControlsEnabled(false);
        aMap.getUiSettings().setMyLocationButtonEnabled(false);

        // 地图移动时更新选中信息（不做逆地理，直接用选中的POI信息）
        aMap.setOnCameraChangeListener(new AMap.OnCameraChangeListener() {
            @Override
            public void onCameraChange(CameraPosition position) {}

            @Override
            public void onCameraChangeFinish(CameraPosition position) {
                if (isProgrammaticMove) return;
                selectedPoiItem = null;
                poiAdapter.setSelectedPosition(-1);
            }
        });

        wkVBinding.searchEditText.requestFocus();
    }

    @Override
    protected void initData() {
        wkVBinding.emptyLayout.setVisibility(View.VISIBLE);
        wkVBinding.poiRecyclerView.setVisibility(View.GONE);

        // 如果没有当前位置，先定位一次以获取城市信息
        if (currentLatitude == 0 && currentLongitude == 0) {
            startLocation();
        }
    }

    private void startLocation() {
        try {
            if (locationClient == null) {
                locationClient = new AMapLocationClient(this.getApplicationContext());
            }
            AMapLocationClientOption option = new AMapLocationClientOption();
            option.setLocationMode(AMapLocationClientOption.AMapLocationMode.Hight_Accuracy);
            option.setOnceLocation(true);
            option.setOnceLocationLatest(true);
            option.setNeedAddress(true);
            option.setHttpTimeOut(15000);
            locationClient.setLocationOption(option);
            locationClient.setLocationListener(location -> {
                if (location != null && location.getErrorCode() == 0) {
                    currentLatitude = location.getLatitude();
                    currentLongitude = location.getLongitude();
                    currentCity = location.getCity();
                }
            });
            locationClient.startLocation();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /**
     * 执行搜索
     * phase: 0=附近5公里, 1=城市范围, 2=全国范围
     */
    private void doSearch(String keyword, int phase, final int requestId) {
        try {
            // 城市code，phase==1时使用currentCity
            String cityCode = (phase == 1 && !TextUtils.isEmpty(currentCity)) ? currentCity : "";
            PoiSearch.Query query = new PoiSearch.Query(keyword, "", cityCode);
            query.setPageSize(30);
            query.setPageNum(0);
            query.setCityLimit(phase == 1 && !TextUtils.isEmpty(currentCity));

            poiSearch = new PoiSearch(this, query);
            poiSearch.setOnPoiSearchListener(new PoiSearch.OnPoiSearchListener() {
                @Override
                public void onPoiSearched(PoiResult result, int code) {
                    // 只处理最新的请求
                    if (requestId != activeRequestId) return;

                    boolean hasResults = (code == 1000 && result != null
                            && result.getPois() != null && !result.getPois().isEmpty());

                    if (hasResults) {
                        poiAdapter.setNewInstance(result.getPois());
                        wkVBinding.poiRecyclerView.setVisibility(View.VISIBLE);
                        wkVBinding.emptyLayout.setVisibility(View.GONE);
                    } else {
                        // 没有结果，升级搜索范围
                        if (phase < 2) {
                            searchPhase = phase + 1;
                            doSearch(keyword, searchPhase, requestId);
                        } else {
                            // 全国范围也没结果
                            poiAdapter.setNewInstance(new ArrayList<>());
                            wkVBinding.emptyLayout.setVisibility(View.VISIBLE);
                            TextView emptyTv = wkVBinding.emptyLayout.getChildAt(0) instanceof TextView
                                    ? (TextView) wkVBinding.emptyLayout.getChildAt(0) : null;
                            if (emptyTv != null) {
                                emptyTv.setText("未找到相关地点");
                            }
                        }
                    }
                }

                @Override
                public void onPoiItemSearched(PoiItem item, int code) {}
            });

            // 根据搜索阶段设置范围
            if (phase == 0 && currentLatitude != 0 && currentLongitude != 0) {
                // 附近5公里
                poiSearch.setBound(
                        new PoiSearch.SearchBound(
                                new LatLonPoint(currentLatitude, currentLongitude),
                                5000,
                                true
                        )
                );
            }
            // phase == 1: 通过构造函数第三个参数设置城市
            // phase == 2 全国范围：不设bound和city

            poiSearch.searchPOIAsyn();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /**
     * 显示地图预览
     */
    private void showMapPreview(PoiItem item) {
        wkVBinding.poiRecyclerView.setVisibility(View.GONE);
        wkVBinding.emptyLayout.setVisibility(View.GONE);
        wkVBinding.mapPreviewLayout.setVisibility(View.VISIBLE);

        double lat = 0, lng = 0;
        if (item.getLatLonPoint() != null) {
            lat = item.getLatLonPoint().getLatitude();
            lng = item.getLatLonPoint().getLongitude();
        }
        LatLng latLng = new LatLng(lat, lng);

        isProgrammaticMove = true;
        aMap.clear();
        aMap.addMarker(new com.amap.api.maps.model.MarkerOptions()
                .anchor(0.5f, 1.0f)
                .position(latLng)
                .icon(com.amap.api.maps.model.BitmapDescriptorFactory.fromResource(R.drawable.ic_location_pin_red)));

        wkVBinding.mapView.post(() -> {
            aMap.animateCamera(CameraUpdateFactory.newLatLngZoom(latLng, 18), 300, new AMap.CancelableCallback() {
                @Override
                public void onFinish() {
                    wkVBinding.mapView.postDelayed(() -> isProgrammaticMove = false, 200);
                }

                @Override
                public void onCancel() {
                    isProgrammaticMove = false;
                }
            });
        });

        wkVBinding.previewNameTv.setText(item.getTitle());
        StringBuilder address = new StringBuilder();
        if (!TextUtils.isEmpty(item.getProvinceName())) address.append(item.getProvinceName());
        if (!TextUtils.isEmpty(item.getCityName())) address.append(item.getCityName());
        if (!TextUtils.isEmpty(item.getAdName())) address.append(item.getAdName());
        if (!TextUtils.isEmpty(item.getSnippet())) address.append(item.getSnippet());
        wkVBinding.previewAddressTv.setText(address.toString());

        updateSendButton(true);
    }

    private void hideKeyboard() {
        InputMethodManager imm = (InputMethodManager) getSystemService(INPUT_METHOD_SERVICE);
        if (imm != null && getCurrentFocus() != null) {
            imm.hideSoftInputFromWindow(getCurrentFocus().getWindowToken(), 0);
        }
    }

    private void updateSendButton(boolean enabled) {
        wkVBinding.btnSend.setEnabled(enabled);
        wkVBinding.btnSend.setAlpha(enabled ? 1.0f : 0.5f);
    }

    /**
     * 发送位置消息 / 确定选择位置
     */
    private void sendLocation() {
        if (selectedPoiItem == null && aMap == null) return;

        double lat;
        double lng;
        String title;
        String address;

        if (selectedPoiItem != null) {
            lat = selectedPoiItem.getLatLonPoint().getLatitude();
            lng = selectedPoiItem.getLatLonPoint().getLongitude();
            title = selectedPoiItem.getTitle();
            StringBuilder sb = new StringBuilder();
            if (!TextUtils.isEmpty(selectedPoiItem.getProvinceName())) sb.append(selectedPoiItem.getProvinceName());
            if (!TextUtils.isEmpty(selectedPoiItem.getCityName())) sb.append(selectedPoiItem.getCityName());
            if (!TextUtils.isEmpty(selectedPoiItem.getAdName())) sb.append(selectedPoiItem.getAdName());
            if (!TextUtils.isEmpty(selectedPoiItem.getSnippet())) sb.append(selectedPoiItem.getSnippet());
            address = sb.toString();
        } else {
            LatLng target = aMap.getCameraPosition().target;
            lat = target.latitude;
            lng = target.longitude;
            title = wkVBinding.previewNameTv.getText().toString();
            address = wkVBinding.previewAddressTv.getText().toString();
        }

        if (isPickMode) {
            // 选择模式：返回位置结果
            Intent resultIntent = new Intent();
            resultIntent.putExtra(KEY_LOCATION_NAME, title);
            resultIntent.putExtra(KEY_LOCATION_ADDRESS, address);
            resultIntent.putExtra(KEY_LOCATION_LAT, lat);
            resultIntent.putExtra(KEY_LOCATION_LNG, lng);
            setResult(RESULT_OK, resultIntent);
            finish();
        } else {
            // 发送模式：发送位置消息
            final WKLocationContent content = new WKLocationContent(lng, lat, address, title);

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
                        Toast.makeText(SearchLocationActivity.this, "已发送", Toast.LENGTH_SHORT).show();
                        setResult(RESULT_OK);
                        finish();
                    });
                }

                @Override
                public void onMapScreenShot(Bitmap bitmap, int status) {
                }
            });
        }
    }

    // === PoiSearch callback (unused, required by interface) ===
    @Override
    public void onPoiSearched(PoiResult result, int code) {}

    @Override
    public void onPoiItemSearched(PoiItem item, int code) {}

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
    }

    /**
     * POI 列表适配器
     */
    private class PoiAdapter extends com.chad.library.adapter.base.BaseQuickAdapter<PoiItem, com.chad.library.adapter.base.viewholder.BaseViewHolder> {

        private int selectedPosition = -1;

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

            StringBuilder detail = new StringBuilder();
            if (!TextUtils.isEmpty(item.getProvinceName())) detail.append(item.getProvinceName());
            if (!TextUtils.isEmpty(item.getCityName())) detail.append(item.getCityName());
            if (!TextUtils.isEmpty(item.getAdName())) detail.append(item.getAdName());
            if (!TextUtils.isEmpty(item.getSnippet())) detail.append(item.getSnippet());

            helper.setText(R.id.poiAddressTv, detail.toString());
            helper.setGone(R.id.poiAddressTv, TextUtils.isEmpty(detail.toString()));

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
