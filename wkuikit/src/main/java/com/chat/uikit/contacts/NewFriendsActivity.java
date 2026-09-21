package com.chat.uikit.contacts;

import android.content.Intent;
import android.widget.ImageView;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKConfig;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.db.ApplyDB;
import com.chat.base.entity.NewFriendEntity;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.contacts.service.FriendModel;
import com.chat.uikit.databinding.ActCommonListLayoutBinding;
import com.chat.uikit.db.WKContactsDB;
import com.chat.uikit.group.service.GroupModel;
import com.chat.uikit.search.AddFriendsActivity;
import com.chat.uikit.user.UserDetailActivity;

import java.util.ArrayList;
import java.util.List;

/**
 * 2019-11-30 11:50
 * 新朋友
 */
public class NewFriendsActivity extends WKBaseActivity<ActCommonListLayoutBinding> {
    private NewFriendAdapter adapter;

    @Override
    protected ActCommonListLayoutBinding getViewBinding() {
        return ActCommonListLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(getString(R.string.new_friends));
    }

    @Override
    protected void initPresenter() {

    }

    @Override
    protected void initView() {
        adapter = new NewFriendAdapter(new ArrayList<>(), item -> {
            ApplyDB.getInstance().delete(item.apply_uid);
            for (int i = 0; i < adapter.getData().size(); i++) {
                if (adapter.getData().get(i).apply_uid.equals(item.apply_uid)) {
                    adapter.removeAt(i);
                    break;
                }
            }
        });
        adapter.setOnItemClickListener((adapter1, view1, position) -> SingleClickUtil.determineTriggerSingleClick(view1, view2 -> {
            NewFriendEntity entity = (NewFriendEntity) adapter1.getData().get(position);
            if (entity != null && entity.status == 1) {
                Intent intent = new Intent(this, UserDetailActivity.class);
                intent.putExtra("uid", entity.apply_uid);
                startActivity(intent);
            }
        }));
        initAdapter(wkVBinding.recyclerView, adapter);
        WKSharedPreferencesUtil.getInstance().putInt(WKConfig.getInstance().getUid() + "_new_friend_count", 0);
    }

    @Override
    protected int getRightIvResourceId(ImageView imageView) {
        return R.mipmap.menu_invite;
    }

    @Override
    protected void rightLayoutClick() {
        super.rightLayoutClick();
        Intent intent = new Intent(this, AddFriendsActivity.class);
        startActivity(intent);
    }

    @Override
    protected void initListener() {
        adapter.addChildClickViewIds(R.id.agreeBtn, R.id.rejectBtn);
        adapter.setOnItemChildClickListener((adapter1, view1, position) -> {
            NewFriendEntity newFriendEntity = (NewFriendEntity) adapter1.getItem(position);
            if (newFriendEntity != null) {
                if (view1.getId() == R.id.agreeBtn) {
                    if (newFriendEntity.type == 1) {
                        // 入群申请 - 通过
                        GroupModel.getInstance().approveGroupApply(newFriendEntity.group_no, newFriendEntity.apply_uid, newFriendEntity.token, (code, msg) -> {
                            if (code == HttpResponseCode.success) {
                                newFriendEntity.status = 1;
                                adapter1.notifyItemChanged(position);
                                ApplyDB.getInstance().update(newFriendEntity);
                            }
                        });
                    } else {
                        // 好友申请 - 通过
                        FriendModel.getInstance().agreeFriendApply(newFriendEntity.token, (code, msg) -> {
                            if (code == HttpResponseCode.success) {
                                FriendModel.getInstance().syncFriends(null);
                                newFriendEntity.status = 1;
                                adapter1.notifyItemChanged(position);
                                ApplyDB.getInstance().update(newFriendEntity);
                                WKContactsDB.getInstance().updateFriendStatus(newFriendEntity.apply_uid, 1);
                            }
                        });
                    }
                } else if (view1.getId() == R.id.rejectBtn) {
                    // 拒绝入群申请
                    WKDialogUtils.getInstance().showInputDialog(this, getString(R.string.reject_apply),
                            "", "", getString(R.string.reject_remark_hint), 100,
                            text -> GroupModel.getInstance().rejectGroupApply(newFriendEntity.group_no, newFriendEntity.apply_uid, newFriendEntity.token, text, (code, msg) -> {
                                if (code == HttpResponseCode.success) {
                                    newFriendEntity.status = 2;
                                    adapter1.notifyItemChanged(position);
                                    ApplyDB.getInstance().update(newFriendEntity);
                                }
                            }));
                }
            }
        });
    }

    @Override
    protected void initData() {
        super.initData();
        List<NewFriendEntity> list = ApplyDB.getInstance().queryAll();
        adapter.setList(list);
    }
}
