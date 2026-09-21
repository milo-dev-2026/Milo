package com.chat.uikit.note;

/**
 * 笔记块数据模型
 */
public class NoteBlock {
    public static final int TYPE_TITLE = 1;
    public static final int TYPE_TEXT = 2;
    public static final int TYPE_IMAGE = 3;
    public static final int TYPE_VIDEO = 4;
    public static final int TYPE_LOCATION = 5;

    public int type;
    public String content;     // 标题/文字内容
    public String imagePath;   // 图片路径
    public String videoPath;   // 视频路径
    public String videoCover;  // 视频封面
    public String locationName;     // 位置名称
    public String locationAddress;  // 位置详细地址
    public double latitude;    // 纬度
    public double longitude;   // 经度

    public NoteBlock(int type) {
        this.type = type;
    }

    // 标题/文字
    public static NoteBlock createTitle() {
        return new NoteBlock(TYPE_TITLE);
    }

    public static NoteBlock createText() {
        return new NoteBlock(TYPE_TEXT);
    }

    // 图片
    public static NoteBlock createImage(String imagePath) {
        NoteBlock block = new NoteBlock(TYPE_IMAGE);
        block.imagePath = imagePath;
        return block;
    }

    // 视频
    public static NoteBlock createVideo(String videoPath, String videoCover) {
        NoteBlock block = new NoteBlock(TYPE_VIDEO);
        block.videoPath = videoPath;
        block.videoCover = videoCover;
        return block;
    }

    // 位置
    public static NoteBlock createLocation(String name, String address, double lat, double lng) {
        NoteBlock block = new NoteBlock(TYPE_LOCATION);
        block.locationName = name;
        block.locationAddress = address;
        block.latitude = lat;
        block.longitude = lng;
        return block;
    }
}
