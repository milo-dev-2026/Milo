package com.chat.uikit.sticker;

import android.content.Intent;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActMyStickerLayoutBinding;

import java.util.ArrayList;
import java.util.List;

import androidx.recyclerview.widget.LinearLayoutManager;

public class MyStickerActivity extends WKBaseActivity<ActMyStickerLayoutBinding> {

    private List<StickerCategoryEntity> myStickerList = new ArrayList<>();
    private MyStickerAdapter adapter;
    private StickerService stickerService;

    @Override
    protected ActMyStickerLayoutBinding getViewBinding() {
        return ActMyStickerLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.str_my_sticker);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        stickerService = StickerService.getInstance();

        LinearLayoutManager layoutManager = new LinearLayoutManager(this);
        wkVBinding.recyclerView.setLayoutManager(layoutManager);

        loadMyStickers();

        adapter = new MyStickerAdapter(myStickerList);
        wkVBinding.recyclerView.setAdapter(adapter);
    }

    @Override
    protected void initListener() {
        adapter.setOnItemClickListener(position -> {
            StickerCategoryEntity item = myStickerList.get(position);
            Intent intent = new Intent(MyStickerActivity.this, StickerStoreDetailActivity.class);
            intent.putExtra(StickerStoreDetailActivity.KEY_CATEGORY_ID, item.categoryID);
            intent.putExtra(StickerStoreDetailActivity.KEY_CATEGORY_NAME, item.name);
            startActivity(intent);
        });

        adapter.setOnRemoveListener(position -> {
            StickerCategoryEntity removed = myStickerList.get(position);
            stickerService.removeCategory(removed.categoryID);
            myStickerList.remove(position);
            adapter.notifyItemRemoved(position);
            WKToastUtils.getInstance().showToastNormal(getString(R.string.sticker_removed));
        });

        SingleClickUtil.onSingleClick(wkVBinding.reorderBtn, v -> {
            startActivity(new Intent(MyStickerActivity.this, StickerReorderActivity.class));
        });

        SingleClickUtil.onSingleClick(wkVBinding.addCustomBtn, v -> {
            startActivity(new Intent(MyStickerActivity.this, CustomStickerActivity.class));
        });
    }

    @Override
    protected void onResume() {
        super.onResume();
        loadMyStickers();
        if (adapter != null) {
            adapter.notifyDataSetChanged();
        }
    }

    private void loadMyStickers() {
        myStickerList.clear();
        myStickerList.addAll(stickerService.getMyCategories());

        List<StickerEntity> customStickers = stickerService.getMyStickers();
        for (StickerEntity s : customStickers) {
            if (s.isCustom) {
                StickerCategoryEntity category = new StickerCategoryEntity();
                category.categoryID = s.stickerID;
                category.name = s.name != null ? s.name : getString(R.string.custom_sticker_name);
                category.desc = getString(R.string.custom_sticker_desc);
                category.isCustom = true;
                category.isAdded = true;
                myStickerList.add(category);
            }
        }

        if (adapter != null) {
            adapter.notifyDataSetChanged();
        }
    }
}
