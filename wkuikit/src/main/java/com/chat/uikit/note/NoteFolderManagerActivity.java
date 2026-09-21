package com.chat.uikit.note;

import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActNoteFolderManagerLayoutBinding;

import org.json.JSONArray;
import org.json.JSONException;

import java.util.ArrayList;
import java.util.List;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

/**
 * 笔记分组管理页面
 */
public class NoteFolderManagerActivity extends WKBaseActivity<ActNoteFolderManagerLayoutBinding> {

    private static final String SP_KEY_FOLDERS = "note_folders";
    private List<String> folderList = new ArrayList<>();
    private FolderAdapter adapter;

    @Override
    protected ActNoteFolderManagerLayoutBinding getViewBinding() {
        return ActNoteFolderManagerLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        // 使用自定义标题栏
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        // 适配状态栏高度（灵动岛/刘海屏）
        initStatusBarPadding();

        LinearLayoutManager layoutManager = new LinearLayoutManager(this);
        wkVBinding.folderRv.setLayoutManager(layoutManager);
        adapter = new FolderAdapter(folderList);
        wkVBinding.folderRv.setAdapter(adapter);

        loadFolders();
    }

    /**
     * 适配状态栏高度，避免标题栏被灵动岛/刘海遮挡
     */
    private void initStatusBarPadding() {
        int statusBarHeight = 0;
        int resourceId = getResources().getIdentifier("status_bar_height", "dimen", "android");
        if (resourceId > 0) {
            statusBarHeight = getResources().getDimensionPixelSize(resourceId);
        }
        if (statusBarHeight < dp2px(24)) {
            statusBarHeight = dp2px(24);
        }
        androidx.constraintlayout.widget.ConstraintLayout.LayoutParams params =
                (androidx.constraintlayout.widget.ConstraintLayout.LayoutParams) wkVBinding.titleLayout.getLayoutParams();
        params.topMargin = statusBarHeight;
        wkVBinding.titleLayout.setLayoutParams(params);
    }

    private int dp2px(float dp) {
        return (int) (dp * getResources().getDisplayMetrics().density + 0.5f);
    }

    @Override
    protected void initListener() {
        // 返回按钮
        wkVBinding.backIv.setOnClickListener(v -> {
            finish();
            overridePendingTransition(R.anim.in_left, R.anim.out_right);
        });

        // 保存按钮
        wkVBinding.saveBtn.setOnClickListener(v -> {
            WKToastUtils.getInstance().showToastNormal("已保存");
            finish();
            overridePendingTransition(R.anim.in_left, R.anim.out_right);
        });

        // 新建分组
        wkVBinding.addFolderTv.setOnClickListener(v -> showAddFolderDialog());

        adapter.setOnItemClickListener(position -> showRenameDialog(position));
        adapter.setOnDeleteClickListener(position -> showDeleteDialog(position));
    }

