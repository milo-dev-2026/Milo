package com.chat.uikit.user;

import android.graphics.Bitmap;
import android.text.TextUtils;
import android.widget.ImageView;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKApiConfig;
import com.chat.base.config.WKConfig;
import com.chat.base.endpoint.EndpointManager;
import com.chat.base.entity.PopupMenuItem;
import com.chat.base.entity.UserInfoEntity;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.utils.ImageUtils;
import com.chat.base.utils.WKDialogUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActUserQrLayoutBinding;
import com.chat.uikit.user.service.UserModel;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.ArrayList;
import java.util.List;

/**
 * 2020-06-29 23:21
 * 个人二维码
 */
public class UserQrActivity extends WKBaseActivity<ActUserQrLayoutBinding> {

    @Override
    protected ActUserQrLayoutBinding getViewBinding() {
        return ActUserQrLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.my_qr);
    }

    @Override
    protected int getRightIvResourceId(ImageView imageView) {
        return R.mipmap.ic_ab_other;
    }

    @Override
    protected void rightLayoutClick() {
        super.rightLayoutClick();
        List<PopupMenuItem> list = new ArrayList<>();
        list.add(new PopupMenuItem(getString(R.string.save_img), R.mipmap.msg_download, () -> {
            Bitmap bitmap = ImageUtils.getInstance().loadBitmapFromView(wkVBinding.shadowLayout);
            if (bitmap != null) {
                ImageUtils.getInstance().saveBitmap(UserQrActivity.this, bitmap, true, path -> showToast(R.string.saved_album));
            }
        }));
        ImageView rightIV = findViewById(R.id.titleRightIv);
        if (rightIV != null) {
            WKDialogUtils.getInstance().showScreenPopup(rightIV, list);
        }

    }


    @Override
    protected void initView() {
        wkVBinding.qrDescTv.setText(String.format(getString(R.string.qr_desc), getString(R.string.app_name)));
        wkVBinding.nameTv.setText(WKConfig.getInstance().getUserName());
        wkVBinding.avatarView.showAvatar(WKConfig.getInstance().getUid(), WKChannelType.PERSONAL);

        wkVBinding.appIdNumLeftTv.setText(String.format(getString(R.string.app_idnum), getString(R.string.app_name)));

        String shortNo = WKConfig.getInstance().getUserInfo() != null ? WKConfig.getInstance().getUserInfo().short_no : null;
        if (!TextUtils.isEmpty(shortNo) && isValidShortNo(shortNo)) {
            wkVBinding.appIdNumTv.setText(shortNo);
        }
        fetchShortNo();
        fetchQrUrl();
    }

    private void fetchShortNo() {
        UserModel.getInstance().userQr((code, msg, userQr) -> {
            if (code == HttpResponseCode.success && userQr != null && !TextUtils.isEmpty(userQr.data)) {
                String shortNo = userQr.data;
                if (isValidShortNo(shortNo)) {
                    UserInfoEntity userInfoEntity = WKConfig.getInstance().getUserInfo();
                    if (userInfoEntity != null) {
                        userInfoEntity.short_no = shortNo;
                        WKConfig.getInstance().saveUserInfo(userInfoEntity);
                    }
                    wkVBinding.appIdNumTv.setText(shortNo);
                }
            }
        });
    }

    private void fetchQrUrl() {
        UserModel.getInstance().userQrUrl((code, msg, userQr) -> {
            if (code == HttpResponseCode.success && userQr != null && !TextUtils.isEmpty(userQr.data)) {
                String qrContent = userQr.data;
                Bitmap mBitmap = (Bitmap) EndpointManager.getInstance().invoke("create_qrcode", qrContent);
                if (mBitmap != null) {
                    wkVBinding.qrIv.setImageBitmap(mBitmap);
                }
            } else {
                String shortNo = WKConfig.getInstance().getUserInfo() != null ? WKConfig.getInstance().getUserInfo().short_no : null;
                if (!TextUtils.isEmpty(shortNo) && isValidShortNo(shortNo)) {
                    String qrContent = WKApiConfig.baseUrl + "qrcode/" + shortNo;
                    Bitmap mBitmap = (Bitmap) EndpointManager.getInstance().invoke("create_qrcode", qrContent);
                    if (mBitmap != null) {
                        wkVBinding.qrIv.setImageBitmap(mBitmap);
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

    @Override
    protected void initListener() {
        wkVBinding.saveImage.setOnClickListener(v -> {
            Bitmap bitmap = ImageUtils.getInstance().loadBitmapFromView(wkVBinding.shadowLayout);
            if (bitmap != null) {
                ImageUtils.getInstance().saveBitmap(UserQrActivity.this, bitmap, true, path -> showToast(R.string.saved_album));
            }
        });
    }
}
