package com.chat.base.ui.components;

import android.content.Context;
import android.content.res.TypedArray;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.util.AttributeSet;
import android.view.View;

import androidx.annotation.Nullable;

import com.chat.base.R;

public class CheckBoxContacts extends View {

    private boolean isChecked = false;
    private boolean isEnabled = true;
    private boolean isAnim = false;

    private int colorChecked = Color.WHITE;
    private int colorCheckedBg = Color.parseColor("#4A90D9");
    private int colorUncheckedBg = Color.TRANSPARENT;
    private int colorUncheckedStroke = Color.parseColor("#BBBCBE");
    private int colorDisableBg = Color.parseColor("#E0E0E0");
    private int colorDisableStroke = Color.parseColor("#BBBCBE");
    private float size = 20f;
    private float strokeWidth = 2f;

    private final Paint bgPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint strokePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint checkPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Path checkPath = new Path();
    private final RectF rectF = new RectF();

    private float animProgress = 0f;

    public CheckBoxContacts(Context context) {
        super(context);
        init(null);
    }

    public CheckBoxContacts(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init(attrs);
    }

    public CheckBoxContacts(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init(attrs);
    }

    private void init(AttributeSet attrs) {
        if (attrs != null) {
            TypedArray a = getContext().obtainStyledAttributes(attrs, R.styleable.CheckBox);
            colorChecked = a.getColor(R.styleable.CheckBox_color_checked, colorChecked);
            colorCheckedBg = a.getColor(R.styleable.CheckBox_color_checked_bg, colorCheckedBg);
            colorUncheckedBg = a.getColor(R.styleable.CheckBox_color_unchecked_bg, colorUncheckedBg);
            colorUncheckedStroke = a.getColor(R.styleable.CheckBox_color_unchecked_stroke, colorUncheckedStroke);
            colorDisableBg = a.getColor(R.styleable.CheckBox_cb_disable_bg, colorDisableBg);
            colorDisableStroke = a.getColor(R.styleable.CheckBox_cb_disable_stroke, colorDisableStroke);
            size = a.getDimension(R.styleable.CheckBox_cb_size, size);
            strokeWidth = a.getDimension(R.styleable.CheckBox_stroke_width, strokeWidth);
            a.recycle();
        }
        strokePaint.setStyle(Paint.Style.STROKE);
        strokePaint.setStrokeWidth(strokeWidth);
        checkPaint.setStyle(Paint.Style.STROKE);
        checkPaint.setStrokeWidth(strokeWidth);
        checkPaint.setStrokeCap(Paint.Cap.ROUND);
        checkPaint.setStrokeJoin(Paint.Join.ROUND);
    }

    public void setChecked(boolean checked) {
        setChecked(checked, false);
    }

    public void setChecked(boolean checked, boolean anim) {
        if (isChecked != checked) {
            isChecked = checked;
            isAnim = anim;
            animProgress = 0f;
            invalidate();
        }
    }

    public boolean isChecked() {
        return isChecked;
    }

    @Override
    public void setEnabled(boolean enabled) {
        this.isEnabled = enabled;
        invalidate();
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        float pixelSize = size;
        if (pixelSize <= 0) pixelSize = 20f;
        int measuredSize = (int) (pixelSize + strokeWidth * 2 + 2);
        setMeasuredDimension(measuredSize, measuredSize);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);

        float cx = getWidth() / 2f;
        float cy = getHeight() / 2f;
        float radius = (Math.min(getWidth(), getHeight()) - strokeWidth * 2) / 2f;

        rectF.set(cx - radius, cy - radius, cx + radius, cy + radius);

        if (!isEnabled) {
            // 禁用状态：灰色填充 + 灰色边框
            bgPaint.setColor(colorDisableBg);
            bgPaint.setStyle(Paint.Style.FILL);
            bgPaint.setAntiAlias(true);
            canvas.drawCircle(cx, cy, radius, bgPaint);
            strokePaint.setColor(colorDisableStroke);
            canvas.drawCircle(cx, cy, radius, strokePaint);
            return;
        }

        if (isChecked) {
            // 选中状态：主题色填充圆形 + 白色对勾
            bgPaint.setColor(colorCheckedBg);
            bgPaint.setStyle(Paint.Style.FILL);
            bgPaint.setAntiAlias(true);
            canvas.drawCircle(cx, cy, radius, bgPaint);

            // 绘制对勾
            checkPaint.setColor(colorChecked);
            float checkRadius = radius * 0.5f;
            float offset = radius * 0.15f;
            checkPath.reset();
            // 对勾路径：左下点 -> 中间下点 -> 右上点
            checkPath.moveTo(cx - checkRadius * 0.6f, cy + offset);
            checkPath.lineTo(cx - checkRadius * 0.1f, cy + checkRadius * 0.5f);
            checkPath.lineTo(cx + checkRadius * 0.7f, cy - checkRadius * 0.5f);
            canvas.drawPath(checkPath, checkPaint);
        } else {
            // 未选中状态：透明背景 + 灰色边框圆圈
            bgPaint.setColor(colorUncheckedBg);
            bgPaint.setStyle(Paint.Style.FILL);
            bgPaint.setAntiAlias(true);
            canvas.drawCircle(cx, cy, radius, bgPaint);

            strokePaint.setColor(colorUncheckedStroke);
            strokePaint.setStyle(Paint.Style.STROKE);
            strokePaint.setStrokeWidth(strokeWidth);
            canvas.drawCircle(cx, cy, radius, strokePaint);
        }
    }
}
