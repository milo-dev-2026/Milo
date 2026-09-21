package com.chat.uikit.sticker;

import android.content.Intent;
import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActStickerStoreLayoutBinding;
import com.scwang.smart.refresh.layout.api.RefreshLayout;
import com.scwang.smart.refresh.layout.listener.OnRefreshLoadMoreListener;

import java.util.ArrayList;
import java.util.List;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.GridLayoutManager;

public class StickerStoreActivity extends WKBaseActivity<ActStickerStoreLayoutBinding> {

    private List<StickerCategoryEntity> categoryList = new ArrayList<>();
    private StickerStoreAdapter adapter;
    private StickerService stickerService;

    @Override
    protected ActStickerStoreLayoutBinding getViewBinding() {
        return ActStickerStoreLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.str_sticker_store);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        stickerService = StickerService.getInstance();

        GridLayoutManager layoutManager = new GridLayoutManager(this, 2);
        wkVBinding.recyclerView.setLayoutManager(layoutManager);
        adapter = new StickerStoreAdapter(categoryList);
        wkVBinding.recyclerView.setAdapter(adapter);

        loadCategories();
    }

    @Override
    protected void initListener() {
        wkVBinding.refreshLayout.setOnRefreshLoadMoreListener(new OnRefreshLoadMoreListener() {
            @Override
            public void onRefresh(@NonNull RefreshLayout refreshLayout) {
                loadCategories();
                refreshLayout.finishRefresh(1000);
            }

            @Override
            public void onLoadMore(@NonNull RefreshLayout refreshLayout) {
                refreshLayout.finishLoadMoreWithNoMoreData();
            }
        });

        adapter.setOnItemClickListener(position -> {
            StickerCategoryEntity category = categoryList.get(position);
            Intent intent = new Intent(StickerStoreActivity.this, StickerStoreDetailActivity.class);
            intent.putExtra(StickerStoreDetailActivity.KEY_CATEGORY_ID, category.categoryID);
            intent.putExtra(StickerStoreDetailActivity.KEY_CATEGORY_NAME, category.name);
            startActivity(intent);
        });

        SingleClickUtil.onSingleClick(wkVBinding.managerBtn, v -> {
            startActivity(new Intent(this, StickerManagerActivity.class));
        });
    }

    private void loadCategories() {
        wkVBinding.spinKit.setVisibility(View.VISIBLE);
        wkVBinding.recyclerView.setVisibility(View.GONE);

        stickerService.fetchStoreCategories(new StickerService.DataCallback<List<StickerCategoryEntity>>() {
            @Override
            public void onSuccess(List<StickerCategoryEntity> data) {
                categoryList.clear();
                categoryList.addAll(data);
                wkVBinding.spinKit.setVisibility(View.GONE);
                wkVBinding.recyclerView.setVisibility(View.VISIBLE);
                adapter.notifyDataSetChanged();
            }

            @Override
            public void onError(String error) {
                wkVBinding.spinKit.setVisibility(View.GONE);
                wkVBinding.recyclerView.setVisibility(View.VISIBLE);
            }
        });
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (adapter != null) {
            for (StickerCategoryEntity c : categoryList) {
                boolean isAdded = false;
                for (StickerCategoryEntity mc : StickerService.getInstance().getMyCategories()) {
                    if (mc.categoryID.equals(c.categoryID)) {
                        isAdded = true;
                        break;
                    }
                }
                c.isAdded = isAdded;
            }
            adapter.notifyDataSetChanged();
        }
    }
}
