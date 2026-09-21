package com.chat.uikit.sticker;

import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActStickerStoreDetailLayoutBinding;

import java.util.ArrayList;
import java.util.List;

import androidx.recyclerview.widget.GridLayoutManager;

public class StickerStoreDetailActivity extends WKBaseActivity<ActStickerStoreDetailLayoutBinding> {

    public static final String KEY_CATEGORY_ID = "category_id";
    public static final String KEY_CATEGORY_NAME = "category_name";

    private String categoryId;
    private String categoryName;
    private boolean isAdded = false;
    private List<StickerEntity> stickerList = new ArrayList<>();
    private StickerDetailAdapter adapter;
    private StickerService stickerService;

    @Override
    protected ActStickerStoreDetailLayoutBinding getViewBinding() {
        return ActStickerStoreDetailLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.str_sticker_store);
    }

    @Override
    protected void initPresenter() {
        if (getIntent() != null) {
            categoryId = getIntent().getStringExtra(KEY_CATEGORY_ID);
            categoryName = getIntent().getStringExtra(KEY_CATEGORY_NAME);
        }
    }

    @Override
    protected void initView() {
        stickerService = StickerService.getInstance();

        wkVBinding.titleTv.setText(categoryName);

        GridLayoutManager layoutManager = new GridLayoutManager(this, 4);
        wkVBinding.recyclerView.setLayoutManager(layoutManager);

        adapter = new StickerDetailAdapter(stickerList);
        wkVBinding.recyclerView.setAdapter(adapter);

        checkIsAdded();
        loadStickers();
    }

    private void checkIsAdded() {
        for (StickerCategoryEntity c : stickerService.getMyCategories()) {
            if (c.categoryID.equals(categoryId)) {
                isAdded = true;
                break;
            }
        }
        updateAddButton();
    }

    private void loadStickers() {
        stickerService.fetchStickersByCategory(categoryId, new StickerService.DataCallback<List<StickerEntity>>() {
            @Override
            public void onSuccess(List<StickerEntity> data) {
                stickerList.clear();
                stickerList.addAll(data);
                wkVBinding.descTv.setText(getString(R.string.sticker_count, data.size()));
                adapter.notifyDataSetChanged();
            }

            @Override
            public void onError(String error) {
                WKToastUtils.getInstance().showToastNormal(error);
            }
        });
    }

    @Override
    protected void initListener() {
        SingleClickUtil.onSingleClick(wkVBinding.addBtn, v -> {
            if (isAdded) {
                stickerService.removeCategory(categoryId);
                isAdded = false;
                updateAddButton();
                WKToastUtils.getInstance().showToastNormal(getString(R.string.sticker_removed));
            } else {
                StickerCategoryEntity category = new StickerCategoryEntity();
                category.categoryID = categoryId;
                category.name = categoryName;
                category.isAdded = true;
                stickerService.addCategory(category);
                isAdded = true;
                updateAddButton();
                WKToastUtils.getInstance().showToastNormal(getString(R.string.sticker_added));
            }
        });

        adapter.setOnItemClickListener(position -> {
            StickerEntity sticker = stickerList.get(position);
            // Navigate to StickerDetailActivity for preview
            android.content.Intent intent = new android.content.Intent(this, StickerDetailActivity.class);
            intent.putExtra(StickerDetailActivity.KEY_STICKER_ID, sticker.stickerID);
            intent.putExtra(StickerDetailActivity.KEY_STICKER_URL, sticker.url);
            intent.putExtra(StickerDetailActivity.KEY_STICKER_NAME, sticker.name);
            intent.putExtra(StickerDetailActivity.KEY_CATEGORY_ID, sticker.categoryID);
            startActivity(intent);
        });
    }

    private void updateAddButton() {
        if (isAdded) {
            wkVBinding.addBtn.setText(R.string.str_sticker_added);
            wkVBinding.addBtn.setAlpha(0.6f);
        } else {
            wkVBinding.addBtn.setText(R.string.str_sticker_add);
            wkVBinding.addBtn.setAlpha(1.0f);
        }
    }
}
