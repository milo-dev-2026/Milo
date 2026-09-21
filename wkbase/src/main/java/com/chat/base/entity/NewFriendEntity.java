package com.chat.base.entity;

/**
 * 2019-11-30 12:12
 * 新朋友实例
 */
public class NewFriendEntity {
    public String apply_uid;
    public String apply_name;
    public String token;
    public String created_at;
    public int status;//0：等待通过1：已通过 2：已拒绝
    public String remark;
    public int type; // 0：好友申请 1：入群申请
    public String group_no; // 入群申请时的群号
    public String group_name; // 入群申请时的群名称

}