    private void loadFolders() {
        folderList.clear();
        folderList.add("全部");
        folderList.add("未分组");

        String json = WKSharedPreferencesUtil.getInstance().getSP(SP_KEY_FOLDERS);
        if (json != null && !json.isEmpty()) {
            try {
                JSONArray array = new JSONArray(json);
                for (int i = 0; i < array.length(); i++) {
                    String name = array.getString(i);
                    if (!folderList.contains(name)) {
                        folderList.add(name);
                    }
                }
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }

        if (folderList.size() <= 2) {
            folderList.add("工作");
            folderList.add("生活");
            folderList.add("学习");
            folderList.add("旅行");
            saveFolders();
        }

        adapter.notifyDataSetChanged();
    }

    private void saveFolders() {
        JSONArray array = new JSONArray();
        for (int i = 2; i < folderList.size(); i++) {
            array.put(folderList.get(i));
        }
        WKSharedPreferencesUtil.getInstance().putSP(SP_KEY_FOLDERS, array.toString());
    }

    private void showAddFolderDialog() {
        WKDialogUtils.getInstance().showInputDialog(this, "新增分组", "请输入分组名称",
                "", "分组名称", 20, text -> {
                    if (TextUtils.isEmpty(text)) {
                        WKToastUtils.getInstance().showToastNormal("请输入分组名称");
                        return;
                    }
                    if (folderList.contains(text)) {
                        WKToastUtils.getInstance().showToastNormal("分组已存在");
                        return;
                    }
                    folderList.add(text);
                    saveFolders();
                    adapter.notifyItemInserted(folderList.size() - 1);
                    WKToastUtils.getInstance().showToastNormal("添加成功");
                });
    }

    private void showRenameDialog(int position) {
        if (position < 2) {
            WKToastUtils.getInstance().showToastNormal("默认分组不可重命名");
            return;
        }
        String oldName = folderList.get(position);
        WKDialogUtils.getInstance().showInputDialog(this, "重命名分组", "请输入新的分组名称",
                oldName, "分组名称", 20, text -> {
                    if (TextUtils.isEmpty(text)) {
                        WKToastUtils.getInstance().showToastNormal("请输入分组名称");
                        return;
                    }
                    if (!text.equals(oldName) && folderList.contains(text)) {
                        WKToastUtils.getInstance().showToastNormal("分组已存在");
                        return;
                    }
                    folderList.set(position, text);
                    saveFolders();
                    adapter.notifyItemChanged(position);
                    WKToastUtils.getInstance().showToastNormal("重命名成功");
                });
    }

    private void showDeleteDialog(int position) {
        if (position < 2) {
            WKToastUtils.getInstance().showToastNormal("默认分组不可删除");
            return;
        }
        WKDialogUtils.getInstance().showDialog(this, "删除分组",
                "删除分组后，组内笔记将移至未分组。确定删除？",
                true, "取消", "删除", 0, 0, index -> {
                    if (index == 1) {
                        folderList.remove(position);
                        saveFolders();
                        adapter.notifyItemRemoved(position);
                        WKToastUtils.getInstance().showToastNormal("已删除");
                    }
                });
    }

    private static class FolderAdapter extends RecyclerView.Adapter<FolderAdapter.ViewHolder> {
        private List<String> list;
        private OnItemClickListener listener;
        private OnDeleteClickListener deleteListener;

        interface OnItemClickListener {
            void onItemClick(int position);
        }

        interface OnDeleteClickListener {
            void onDeleteClick(int position);
        }

        void setOnItemClickListener(OnItemClickListener listener) {
            this.listener = listener;
        }

        void setOnDeleteClickListener(OnDeleteClickListener listener) {
            this.deleteListener = listener;
        }

        FolderAdapter(List<String> list) {
            this.list = list;
        }

        @NonNull
        @Override
        public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
            View view = LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.item_note_folder_manager, parent, false);
            return new ViewHolder(view);
        }

        @Override
        public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
            String name = list.get(position);
            holder.nameTv.setText(name);

            if (position < 2) {
                holder.deleteIv.setVisibility(View.GONE);
                holder.editIv.setVisibility(View.GONE);
            } else {
                holder.deleteIv.setVisibility(View.VISIBLE);
                holder.editIv.setVisibility(View.VISIBLE);
            }

            holder.itemView.setOnClickListener(v -> {
                if (listener != null) listener.onItemClick(holder.getBindingAdapterPosition());
            });
            holder.deleteIv.setOnClickListener(v -> {
                if (deleteListener != null) deleteListener.onDeleteClick(holder.getBindingAdapterPosition());
            });
            holder.editIv.setOnClickListener(v -> {
                if (listener != null) listener.onItemClick(holder.getBindingAdapterPosition());
            });
        }

        @Override
        public int getItemCount() {
            return list.size();
        }

        static class ViewHolder extends RecyclerView.ViewHolder {
            TextView nameTv;
            View deleteIv;
            View editIv;

            ViewHolder(View itemView) {
                super(itemView);
                nameTv = itemView.findViewById(R.id.nameTv);
                deleteIv = itemView.findViewById(R.id.deleteIv);
                editIv = itemView.findViewById(R.id.editIv);
            }
        }
    }
}
