package com.chat.richeditor.component.util;

import android.graphics.Color;

public class WMColor {
    public static final int[] TEXT_COLORS = {
            0xFF000000, // 黑
            0xFFE74C3C, // 红
            0xFFE67E22, // 橙
            0xFFF1C40F, // 黄
            0xFF2ECC71, // 绿
            0xFF3498DB, // 蓝
            0xFF9B59B6, // 紫
            0xFF7F8C8D, // 灰
            0xFFFFFFFF, // 白
    };

    public static final int[] TEXT_SIZES = {
            12, 14, 16, 18, 20, 24, 28, 32
    };

    public static String colorToHex(int color) {
        return String.format("#%06X", 0xFFFFFF & color);
    }

    public static int parseColor(String colorString) {
        if (colorString == null || colorString.isEmpty()) {
            return Color.BLACK;
        }
        try {
            if (!colorString.startsWith("#")) {
                colorString = "#" + colorString;
            }
            return Color.parseColor(colorString);
        } catch (Exception e) {
            return Color.BLACK;
        }
    }
}
