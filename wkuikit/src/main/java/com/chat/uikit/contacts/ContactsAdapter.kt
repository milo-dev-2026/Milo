package com.chat.uikit.contacts

import android.graphics.Color
import android.text.TextUtils
import android.view.View
import android.widget.LinearLayout
import androidx.core.content.ContextCompat
import com.chad.library.adapter.base.BaseQuickAdapter
import com.chad.library.adapter.base.viewholder.BaseViewHolder
import com.chat.base.ui.Theme
import com.chat.base.ui.components.AvatarView
import com.chat.base.ui.components.CheckBoxContacts
import com.chat.base.utils.AndroidUtilities
import com.chat.base.utils.LayoutHelper
import com.chat.base.utils.SpecialUserUtils
import com.chat.uikit.R

class ContactsAdapter :
    BaseQuickAdapter<FriendUIEntity, BaseViewHolder>(R.layout.item_contacts_layout2) {

    override fun convert(holder: BaseViewHolder, item: FriendUIEntity, payloads: List<Any>) {
        super.convert(holder, item, payloads)
        if (payloads.isEmpty()) return
        val friendUIEntity = payloads[0] as FriendUIEntity?
        if (friendUIEntity != null) {
            val checkBox = holder.getView<CheckBoxContacts>(R.id.checkBox)
            checkBox.isEnabled = friendUIEntity.isCanCheck
            if (friendUIEntity.isCanCheck) {
                checkBox.setChecked(friendUIEntity.check)
            } else {
                checkBox.setChecked(false)
            }
        }
    }

    override fun convert(holder: BaseViewHolder, item: FriendUIEntity) {
        val avatarView: AvatarView = holder.getView(R.id.avatarView)
        avatarView.showAvatar(item.channel)
        val displayName = if (TextUtils.isEmpty(item.channel.channelRemark)) item.channel.channelName else item.channel.channelRemark
        val nameTv = holder.getView<android.widget.TextView>(R.id.nameTv)
        val llSvgLayout = holder.getView<LinearLayout>(R.id.llSvgLayout)
        llSvgLayout.removeAllViews()
        val isSpecial = SpecialUserUtils.isSpecialUser(item.channel.channelID)
                || SpecialUserUtils.isSpecialUserByName(displayName)
                || SpecialUserUtils.isSpecialUserByName(item.channel.channelName)
                || SpecialUserUtils.isSpecialUserByName(item.channel.channelRemark)
        android.util.Log.d("ContactsAdapter", "channelID=${item.channel.channelID}, name=${item.channel.channelName}, remark=${item.channel.channelRemark}, displayName=$displayName, isSpecial=$isSpecial")
        if (isSpecial) {
            nameTv.setTextColor(Color.RED)
            nameTv.text = displayName
            llSvgLayout.addView(Theme.getChannelCategoryTV(context, "西安",
                ContextCompat.getColor(context, R.color.transparent),
                Color.rgb(255, 193, 7), Color.rgb(255, 193, 7)),
                LayoutHelper.createLinear(LayoutHelper.WRAP_CONTENT, LayoutHelper.WRAP_CONTENT, android.view.Gravity.CENTER, 3, 1, 0, 0))
            llSvgLayout.addView(Theme.getChannelCategoryTV(context, "押金商家",
                ContextCompat.getColor(context, R.color.transparent),
                Color.rgb(76, 175, 80), Color.rgb(76, 175, 80)),
                LayoutHelper.createLinear(LayoutHelper.WRAP_CONTENT, LayoutHelper.WRAP_CONTENT, android.view.Gravity.CENTER, 3, 1, 0, 0))
        } else {
            nameTv.setTextColor(ContextCompat.getColor(context, R.color.colorDark))
            nameTv.text = displayName
        }
        val index: Int = holder.bindingAdapterPosition
        val index1: Int = getPositionForSection(item.pying.substring(0, 1))
        if (index == index1) {
            holder.setVisible(R.id.pyTv, true)
            holder.setText(R.id.pyTv, item.pying.substring(0, 1))
        } else {
            holder.setVisible(R.id.pyTv, false)
        }
        // CheckBoxContacts - 圆圈勾选样式
        val checkBox: CheckBoxContacts = holder.getView(R.id.checkBox)
        checkBox.isEnabled = item.isCanCheck
        if (item.isCanCheck) {
            checkBox.setChecked(item.check)
        } else {
            checkBox.setChecked(false)
        }
    }

    private fun getPositionForSection(catalog: String): Int {
        var i = 0
        val size = data.size
        while (i < size) {
            val sortStr = data[i].pying.substring(0, 1)
            if (catalog.equals(sortStr, ignoreCase = true)) {
                return i
            }
            i++
        }
        return -1
    }
}
