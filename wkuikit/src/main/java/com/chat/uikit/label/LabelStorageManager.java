package com.chat.uikit.label;

import android.content.Context;

import com.chat.base.config.WKSharedPreferencesUtil;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

public class LabelStorageManager {
    private static LabelStorageManager instance;
    private final Context context;
    private static final String SP_KEY_LABELS = "label_list";

    private LabelStorageManager(Context context) {
        this.context = context.getApplicationContext();
    }

    public static LabelStorageManager getInstance(Context context) {
        if (instance == null) {
            synchronized (LabelStorageManager.class) {
                if (instance == null) {
                    instance = new LabelStorageManager(context);
                }
            }
        }
        return instance;
    }

    public void saveLabel(LabelEntity label) {
        List<LabelEntity> list = getAllLabels();
        boolean found = false;
        for (int i = 0; i < list.size(); i++) {
            if (list.get(i).id.equals(label.id)) {
                list.set(i, label);
                found = true;
                break;
            }
        }
        if (!found) {
            list.add(0, label);
        }
        saveLabels(list);
    }

    public void deleteLabel(String labelId) {
        List<LabelEntity> list = getAllLabels();
        list.removeIf(l -> l.id.equals(labelId));
        saveLabels(list);
    }

    public LabelEntity getLabel(String labelId) {
        List<LabelEntity> list = getAllLabels();
        for (LabelEntity l : list) {
            if (l.id.equals(labelId)) {
                return l;
            }
        }
        return null;
    }

    public List<LabelEntity> getAllLabels() {
        List<LabelEntity> list = new ArrayList<>();
        String json = WKSharedPreferencesUtil.getInstance().getSP(SP_KEY_LABELS);
        if (json != null && !json.isEmpty()) {
            try {
                JSONArray array = new JSONArray(json);
                for (int i = 0; i < array.length(); i++) {
                    JSONObject obj = array.getJSONObject(i);
                    LabelEntity label = new LabelEntity();
                    label.id = obj.optString("id", "");
                    label.name = obj.optString("name", "");
                    label.memberCount = obj.optInt("memberCount", 0);

                    JSONArray membersArray = obj.optJSONArray("members");
                    if (membersArray != null) {
                        for (int j = 0; j < membersArray.length(); j++) {
                            JSONObject memberObj = membersArray.getJSONObject(j);
                            LabelEntity.LabelMember member = new LabelEntity.LabelMember();
                            member.uid = memberObj.optString("uid", "");
                            member.name = memberObj.optString("name", "");
                            member.avatar = memberObj.optString("avatar", "");
                            label.members.add(member);
                        }
                    }
                    list.add(label);
                }
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        return list;
    }

    private void saveLabels(List<LabelEntity> list) {
        JSONArray array = new JSONArray();
        for (LabelEntity label : list) {
            JSONObject obj = new JSONObject();
            try {
                obj.put("id", label.id != null ? label.id : "");
                obj.put("name", label.name != null ? label.name : "");
                obj.put("memberCount", label.memberCount);

                JSONArray membersArray = new JSONArray();
                for (LabelEntity.LabelMember member : label.members) {
                    JSONObject memberObj = new JSONObject();
                    memberObj.put("uid", member.uid != null ? member.uid : "");
                    memberObj.put("name", member.name != null ? member.name : "");
                    memberObj.put("avatar", member.avatar != null ? member.avatar : "");
                    membersArray.put(memberObj);
                }
                obj.put("members", membersArray);
                array.put(obj);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        WKSharedPreferencesUtil.getInstance().putSP(SP_KEY_LABELS, array.toString());
    }
}
