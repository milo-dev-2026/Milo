package com.chat.base.msgitem;

import android.content.Context;
import android.graphics.Color;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffColorFilter;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.StateListDrawable;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.core.content.ContextCompat;

import com.chat.base.R;
import com.chat.base.entity.PopupMenuItem;
import com.chat.base.utils.AndroidUtilities;

import java.util.List;

public final class ChatContextMenuView extends LinearLayout {

    public ChatContextMenuView(Context context) {
        super(context);
        setOrientation(LinearLayout.VERTICAL);
        GradientDrawable gradientDrawable = new GradientDrawable();
        gradientDrawable.setColor(surfaceColor(context));
        gradientDrawable.setCornerRadius(AndroidUtilities.dp(20f));
        gradientDrawable.setStroke(1, strokeColor(context));
        setBackground(gradientDrawable);
        setElevation(AndroidUtilities.dp(10f));
        setClipToPadding(false);
        setClipToOutline(true);
        setClickable(true);
    }

    private View createRow(final PopupMenuItem popupMenuItem, final OnMenuItemClickListener listener) {
        int color = popupMenuItem.getColor();
        if (color == 0) {
            color = ContextCompat.getColor(getContext(), R.color.textuser);
        }

        LinearLayout row = new LinearLayout(getContext());
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(android.view.Gravity.CENTER_VERTICAL);
        row.setPadding(AndroidUtilities.dp(18f), 0, AndroidUtilities.dp(18f), 0);
        row.setMinimumHeight(AndroidUtilities.dp(50f));
        row.setClickable(true);
        row.setBackground(rowSelector(getContext()));
        row.setOnClickListener(v -> listener.onItemClick(popupMenuItem));

        ImageView imageView = new ImageView(getContext());
        imageView.setImageResource(popupMenuItem.getIconResourceID());
        imageView.setColorFilter(new PorterDuffColorFilter(color, PorterDuff.Mode.MULTIPLY));
        imageView.setScaleType(ImageView.ScaleType.CENTER);
        row.addView(imageView, new LinearLayout.LayoutParams(AndroidUtilities.dp(24f), AndroidUtilities.dp(50f)));

        TextView textView = new TextView(getContext());
        textView.setText(popupMenuItem.getText());
        textView.setTextColor(color);
        textView.setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, 15f);
        textView.setGravity(android.view.Gravity.CENTER_VERTICAL);
        textView.setIncludeFontPadding(false);
        LinearLayout.LayoutParams textParams = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1f);
        textParams.leftMargin = AndroidUtilities.dp(12f);
        row.addView(textView, textParams);

        row.setLayoutParams(new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, AndroidUtilities.dp(50f)));
        return row;
    }

    private boolean isNightMode(Context context) {
        return (context.getResources().getConfiguration().uiMode & 48) == 32;
    }

    private StateListDrawable rowSelector(Context context) {
        int argb;
        if (isNightMode(context)) {
            argb = Color.argb(42, 255, 255, 255);
        } else {
            argb = Color.argb(38, 0, 0, 0);
        }
        StateListDrawable stateListDrawable = new StateListDrawable();
        stateListDrawable.addState(new int[]{android.R.attr.state_pressed}, new ColorDrawable(argb));
        stateListDrawable.addState(new int[]{android.R.attr.state_selected}, new ColorDrawable(argb));
        stateListDrawable.addState(new int[]{android.R.attr.state_focused}, new ColorDrawable(argb));
        stateListDrawable.addState(new int[0], new ColorDrawable(0));
        return stateListDrawable;
    }

    private int strokeColor(Context context) {
        if (isNightMode(context)) {
            return Color.argb(58, 255, 255, 255);
        }
        return Color.argb(58, 255, 255, 255);
    }

    private int surfaceColor(Context context) {
        if (isNightMode(context)) {
            return Color.argb(238, 38, 40, 38);
        }
        return Color.argb(246, 246, 252, 242);
    }

    public void setItems(List<PopupMenuItem> items, OnMenuItemClickListener listener) {
        removeAllViews();
        for (PopupMenuItem item : items) {
            addView(createRow(item, listener));
        }
    }

    public interface OnMenuItemClickListener {
        void onItemClick(PopupMenuItem item);
    }
}
