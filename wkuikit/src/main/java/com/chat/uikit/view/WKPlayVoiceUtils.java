package com.chat.uikit.view;

import android.media.MediaPlayer;
import android.os.Handler;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

/**
 * 2021/8/2 17:01
 */
public class WKPlayVoiceUtils {
    private WKPlayVoiceUtils() {

    }

    private static class PlayVoiceUtilsBinder {
        static WKPlayVoiceUtils playVoiceUtils = new WKPlayVoiceUtils();
    }

    public static WKPlayVoiceUtils getInstance() {
        return PlayVoiceUtilsBinder.playVoiceUtils;
    }

    private List<IPlayListener> iPlayListener;
    private String oldPlayKey;
    public MediaPlayer mediaPlayer;

    public String getPlayKey() {
        return oldPlayKey;
    }

    public void playVoice(String voicePath, String playKey) {
        if (mediaPlayer != null) {
            try {
                if (mediaPlayer.isPlaying())
                    mediaPlayer.stop();
            } catch (Exception e) {
                e.printStackTrace();
            }
            try {
                mediaPlayer.reset();
            } catch (Exception e) {
                e.printStackTrace();
            }
            try {
                mediaPlayer.release();
            } catch (Exception e) {
                e.printStackTrace();
            }
            mediaPlayer = null;
        }
        handler.removeCallbacks(runnable);
        position = 0;
        if (voicePath == null || voicePath.isEmpty()) {
            return;
        }
        java.io.File file = new java.io.File(voicePath);
        if (!file.exists() || file.length() == 0) {
            return;
        }
        mediaPlayer = new MediaPlayer();
        this.oldPlayKey = playKey;
        try {
            mediaPlayer.setOnPreparedListener(new MediaPlayer.OnPreparedListener() {
                @Override
                public void onPrepared(MediaPlayer mp) {
                    try {
                        mediaPlayer.start();
                        handler.post(runnable);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    mediaPlayer.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
                        @Override
                        public void onCompletion(MediaPlayer mp) {
                            handler.removeCallbacks(runnable);
                            if (iPlayListener != null) {
                                for (int i = 0; i < iPlayListener.size(); i++) {
                                    iPlayListener.get(i).onCompletion(oldPlayKey);
                                }
                            }
                            position = 0;
                        }
                    });
                }
            });
            mediaPlayer.setDataSource(voicePath);
            mediaPlayer.prepareAsync();

        } catch (Exception e) {
            e.printStackTrace();
            if (mediaPlayer != null) {
                try {
                    mediaPlayer.release();
                } catch (Exception ex) {
                    ex.printStackTrace();
                }
                mediaPlayer = null;
            }
        }

    }

    public String getOldPlayKey() {
        return oldPlayKey;
    }

    public boolean isPlaying() {
        return mediaPlayer != null && mediaPlayer.isPlaying();
    }

    public void stopPlay() {
        if (mediaPlayer != null) {
            try {
                mediaPlayer.stop();
            } catch (Exception e) {
                e.printStackTrace();
            }
            handler.removeCallbacks(runnable);
            position = 0;
            try {
                if (iPlayListener != null) {
                    for (int i = 0; i < iPlayListener.size(); i++) {
                        iPlayListener.get(i).onStop(oldPlayKey);
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
            try {
                mediaPlayer.reset();
                mediaPlayer.release();
            } catch (Exception e) {
                e.printStackTrace();
            }
            mediaPlayer = null;
        }
    }

    public void onPause() {
        if (mediaPlayer != null) {
            handler.removeCallbacks(runnable);
            mediaPlayer.pause();
        }
    }

    private int position;
    Handler handler = new Handler();
    public Runnable runnable = new Runnable() {

        @Override
        public void run() {
            if (mediaPlayer == null) {
                handler.removeCallbacks(runnable);
                return;
            }
            try {
                position = mediaPlayer.getCurrentPosition();
                int total = mediaPlayer.getDuration();
                if (iPlayListener != null) {
                    float progress = total > 0 ? (float) position / total : 0f;
                    for (int i = 0; i < iPlayListener.size(); i++) {
                        iPlayListener.get(i).onProgress(oldPlayKey, progress);
                    }
                }
                handler.postDelayed(runnable, 100);
            } catch (Exception e) {
                e.printStackTrace();
                handler.removeCallbacks(runnable);
            }
        }
    };

    public void setPlayListener(IPlayListener iPlayListener) {
        this.iPlayListener = new ArrayList<>();
        this.iPlayListener.add(iPlayListener);
    }

    public interface IPlayListener {
        void onCompletion(String key);

        void onProgress(String key, float pg);

        void onStop(String key);
    }
}
