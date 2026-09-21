package com.chat.base.kotlin.view

import android.content.Context
import android.graphics.Color
import android.util.AttributeSet
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.ImageView
import android.widget.RelativeLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import com.chat.base.R

class CustomTitleBar @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : RelativeLayout(context, attrs, defStyleAttr) {

    private val titleTv: TextView
    private val backIv: ImageView
    private val rightBtn1Iv: ImageView
    private val rightBtn2Iv: ImageView
    private val rightBtn3Tv: TextView
    private val leftIconIv: ImageView

    private var rightBtn1ClickListener: OnClickListener? = null
    private var rightBtn2ClickListener: OnClickListener? = null
    private var rightBtn3ClickListener: OnClickListener? = null
    private var backClickListener: OnClickListener? = null
    private var leftIconClickListener: OnClickListener? = null

    init {
        val density = resources.displayMetrics.density
        val height48 = (48 * density).toInt()

        // Back button
        backIv = ImageView(context).apply {
            id = generateViewId()
            setImageResource(R.mipmap.ic_ab_back)
            setColorFilter(Color.BLACK)
            visibility = GONE
            val padding = (12 * density).toInt()
            setPadding(padding, padding, padding, padding)
            setOnClickListener { backClickListener?.onClick(this) }
        }
        val backLp = LayoutParams(height48, height48)
        backLp.addRule(ALIGN_PARENT_START)
        backLp.addRule(CENTER_VERTICAL)
        addView(backIv, backLp)

        // Left icon
        leftIconIv = ImageView(context).apply {
            id = generateViewId()
            visibility = GONE
            val padding = (12 * density).toInt()
            setPadding(padding, padding, padding, padding)
            setOnClickListener { leftIconClickListener?.onClick(this) }
        }
        val leftIconLp = LayoutParams(height48, height48)
        leftIconLp.addRule(ALIGN_PARENT_START)
        leftIconLp.addRule(CENTER_VERTICAL)
        addView(leftIconIv, leftIconLp)

        // Right button 3 (text button, rightmost)
        rightBtn3Tv = TextView(context).apply {
            id = generateViewId()
            visibility = GONE
            textSize = 14f
            setTextColor(Color.BLACK)
            gravity = Gravity.CENTER
            val paddingH = (12 * density).toInt()
            setPadding(paddingH, 0, paddingH, 0)
            setOnClickListener { rightBtn3ClickListener?.onClick(this) }
        }
        val rightBtn3Lp = LayoutParams(LayoutParams.WRAP_CONTENT, height48)
        rightBtn3Lp.addRule(ALIGN_PARENT_END)
        rightBtn3Lp.addRule(CENTER_VERTICAL)
        addView(rightBtn3Tv, rightBtn3Lp)

        // Right button 2 (icon)
        rightBtn2Iv = ImageView(context).apply {
            id = generateViewId()
            visibility = GONE
            val padding = (12 * density).toInt()
            setPadding(padding, padding, padding, padding)
            setOnClickListener { rightBtn2ClickListener?.onClick(this) }
        }
        val rightBtn2Lp = LayoutParams(height48, height48)
        rightBtn2Lp.addRule(ALIGN_PARENT_END)
        rightBtn2Lp.addRule(CENTER_VERTICAL)
        addView(rightBtn2Iv, rightBtn2Lp)

        // Right button 1 (icon)
        rightBtn1Iv = ImageView(context).apply {
            id = generateViewId()
            visibility = GONE
            val padding = (12 * density).toInt()
            setPadding(padding, padding, padding, padding)
            setOnClickListener { rightBtn1ClickListener?.onClick(this) }
        }
        val rightBtn1Lp = LayoutParams(height48, height48)
        rightBtn1Lp.addRule(ALIGN_PARENT_END)
        rightBtn1Lp.addRule(CENTER_VERTICAL)
        addView(rightBtn1Iv, rightBtn1Lp)

        // Title text
        titleTv = TextView(context).apply {
            id = generateViewId()
            textSize = 17f
            setTextColor(Color.BLACK)
            gravity = Gravity.CENTER
            setSingleLine()
        }
        val titleLp = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT)
        titleLp.addRule(CENTER_IN_PARENT)
        addView(titleTv, titleLp)

