package com.chat.uikit.contacts

import android.text.TextUtils
import android.view.View
import androidx.core.content.ContextCompat
import com.chad.library.adapter.base.BaseQuickAdapter
import com.chad.library.adapter.base.viewholder.BaseViewHolder
import com.chat.base.ui.Theme
import com.chat.base.ui.components.AvatarView
import com.chat.base.ui.components.CheckBoxContacts
import com.chat.base.utils.AndroidUtilities
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
        holder.setText(
            R.id.nameTv,
            if (TextUtils.isEmpty(item.channel.channelRemark)) item.channel.channelName else item.channel.channelRemark
        )
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
