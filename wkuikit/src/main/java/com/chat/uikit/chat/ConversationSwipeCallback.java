package com.chat.uikit.chat;

import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.Typeface;
import android.graphics.drawable.ColorDrawable;
import android.view.MotionEvent;
import android.view.View;
import android.view.animation.DecelerateInterpolator;
import android.view.animation.Interpolator;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.RecyclerView;

public class ConversationSwipeCallback extends ItemTouchHelper.Callback {

    public interface SwipeActions {
        String getMuteText(int position);
        void onMute(int position);
        String getPinText(int position);
        void onPin(int position);
        void onDelete(int position);
    }

    private static final int BUTTON_WIDTH = 200;
    private static final int BUTTON_COUNT = 3;
    private static final float SWIPE_OPEN_THRESHOLD = 0.3f;

    private final SwipeActions swipeActions;
    private final ColorDrawable orangeBackground;
    private final ColorDrawable blueBackground;
    private final ColorDrawable redBackground;
    private final Paint textPaint;

    private int swipedPosition = -1;
    private float currentDx = 0f;
    private boolean shouldFixSwipe = false;
    private boolean lastIsActive = false;
    private RecyclerView recyclerView;
    private RecyclerView.ItemDecoration buttonDecoration;
    private final Interpolator interpolator = new DecelerateInterpolator(1.5f);
    private long animationStartTime = 0;
    private float animationStartDx = 0;
    private float animationTargetDx = 0;
    private boolean isAnimating = false;

    public ConversationSwipeCallback(android.app.Activity activity, SwipeActions swipeActions) {
        this.swipeActions = swipeActions;
        orangeBackground = new ColorDrawable(Color.parseColor("#FF9500"));
        blueBackground = new ColorDrawable(Color.parseColor("#3F74FC"));
        redBackground = new ColorDrawable(Color.parseColor("#FA5151"));
        textPaint = new Paint();
        textPaint.setAntiAlias(true);
        textPaint.setColor(Color.WHITE);
        textPaint.setTextSize(42);
        textPaint.setTypeface(Typeface.create(Typeface.DEFAULT, Typeface.BOLD));
        textPaint.setTextAlign(Paint.Align.CENTER);
    }

