package com.chat.base.views;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.util.AttributeSet;
import android.widget.LinearLayout;

import androidx.core.content.ContextCompat;

import com.chat.base.R;
import com.chat.base.msgitem.WKChatIteMsgFromType;
import com.chat.base.msgitem.WKMsgBgType;

public class BubbleLayout extends LinearLayout {
    private int gravity;
    private Paint bubblePaint;
    private Path bubblePath;
    private float bubbleRadius;
    private int bubbleNormalColor = 0;
    private int bubbleSelectedColor = 0;
    private int bubbleBorderColor = 0;
    private boolean isPressed = false;
    private WKMsgBgType bgType = WKMsgBgType.single;
    private WKChatIteMsgFromType fromType = WKChatIteMsgFromType.SEND;
    private int contentType = 0;

    // 小尾巴相关
    private int lookLength = 10; // 小尾巴长度 dp
    private int lookWidth = 10;  // 小尾巴宽度 dp
    private boolean hasLook = false; // 是否有小尾巴
    private int originalPaddingLeft = 0;
    private int originalPaddingTop = 0;
    private int originalPaddingRight = 0;
    private int originalPaddingBottom = 0;
    private boolean originalPaddingSaved = false;

    public BubbleLayout(Context context) {
        super(context);
        init();
    }

