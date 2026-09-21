package com.chat.uikit.location;

import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;

import com.amap.api.services.core.PoiItem;
import com.chad.library.adapter.base.BaseQuickAdapter;
import com.chad.library.adapter.base.viewholder.BaseViewHolder;
import com.chat.uikit.R;

public class PoiAdapter extends BaseQuickAdapter<PoiItem, PoiAdapter.PoiViewHolder> {

    public PoiAdapter() {
        super(R.layout.item_poi_layout);
    }

    @Override
    protected void convert(@NonNull PoiViewHolder holder, PoiItem item) {
        holder.nameTv.setText(item.getTitle());
        String address = TextUtils.isEmpty(item.getSnippet()) ? item.getCityName() : item.getSnippet();
        if (TextUtils.isEmpty(address)) {
            holder.addressTv.setVisibility(View.GONE);
        } else {
            holder.addressTv.setVisibility(View.VISIBLE);
            holder.addressTv.setText(address);
        }
    }

    static class PoiViewHolder extends BaseViewHolder {
        TextView nameTv;
        TextView addressTv;

        public PoiViewHolder(@NonNull View itemView) {
            super(itemView);
            nameTv = itemView.findViewById(R.id.poiNameTv);
            addressTv = itemView.findViewById(R.id.poiAddressTv);
        }
    }
}
