package com.chat.uikit.favorite;

import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActFavoriteSelectLayoutBinding;

import java.util.ArrayList;
import java.util.List;

import androidx.recyclerview.widget.LinearLayoutManager;

public class FavoriteSelectActivity extends WKBaseActivity<ActFavoriteSelectLayoutBinding> {

    private List<FavoriteItem> favoriteList = new ArrayList<>();
    private FavoriteAdapter adapter;

    @Override
    protected ActFavoriteSelectLayoutBinding getViewBinding() {
        return ActFavoriteSelectLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText("选择收藏");
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

        loadFavorites();
        adapter.setMultiSelect(true);
    }

    @Override
    protected void initListener() {
        adapter.setOnItemClickListener(position -> {
            FavoriteItem item = favoriteList.get(position);
            item.isSelected = !item.isSelected;
            adapter.notifyItemChanged(position);
        });

        SingleClickUtil.onSingleClick(wkVBinding.selectAllBtn, v -> {
            boolean allSelected = true;
            for (FavoriteItem item : favoriteList) {
                if (!item.isSelected) {
                    allSelected = false;
                    break;
                }
            }
            for (FavoriteItem item : favoriteList) {
                item.isSelected = !allSelected;
            }
            adapter.notifyDataSetChanged();
        });

        SingleClickUtil.onSingleClick(wkVBinding.forwardBtn, v -> {
            int count = 0;
            for (FavoriteItem item : favoriteList) {
                if (item.isSelected) count++;
            }
            if (count == 0) {
                WKToastUtils.getInstance().showToastNormal("请选择要转发的收藏");
                return;
            }
            WKToastUtils.getInstance().showToastNormal("已转发 " + count + " 条收藏");
            finish();
        });
    }

    private void loadFavorites() {
        favoriteList.clear();
        List<FavoriteItem> stored = FavoriteStorageManager.getInstance(getApplicationContext()).getAllFavorites();
        favoriteList.addAll(stored);
        adapter.notifyDataSetChanged();
    }
}
