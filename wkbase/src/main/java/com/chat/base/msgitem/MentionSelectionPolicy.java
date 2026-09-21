package com.chat.base.msgitem;

import androidx.annotation.Nullable;

import java.util.List;

/**
 * Mention selection policy - prevents duplicate mentions
 */
public final class MentionSelectionPolicy {

    public static final MentionSelectionPolicy INSTANCE = new MentionSelectionPolicy();

    private MentionSelectionPolicy() {
    }

    public static boolean canAdd(@Nullable List<String> list, @Nullable String uid) {
        if (uid == null || uid.isEmpty()) {
            return false;
        }
        if (list == null) {
            return true;
        }
        return !list.contains(uid);
    }
}
