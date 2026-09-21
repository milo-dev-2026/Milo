package com.chat.base.msgitem;

import android.graphics.Rect;
import android.view.View;

import com.chat.base.utils.AndroidUtilities;

public final class ChatContextPositionCalculator {

    public static final ChatContextPositionCalculator INSTANCE = new ChatContextPositionCalculator();

    public static class LayoutResult {
        private final int messageLeft;
        private final int messageTop;
        private final int reactionLeft;
        private final int reactionTop;
        private final int menuLeft;
        private final int menuTop;

        public LayoutResult(int messageLeft, int messageTop, int reactionLeft, int reactionTop, int menuLeft, int menuTop) {
            this.messageLeft = messageLeft;
            this.messageTop = messageTop;
            this.reactionLeft = reactionLeft;
            this.reactionTop = reactionTop;
            this.menuLeft = menuLeft;
            this.menuTop = menuTop;
        }

        public int getMessageLeft() { return messageLeft; }
        public int getMessageTop() { return messageTop; }
        public int getReactionLeft() { return reactionLeft; }
        public int getReactionTop() { return reactionTop; }
        public int getMenuLeft() { return menuLeft; }
        public int getMenuTop() { return menuTop; }
    }

    private ChatContextPositionCalculator() {}

    private int clamp(int value, int min, int max) {
        if (max < min) return min;
        return Math.min(Math.max(value, min), max);
    }

    public LayoutResult calculate(View hostView, Rect msgRect, int msgWidth, int msgHeight,
                                   int reactionWidth, int reactionHeight,
                                   int menuWidth, int menuHeight,
                                   boolean hasReactions, boolean isSentByMe) {
        int margin = AndroidUtilities.dp(12f);
        int bottomMargin = AndroidUtilities.dp(12f);
        int topMargin = AndroidUtilities.dp(12f);
        int reactionGap = hasReactions ? AndroidUtilities.dp(2f) : 0;
        int gapBetweenMsgAndMenu = AndroidUtilities.dp(2f);
        int reactionTopOffset = AndroidUtilities.dp(18f);

        int reactionTotalHeight = hasReactions ? reactionHeight + reactionGap : 0;
        int maxBottom = hostView.getHeight() - bottomMargin;
        int totalContentHeight = reactionTotalHeight + msgHeight + gapBetweenMsgAndMenu + menuHeight;

        int messageTop = msgRect.top;

        // Check if everything fits below the message
        int spaceBelow = maxBottom - msgRect.top;
        boolean fitsBelow = spaceBelow >= totalContentHeight;

        if (fitsBelow) {
            // Everything fits: reactions above message, menu below
            // Keep messageTop at msgRect.top, no shift needed
        } else {
            // Not enough space, shift up
            messageTop = maxBottom - totalContentHeight;
            if (messageTop < topMargin) {
                messageTop = topMargin;
            }
        }

        int messageLeft = clamp(msgRect.left, margin, hostView.getWidth() - margin - msgWidth);

        int menuLeft;
        if (isSentByMe) {
            menuLeft = (messageLeft + msgWidth) - menuWidth;
        } else {
            menuLeft = messageLeft;
        }
        menuLeft = clamp(menuLeft, margin, hostView.getWidth() - margin - menuWidth);

        int reactionLeft;
        if (hasReactions) {
            reactionLeft = clamp(messageLeft, margin, hostView.getWidth() - margin - reactionWidth);
        } else {
            reactionLeft = messageLeft;
        }

        // Menu right below message
        int menuTop = messageTop + msgHeight + gapBetweenMsgAndMenu;
        // Clamp menu within screen bounds
        if (menuTop + menuHeight > maxBottom) {
            menuTop = maxBottom - menuHeight;
        }
        if (menuTop < topMargin) {
            menuTop = topMargin;
        }

        // Reactions above message
        int reactionTop;
        if (hasReactions) {
            reactionTop = messageTop - reactionGap - reactionHeight + reactionTopOffset;
            // Clamp within screen
            if (reactionTop < topMargin) {
                reactionTop = topMargin;
            }
        } else {
            reactionTop = messageTop;
        }

        return new LayoutResult(messageLeft, messageTop, reactionLeft, reactionTop, menuLeft, menuTop);
    }
}
