package com.chat.uikit.note;

import java.util.List;

/**
 * 笔记实体类
 */
public class NoteEntity {
    public String id;
    public String title;
    public String content;
    public String groupName;
    public String remark;
    public String time;
    public boolean isTop;
    public int type; // 1: text, 2: image, 3: video, 4: location
    public String blockListJson; // 笔记块列表的 JSON 序列化数据（完整块结构）
    public String coverUrl; // 笔记封面图URL

    public NoteEntity() {
    }

    public NoteEntity(String id, String title, String content, String groupName, String time, boolean isTop) {
        this.id = id;
        this.title = title;
        this.content = content;
        this.groupName = groupName;
        this.time = time;
        this.isTop = isTop;
    }
}
