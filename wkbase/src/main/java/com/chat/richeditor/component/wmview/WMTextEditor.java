package com.chat.richeditor.component.wmview;

import android.content.Context;
import android.graphics.Typeface;
import android.text.Spannable;
import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.text.style.AbsoluteSizeSpan;
import android.text.style.ForegroundColorSpan;
import android.text.style.StrikethroughSpan;
import android.text.style.StyleSpan;
import android.text.style.UnderlineSpan;
import android.util.AttributeSet;
import android.view.View;
import android.widget.LinearLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.chat.base.ui.components.AlignImageSpan;
import com.chat.richeditor.component.RichStyles;
import com.chat.richeditor.component.span.WMMentionSpan;
import com.chat.richeditor.component.span.WMUnderlineSpan;
import com.chat.richeditor.component.toolitem.WMToolBold;
import com.chat.richeditor.component.toolitem.WMToolImage;
import com.chat.richeditor.component.toolitem.WMToolItalic;
import com.chat.richeditor.component.toolitem.WMToolItem;
import com.chat.richeditor.component.toolitem.WMToolMention;
import com.chat.richeditor.component.toolitem.WMToolStrikethrough;
import com.chat.richeditor.component.toolitem.WMToolTextColor;
import com.chat.richeditor.component.toolitem.WMToolTextSize;
import com.chat.richeditor.component.toolitem.WMToolUnderline;
import com.chat.richeditor.component.util.WMColor;
import com.chat.richeditor.component.util.WMUtil;
import com.xinbida.wukongim.msgmodel.WKMsgEntity;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;

/**
 * 富文本编辑器主组件
 * 包含可编辑文本区域和工具栏容器
 */
public class WMTextEditor extends LinearLayout {

    private WMEditText editText;
    private WMToolContainer toolContainer;
    private WMToolBold toolBold;
    private WMToolItalic toolItalic;
    private WMToolUnderline toolUnderline;
    private WMToolStrikethrough toolStrikethrough;
    private WMToolTextColor toolTextColor;
    private WMToolTextSize toolTextSize;
    private WMToolMention toolMention;
    private WMToolImage toolImage;

    private boolean showMentionTool = true;
    private OnChooseGroupMemberListener mentionListener;
    private OnInsertImageListener imageListener;

    public interface OnChooseGroupMemberListener {
        void onChooseMention();
    }

    public interface OnInsertImageListener {
        void onInsertImage();
    }

    public WMTextEditor(@NonNull Context context) {
        super(context);
        init(context);
    }

    public WMTextEditor(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init(context);
    }

    public WMTextEditor(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init(context);
    }

    private void init(Context context) {
        setOrientation(VERTICAL);

        // 创建编辑区域
        editText = new WMEditText(context);
        LayoutParams editParams = new LayoutParams(
                LayoutParams.MATCH_PARENT,
                0,
                1.0f
        );
        editText.setLayoutParams(editParams);
        editText.setBackgroundColor(0xffffffff);
        editText.setPadding(
                WMUtil.dp2px(context, 16),
                WMUtil.dp2px(context, 12),
                WMUtil.dp2px(context, 16),
                WMUtil.dp2px(context, 12)
        );
        editText.setTextSize(15);
        editText.setTextColor(0xff2b313d);
        editText.setHint("输入内容...");
        editText.setHintTextColor(0xffb4b6bd);
        addView(editText);

        // 创建工具栏容器
        toolContainer = new WMToolContainer(context);
        LayoutParams toolParams = new LayoutParams(
                LayoutParams.MATCH_PARENT,
                WMUtil.dp2px(context, 48)
        );
        toolContainer.setLayoutParams(toolParams);
        toolContainer.setBackgroundColor(0xfff6f7f9);
        addView(toolContainer);

        // 初始化工具项
        initTools(context);

        // 绑定编辑器和工具栏
        editText.setupWithToolContainer(toolContainer);
    }

