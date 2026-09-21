package com.chat.uikit.favorite;

import android.content.Intent;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKToastUtils;
import com.google.android.material.tabs.TabLayout;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityFavoriteListBinding;

import java.util.ArrayList;
import java.util.List;

import androidx.recyclerview.widget.LinearLayoutManager;

public class FavoriteListActivity extends WKBaseActivity<ActivityFavoriteListBinding> {

    private List<FavoriteItem> allFavorites = new ArrayList<>();
    private List<FavoriteItem> filteredList = new ArrayList<>();
    private FavoriteAdapter adapter;
    private int currentFilter = 0;

    private static final int FILTER_ALL = 0;
    private static final int FILTER_TEXT = 1;
    private static final int FILTER_IMAGE = 2;
    private static final int FILTER_LINK = 3;
    private static final int FILTER_FILE = 4;

    @Override
    protected ActivityFavoriteListBinding getViewBinding() {
        return ActivityFavoriteListBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.favorite_list);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        LinearLayoutManager layoutManager = new LinearLayoutManager(this);
        wkVBinding.recyclerView.setLayoutManager(layoutManager);
        adapter = new FavoriteAdapter(filteredList);
        wkVBinding.recyclerView.setAdapter(adapter);

        setupTabs();
        loadData();
    }

    private void setupTabs() {
        String[] tabNames = {getString(R.string.All), getString(R.string.fav_type_text),
                getString(R.string.image), getString(R.string.fav_type_link),
                getString(R.string.fav_type_file)};
        for (String name : tabNames) {
            TabLayout.Tab tab = wkVBinding.typeTabLayout.newTab();
            tab.setText(name);
            wkVBinding.typeTabLayout.addTab(tab);
        }

        wkVBinding.typeTabLayout.addOnTabSelectedListener(new TabLayout.OnTabSelectedListener() {
            @Override
            public void onTabSelected(TabLayout.Tab tab) {
                currentFilter = tab.getPosition();
                applyFilter();
            }

            @Override
            public void onTabUnselected(TabLayout.Tab tab) {}

            @Override
            public void onTabReselected(TabLayout.Tab tab) {}
        });
    }

    private void loadData() {
        allFavorites.clear();
        List<FavoriteItem> stored = FavoriteStorageManager.getInstance(getApplicationContext()).getAllFavorites();
        allFavorites.addAll(stored);
        applyFilter();
        if (allFavorites.isEmpty()) {
            WKToastUtils.getInstance().showToastNormal("暂无收藏内容");
        }
    }

    private void applyFilter() {
        filteredList.clear();
        for (FavoriteItem item : allFavorites) {
            switch (currentFilter) {
                case FILTER_ALL:
                    filteredList.add(item);
                    break;
                case FILTER_TEXT:
                    if (item.type == FavoriteItem.TYPE_TEXT) filteredList.add(item);
                    break;
                case FILTER_IMAGE:
                    if (item.type == FavoriteItem.TYPE_IMAGE) filteredList.add(item);
                    break;
                case FILTER_LINK:
                    if (item.type == FavoriteItem.TYPE_LINK) filteredList.add(item);
                    break;
                case FILTER_FILE:
                    if (item.type == FavoriteItem.TYPE_FILE) filteredList.add(item);
                    break;
            }
        }
        adapter.notifyDataSetChanged();
    }

    @Override
    protected void onResume() {
        super.onResume();
        loadData();
    }

    @Override
    protected void initListener() {
        adapter.setOnItemClickListener(position -> {
            FavoriteItem item = filteredList.get(position);
            Intent intent;
            if (item.type == FavoriteItem.TYPE_IMAGE) {
                intent = new Intent(this, DetailImgActivity.class);
                intent.putExtra(DetailImgActivity.KEY_IMG_URL, item.extra != null && !item.extra.isEmpty() ? item.extra : item.content);
            } else {
                intent = new Intent(this, DetailTextActivity.class);
                intent.putExtra(DetailTextActivity.KEY_TEXT_CONTENT, item.content);
            }
            intent.putExtra(DetailTextActivity.KEY_SENDER, item.senderName);
            intent.putExtra(DetailTextActivity.KEY_TIME, item.time);
            intent.putExtra(FavoriteDetailActivity.KEY_FAV_ID, item.id);
            startActivity(intent);
        });

        adapter.setOnItemLongClickListener(position -> {
            if (!adapter.isMultiSelect()) {
                adapter.setMultiSelect(true);
                filteredList.get(position).isSelected = true;
                adapter.notifyItemChanged(position);
                WKToastUtils.getInstance().showToastNormal(getString(R.string.enter_select_mode));
            }
        });
    }

    @Override
    public void onBackPressed() {
        if (adapter.isMultiSelect()) {
            adapter.setMultiSelect(false);
        } else {
            super.onBackPressed();
        }
    }
}
