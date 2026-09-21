package com.chat.richeditor.component.wmview;

import android.content.Context;
import android.util.AttributeSet;
import android.view.View;
import android.view.ViewGroup;
import android.widget.HorizontalScrollView;
import android.widget.LinearLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.chat.richeditor.component.toolitem.WMToolItem;
import com.chat.richeditor.component.util.WMUtil;

import java.util.ArrayList;
import java.util.List;

public class WMToolContainer extends HorizontalScrollView {

    private LinearLayout contentLayout;
    private List<WMToolItem> tools = new ArrayList<>();
    private Context context;

    public WMToolContainer(@NonNull Context context) {
        super(context);
        init(context);
    }

    public WMToolContainer(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init(context);
    }

    public WMToolContainer(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init(context);
    }

    private void init(Context context) {
        this.context = context;
        setHorizontalScrollBarEnabled(false);
        setFillViewport(true);

        contentLayout = new LinearLayout(context);
        contentLayout.setOrientation(LinearLayout.HORIZONTAL);
        LayoutParams params = new LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.MATCH_PARENT
        );
        contentLayout.setLayoutParams(params);
        addView(contentLayout);
    }

    public void addTool(WMToolItem toolItem) {
        tools.add(toolItem);
        List<View> views = toolItem.getView(context);
        if (views != null) {
            for (View view : views) {
                LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                        WMUtil.dp2px(context, 44),
                        ViewGroup.LayoutParams.MATCH_PARENT
                );
                view.setLayoutParams(lp);
                contentLayout.addView(view);
            }
        }
    }

    public List<WMToolItem> getTools() {
        return tools;
    }

    public LinearLayout getContentLayout() {
        return contentLayout;
    }
}
