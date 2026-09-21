package com.chat.base.views.sidebar;

import android.content.Context;
import android.content.res.TypedArray;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.Typeface;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.View;

import com.chat.base.R;
import com.chat.base.views.sidebar.listener.OnQuickSideBarTouchListener;

import java.util.Arrays;
import java.util.List;

public class QuickSideBarView extends View {
    private OnQuickSideBarTouchListener listener;
    private int mChoose;
    private int mHeight;
    private float mItemHeight;
    private float mItemStartY;
    private List<String> mLetters;
    private final Paint mPaint;
    private int mTextColor;
    private int mTextColorChoose;
    private float mTextSize;
    private float mTextSizeChoose;
    private int mWidth;

    public QuickSideBarView(Context context, AttributeSet attributeSet, int i) {
        super(context, attributeSet, i);
        this.mChoose = -1;
        this.mPaint = new Paint();
        init(context, attributeSet);
    }

    private void init(Context context, AttributeSet attributeSet) {
        this.mLetters = Arrays.asList(context.getResources().getStringArray(R.array.quickSideBarLetters));
        this.mTextColor = context.getResources().getColor(android.R.color.black);
        this.mTextColorChoose = context.getResources().getColor(android.R.color.black);
        this.mTextSize = context.getResources().getDimensionPixelSize(R.dimen.font_size_10);
        this.mTextSizeChoose = context.getResources().getDimensionPixelSize(R.dimen.font_size_16);
        this.mItemHeight = context.getResources().getDimension(R.dimen.font_size_20);
        if (attributeSet != null) {
            TypedArray obtainStyledAttributes = getContext().obtainStyledAttributes(attributeSet, R.styleable.QuickSideBarView);
            this.mTextColor = obtainStyledAttributes.getColor(R.styleable.QuickSideBarView_sidebarTextColor, this.mTextColor);
            this.mTextColorChoose = obtainStyledAttributes.getColor(R.styleable.QuickSideBarView_sidebarTextColorChoose, this.mTextColorChoose);
            this.mTextSize = obtainStyledAttributes.getDimension(R.styleable.QuickSideBarView_sidebarTextSize, this.mTextSize);
            this.mTextSizeChoose = obtainStyledAttributes.getDimension(R.styleable.QuickSideBarView_sidebarTextSizeChoose, this.mTextSizeChoose);
            this.mItemHeight = obtainStyledAttributes.getDimension(R.styleable.QuickSideBarView_sidebarItemHeight, this.mItemHeight);
            obtainStyledAttributes.recycle();
        }
    }

    @Override
    public boolean dispatchTouchEvent(MotionEvent motionEvent) {
        int action = motionEvent.getAction();
        float y = motionEvent.getY();
        int i = this.mChoose;
        int i2 = (int) ((y - this.mItemStartY) / this.mItemHeight);
        if (action != 1) {
            if (i != i2) {
                if (i2 >= 0 && i2 < this.mLetters.size()) {
                    this.mChoose = i2;
                    if (this.listener != null) {
                        Rect rect = new Rect();
                        this.mPaint.getTextBounds(this.mLetters.get(this.mChoose), 0, this.mLetters.get(this.mChoose).length(), rect);
                        this.listener.onLetterChanged(this.mLetters.get(i2), this.mChoose, (this.mChoose * this.mItemHeight) + ((int) ((this.mItemHeight - rect.height()) * 0.5)) + this.mItemStartY);
                    }
                }
                invalidate();
            }
            if (motionEvent.getAction() == 3) {
                if (this.listener != null) {
                    this.listener.onLetterTouching(false);
                }
            } else if (motionEvent.getAction() == 0 && this.listener != null) {
                this.listener.onLetterTouching(true);
            }
        } else {
            this.mChoose = -1;
            if (this.listener != null) {
                this.listener.onLetterTouching(false);
            }
            invalidate();
        }
        return true;
    }

    public List<String> getLetters() {
        return this.mLetters;
    }

    public OnQuickSideBarTouchListener getListener() {
        return this.listener;
    }

    @Override
    public void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        for (int i = 0; i < this.mLetters.size(); i++) {
            this.mPaint.setColor(this.mTextColor);
            this.mPaint.setAntiAlias(true);
            this.mPaint.setTextSize(this.mTextSize);
            if (i == this.mChoose) {
                this.mPaint.setColor(this.mTextColorChoose);
                this.mPaint.setFakeBoldText(true);
                this.mPaint.setTypeface(Typeface.DEFAULT_BOLD);
                this.mPaint.setTextSize(this.mTextSizeChoose);
            }
            Rect rect = new Rect();
            this.mPaint.getTextBounds(this.mLetters.get(i), 0, this.mLetters.get(i).length(), rect);
            canvas.drawText(this.mLetters.get(i), (int) ((this.mWidth - rect.width()) * 0.5), (i * this.mItemHeight) + ((int) ((this.mItemHeight - rect.height()) * 0.5)) + this.mItemStartY, this.mPaint);
            this.mPaint.reset();
        }
    }

    @Override
    public void onMeasure(int i, int i2) {
        super.onMeasure(i, i2);
        this.mHeight = getMeasuredHeight();
        this.mWidth = getMeasuredWidth();
        this.mItemStartY = (this.mHeight - (this.mLetters.size() * this.mItemHeight)) / 2.0f;
    }

    public void setLetters(List<String> list) {
        this.mLetters = list;
        invalidate();
    }

    public void setOnQuickSideBarTouchListener(OnQuickSideBarTouchListener onQuickSideBarTouchListener) {
        this.listener = onQuickSideBarTouchListener;
    }

    public void setTextChooseColor(int i) {
        this.mTextColorChoose = i;
        invalidate();
    }

    public QuickSideBarView(Context context, AttributeSet attributeSet) {
        this(context, attributeSet, 0);
    }

    public QuickSideBarView(Context context) {
        this(context, null);
    }
}
