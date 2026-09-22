package com.chat.uikit.note;

import android.content.Context;

import com.chat.base.config.WKSharedPreferencesUtil;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

public class NoteStorageManager {
    private static NoteStorageManager instance;
    private final Context context;
    private static final String SP_KEY_NOTES = "note_list";

    private NoteStorageManager(Context context) {
        this.context = context.getApplicationContext();
    }

    public static NoteStorageManager getInstance(Context context) {
        if (instance == null) {
            synchronized (NoteStorageManager.class) {
                if (instance == null) {
                    instance = new NoteStorageManager(context);
                }
            }
        }
        return instance;
    }

    public void saveNote(NoteEntity note) {
        List<NoteEntity> list = getAllNotes();
        boolean found = false;
        for (int i = 0; i < list.size(); i++) {
            if (list.get(i).id.equals(note.id)) {
                list.set(i, note);
                found = true;
                break;
            }
        }
        if (!found) {
            list.add(0, note);
        }
        saveNotes(list);
    }

    public void deleteNote(String noteId) {
        List<NoteEntity> list = getAllNotes();
        list.removeIf(n -> n.id.equals(noteId));
        saveNotes(list);
    }

    public NoteEntity getNote(String noteId) {
        List<NoteEntity> list = getAllNotes();
        for (NoteEntity n : list) {
            if (n.id.equals(noteId)) {
                return n;
            }
        }
        return null;
    }

    /**
     * 获取所有笔记（按置顶 + 时间倒序排列）
     */
    public List<NoteEntity> getAllNotes() {
        List<NoteEntity> list = new ArrayList<>();
        String json = WKSharedPreferencesUtil.getInstance().getSP(SP_KEY_NOTES);
        if (json != null && !json.isEmpty()) {
            try {
                JSONArray array = new JSONArray(json);
                for (int i = 0; i < array.length(); i++) {
                    JSONObject obj = array.getJSONObject(i);
                    NoteEntity note = new NoteEntity();
                    note.id = obj.optString("id", "");
                    note.title = obj.optString("title", "");
                    note.content = obj.optString("content", "");
                    note.groupName = obj.optString("groupName", "");
                    note.remark = obj.optString("remark", "");
                    note.time = obj.optString("time", "");
                    note.isTop = obj.optBoolean("isTop", false);
                    note.type = obj.optInt("type", 1);
                    note.blockListJson = obj.optString("blockListJson", "");
                    note.coverUrl = obj.optString("coverUrl", "");
                    list.add(note);
                }
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        return list;
    }

    public void updateNoteGroup(String noteId, String groupName) {
        List<NoteEntity> list = getAllNotes();
        for (NoteEntity n : list) {
            if (n.id.equals(noteId)) {
                n.groupName = groupName;
                break;
            }
        }
        saveNotes(list);
    }

    public void updateNoteRemark(String noteId, String remark) {
        List<NoteEntity> list = getAllNotes();
        for (NoteEntity n : list) {
            if (n.id.equals(noteId)) {
                n.remark = remark;
                break;
            }
        }
        saveNotes(list);
    }

    public void toggleTop(String noteId) {
        List<NoteEntity> list = getAllNotes();
        for (NoteEntity n : list) {
            if (n.id.equals(noteId)) {
                n.isTop = !n.isTop;
                break;
            }
        }
        saveNotes(list);
    }

    private void saveNotes(List<NoteEntity> list) {
        JSONArray array = new JSONArray();
        for (NoteEntity note : list) {
            JSONObject obj = new JSONObject();
            try {
                obj.put("id", note.id != null ? note.id : "");
                obj.put("title", note.title != null ? note.title : "");
                obj.put("content", note.content != null ? note.content : "");
                obj.put("groupName", note.groupName != null ? note.groupName : "");
                obj.put("remark", note.remark != null ? note.remark : "");
                obj.put("time", note.time != null ? note.time : "");
                obj.put("isTop", note.isTop);
                obj.put("type", note.type);
                obj.put("blockListJson", note.blockListJson != null ? note.blockListJson : "");
                obj.put("coverUrl", note.coverUrl != null ? note.coverUrl : "");
                array.put(obj);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        WKSharedPreferencesUtil.getInstance().putSP(SP_KEY_NOTES, array.toString());
    }
}
