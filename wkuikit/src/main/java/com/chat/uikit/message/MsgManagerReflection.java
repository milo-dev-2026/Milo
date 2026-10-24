package com.chat.uikit.message;

import android.util.Log;
import com.xinbida.wukongim.entity.WKSyncExtraMsg;
import java.lang.reflect.Field;

public class MsgManagerReflection {
    public static void dumpSyncExtraMsgFields() {
        try {
            Field[] fields = WKSyncExtraMsg.class.getDeclaredFields();
            Log.d("WKReceiptDebug", "=== WKSyncExtraMsg fields (" + fields.length + ") ===");
            for (Field f : fields) {
                f.setAccessible(true);
                Log.d("WKReceiptDebug", "  " + f.getType().getSimpleName() + " " + f.getName());
            }
        } catch (Exception e) {
            Log.e("WKReceiptDebug", "dumpSyncExtraMsgFields error: " + e.getMessage());
        }
    }

    public static void dumpChannelFields() {
        try {
            Class<?> clazz = Class.forName("com.xinbida.wukongim.entity.WKChannel");
            Field[] fields = clazz.getDeclaredFields();
            Log.d("WKReceiptDebug", "=== WKChannel fields (" + fields.length + ") ===");
            for (Field f : fields) {
                f.setAccessible(true);
                Log.d("WKReceiptDebug", "  " + f.getType().getSimpleName() + " " + f.getName());
            }
        } catch (Exception e) {
            Log.e("WKReceiptDebug", "dumpChannelFields error: " + e.getMessage());
        }
    }
}
