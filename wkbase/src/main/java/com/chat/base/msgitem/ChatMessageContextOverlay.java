package com.chat.base.msgitem;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.AnimatorSet;
import android.animation.ObjectAnimator;
import android.content.Context;
import android.graphics.Rect;
import android.graphics.RenderEffect;
import android.graphics.Shader;
import android.os.Build;
import android.view.KeyEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewParent;
import android.view.animation.DecelerateInterpolator;
import android.widget.FrameLayout;
import android.widget.ImageView;

import com.chat.base.ui.components.ReactionsContainerLayout;
import com.chat.base.utils.AndroidUtilities;

import java.util.ArrayList;
import java.util.List;

public final class ChatMessageContextOverlay extends FrameLayout {

    private static final float MENU_WIDTH_SCREEN_RATIO = 0.52f;
    private static final int MIN_MENU_WIDTH_DP = 188;

    private AnimatorSet animatorSet;
    private final View blurTarget;
    private final ChatFrostedBackdropView dimView;
    private boolean dismissFinished;
    private boolean dismissing;
    private final int horizontalMargin;
    private final ViewGroup host;
    private final DecelerateInterpolator interpolator;
    private final boolean isSentByMe;
    private final ChatContextMenuView menuView;
    private final Runnable onDismissComplete;
    private final ReactionsContainerLayout reactionsView;
    private final ChatMessageSnapshotHelper.Snapshot snapshot;
    private final ImageView snapshotView;

    public ChatMessageContextOverlay(Context context, ViewGroup host, View blurTarget,
                                     ChatMessageSnapshotHelper.Snapshot snapshot,
                                     ChatContextMenuView menuView,
                                     ReactionsContainerLayout reactionsView,
                                     boolean isSentByMe,
                                     Runnable onDismissComplete) {
        super(context);
        this.host = host;
        this.blurTarget = blurTarget;
        this.snapshot = snapshot;
        this.menuView = menuView;
        this.reactionsView = reactionsView;
        this.isSentByMe = isSentByMe;
        this.onDismissComplete = onDismissComplete;
        this.interpolator = new DecelerateInterpolator(1.5f);
        this.horizontalMargin = dp(20);

        ChatFrostedBackdropView frostedView = new ChatFrostedBackdropView(context);
        this.dimView = frostedView;

        ImageView imageView = new ImageView(context);
        this.snapshotView = imageView;

        setFocusable(true);
        setFocusableInTouchMode(true);
        setBackgroundColor(0);

        frostedView.setAlpha(0f);
        frostedView.setOnClickListener(v -> dismiss(true));
        addView(frostedView, new FrameLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT));

        if (snapshot != null && snapshot.getBitmap() != null) {
            imageView.setImageBitmap(snapshot.getBitmap());
            imageView.setScaleType(ImageView.ScaleType.FIT_XY);
            imageView.setPivotX(0f);
            imageView.setPivotY(0f);
            Rect rect = snapshot.getRectInHost();
            FrameLayout.LayoutParams snapParams = new FrameLayout.LayoutParams(rect.width(), rect.height());
            snapParams.leftMargin = rect.left;
            snapParams.topMargin = rect.top;
            addView(imageView, snapParams);
        }

        if (reactionsView != null) {
            reactionsView.setAlpha(0f);
            addView(reactionsView, new FrameLayout.LayoutParams(WRAP_CONTENT, AndroidUtilities.dp(74f)));
        }

