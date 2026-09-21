package com.chat.uikit.view.voice;

import android.content.Context;
import android.util.AttributeSet;
import android.view.View;

public class LineWaveVoiceView extends View {
    public LineWaveVoiceView(Context context) { super(context); }
    public LineWaveVoiceView(Context context, AttributeSet attrs) { super(context, attrs); }
    public LineWaveVoiceView(Context context, AttributeSet attrs, int defStyleAttr) { super(context, attrs, defStyleAttr); }

    public void setTextColor(int color) {}
    public void setLineColor(int color) {}
    public void setText(String text) {}
    public void startRecord() {}
    public void stopRecord() {}
    public void setVolume(int volume) {}
}