    private void initTools(Context context) {
        toolBold = new WMToolBold();
        toolContainer.addTool(toolBold);

        toolItalic = new WMToolItalic();
        toolContainer.addTool(toolItalic);

        toolUnderline = new WMToolUnderline();
        toolContainer.addTool(toolUnderline);

        toolStrikethrough = new WMToolStrikethrough();
        toolContainer.addTool(toolStrikethrough);

        toolTextColor = new WMToolTextColor();
        toolTextColor.setOnColorPickerListener(tool -> {
            // 简单实现：循环切换颜色
            int currentColor = tool.getCurrentColor();
            int[] colors = WMColor.TEXT_COLORS;
            int nextIndex = 0;
            for (int i = 0; i < colors.length; i++) {
                if (colors[i] == currentColor) {
                    nextIndex = (i + 1) % colors.length;
                    break;
                }
            }
            tool.setColor(colors[nextIndex]);
        });
        toolContainer.addTool(toolTextColor);

        toolTextSize = new WMToolTextSize();
        toolTextSize.setOnSizePickerListener(tool -> {
            // 简单实现：循环切换字号
            int currentSize = tool.getCurrentSize();
            int[] sizes = WMColor.TEXT_SIZES;
            int nextIndex = 0;
            for (int i = 0; i < sizes.length; i++) {
                if (sizes[i] == currentSize) {
                    nextIndex = (i + 1) % sizes.length;
                    break;
                }
            }
            tool.setSize(sizes[nextIndex]);
        });
        toolContainer.addTool(toolTextSize);

        if (showMentionTool) {
            toolMention = new WMToolMention();
            toolMention.setOnMentionClickListener(() -> {
                if (mentionListener != null) {
                    mentionListener.onChooseMention();
                }
            });
            toolContainer.addTool(toolMention);
        }

        toolImage = new WMToolImage();
        toolImage.setOnImageClickListener(() -> {
            if (imageListener != null) {
                imageListener.onInsertImage();
            }
        });
        toolContainer.addTool(toolImage);
    }

    /**
     * 获取编辑内容的纯文本
     */
    public String getContentText() {
        if (editText == null || editText.getText() == null) {
            return "";
        }
        return editText.getText().toString();
    }

    /**
     * 获取富文本实体列表（用于发送消息）
     */
    public List<WKMsgEntity> getContentEntities() {
        List<WKMsgEntity> entities = new ArrayList<>();
        if (editText == null || editText.getText() == null) {
            return entities;
        }

        Spannable spannable = editText.getText();
        String text = spannable.toString();

        // 提取粗体
        StyleSpan[] boldSpans = spannable.getSpans(0, spannable.length(), StyleSpan.class);
        for (StyleSpan span : boldSpans) {
            if (span.getStyle() == Typeface.BOLD || span.getStyle() == Typeface.BOLD_ITALIC) {
                int start = spannable.getSpanStart(span);
                int end = spannable.getSpanEnd(span);
                WKMsgEntity entity = new WKMsgEntity();
                entity.type = RichStyles.BOLD;
                entity.offset = start;
                entity.length = end - start;
                entities.add(entity);
            }
        }

        // 提取斜体
        for (StyleSpan span : boldSpans) {
            if (span.getStyle() == Typeface.ITALIC || span.getStyle() == Typeface.BOLD_ITALIC) {
                int start = spannable.getSpanStart(span);
                int end = spannable.getSpanEnd(span);
                // 避免与 BOLD_ITALIC 重复
                boolean alreadyAdded = false;
                for (WKMsgEntity e : entities) {
                    if (e.type.equals(RichStyles.ITALIC) && e.offset == start && e.length == end - start) {
                        alreadyAdded = true;
                        break;
                    }
                }
                if (!alreadyAdded) {
                    WKMsgEntity entity = new WKMsgEntity();
                    entity.type = RichStyles.ITALIC;
                    entity.offset = start;
                    entity.length = end - start;
                    entities.add(entity);
                }
            }
        }

        // 提取下划线
        UnderlineSpan[] underlineSpans = spannable.getSpans(0, spannable.length(), UnderlineSpan.class);
        for (UnderlineSpan span : underlineSpans) {
            int start = spannable.getSpanStart(span);
            int end = spannable.getSpanEnd(span);
            WKMsgEntity entity = new WKMsgEntity();
            entity.type = RichStyles.UNDERLINE;
            entity.offset = start;
            entity.length = end - start;
            entities.add(entity);
        }

        // 提取删除线
        StrikethroughSpan[] strikeSpans = spannable.getSpans(0, spannable.length(), StrikethroughSpan.class);
        for (StrikethroughSpan span : strikeSpans) {
            int start = spannable.getSpanStart(span);
            int end = spannable.getSpanEnd(span);
            WKMsgEntity entity = new WKMsgEntity();
            entity.type = RichStyles.STRIKETHROUGH;
            entity.offset = start;
            entity.length = end - start;
            entities.add(entity);
        }

        // 提取文字颜色
        ForegroundColorSpan[] colorSpans = spannable.getSpans(0, spannable.length(), ForegroundColorSpan.class);
        for (ForegroundColorSpan span : colorSpans) {
            int start = spannable.getSpanStart(span);
            int end = spannable.getSpanEnd(span);
            WKMsgEntity entity = new WKMsgEntity();
            entity.type = RichStyles.COLOR;
            entity.offset = start;
            entity.length = end - start;
            entity.value = WMColor.colorToHex(span.getForegroundColor());
            entities.add(entity);
        }

        // 提取字号
        AbsoluteSizeSpan[] sizeSpans = spannable.getSpans(0, spannable.length(), AbsoluteSizeSpan.class);
        for (AbsoluteSizeSpan span : sizeSpans) {
            int start = spannable.getSpanStart(span);
            int end = spannable.getSpanEnd(span);
            WKMsgEntity entity = new WKMsgEntity();
            entity.type = RichStyles.FONT;
            entity.offset = start;
            entity.length = end - start;
            entity.value = String.valueOf(span.getSize());
            entities.add(entity);
        }

        // 提取@提及
        WMMentionSpan[] mentionSpans = spannable.getSpans(0, spannable.length(), WMMentionSpan.class);
        for (WMMentionSpan span : mentionSpans) {
            int start = spannable.getSpanStart(span);
            int end = spannable.getSpanEnd(span);
            WKMsgEntity entity = new WKMsgEntity();
            entity.type = RichStyles.MENTION;
            entity.offset = start;
            entity.length = end - start;
            entity.value = span.getUid();
            entities.add(entity);
        }

        // 提取图片
        AlignImageSpan[] imageSpans = spannable.getSpans(0, spannable.length(), AlignImageSpan.class);
        for (AlignImageSpan span : imageSpans) {
            int start = spannable.getSpanStart(span);
            int end = spannable.getSpanEnd(span);
            WKMsgEntity entity = new WKMsgEntity();
            entity.type = RichStyles.IMG;
            entity.offset = start;
            entity.length = end - start;
            // 图片 URL 暂存在 value 中，实际使用时需要额外处理
            entity.value = "";
            entities.add(entity);
        }

        // 提取链接（正则匹配）
        Matcher urlMatcher = WMUtil.matchUrl(text);
        while (urlMatcher.find()) {
            int start = urlMatcher.start();
            int end = urlMatcher.end();
            WKMsgEntity entity = new WKMsgEntity();
            entity.type = RichStyles.LINK;
            entity.offset = start;
            entity.length = end - start;
            entity.value = urlMatcher.group();
            entities.add(entity);
        }

        return entities;
    }

