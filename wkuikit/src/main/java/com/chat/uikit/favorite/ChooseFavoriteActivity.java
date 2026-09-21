package com.chat.uikit.favorite;

import android.view.View;
import android.widget.CompoundButton;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityChooseFavoriteBinding;

import java.util.ArrayList;
import java.util.List;

import androidx.recyclerview.widget.LinearLayoutManager;

public class ChooseFavoriteActivity extends WKBaseActivity<ActivityChooseFavoriteBinding> {

    private List<FavoriteItem> favoriteList = new ArrayList<>();
    private FavoriteAdapter adapter;

    @Override
    protected ActivityChooseFavoriteBinding getViewBinding() {
        return ActivityChooseFavoriteBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.choose_favorite);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        LinearLayoutManager layoutManager = new LinearLayoutManager(this);
        wkVBinding.recyclerView.setLayoutManager(layoutManager);
        adapter = new FavoriteAdapter(favoriteList);
        wkVBinding.recyclerView.setAdapter(adapter);
        adapter.setMultiSelect(true);

        loadFavorites();
    }

    private void loadFavorites() {
        favoriteList.clear();
        List<FavoriteItem> stored = FavoriteStorageManager.getInstance(getApplicationContext()).getAllFavorites();
        favoriteList.addAll(stored);
        adapter.notifyDataSetChanged();
        wkVBinding.emptyTv.setVisibility(favoriteList.isEmpty() ? View.VISIBLE : View.GONE);
    }

    @Override
    protected void initListener() {
        adapter.setOnItemClickListener(position -> {
            FavoriteItem item = favoriteList.get(position);
            item.isSelected = !item.isSelected;
            adapter.notifyItemChanged(position);
            updateSelectAllCb();
        });

        wkVBinding.selectAllCb.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (buttonView.isPressed()) {
                    for (FavoriteItem item : favoriteList) {
                        item.isSelected = isChecked;
                    }
                    adapter.notifyDataSetChanged();
                }
            }
        });

        SingleClickUtil.onSingleClick(wkVBinding.sendBtn, v -> {
            int count = 0;
            for (FavoriteItem item : favoriteList) {
                if (item.isSelected) count++;
            }
            if (count == 0) {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.fav_select_empty));
                return;
            }
            WKToastUtils.getInstance().showToastNormal(getString(R.string.fav_forwarded_count, count));
            setResult(RESULT_OK);
            finish();
        });
    }

    private void updateSelectAllCb() {
        boolean allSelected = true;
        boolean anySelected = false;
        for (FavoriteItem item : favoriteList) {
            if (!item.isSelected) {
                allSelected = false;
            } else {
                anySelected = true;
            }
        }
        wkVBinding.selectAllCb.setOnCheckedChangeListener(null);
        if (allSelected && !favoriteList.isEmpty()) {
            wkVBinding.selectAllCb.setChecked(true);
        } else if (anySelected) {
            wkVBinding.selectAllCb.setChecked(false);
        } else {
            wkVBinding.selectAllCb.setChecked(false);
        }
        wkVBinding.selectAllCb.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                for (FavoriteItem item : favoriteList) {
                    item.isSelected = isChecked;
                }
                adapter.notifyDataSetChanged();
            }
        });
    }
}
