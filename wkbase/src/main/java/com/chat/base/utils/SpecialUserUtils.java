package com.chat.base.utils;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.graphics.drawable.GradientDrawable;
import android.text.SpannableStringBuilder;
import android.text.SpannableString;
import android.text.TextPaint;
import android.text.style.ForegroundColorSpan;
import android.text.style.LineBackgroundSpan;
import android.text.style.ReplacementSpan;
import android.util.TypedValue;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.core.content.ContextCompat;

import com.chat.base.R;

/**
 * 特殊用户显示工具类
 * 用于处理特定用户的昵称显示：红色文字 + 黄/绿边框标志
 */
public class SpecialUserUtils {

    public static final String SPECIAL_UID = "06448fc919214f0b8615710d40910382";
    public static final String SPECIAL_SHORT_NO = "888";
    public static final String SPECIAL_NAME = "西安雷虎虎";

    public static boolean isSpecialUser(String uid) {
        return SPECIAL_UID.equals(uid);
    }

    public static boolean isSpecialUserByShortNo(String shortNo) {
        return SPECIAL_SHORT_NO.equals(shortNo);
    }

    public static boolean isSpecialUser(String uid, String shortNo) {
        return isSpecialUser(uid) || isSpecialUserByShortNo(shortNo);
    }

    public static boolean isSpecialUserByName(String name) {
        return name != null && name.contains(SPECIAL_NAME);
    }

    /**
     * 对TextView设置特殊用户昵称样式
     * 昵称红色 + 后缀"西安"(黄色边框) + "押金商家"(绿色边框)
     */
    public static void setSpecialUserName(TextView textView, String name) {
        if (textView == null || name == null) return;

        SpannableStringBuilder ssb = new SpannableStringBuilder();
        ssb.append(name);
        ssb.setSpan(new ForegroundColorSpan(Color.RED), 0, name.length(),
                SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE);

        float badgeSize = textView.getTextSize() * 0.85f;
        float padding = 2f;

        ssb.append(" ");
        int start = ssb.length();
        ssb.append("西安");
        ssb.setSpan(new BorderSpan(Color.rgb(255, 193, 7), Color.TRANSPARENT,
                badgeSize, padding), start, ssb.length(),
                SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE);

        ssb.append(" ");
        start = ssb.length();
        ssb.append("押金商家");
        ssb.setSpan(new BorderSpan(Color.rgb(76, 175, 80), Color.TRANSPARENT,
                badgeSize, padding), start, ssb.length(),
                SpannableString.SPAN_EXCLUSIVE_EXCLUSIVE);

        textView.setText(ssb);
        textView.setTextColor(Color.RED);
    }

    /**
     * 在独立布局中添加标志（西安+押金商家），用于个人名片页等
     */
    public static void setSpecialUserBadges(LinearLayout container, float textSizeSp) {
        if (container == null) return;
        container.removeAllViews();
        container.setVisibility(View.VISIBLE);

        int padding = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 2, container.getResources().getDisplayMetrics());
        int margin = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 3, container.getResources().getDisplayMetrics());
        int corner = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 3, container.getResources().getDisplayMetrics());

        // "西安" - 黄色边框
        TextView xianBadge = createBadgeTextView(container.getContext(), "西安", Color.rgb(255, 193, 7), Color.TRANSPARENT, textSizeSp, padding, corner);
        LinearLayout.LayoutParams xianParams = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        xianParams.setMarginEnd(margin);
        xianBadge.setLayoutParams(xianParams);
        container.addView(xianBadge);

        // "押金商家" - 绿色边框
        TextView depositBadge = createBadgeTextView(container.getContext(), "押金商家", Color.rgb(76, 175, 80), Color.TRANSPARENT, textSizeSp, padding, corner);
        container.addView(depositBadge);
    }

    private static TextView createBadgeTextView(Context context, String text, int borderColor, int bgColor, float textSizeSp, int padding, int cornerRadius) {
        TextView tv = new TextView(context);
        tv.setText(text);
        tv.setTextSize(TypedValue.COMPLEX_UNIT_SP, textSizeSp);
        tv.setTextColor(borderColor);
        tv.setTypeface(tv.getTypeface(), android.graphics.Typeface.BOLD);

        GradientDrawable drawable = new GradientDrawable();
        drawable.setShape(GradientDrawable.RECTANGLE);
        drawable.setCornerRadius(cornerRadius);
        drawable.setStroke(2, borderColor);
        if (bgColor != Color.TRANSPARENT) {
            drawable.setColor(bgColor);
        }
        tv.setBackground(drawable);
        tv.setPadding(padding * 2, 0, padding * 2, 0);
        return tv;
    }

    /**
     * 自定义ReplacementSpan：绘制带边框的文字
     */
    public static class BorderSpan extends ReplacementSpan {
        private final int borderColor;
        private final int bgColor;
        private final float textSize;
        private final float padding;
        private final float borderWidth;
        private final float cornerRadius;

        public BorderSpan(int borderColor, int bgColor, float textSize, float padding) {
            this.borderColor = borderColor;
            this.bgColor = bgColor;
            this.textSize = textSize;
            this.padding = padding;
            this.borderWidth = 1f;
            this.cornerRadius = 4f;
        }

        @Override
        public int getSize(Paint paint, CharSequence text, int start, int end, Paint.FontMetricsInt fm) {
            Paint p = new Paint(paint);
            p.setTextSize(textSize);
            float textWidth = p.measureText(text, start, end);
            return (int) (textWidth + padding * 4 + borderWidth * 2);
        }

        @Override
        public void draw(Canvas canvas, CharSequence text, int start, int end,
                         float x, int top, int y, int bottom, Paint paint) {
            Paint p = new Paint(paint);
            p.setTextSize(textSize);
            p.setAntiAlias(true);

            float textWidth = p.measureText(text, start, end);
            float totalWidth = textWidth + padding * 4 + borderWidth * 2;
            float totalHeight = bottom - top;
            float rectHeight = textSize + padding;

            RectF rect = new RectF(x, top + (totalHeight - rectHeight) / 2,
                    x + totalWidth, top + (totalHeight - rectHeight) / 2 + rectHeight);

            if (bgColor != Color.TRANSPARENT) {
                p.setColor(bgColor);
                canvas.drawRoundRect(rect, cornerRadius, cornerRadius, p);
            }

            p.setStyle(Paint.Style.STROKE);
            p.setColor(borderColor);
            p.setStrokeWidth(borderWidth);
            canvas.drawRoundRect(rect, cornerRadius, cornerRadius, p);

            p.setStyle(Paint.Style.FILL);
            p.setColor(borderColor);
            Paint.FontMetrics fm = p.getFontMetrics();
            float baseline = rect.top + (rect.height() - fm.descent + fm.ascent) / 2 - fm.ascent;
            canvas.drawText(text, start, end, x + padding * 2 + borderWidth, baseline, p);
        }
    }
}
