package com.chat.uikit.fragment;

import android.content.Intent;
import android.text.TextUtils;

import com.chat.base.base.WKBaseFragment;
import com.chat.base.common.WKCommonModel;
import com.chat.base.config.WKConfig;
import com.chat.base.endpoint.entity.PersonalInfoMenu;
import com.chat.base.entity.UserInfoEntity;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.ui.Theme;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.FragMyLayoutBinding;
import com.chat.uikit.setting.SettingActivity;
import com.chat.uikit.user.MyInfoActivity;
import com.chat.uikit.user.UserQrActivity;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.ArrayList;
import java.util.List;

/**
 * 2019-11-12 14:58
 * 我的
 */
public class MyFragment extends WKBaseFragment<FragMyLayoutBinding> {
    private PersonalItemAdapter adapter;

    @Override
    protected FragMyLayoutBinding getViewBinding() {
        return FragMyLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void initView() {
        wkVBinding.recyclerView.setNestedScrollingEnabled(false);
        adapter = new PersonalItemAdapter(new ArrayList<>());
        initAdapter(wkVBinding.recyclerView, adapter);
        // 构造菜单项：我的笔记、我的收藏、设置
        List<PersonalInfoMenu> menuList = new ArrayList<>();
        // 我的笔记
        menuList.add(new PersonalInfoMenu(R.drawable.ic_mine_note, "我的笔记", () -> {
            if (getActivity() != null && !getActivity().isFinishing()) {
                Intent intent = new Intent(getActivity(), com.chat.uikit.note.NoteListActivity.class);
                startActivity(intent);
            }
        }));
        // 我的收藏
        menuList.add(new PersonalInfoMenu(R.drawable.ic_mine_favorite, getString(R.string.favorite), () -> {
            if (getActivity() != null && !getActivity().isFinishing()) {
                Intent intent = new Intent(getActivity(), com.chat.uikit.favorite.FavoriteActivity.class);
                startActivity(intent);
            }
        }));
        // 设置
        menuList.add(new PersonalInfoMenu(R.drawable.icon_setting, getString(R.string.setting), () -> {
            if (getActivity() != null && !getActivity().isFinishing()) {
                Intent intent = new Intent(getActivity(), SettingActivity.class);
                startActivity(intent);
            }
        }));
        adapter.setList(menuList);
    }

    @Override
    protected void initPresenter() {
        wkVBinding.avatarView.setSize(90);
        wkVBinding.refreshLayout.setEnableOverScrollDrag(true);
        wkVBinding.refreshLayout.setEnableLoadMore(false);
        wkVBinding.refreshLayout.setEnableRefresh(false);
        Theme.setPressedBackground(wkVBinding.qrIv);
    }

    @Override
    protected void initListener() {
        adapter.setOnItemClickListener((adapter1, view, position) -> SingleClickUtil.determineTriggerSingleClick(view, view1 -> {
            PersonalInfoMenu menu = (PersonalInfoMenu) adapter1.getItem(position);
            if (menu != null && menu.iPersonalInfoMenuClick != null) {
                menu.iPersonalInfoMenuClick.onClick();
            }
        }));
        SingleClickUtil.onSingleClick(wkVBinding.avatarView, view -> gotoMyInfo());
        SingleClickUtil.onSingleClick(wkVBinding.qrIv, view -> {
            if (getActivity() != null && !getActivity().isFinishing()) {
                startActivity(new Intent(getActivity(), UserQrActivity.class));
            }
        });
    }

    void gotoMyInfo() {
        if (getActivity() != null && !getActivity().isFinishing()) {
            startActivity(new Intent(getActivity(), MyInfoActivity.class));
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        var userInfo = WKConfig.getInstance().getUserInfo();
        if (userInfo != null && !TextUtils.isEmpty(userInfo.name)) {
            wkVBinding.nameTv.setText(userInfo.name);
        } else {
            wkVBinding.nameTv.setText("");
        }
        if (userInfo != null && !TextUtils.isEmpty(userInfo.short_no) && isValidShortNo(userInfo.short_no)) {
            String idLabel = String.format(getString(R.string.app_idnum), getString(R.string.app_name));
            wkVBinding.nameFay.setText(idLabel + userInfo.short_no);
        } else {
            wkVBinding.nameFay.setText("");
            fetchShortNo();
        }
        String uid = WKConfig.getInstance().getUid();
        if (!TextUtils.isEmpty(uid)) {
            wkVBinding.avatarView.showAvatar(uid, WKChannelType.PERSONAL);
        }
    }

    private void fetchShortNo() {
        WKCommonModel.getInstance().getChannel(WKConfig.getInstance().getUid(), WKChannelType.PERSONAL, (code, msg, entity) -> {
            if (entity != null && entity.extra != null) {
                Object shortNoObject = entity.extra.get("short_no");
                if (shortNoObject != null) {
                    String shortNo = (String) shortNoObject;
                    if (!TextUtils.isEmpty(shortNo) && isValidShortNo(shortNo)) {
                        UserInfoEntity userInfoEntity = WKConfig.getInstance().getUserInfo();
                        if (userInfoEntity != null) {
                            userInfoEntity.short_no = shortNo;
                            WKConfig.getInstance().saveUserInfo(userInfoEntity);
                        }
                        if (getActivity() != null && !getActivity().isFinishing()) {
                            String idLabel = String.format(getString(R.string.app_idnum), getString(R.string.app_name));
                            wkVBinding.nameFay.setText(idLabel + shortNo);
                        }
                    }
                }
            }
        });
    }

    /**
     * 验证short_no格式是否正确（10位大写字母+数字，不含易混淆字符O/0/I/1）
     */
    private boolean isValidShortNo(String shortNo) {
        if (TextUtils.isEmpty(shortNo) || shortNo.length() != 10) {
            return false;
        }
        String validChars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        for (int i = 0; i < shortNo.length(); i++) {
            if (validChars.indexOf(shortNo.charAt(i)) == -1) {
                return false;
            }
        }
        return true;
    }
}
