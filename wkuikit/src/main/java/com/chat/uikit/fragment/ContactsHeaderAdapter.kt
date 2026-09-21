package com.chat.uikit.fragment

import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.View
import android.widget.LinearLayout
import androidx.core.content.ContextCompat
import com.chad.library.adapter.base.BaseQuickAdapter
import com.chad.library.adapter.base.viewholder.BaseViewHolder
import com.chat.base.endpoint.entity.ContactsMenu
import com.chat.base.ui.Theme
import com.chat.base.ui.components.CounterView
import com.chat.base.utils.LayoutHelper
import com.chat.uikit.R

class ContactsHeaderAdapter :
    BaseQuickAdapter<ContactsMenu, BaseViewHolder>(R.layout.item_contacts_header_layout) {

    private val iconBgColors = mapOf(
        "friend" to Color.parseColor("#FF6B7B"),
        "group" to Color.parseColor("#5B8DEF"),
        "joined_group" to Color.parseColor("#26A69A"),
        "system_notice" to Color.parseColor("#FFA940"),
        "file_helper" to Color.parseColor("#4CAF50")
    )

    override fun convert(holder: BaseViewHolder, item: ContactsMenu) {
        holder.setImageResource(R.id.imageView, item.imgResourceID)
        holder.setText(R.id.nameTv, item.text)

        val imageView = holder.getView<androidx.appcompat.widget.AppCompatImageView>(R.id.imageView)
        val bgDrawable = imageView.background
        if (bgDrawable is GradientDrawable) {
            val color = iconBgColors[item.sid] ?: Color.parseColor("#5B8DEF")
            bgDrawable.setColor(color)
        }

        val categoryLayout: LinearLayout = holder.getView(R.id.categoryLayout)
        categoryLayout.removeAllViews()
        when (item.sid) {
            "file_helper", "system_notice" -> {
                categoryLayout.addView(
                    Theme.getChannelCategoryTV(
                        context,
                        context.getString(R.string.official),
                        ContextCompat.getColor(context, R.color.transparent),
                        ContextCompat.getColor(context, R.color.reminderColor),
                        ContextCompat.getColor(context, R.color.reminderColor)
                    ),
                    LayoutHelper.createLinear(
                        LayoutHelper.WRAP_CONTENT,
                        LayoutHelper.WRAP_CONTENT,
                        Gravity.CENTER,
                        0,
                        0,
                        5,
                        0
                    )
                )
                if (item.sid == "system_notice") {
                    categoryLayout.addView(
                        Theme.getChannelCategoryTV(
                            context,
                            context.getString(R.string.bot),
                            ContextCompat.getColor(context, R.color.color_main),
                            ContextCompat.getColor(context, R.color.white),
                            ContextCompat.getColor(context, R.color.color_main)
                        ),
                        LayoutHelper.createLinear(
                            LayoutHelper.WRAP_CONTENT,
                            LayoutHelper.WRAP_CONTENT,
                            Gravity.CENTER,
                            0,
                            0,
                            0,
                            0
                        )
                    )
                }
            }
        }

        val msgCountTv: CounterView = holder.getView(R.id.msgCountTv)
        msgCountTv.setColors(R.color.white, R.color.reminderColor)
        msgCountTv.setCount(item.badgeNum, true)
        msgCountTv.visibility = if (item.badgeNum > 0) View.VISIBLE else View.GONE

        holder.setGone(R.id.endView, holder.bindingAdapterPosition != data.size - 1)
    }
}
