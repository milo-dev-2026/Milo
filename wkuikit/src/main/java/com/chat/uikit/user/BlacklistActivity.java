package com.chat.uikit.user;

import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActBlackListLayoutBinding;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

public class BlacklistActivity extends WKBaseActivity<ActBlackListLayoutBinding> {

    private static final String SP_KEY_BLACKLIST = "blacklist_users";

    private List<BlackUser> userList = new ArrayList<>();
    private BlacklistAdapter adapter;

    @Override
    protected ActBlackListLayoutBinding getViewBinding() {
        return ActBlackListLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.blacklist);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        wkVBinding.recyclerView.setLayoutManager(new LinearLayoutManager(this));
        adapter = new BlacklistAdapter(userList);
        wkVBinding.recyclerView.setAdapter(adapter);
        loadBlacklist();
    }

    @Override
    protected void initListener() {
        adapter.setOnRemoveClickListener(position -> {
            BlackUser user = userList.get(position);
            userList.remove(position);
            saveBlacklist();
            adapter.notifyItemRemoved(position);
            WKToastUtils.getInstance().showToastNormal("已移除" + user.name);
            updateView();
        });
    }

    private void loadBlacklist() {
        userList.clear();
        String json = WKSharedPreferencesUtil.getInstance().getSP(SP_KEY_BLACKLIST);
        if (!TextUtils.isEmpty(json)) {
            try {
                JSONArray array = new JSONArray(json);
                for (int i = 0; i < array.length(); i++) {
                    JSONObject obj = array.getJSONObject(i);
                    userList.add(new BlackUser(
                            obj.optString("uid"),
                            obj.optString("name"),
                            obj.optString("avatar")
                    ));
                }
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        adapter.notifyDataSetChanged();
        updateView();
    }

    private void saveBlacklist() {
        JSONArray array = new JSONArray();
        for (BlackUser user : userList) {
            JSONObject obj = new JSONObject();
            try {
                obj.put("uid", user.uid);
                obj.put("name", user.name);
                obj.put("avatar", user.avatar != null ? user.avatar : "");
                array.put(obj);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        WKSharedPreferencesUtil.getInstance().putSP(SP_KEY_BLACKLIST, array.toString());
    }

    private void updateView() {
        int count = userList.size();
        wkVBinding.blockedCountTv.setText(getString(R.string.blocked_count_format, count));
        if (count == 0) {
            wkVBinding.recyclerView.setVisibility(View.GONE);
            wkVBinding.emptyLayout.setVisibility(View.VISIBLE);
        } else {
            wkVBinding.recyclerView.setVisibility(View.VISIBLE);
            wkVBinding.emptyLayout.setVisibility(View.GONE);
        }
    }

    public static class BlackUser {
        public String uid;
        public String name;
        public String avatar;

        public BlackUser(String uid, String name, String avatar) {
            this.uid = uid;
            this.name = name;
            this.avatar = avatar;
        }
    }

    private static class BlacklistAdapter extends RecyclerView.Adapter<BlacklistAdapter.ViewHolder> {

        private final List<BlackUser> list;
        private OnRemoveClickListener listener;

        interface OnRemoveClickListener {
            void onRemoveClick(int position);
        }

        void setOnRemoveClickListener(OnRemoveClickListener listener) {
            this.listener = listener;
        }

        BlacklistAdapter(List<BlackUser> list) {
            this.list = list;
        }

        @NonNull
        @Override
        public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
            View view = LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.item_blacklist_user, parent, false);
            return new ViewHolder(view);
        }

        @Override
        public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
            BlackUser user = list.get(position);
            holder.nameTv.setText(user.name);
            holder.uidTv.setText("ID: " + user.uid);
            holder.removeBtn.setOnClickListener(v -> {
                if (listener != null) {
                    listener.onRemoveClick(holder.getBindingAdapterPosition());
                }
            });
        }

        @Override
        public int getItemCount() {
            return list.size();
        }

        static class ViewHolder extends RecyclerView.ViewHolder {
            ImageView avatarIv;
            TextView nameTv;
            TextView uidTv;
            TextView removeBtn;

            ViewHolder(View itemView) {
                super(itemView);
                avatarIv = itemView.findViewById(R.id.avatarIv);
                nameTv = itemView.findViewById(R.id.nameTv);
                uidTv = itemView.findViewById(R.id.uidTv);
                removeBtn = itemView.findViewById(R.id.removeBtn);
            }
        }
    }
}