    public void attachToRecyclerView(RecyclerView rv) {
        this.recyclerView = rv;

        buttonDecoration = new RecyclerView.ItemDecoration() {
            @Override
            public void onDraw(@NonNull Canvas c, @NonNull RecyclerView parent, @NonNull RecyclerView.State state) {
                super.onDraw(c, parent, state);
                if (swipedPosition < 0) return;

                RecyclerView.ViewHolder vh = parent.findViewHolderForAdapterPosition(swipedPosition);
                if (vh == null) return;

                View itemView = vh.itemView;
                int itemHeight = itemView.getHeight();
                int totalButtonWidth = BUTTON_WIDTH * BUTTON_COUNT;

                if (Math.abs(itemView.getTranslationX()) >= totalButtonWidth * 0.9f) {
                    drawFullButtons(c, itemView, swipedPosition, itemHeight);
                }
            }
        };
        rv.addItemDecoration(buttonDecoration);

        rv.addOnItemTouchListener(new RecyclerView.OnItemTouchListener() {
            @Override
            public boolean onInterceptTouchEvent(@NonNull RecyclerView rv, @NonNull MotionEvent e) {
                if (swipedPosition < 0) return false;

                if (e.getAction() == MotionEvent.ACTION_DOWN) {
                    RecyclerView.ViewHolder vh = rv.findViewHolderForAdapterPosition(swipedPosition);
                    if (vh == null) {
                        swipedPosition = -1;
                        rv.invalidateItemDecorations();
                        return false;
                    }
                    View itemView = vh.itemView;
                    float x = e.getX();
                    float y = e.getY();

                    if (y < itemView.getTop() || y > itemView.getBottom()) {
                        closeSwipedItem();
                        return false;
                    }

                    int totalButtonWidth = BUTTON_WIDTH * BUTTON_COUNT;
                    int buttonsLeft = itemView.getRight() - totalButtonWidth;
                    int buttonsRight = itemView.getRight();

                    if (x >= buttonsLeft && x <= buttonsRight) {
                        int buttonIndexFromRight = (int) ((buttonsRight - x) / BUTTON_WIDTH);
                        if (buttonIndexFromRight < 0) buttonIndexFromRight = 0;
                        if (buttonIndexFromRight >= BUTTON_COUNT) buttonIndexFromRight = BUTTON_COUNT - 1;

                        switch (buttonIndexFromRight) {
                            case 0:
                                try { swipeActions.onMute(swipedPosition); } catch (Exception ex) { android.util.Log.e("SwipeCallback", "onMute error", ex); }
                                break;
                            case 1:
                                try { swipeActions.onPin(swipedPosition); } catch (Exception ex) { android.util.Log.e("SwipeCallback", "onPin error", ex); }
                                break;
                            case 2:
                                try { swipeActions.onDelete(swipedPosition); } catch (Exception ex) { android.util.Log.e("SwipeCallback", "onDelete error", ex); }
                                break;
                        }
                        closeSwipedItem();
                        return true;
                    }

                    if (x < itemView.getRight() - totalButtonWidth) {
                        closeSwipedItem();
                        return false;
                    }
                }
                return false;
            }

            @Override
            public void onTouchEvent(@NonNull RecyclerView rv, @NonNull MotionEvent e) {
            }

            @Override
            public void onRequestDisallowInterceptTouchEvent(boolean disallowIntercept) {
            }
        });

        rv.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrolled(@NonNull RecyclerView recyclerView, int dx, int dy) {
                if (dy != 0 && swipedPosition >= 0) {
                    closeSwipedItem();
                }
            }
        });

        rv.addOnChildAttachStateChangeListener(new RecyclerView.OnChildAttachStateChangeListener() {
            @Override
            public void onChildViewAttachedToWindow(@NonNull View view) {
                RecyclerView.ViewHolder vh = rv.getChildViewHolder(view);
                if (vh != null) {
                    int position = vh.getBindingAdapterPosition();
                    if (position != swipedPosition) {
                        view.setTranslationX(0);
                    } else {
                        int totalButtonWidth = BUTTON_WIDTH * BUTTON_COUNT;
                        view.setTranslationX(-totalButtonWidth);
                    }
                }
            }

            @Override
            public void onChildViewDetachedFromWindow(@NonNull View view) {
                RecyclerView.ViewHolder vh = rv.getChildViewHolder(view);
                if (vh != null) {
                    int position = vh.getBindingAdapterPosition();
                    if (position == swipedPosition) {
                        swipedPosition = -1;
                        rv.post(() -> {
                            if (rv.isComputingLayout()) return;
                            try {
                                rv.invalidateItemDecorations();
                            } catch (Exception ignored) { android.util.Log.w("SwipeCallback", "invalidateItemDecorations", ignored); }
                        });
                    }
                }
                view.setTranslationX(0);
            }
        });
    }

    public void closeSwipedItem() {
        if (swipedPosition >= 0 && recyclerView != null) {
            RecyclerView.ViewHolder vh = recyclerView.findViewHolderForAdapterPosition(swipedPosition);
            if (vh != null) {
                vh.itemView.setTranslationX(0);
            }
            swipedPosition = -1;
            shouldFixSwipe = false;
            isAnimating = false;
            try {
                recyclerView.invalidateItemDecorations();
            } catch (Exception ignored) { android.util.Log.w("SwipeCallback", "closeSwipedItem invalidate", ignored); }
        }
    }

    public int getSwipedPosition() {
        return swipedPosition;
    }

    @Override
    public int getMovementFlags(@NonNull RecyclerView recyclerView, @NonNull RecyclerView.ViewHolder viewHolder) {
        int dragFlags = 0;
        int swipeFlags = ItemTouchHelper.START;
        return makeMovementFlags(dragFlags, swipeFlags);
    }

    @Override
    public boolean onMove(@NonNull RecyclerView recyclerView, @NonNull RecyclerView.ViewHolder viewHolder, @NonNull RecyclerView.ViewHolder target) {
        return false;
    }

    @Override
    public float getSwipeThreshold(@NonNull RecyclerView.ViewHolder viewHolder) {
        return Float.MAX_VALUE;
    }

    @Override
    public float getSwipeEscapeVelocity(float defaultValue) {
        return Float.MAX_VALUE;
    }

    @Override
    public float getSwipeVelocityThreshold(float defaultValue) {
        return Float.MAX_VALUE;
    }

    @Override
    public void onSwiped(@NonNull RecyclerView.ViewHolder viewHolder, int direction) {
    }

    @Override
    public void clearView(@NonNull RecyclerView recyclerView, @NonNull RecyclerView.ViewHolder viewHolder) {
        super.clearView(recyclerView, viewHolder);
        int position = viewHolder.getBindingAdapterPosition();
        if (position < 0) return;

        int totalButtonWidth = BUTTON_WIDTH * BUTTON_COUNT;

        if (shouldFixSwipe) {
            viewHolder.itemView.setTranslationX(-totalButtonWidth);
            if (swipedPosition >= 0 && swipedPosition != position) {
                RecyclerView.ViewHolder prevVh = recyclerView.findViewHolderForAdapterPosition(swipedPosition);
                if (prevVh != null) {
                    prevVh.itemView.setTranslationX(0);
                }
            }
            swipedPosition = position;
        } else {
            viewHolder.itemView.setTranslationX(0);
            if (swipedPosition == position) {
                swipedPosition = -1;
            }
        }

        currentDx = 0f;
        lastIsActive = false;
        isAnimating = false;
        recyclerView.invalidateItemDecorations();
    }

    @Override
    public void onSelectedChanged(RecyclerView.ViewHolder viewHolder, int actionState) {
        super.onSelectedChanged(viewHolder, actionState);
        if (actionState == ItemTouchHelper.ACTION_STATE_IDLE) {
            if (shouldFixSwipe && viewHolder != null) {
                int totalButtonWidth = BUTTON_WIDTH * BUTTON_COUNT;
                viewHolder.itemView.setTranslationX(-totalButtonWidth);
            }
            isAnimating = false;
        }
    }

    @Override
    public void onChildDraw(@NonNull Canvas canvas, @NonNull RecyclerView recyclerView,
                            @NonNull RecyclerView.ViewHolder viewHolder, float dX, float dY,
                            int actionState, boolean isCurrentlyActive) {
        if (actionState == ItemTouchHelper.ACTION_STATE_SWIPE) {
            currentDx = dX;
            View itemView = viewHolder.itemView;
            int position = viewHolder.getBindingAdapterPosition();
            int maxSwipe = BUTTON_WIDTH * BUTTON_COUNT;

            if (isCurrentlyActive && swipedPosition >= 0 && swipedPosition != position) {
                RecyclerView.ViewHolder prevVh = recyclerView.findViewHolderForAdapterPosition(swipedPosition);
                if (prevVh != null) {
                    prevVh.itemView.setTranslationX(0);
                }
                swipedPosition = -1;
                recyclerView.invalidateItemDecorations();
            }

            if (lastIsActive && !isCurrentlyActive) {
                if (Math.abs(currentDx) >= BUTTON_WIDTH * SWIPE_OPEN_THRESHOLD) {
                    shouldFixSwipe = true;
                    if (swipedPosition >= 0 && swipedPosition != position) {
                        RecyclerView.ViewHolder prevVh = recyclerView.findViewHolderForAdapterPosition(swipedPosition);
                        if (prevVh != null) {
                            prevVh.itemView.setTranslationX(0);
                        }
                    }
                    swipedPosition = position;
                    isAnimating = true;
                    animationStartTime = System.currentTimeMillis();
                    animationStartDx = currentDx;
                    animationTargetDx = -maxSwipe;
                } else {
                    shouldFixSwipe = false;
                    isAnimating = true;
                    animationStartTime = System.currentTimeMillis();
                    animationStartDx = currentDx;
                    animationTargetDx = 0;
                }
            }
            lastIsActive = isCurrentlyActive;

            float clampedDx = dX;
            float absDx = Math.abs(dX);

            if (isAnimating && !isCurrentlyActive) {
                float elapsed = (float)(System.currentTimeMillis() - animationStartTime);
                float t = Math.min(1f, elapsed / 250f);
                float interpolated = interpolator.getInterpolation(t);
                clampedDx = animationStartDx + (animationTargetDx - animationStartDx) * interpolated;
                absDx = Math.abs(clampedDx);
                if (t >= 1f) {
                    isAnimating = false;
                }
            } else if (!isCurrentlyActive && shouldFixSwipe) {
                clampedDx = -maxSwipe;
                absDx = maxSwipe;
            } else {
                if (absDx > maxSwipe) {
                    clampedDx = -maxSwipe;
                    absDx = maxSwipe;
                }
            }

            int itemHeight = itemView.getHeight();
            drawButtonBackgrounds(canvas, itemView, clampedDx, absDx, position, itemHeight);

            super.onChildDraw(canvas, recyclerView, viewHolder, clampedDx, dY, actionState, isCurrentlyActive);
        } else {
            super.onChildDraw(canvas, recyclerView, viewHolder, dX, dY, actionState, isCurrentlyActive);
        }
    }

    private void drawButtonBackgrounds(Canvas canvas, View itemView, float clampedDx, float absDx, int position, int itemHeight) {
        String muteText;
        String pinText;
        try {
            muteText = position >= 0 ? swipeActions.getMuteText(position) : "关闭通知";
            pinText = position >= 0 ? swipeActions.getPinText(position) : "置顶";
        } catch (Exception e) {
            muteText = "关闭通知";
            pinText = "置顶";
        }

        if (absDx <= BUTTON_WIDTH) {
            orangeBackground.setBounds(itemView.getRight() + (int) clampedDx, itemView.getTop(),
                    itemView.getRight(), itemView.getBottom());
            orangeBackground.draw(canvas);
            drawText(canvas, muteText, itemView, BUTTON_WIDTH, 0, (int) clampedDx, itemHeight);
        } else if (absDx <= BUTTON_WIDTH * 2) {
            orangeBackground.setBounds(itemView.getRight() - BUTTON_WIDTH, itemView.getTop(),
                    itemView.getRight(), itemView.getBottom());
            orangeBackground.draw(canvas);
            drawText(canvas, muteText, itemView, BUTTON_WIDTH, 0, -BUTTON_WIDTH, itemHeight);

            blueBackground.setBounds(itemView.getRight() + (int) clampedDx, itemView.getTop(),
                    itemView.getRight() - BUTTON_WIDTH, itemView.getBottom());
            blueBackground.draw(canvas);
            drawText(canvas, pinText, itemView, BUTTON_WIDTH, 1, (int) clampedDx, itemHeight);
        } else {
            orangeBackground.setBounds(itemView.getRight() - BUTTON_WIDTH, itemView.getTop(),
                    itemView.getRight(), itemView.getBottom());
            orangeBackground.draw(canvas);
            drawText(canvas, muteText, itemView, BUTTON_WIDTH, 0, -BUTTON_WIDTH, itemHeight);

            blueBackground.setBounds(itemView.getRight() - BUTTON_WIDTH * 2, itemView.getTop(),
                    itemView.getRight() - BUTTON_WIDTH, itemView.getBottom());
            blueBackground.draw(canvas);
            drawText(canvas, pinText, itemView, BUTTON_WIDTH, 1, -BUTTON_WIDTH * 2, itemHeight);

            redBackground.setBounds(itemView.getRight() + (int) clampedDx, itemView.getTop(),
                    itemView.getRight() - BUTTON_WIDTH * 2, itemView.getBottom());
            redBackground.draw(canvas);
            drawText(canvas, "删除", itemView, BUTTON_WIDTH, 2, (int) clampedDx, itemHeight);
        }
    }

    private void drawFullButtons(Canvas canvas, View itemView, int position, int itemHeight) {
        String muteText;
        String pinText;
        try {
            muteText = position >= 0 ? swipeActions.getMuteText(position) : "关闭通知";
            pinText = position >= 0 ? swipeActions.getPinText(position) : "置顶";
        } catch (Exception e) {
            muteText = "关闭通知";
            pinText = "置顶";
        }
        int totalButtonWidth = BUTTON_WIDTH * BUTTON_COUNT;

        orangeBackground.setBounds(itemView.getRight() - BUTTON_WIDTH, itemView.getTop(),
                itemView.getRight(), itemView.getBottom());
        orangeBackground.draw(canvas);
        drawText(canvas, muteText, itemView, BUTTON_WIDTH, 0, -BUTTON_WIDTH, itemHeight);

        blueBackground.setBounds(itemView.getRight() - BUTTON_WIDTH * 2, itemView.getTop(),
                itemView.getRight() - BUTTON_WIDTH, itemView.getBottom());
        blueBackground.draw(canvas);
        drawText(canvas, pinText, itemView, BUTTON_WIDTH, 1, -BUTTON_WIDTH * 2, itemHeight);

        redBackground.setBounds(itemView.getRight() - totalButtonWidth, itemView.getTop(),
                itemView.getRight() - BUTTON_WIDTH * 2, itemView.getBottom());
        redBackground.draw(canvas);
        drawText(canvas, "删除", itemView, BUTTON_WIDTH, 2, -totalButtonWidth, itemHeight);
    }

    private void drawText(Canvas canvas, String text, View itemView, int buttonWidth,
                          int buttonIndex, int dX, int itemHeight) {
        int buttonRight = itemView.getRight() - buttonIndex * buttonWidth;
        int buttonLeft = buttonRight - buttonWidth;
        float centerX = (buttonLeft + buttonRight) / 2f;
        float centerY = itemView.getTop() + itemHeight / 2f;
        Rect textBounds = new Rect();
        textPaint.getTextBounds(text, 0, text.length(), textBounds);
        float baseline = centerY + textBounds.height() / 2f - textBounds.bottom;
        canvas.drawText(text, centerX, baseline, textPaint);
    }
}
