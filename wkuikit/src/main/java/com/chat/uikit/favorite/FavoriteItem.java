package com.chat.uikit.favorite;

/**
 * 收藏条目实体类
 */
public class FavoriteItem {
    public static final int TYPE_TEXT = 1;
    public static final int TYPE_IMAGE = 2;
    public static final int TYPE_VIDEO = 3;
    public static final int TYPE_LOCATION = 4;
    public static final int TYPE_FILE = 5;
    public static final int TYPE_VOICE = 6;
    public static final int TYPE_LINK = 7;

    public long id;
    public int type;
    public String content;
    public String extra;
    public String senderName;
    public String senderAvatar;
    public String time;
    public String fromConversation;
    public boolean isSelected;
    public int width;
    public int height;
    public String videoUrl;

    public FavoriteItem() {
    }

    public FavoriteItem(long id, int type, String content, String extra, String senderName, String time) {
        this.id = id;
        this.type = type;
        this.content = content;
        this.extra = extra;
        this.senderName = senderName;
        this.time = time;
    }
}
