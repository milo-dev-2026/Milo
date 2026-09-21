package com.chat.base.ui.components;

import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.text.Editable;
import android.text.Spannable;
import android.text.SpannableString;
import android.text.TextUtils;
import android.text.style.ImageSpan;
import android.util.AttributeSet;
import android.util.Log;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.TextView;

import androidx.appcompat.widget.AppCompatAutoCompleteTextView;
import androidx.core.content.ContextCompat;

import com.chat.api.entity.message.WKMsgEntity;
import com.chat.base.R;
import com.chat.base.emoji.MoonUtil;
import com.chat.base.msg.ChatContentSpanType;
import com.chat.base.msgitem.MentionSelectionPolicy;
import com.chat.base.utils.StringUtils;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Objects;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * ContactEditText with mention (\@user) support.
 * Renders \@mentions as inline image spans and tracks their UIDs.
 */
public class ContactEditText extends AppCompatAutoCompleteTextView {
    private static final String TAG = "ContactEditText";
    private int itemPadding;

    /**
     * Image span that carries the mention display text and uid.
     */
    public static class MyImageSpan extends ImageSpan {
        private final String showText;
        private final String uid;

        public MyImageSpan(Drawable drawable, String showText, String uid) {
            super(drawable);
            this.showText = showText;
            this.uid = uid;
        }

        public String getShowText() {
            return this.showText;
        }

        public String getUid() {
            return this.uid;
        }
    }

    /**
     * A text region that should be (re)wrapped in a mention span.
     */
    public static class UnSpanText {
        final int start;
        final int end;
        final CharSequence showText;
        final String uid;

        public UnSpanText(int start, int end, CharSequence showText, String uid) {
            this.start = start;
            this.end = end;
            this.showText = showText;
            this.uid = uid;
        }
    }

    /**
     * URL match info with offset.
     */
    public static class UrlInfo {
        final int offset;
        final String url;

        public UrlInfo(String url, int offset) {
            this.url = url;
            this.offset = offset;
        }
    }

    public ContactEditText(Context context) {
        super(context);
        init();
    }