        // Parse attributes
        if (attrs != null) {
            val ta = context.obtainStyledAttributes(attrs, R.styleable.CustomTitleBar)
            val titleText = ta.getString(R.styleable.CustomTitleBar_titleText)
            val titleTextColor = ta.getColor(R.styleable.CustomTitleBar_titleTextColor, Color.BLACK)
            val titleTextSize = ta.getDimension(R.styleable.CustomTitleBar_titleTextSize, 17f * density)
            val rightBtn1Visible = ta.getBoolean(R.styleable.CustomTitleBar_rightBtn1Visible, false)
            val rightBtn2Visible = ta.getBoolean(R.styleable.CustomTitleBar_rightBtn2Visible, false)
            val rightBtn3Visible = ta.getBoolean(R.styleable.CustomTitleBar_rightBtn3Visible, false)
            val rightBtn3Enabled = ta.getBoolean(R.styleable.CustomTitleBar_rightBtn3Enabled, true)
            val rightBtn1Icon = ta.getResourceId(R.styleable.CustomTitleBar_rightBtn1Icon, 0)
            val rightBtn2Icon = ta.getResourceId(R.styleable.CustomTitleBar_rightBtn2Icon, 0)
            val rightBtn1Text = ta.getString(R.styleable.CustomTitleBar_rightBtn1Text)
            val rightBtn2Text = ta.getString(R.styleable.CustomTitleBar_rightBtn2Text)
            val rightBtn3Text = ta.getString(R.styleable.CustomTitleBar_rightBtn3Text)
            val rightBtn1TextColor = ta.getColor(R.styleable.CustomTitleBar_rightBtn1TextColor, Color.BLACK)
            val rightBtn2TextColor = ta.getColor(R.styleable.CustomTitleBar_rightBtn2TextColor, Color.BLACK)
            val rightBtn3TextColor = ta.getColor(R.styleable.CustomTitleBar_rightBtn3TextColor, Color.BLACK)
            val leftIcon = ta.getResourceId(R.styleable.CustomTitleBar_leftIcon, 0)
            val backVisible = ta.getBoolean(R.styleable.CustomTitleBar_backVisible, false)
            ta.recycle()

            titleText?.let { titleTv.text = it }
            titleTv.setTextColor(titleTextColor)
            titleTv.setTextSize(TypedValue.COMPLEX_UNIT_PX, titleTextSize)

            backIv.visibility = if (backVisible) VISIBLE else GONE

            if (leftIcon != 0) {
                leftIconIv.setImageResource(leftIcon)
                leftIconIv.visibility = VISIBLE
            }

            // Right button 1
            if (rightBtn1Visible) {
                rightBtn1Iv.visibility = VISIBLE
                if (rightBtn1Icon != 0) {
                    rightBtn1Iv.setImageResource(rightBtn1Icon)
                }
            }

            // Right button 2
            if (rightBtn2Visible) {
                rightBtn2Iv.visibility = VISIBLE
                if (rightBtn2Icon != 0) {
                    rightBtn2Iv.setImageResource(rightBtn2Icon)
                }
                // Position to left of button 1 if button 1 is visible
                if (rightBtn1Visible) {
                    (rightBtn2Iv.layoutParams as LayoutParams).apply {
                        removeRule(ALIGN_PARENT_END)
                        addRule(START_OF, rightBtn1Iv.id)
                    }
                }
            }

            // Right button 3 (text)
            if (rightBtn3Visible) {
                rightBtn3Tv.visibility = VISIBLE
                rightBtn3Tv.text = rightBtn3Text
                rightBtn3Tv.setTextColor(rightBtn3TextColor)
                rightBtn3Tv.isEnabled = rightBtn3Enabled
                // Position to left of button 2 if visible, else button 1 if visible
                val leftOfId = when {
                    rightBtn2Visible -> rightBtn2Iv.id
                    rightBtn1Visible -> rightBtn1Iv.id
                    else -> 0
                }
                if (leftOfId != 0) {
                    (rightBtn3Tv.layoutParams as LayoutParams).apply {
                        removeRule(ALIGN_PARENT_END)
                        addRule(START_OF, leftOfId)
                    }
                }
            }
        }

        // Set default height
        setPadding(0, 0, 0, 0)
    }

    fun setTitleText(text: String?) {
        titleTv.text = text
    }

    fun setTitleText(resId: Int) {
        titleTv.setText(resId)
    }

    fun setTitleTextColor(color: Int) {
        titleTv.setTextColor(color)
    }

    fun setRightBtn1Visible(visible: Boolean) {
        rightBtn1Iv.visibility = if (visible) VISIBLE else GONE
    }

    fun setRightBtn2Visible(visible: Boolean) {
        rightBtn2Iv.visibility = if (visible) VISIBLE else GONE
    }

    fun setRightBtn3Visible(visible: Boolean) {
        rightBtn3Tv.visibility = if (visible) VISIBLE else GONE
    }

    fun setRightBtn3Enabled(enabled: Boolean) {
        rightBtn3Tv.isEnabled = enabled
    }

    fun setRightBtn1Icon(resId: Int) {
        rightBtn1Iv.setImageResource(resId)
    }

    fun setRightBtn2Icon(resId: Int) {
        rightBtn2Iv.setImageResource(resId)
    }

    fun setRightBtn3Text(text: String?) {
        rightBtn3Tv.text = text
    }

    fun setRightBtn1ClickListener(listener: OnClickListener?) {
        rightBtn1ClickListener = listener
    }

    fun setRightBtn2ClickListener(listener: OnClickListener?) {
        rightBtn2ClickListener = listener
    }

    fun setRightBtn3ClickListener(listener: OnClickListener?) {
        rightBtn3ClickListener = listener
    }

    fun setBackClickListener(listener: OnClickListener?) {
        backClickListener = listener
    }

    fun setLeftIconClickListener(listener: OnClickListener?) {
        leftIconClickListener = listener
    }

    fun setBackVisible(visible: Boolean) {
        backIv.visibility = if (visible) VISIBLE else GONE
    }

    fun getBackIv(): ImageView = backIv

    fun getRightBtn1Iv(): ImageView = rightBtn1Iv

    fun getRightBtn2Iv(): ImageView = rightBtn2Iv

    fun getRightBtn3Tv(): TextView = rightBtn3Tv

    fun getTitleTv(): TextView = titleTv
}
