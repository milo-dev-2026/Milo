package com.chat.uikit.label;

import java.util.ArrayList;
import java.util.List;

/**
 * 标签实体类
 */
public class LabelEntity {
    public String id;
    public String name;
    public List<LabelMember> members;
    public int memberCount;

    public LabelEntity() {
        this.members = new ArrayList<>();
    }

    public LabelEntity(String id, String name, int memberCount) {
        this.id = id;
        this.name = name;
        this.memberCount = memberCount;
        this.members = new ArrayList<>();
    }

    /**
     * 标签成员
     */
    public static class LabelMember {
        public String uid;
        public String name;
        public String avatar;
        public boolean isSelected;

        public LabelMember() {
        }

        public LabelMember(String uid, String name, String avatar) {
            this.uid = uid;
            this.name = name;
            this.avatar = avatar;
        }
    }
}