    public BubbleLayout(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public BubbleLayout(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    private void init() {
        setOrientation(VERTICAL);
        bubblePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        bubblePaint.setStyle(Paint.Style.FILL);
        bubblePaint.setDither(true);
        bubblePath = new Path();
        bubbleRadius = getResources().getDimension(R.dimen.chat_radius);
        lookLength = dp2px(10);
        lookWidth = dp2px(8);
        bubbleNormalColor = ContextCompat.getColor(getContext(), R.color.c3F74FC);
        setWillNotDraw(false);
        setBackground(null);
        setLayerType(LAYER_TYPE_SOFTWARE, null);
    }

    private int dp2px(int dp) {
        return (int) (dp * getResources().getDisplayMetrics().density + 0.5f);
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);
        applyShape();
    }

    private void applyShape() {
        int w = getWidth();
        int h = getHeight();
        if (w == 0 || h == 0) return;

        bubblePath.reset();
        boolean isSend = fromType == WKChatIteMsgFromType.SEND;
        boolean isBottom = bgType == WKMsgBgType.bottom || bgType == WKMsgBgType.single;

        // 前端圆角半径，与尾部保持一致
        float frontRadius = dp2px(12);
        // 后端（小尾巴侧）的圆角半径
        float backRadius = dp2px(12);
        if (frontRadius > h / 2f) frontRadius = h / 2f;
        if (backRadius > h / 2f) backRadius = h / 2f;

        float[] radii = new float[8];

        if (isSend) {
            // 发送方：左侧（前面）是半圆形，右侧（小尾巴侧）有圆角
            radii[0] = frontRadius; radii[1] = frontRadius;  // left-top
            radii[2] = backRadius;  radii[3] = backRadius;   // right-top
            radii[4] = backRadius;  radii[5] = backRadius;   // right-bottom
            radii[6] = frontRadius; radii[7] = frontRadius;  // left-bottom
        } else {
            // 接收方：右侧（前面）是半圆形，左侧（小尾巴侧）有圆角
            radii[0] = backRadius;  radii[1] = backRadius;   // left-top
            radii[2] = frontRadius; radii[3] = frontRadius;  // right-top
            radii[4] = frontRadius; radii[5] = frontRadius;  // right-bottom
            radii[6] = backRadius;  radii[7] = backRadius;   // left-bottom
        }

        // 如果需要显示小尾巴（底部消息才有小尾巴）
        if (hasLook && isBottom) {
            drawBubbleWithLook(w, h, frontRadius, backRadius, isSend);
        } else {
            // 没有小尾巴的普通圆角矩形
            bubblePath.addRoundRect(new RectF(0, 0, w, h), radii, Path.Direction.CW);
        }
    }

    private void drawBubbleWithLook(int w, int h, float frontR, float backR, boolean isSend) {
        float lookW = lookWidth;
        float lookL = lookLength;

        if (isSend) {
            // 发送方：左侧半圆，右侧圆角 + 右下角小尾巴
            bubblePath.moveTo(frontR, 0);
            bubblePath.lineTo(w - backR, 0);
            bubblePath.quadTo(w, 0, w, backR);
            // 右边线向下到小尾巴起点
            float lookStart = h - lookW * 1.5f;
            if (lookStart < backR) lookStart = backR;
            bubblePath.lineTo(w, lookStart);
            // 小尾巴三角形 - 从右边线向右伸出再回到右下角
            bubblePath.lineTo(w + lookL, h - lookW / 2f);
            bubblePath.lineTo(w, h);
            // 底边到左下角半圆
            bubblePath.lineTo(frontR, h);
            bubblePath.quadTo(0, h, 0, h - frontR);
            bubblePath.lineTo(0, frontR);
            bubblePath.quadTo(0, 0, frontR, 0);
        } else {
            // 接收方：右侧半圆，左侧圆角 + 左下角小尾巴
            bubblePath.moveTo(backR, 0);
            bubblePath.lineTo(w - frontR, 0);
            bubblePath.quadTo(w, 0, w, frontR);
            bubblePath.lineTo(w, h - frontR);
            bubblePath.quadTo(w, h, w - frontR, h);
            bubblePath.lineTo(backR, h);
            // 小尾巴三角形 - 从左边线向左伸出再回到左下角
            float lookStart = h - lookW * 1.5f;
            if (lookStart < backR) lookStart = backR;
            bubblePath.lineTo(-lookL, h - lookW / 2f);
            bubblePath.lineTo(0, h);
            bubblePath.lineTo(0, lookStart);
            bubblePath.lineTo(0, backR);
            bubblePath.quadTo(0, 0, backR, 0);
        }
        bubblePath.close();
    }

    @Override
    protected void onDraw(Canvas canvas) {
        int color = bubbleNormalColor;
        if (color != 0) {
            bubblePaint.setStyle(Paint.Style.FILL);
            bubblePaint.setColor(color);
            canvas.drawPath(bubblePath, bubblePaint);
        }
        if (bubbleBorderColor != 0) {
            bubblePaint.setStyle(Paint.Style.STROKE);
            bubblePaint.setColor(bubbleBorderColor);
            bubblePaint.setStrokeWidth(dp2px(2));
            bubblePaint.setAntiAlias(true);
            canvas.drawPath(bubblePath, bubblePaint);
            bubblePaint.setStyle(Paint.Style.FILL);
        }
        super.onDraw(canvas);
    }

    public void setAll(WKMsgBgType bgType, WKChatIteMsgFromType from, int contentType) {
        this.bgType = bgType;
        this.fromType = from;
        this.contentType = contentType;
        if (from == WKChatIteMsgFromType.SEND) {
            applySendPalette(contentType);
        } else {
            applyReceivedPalette(contentType);
        }
        // 恢复原始 padding
        if (!originalPaddingSaved) {
            originalPaddingLeft = getPaddingLeft();
            originalPaddingTop = getPaddingTop();
            originalPaddingRight = getPaddingRight();
            originalPaddingBottom = getPaddingBottom();
            originalPaddingSaved = true;
        }
        setPadding(originalPaddingLeft, originalPaddingTop,
                originalPaddingRight, originalPaddingBottom);
        // 背景设为透明
        setBackground(null);
        applyShape();
        invalidate();
    }

    public void setAll(WKMsgBgType bgType, WKChatIteMsgFromType from, int normalColor, int selectedColor) {
        this.bgType = bgType;
        this.fromType = from;
        bubbleNormalColor = normalColor;
        bubbleSelectedColor = selectedColor;
        if (from == WKChatIteMsgFromType.SEND) {
            bubbleBorderColor = ContextCompat.getColor(getContext(), R.color.transparent);
        } else {
            bubbleBorderColor = ContextCompat.getColor(getContext(), R.color.transparent);
        }
        applyShape();
        invalidate();
    }

    private void applySendPalette(int contentType) {
        if (contentType == 6 || contentType == 8 || contentType == 11) {
            bubbleNormalColor = ContextCompat.getColor(getContext(), R.color.chat_received_bg_normal);
            bubbleSelectedColor = ContextCompat.getColor(getContext(), R.color.chat_received_bg_selected);
            bubbleBorderColor = 0; // 图片/视频等白色气泡不加边框
        } else if (contentType == 7) {
            // 个人名片：浅灰色背景 + 边框
            bubbleNormalColor = ContextCompat.getColor(getContext(), R.color.cF6F7F9);
            bubbleSelectedColor = ContextCompat.getColor(getContext(), R.color.cF6F7F9);
            bubbleBorderColor = ContextCompat.getColor(getContext(), R.color.colorB6B5B5);
        } else if (contentType == 18) {
            bubbleNormalColor = 0;
            bubbleSelectedColor = 0;
            bubbleBorderColor = 0;
        } else {
            // 蓝色气泡
            bubbleNormalColor = ContextCompat.getColor(getContext(), R.color.c3F74FC);
            bubbleSelectedColor = ContextCompat.getColor(getContext(), R.color.c804273F0);
            // 蓝色气泡：边框颜色和气泡同色，2px宽度，覆盖边缘抗锯齿白边
            bubbleBorderColor = bubbleNormalColor;
        }
    }

    private void applyReceivedPalette(int contentType) {
        if (contentType == 7) {
            // 个人名片：浅灰色背景 + 边框
            bubbleNormalColor = ContextCompat.getColor(getContext(), R.color.cF6F7F9);
            bubbleSelectedColor = ContextCompat.getColor(getContext(), R.color.cF6F7F9);
            bubbleBorderColor = ContextCompat.getColor(getContext(), R.color.colorB6B5B5);
        } else {
            bubbleNormalColor = ContextCompat.getColor(getContext(), R.color.chat_received_bg_normal);
            bubbleSelectedColor = ContextCompat.getColor(getContext(), R.color.chat_received_bg_selected);
            // 添加背景色边框，掩盖边缘抗锯齿白边
            bubbleBorderColor = ContextCompat.getColor(getContext(), R.color.color_chat);
        }
    }

    @Override
    public void setPressed(boolean pressed) {
        super.setPressed(pressed);
        if (isPressed != pressed) {
            isPressed = pressed;
            invalidate();
        }
    }

    @Override
    public void setGravity(int gravity) {
        super.setGravity(gravity);
        this.gravity = gravity;
    }

    @Override
    public int getGravity() {
        return gravity;
    }

    public void setHasLook(boolean hasLook) {
        this.hasLook = hasLook;
    }
}