        menuView.setAlpha(0f);
        addView(menuView, new FrameLayout.LayoutParams(WRAP_CONTENT, WRAP_CONTENT));
    }

    private void applyBackgroundBlur() {
        if (Build.VERSION.SDK_INT >= 31 && blurTarget != null) {
            RenderEffect effect = RenderEffect.createBlurEffect(
                    AndroidUtilities.dp(18f), AndroidUtilities.dp(18f), Shader.TileMode.CLAMP);
            blurTarget.setRenderEffect(effect);
        }
    }

    private void clearBackgroundBlur() {
        if (Build.VERSION.SDK_INT >= 31 && blurTarget != null) {
            blurTarget.setRenderEffect(null);
        }
    }

    private int dp(int value) {
        return AndroidUtilities.dp(value);
    }

    private int maxFloatingWidth() {
        return Math.max(host.getWidth() - horizontalMargin * 2, dp(120));
    }

    private int targetMenuWidth() {
        return Math.min(Math.max(Math.round(host.getWidth() * MENU_WIDTH_SCREEN_RATIO), dp(MIN_MENU_WIDTH_DP)), maxFloatingWidth());
    }

    private int resolvedReactionWidth() {
        if (reactionsView != null) {
            return Math.min(reactionsView.getMeasuredWidth(), maxFloatingWidth());
        }
        return 0;
    }

    private void measureFloatingViews() {
        int widthSpec = View.MeasureSpec.makeMeasureSpec(maxFloatingWidth(), View.MeasureSpec.AT_MOST);
        int heightSpec = View.MeasureSpec.makeMeasureSpec(host.getHeight(), View.MeasureSpec.AT_MOST);
        int menuWidth = targetMenuWidth();
        menuView.setMinimumWidth(menuWidth);
        menuView.measure(View.MeasureSpec.makeMeasureSpec(menuWidth, View.MeasureSpec.EXACTLY), heightSpec);
        if (reactionsView != null) {
            reactionsView.measure(widthSpec, heightSpec);
        }
    }

    private ChatContextPositionCalculator.LayoutResult calculateTargetLayout() {
        int menuWidth = targetMenuWidth();
        int menuHeight = menuView.getMeasuredHeight();
        int reactionWidth = reactionsView != null ? resolvedReactionWidth() : 0;
        int reactionHeight = reactionsView != null ? reactionsView.getMeasuredHeight() : 0;
        boolean hasReactions = reactionsView != null;

        return ChatContextPositionCalculator.INSTANCE.calculate(
                host, snapshot.getRectInHost(),
                snapshot.getRectInHost().width(), snapshot.getRectInHost().height(),
                reactionWidth, reactionHeight, menuWidth, menuHeight,
                hasReactions, isSentByMe);
    }

    private void applyInitialFloatingLayout(ChatContextPositionCalculator.LayoutResult layout) {
        FrameLayout.LayoutParams menuParams = (FrameLayout.LayoutParams) menuView.getLayoutParams();
        int menuWidth = targetMenuWidth();
        int menuHeight = menuView.getMeasuredHeight();
        if (menuHeight <= 0) menuHeight = dp(50) * Math.max(1, menuView.getChildCount());
        menuParams.width = menuWidth;
        menuParams.height = menuHeight;
        menuParams.leftMargin = layout.getMenuLeft();
        menuParams.topMargin = layout.getMenuTop();
        menuParams.gravity = GravityStart | GravityTop;
        menuView.setLayoutParams(menuParams);

        if (reactionsView != null) {
            FrameLayout.LayoutParams reactionParams = (FrameLayout.LayoutParams) reactionsView.getLayoutParams();
            int rw = resolvedReactionWidth();
            if (rw <= 0) rw = dp(200);
            int rh = reactionsView.getMeasuredHeight();
            if (rh <= 0) rh = dp(52);
            reactionParams.width = rw;
            reactionParams.height = rh;
            reactionParams.leftMargin = layout.getReactionLeft();
            reactionParams.topMargin = layout.getReactionTop();
            reactionParams.gravity = GravityStart | GravityTop;
            reactionsView.setLayoutParams(reactionParams);
        }
    }

    private void playShowAnimation(ChatContextPositionCalculator.LayoutResult layout) {
        List<Animator> animators = new ArrayList<>();

        animators.add(ObjectAnimator.ofFloat(dimView, View.ALPHA, 0f, 1f));

        if (snapshotView != null && snapshot != null) {
            animators.add(ObjectAnimator.ofFloat(snapshotView, View.X, (float) snapshot.getRectInHost().left, (float) layout.getMessageLeft()));
            animators.add(ObjectAnimator.ofFloat(snapshotView, View.Y, (float) snapshot.getRectInHost().top, (float) layout.getMessageTop()));
        }

        animators.add(ObjectAnimator.ofFloat(menuView, View.ALPHA, 0f, 1f));
        animators.add(ObjectAnimator.ofFloat(menuView, View.TRANSLATION_Y, (float) dp(8), 0f));

        if (reactionsView != null) {
            animators.add(ObjectAnimator.ofFloat(reactionsView, View.ALPHA, 0f, 1f));
            animators.add(ObjectAnimator.ofFloat(reactionsView, View.TRANSLATION_Y, (float) dp(8), 0f));
        }

        AnimatorSet set = new AnimatorSet();
        set.playTogether(animators);
        set.setDuration(210L);
        set.setInterpolator(interpolator);
        set.start();
        animatorSet = set;

        if (reactionsView != null) {
            reactionsView.startEnterAnimation();
        }
    }

    private void cancelCurrentAnimation() {
        if (animatorSet == null) return;
        animatorSet.removeAllListeners();
        animatorSet.cancel();
        animatorSet = null;
    }

    private Rect latestSourceRect() {
        View sourceView = snapshot.getSourceView();
        if (sourceView.isAttachedToWindow() && sourceView.getWidth() > 0 && sourceView.getHeight() > 0) {
            int[] sourceLoc = new int[2];
            int[] hostLoc = new int[2];
            sourceView.getLocationOnScreen(sourceLoc);
            host.getLocationOnScreen(hostLoc);
            int left = sourceLoc[0] - hostLoc[0];
            int top = sourceLoc[1] - hostLoc[1];
            return new Rect(left, top, left + sourceView.getWidth(), top + sourceView.getHeight());
        }
        return null;
    }

    private void finishDismiss() {
        if (dismissFinished) return;
        dismissFinished = true;
        cancelCurrentAnimation();
        clearBackgroundBlur();
        ChatMessageSnapshotHelper.INSTANCE.restoreSource(snapshot.getSourceView());
        if (snapshot.getBitmap() != null) {
            snapshot.getBitmap().recycle();
        }
        if (getParent() instanceof ViewGroup) {
            ((ViewGroup) getParent()).removeView(this);
        }
        if (onDismissComplete != null) {
            onDismissComplete.run();
        }
    }

    public void show() {
        applyBackgroundBlur();
        host.addView(this, new FrameLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT));
        requestFocus();
        host.post(() -> {
            if (snapshot == null) {
                if (onDismissComplete != null) onDismissComplete.run();
                return;
            }
            measureFloatingViews();
            ChatContextPositionCalculator.LayoutResult layout = calculateTargetLayout();
            applyInitialFloatingLayout(layout);
            ChatMessageSnapshotHelper.INSTANCE.hideSourceUntilDetached(snapshot.getSourceView());
            playShowAnimation(layout);
        });
    }

    public void dismiss(boolean animated) {
        if (dismissing) return;
        dismissing = true;
        cancelCurrentAnimation();

        if (!animated) {
            finishDismiss();
            return;
        }

        Rect sourceRect = latestSourceRect();
        if (sourceRect == null) {
            sourceRect = snapshot.getRectInHost();
        }

        List<Animator> animators = new ArrayList<>();
        animators.add(ObjectAnimator.ofFloat(dimView, View.ALPHA, dimView.getAlpha(), 0f));

        if (snapshotView != null) {
            animators.add(ObjectAnimator.ofFloat(snapshotView, View.X, snapshotView.getX(), (float) sourceRect.left));
            animators.add(ObjectAnimator.ofFloat(snapshotView, View.Y, snapshotView.getY(), (float) sourceRect.top));
            float scaleW = snapshot.getRectInHost().width() > 0
                    ? (float) sourceRect.width() / snapshot.getRectInHost().width() : 1f;
            float scaleH = snapshot.getRectInHost().height() > 0
                    ? (float) sourceRect.height() / snapshot.getRectInHost().height() : 1f;
            animators.add(ObjectAnimator.ofFloat(snapshotView, View.SCALE_X, snapshotView.getScaleX(), scaleW));
            animators.add(ObjectAnimator.ofFloat(snapshotView, View.SCALE_Y, snapshotView.getScaleY(), scaleH));
        }

        animators.add(ObjectAnimator.ofFloat(menuView, View.ALPHA, menuView.getAlpha(), 0f));

        if (reactionsView != null) {
            animators.add(ObjectAnimator.ofFloat(reactionsView, View.ALPHA, reactionsView.getAlpha(), 0f));
        }

        AnimatorSet set = new AnimatorSet();
        set.playTogether(animators);
        set.setDuration(180L);
        set.setInterpolator(interpolator);
        set.addListener(new AnimatorListenerAdapter() {
            @Override
            public void onAnimationEnd(Animator animation) {
                finishDismiss();
            }
        });
        set.start();
        animatorSet = set;
    }

    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        if (event.getKeyCode() == KeyEvent.KEYCODE_BACK && event.getAction() == KeyEvent.ACTION_UP) {
            dismiss(true);
            return true;
        }
        return super.dispatchKeyEvent(event);
    }

    private static final int MATCH_PARENT = FrameLayout.LayoutParams.MATCH_PARENT;
    private static final int WRAP_CONTENT = FrameLayout.LayoutParams.WRAP_CONTENT;
    private static final int GravityStart = android.view.Gravity.START;
    private static final int GravityTop = android.view.Gravity.TOP;
}