    /**
     * 获取所有 @提及的 UID 列表
     */
    public List<String> getMentionUids() {
        List<String> uids = new ArrayList<>();
        if (editText == null || editText.getText() == null) {
            return uids;
        }

        Spannable spannable = editText.getText();
        WMMentionSpan[] mentionSpans = spannable.getSpans(0, spannable.length(), WMMentionSpan.class);
        for (WMMentionSpan span : mentionSpans) {
            if (!uids.contains(span.getUid())) {
                uids.add(span.getUid());
            }
        }
        return uids;
    }

    /**
     * 插入@提及
     */
    public void insertMention(String uid, String name) {
        if (toolMention != null) {
            toolMention.insertMention(uid, name);
        }
    }

    /**
     * 插入图片
     */
    public void insertImage(String imageUrl, int width, int height) {
        if (toolImage != null) {
            toolImage.insertImage(imageUrl, width, height);
        }
    }

    public WMEditText getEditText() {
        return editText;
    }

    public WMToolContainer getToolContainer() {
        return toolContainer;
    }

    public void setOnChooseGroupMemberListener(OnChooseGroupMemberListener listener) {
        this.mentionListener = listener;
    }

    public void setOnInsertImageListener(OnInsertImageListener listener) {
        this.imageListener = listener;
    }

    public void setShowMentionTool(boolean show) {
        this.showMentionTool = show;
    }

    /**
     * 设置编辑器内容（用于编辑已有富文本）
     */
    public void setContent(CharSequence content) {
        if (editText != null) {
            editText.setText(content);
            if (content != null) {
                editText.setSelection(content.length());
            }
        }
    }

    /**
     * 设置是否可编辑
     */
    public void setEditable(boolean editable) {
        if (editText != null) {
            editText.setEditable(editable);
        }
        if (toolContainer != null) {
            toolContainer.setVisibility(editable ? VISIBLE : GONE);
        }
    }
}