    public ContactEditText(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public ContactEditText(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    private void init() {
        this.itemPadding = dip2px(getContext(), 3);
    }

    /**
     * Set max input length. Actual enforcement is done via InputFilter set externally.
     */
    public void setMaxLength(int max) {
        if (max > 0) {
            setFilters(new android.text.InputFilter[]{new android.text.InputFilter.LengthFilter(max)});
        }
    }

    public static int dip2px(Context context, int dp) {
        return (int) ((dp * context.getResources().getDisplayMetrics().density) + 0.5f);
    }

    // ------------------------------------------------------------------
    // Public API used by the chat panel
    // ------------------------------------------------------------------

    /**
     * Insert a mention span (\@name uid) at the current cursor position.
     */
    public void addSpan(String text, String uid) {
        if (!MentionSelectionPolicy.canAdd(getAllUIDs(), uid)) {
            return;
        }
        int selectionStart = getSelectionStart();
        getText().insert(selectionStart, text);
        SpannableString spannableString = new SpannableString(getText());
        generateOneSpan(spannableString, new UnSpanText(selectionStart, text.length() + selectionStart, text, uid));
        setText(spannableString);
        setSelection(selectionStart + text.length());
    }

    /**
     * Convenience overload (no arg) - uses the current EditText text as content.
     */
    public List<WKMsgEntity> getAllEntity() {
        return getAllEntity(getText().toString());
    }

    /**
     * Extract mention spans, URLs, emails, and phone numbers as WKMsgEntity list.
     *
     * @param content the display text to extract entities from
     */
    public List<WKMsgEntity> getAllEntity(String content) {
        ArrayList<WKMsgEntity> result = new ArrayList<>();
        final Editable text = getText();
        int baseOffset = text.toString().indexOf(content);
        if (baseOffset < 0) {
            baseOffset = 0;
        }
        MyImageSpan[] spans = (MyImageSpan[]) text.getSpans(0, text.length(), MyImageSpan.class);
        Arrays.sort(spans, Comparator.comparingInt(span -> text.getSpanStart((MyImageSpan) span)));

        HashSet<String> seen = new HashSet<>();
        for (MyImageSpan span : spans) {
            int spanStart = text.getSpanStart(span) - baseOffset;
            int spanEnd = text.getSpanEnd(span) - baseOffset;
            if (spanStart >= 0 && spanEnd > spanStart && spanEnd <= content.length()
                    && span.uid != null && seen.add(span.uid)) {
                WKMsgEntity entity = new WKMsgEntity();
                entity.type = ChatContentSpanType.mention;
                entity.offset = spanStart;
                entity.length = spanEnd - spanStart;
                entity.value = span.uid;
                result.add(entity);
            }
        }

        // URLs
        for (UrlInfo urlInfo : getUrlsWithOffsets(content)) {
            WKMsgEntity entity = new WKMsgEntity();
            entity.type = ChatContentSpanType.link;
            entity.offset = urlInfo.offset;
            entity.length = urlInfo.url.length();
            entity.value = urlInfo.url;
            result.add(entity);
        }

        // Emails
        for (String email : StringUtils.getEmails(content)) {
            int idx = 0;
            while (idx >= 0) {
                idx = content.indexOf(email, idx);
                if (idx >= 0) {
                    WKMsgEntity entity = new WKMsgEntity();
                    entity.type = ChatContentSpanType.link;
                    entity.offset = idx;
                    entity.length = email.length();
                    entity.value = email;
                    result.add(entity);
                    idx += email.length();
                }
            }
        }

        // Phone numbers
        for (String number : StringUtils.getNumbers(content)) {
            int idx = 0;
            while (idx >= 0) {
                idx = content.indexOf(number, idx);
                if (idx >= 0) {
                    WKMsgEntity entity = new WKMsgEntity();
                    entity.type = ChatContentSpanType.link;
                    entity.offset = idx;
                    entity.length = number.length();
                    entity.value = number;
                    result.add(entity);
                    idx += number.length();
                }
            }
        }

        return result;
    }

    /**
     * Collect all unique mention UIDs currently in the EditText.
     */
    public List<String> getAllUIDs() {
        LinkedHashSet<String> uidSet = new LinkedHashSet<>();
        Editable text = getText();
        SpannableString spannableString = new SpannableString(text);
        MyImageSpan[] spans = (MyImageSpan[]) spannableString.getSpans(0, spannableString.length(), MyImageSpan.class);
        Arrays.sort(spans, Comparator.comparingInt(span -> spannableString.getSpanStart((MyImageSpan) span)));
        for (MyImageSpan span : spans) {
            if (span.getUid() != null && !span.getUid().isEmpty()) {
                uidSet.add(span.getUid());
            }
        }
        return new ArrayList<>(uidSet);
    }

    /**
     * Restore mention entities into the EditText from a text and entity list.
     */
    public void setTextWithMentionEntities(String text, List<WKMsgEntity> entities) {
        if (text == null) {
            text = "";
        }
        SpannableString spannableString = new SpannableString(text);
        HashSet<String> seen = new HashSet<>();
        if (entities != null) {
            for (WKMsgEntity entity : entities) {
                if (entity == null) continue;
                if (!ChatContentSpanType.mention.equals(entity.type)) continue;
                String uid = entity.value;
                if (uid == null || !seen.add(uid)) continue;
                int start = entity.offset;
                int length = entity.length;
                if (start < 0 || length <= 0 || start + length > spannableString.length()) continue;
                CharSequence subSequence = spannableString.subSequence(start, start + length);
                generateOneSpan(spannableString, new UnSpanText(start, start + length, subSequence, uid));
            }
        }
        setText(spannableString);
        setSelection(spannableString.length());
    }

    // ------------------------------------------------------------------
    // Internal helpers
    // ------------------------------------------------------------------

    private void flushSpans() {
        Editable text = getText();
        Spannable spannableString = new SpannableString(text);
        MyImageSpan[] spans = (MyImageSpan[]) spannableString.getSpans(0, text.length(), MyImageSpan.class);
        Arrays.sort(spans, Comparator.comparingInt(span -> spannableString.getSpanStart((MyImageSpan) span)));
        for (UnSpanText unSpanText : getAllTexts(spans, text)) {
            if (!TextUtils.isEmpty(unSpanText.showText.toString().trim())) {
                generateOneSpan(spannableString, unSpanText);
            }
        }
        setText(spannableString);
        setSelection(spannableString.length());
    }

    private void generateOneSpan(Spannable spannable, UnSpanText unSpanText) {
        BitmapDrawable bitmapDrawable = (BitmapDrawable) convertViewToDrawable(
                getSpanView(getContext(), unSpanText.showText.toString(), getMeasuredWidth()));
        bitmapDrawable.setBounds(0, 0, bitmapDrawable.getIntrinsicWidth(), bitmapDrawable.getIntrinsicHeight());
        spannable.setSpan(new MyImageSpan(bitmapDrawable, unSpanText.showText.toString(), unSpanText.uid),
                unSpanText.start, unSpanText.end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
    }

    private List<UnSpanText> getAllTexts(MyImageSpan[] spans, Editable editable) {
        ArrayList<UnSpanText> result = new ArrayList<>();
        ArrayList<Integer> bounds = new ArrayList<>();
        bounds.add(0);
        for (MyImageSpan span : spans) {
            bounds.add(editable.getSpanStart(span));
            bounds.add(editable.getSpanEnd(span));
        }
        bounds.add(editable.length());
        Collections.sort(bounds);
        for (int i = 0; i < bounds.size(); i += 2) {
            int start = bounds.get(i);
            int end = bounds.get(i + 1);
            CharSequence subSequence = editable.subSequence(start, end);
            if (!TextUtils.isEmpty(subSequence)) {
                result.add(new UnSpanText(start, end, subSequence, spans[i].uid));
            }
        }
        return result;
    }

    private List<UrlInfo> getUrlsWithOffsets(String str) {
        ArrayList<UrlInfo> result = new ArrayList<>();
        if (str == null || str.isEmpty()) {
            return result;
        }
        Matcher matcher = Pattern.compile("https?://[^\\s]+", Pattern.CASE_INSENSITIVE).matcher(str);
        while (matcher.find()) {
            result.add(new UrlInfo(matcher.group(), matcher.start()));
        }
        return result;
    }

    public Drawable convertViewToDrawable(View view) {
        int measureSpec = View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED);
        view.measure(measureSpec, measureSpec);
        view.layout(0, 0, view.getMeasuredWidth(), view.getMeasuredHeight());
        int width = view.getMeasuredWidth();
        int height = view.getMeasuredHeight();
        Bitmap.Config config = Bitmap.Config.ARGB_8888;
        Canvas canvas = new Canvas(Bitmap.createBitmap(width, height, config));
        canvas.translate(-view.getScrollX(), -view.getScrollY());
        view.draw(canvas);
        view.setDrawingCacheEnabled(true);
        Bitmap drawingCache = view.getDrawingCache();
        Bitmap copy = drawingCache.copy(config, true);
        drawingCache.recycle();
        view.destroyDrawingCache();
        return new BitmapDrawable(copy);
    }

    public View getSpanView(Context context, String text, int maxWidth) {
        TextView textView = new TextView(context);
        textView.setMaxWidth(maxWidth);
        textView.setText(text);
        textView.setEllipsize(TextUtils.TruncateAt.END);
        textView.setSingleLine(true);
        textView.setBackgroundResource(R.drawable.shape_corner_rectangle);
        textView.setTextSize(getTextSize());
        textView.setTextColor(ContextCompat.getColor(context, R.color.colorDark));
        FrameLayout frameLayout = new FrameLayout(context);
        frameLayout.addView(textView);
        return frameLayout;
    }

    @Override
    public void onSelectionChanged(int selStart, int selEnd) {
        MyImageSpan[] spans = (MyImageSpan[]) getText().getSpans(0, getText().length(), MyImageSpan.class);
        for (MyImageSpan span : spans) {
            if (getText().getSpanEnd(span) - 1 == selStart) {
                int newPos = selStart + 1;
                setSelection(newPos);
                super.onSelectionChanged(newPos, newPos);
                return;
            }
        }
        super.onSelectionChanged(selStart, selEnd);
    }

    @Override
    public boolean onTextContextMenuItem(int id) {
        if (id == android.R.id.paste) {
            ClipboardManager clipboardManager = (ClipboardManager) getContext().getSystemService(Context.CLIPBOARD_SERVICE);
            if (clipboardManager == null) {
                return super.onTextContextMenuItem(id);
            }
            ClipData primaryClip = clipboardManager.getPrimaryClip();
            if (primaryClip != null && primaryClip.getItemCount() != 0) {
                ClipData.Item item = primaryClip.getItemAt(0);
                String pasteText = item.getText() != null ? item.getText().toString() : "";
                int selectionStart = getSelectionStart();
                Editable text = getText();
                Objects.requireNonNull(text);
                StringBuilder sb = new StringBuilder(text.toString());
                sb.insert(selectionStart, pasteText);
                setText(MoonUtil.getEmotionContent(getContext(), this, sb.toString()));
                setSelection(selectionStart + pasteText.length());
                return true;
            }
        }
        return super.onTextContextMenuItem(id);
    }

    @Override
    protected void performFiltering(CharSequence text, int keyCode) {
        super.performFiltering(text, keyCode);
    }
}
