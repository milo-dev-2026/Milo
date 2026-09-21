package com.chat.uikit.view.voice;

import android.media.MediaRecorder;
import android.os.Handler;
import android.os.Looper;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

public class AudioRecordManager {
    private static AudioRecordManager instance;
    private IAudioRecordListener listener;
    private MediaRecorder mediaRecorder;
    private String filePath;
    private long startTime;
    private boolean isRecording = false;
    private Handler samplingHandler;
    private List<Integer> amplitudeList;
    private static final int SAMPLE_INTERVAL = 100; // 每100ms采样一次

    public static AudioRecordManager getInstance() {
        if (instance == null) {
            synchronized (AudioRecordManager.class) {
                if (instance == null) {
                    instance = new AudioRecordManager();
                }
            }
        }
        return instance;
    }

    public void setAudioRecordListener(IAudioRecordListener listener) {
        this.listener = listener;
    }

    public void startRecord(String filePath) {
        if (isRecording) return;
        try {
            this.filePath = filePath;
            File file = new File(filePath);
            if (file.getParentFile() != null && !file.getParentFile().exists()) {
                file.getParentFile().mkdirs();
            }

            amplitudeList = new ArrayList<>();
            mediaRecorder = new MediaRecorder();
            mediaRecorder.setAudioSource(MediaRecorder.AudioSource.MIC);
            mediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.AMR_NB);
            mediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB);
            mediaRecorder.setAudioSamplingRate(8000);
            mediaRecorder.setAudioEncodingBitRate(12200);
            mediaRecorder.setOutputFile(filePath);
            mediaRecorder.prepare();
            mediaRecorder.start();
            startTime = System.currentTimeMillis();
            isRecording = true;

            // 开始采样振幅
            startSampling();

            if (listener != null) {
                listener.onStartRecord();
            }
        } catch (Exception e) {
            e.printStackTrace();
            isRecording = false;
            stopSampling();
            if (mediaRecorder != null) {
                try {
                    mediaRecorder.release();
                } catch (Exception ex) {
                    ex.printStackTrace();
                }
                mediaRecorder = null;
            }
            if (listener != null) {
                listener.onRecordError();
            }
        }
    }

    private void startSampling() {
        if (samplingHandler == null) {
            samplingHandler = new Handler(Looper.getMainLooper());
        }
        samplingHandler.postDelayed(samplingRunnable, SAMPLE_INTERVAL);
    }

    private void stopSampling() {
        if (samplingHandler != null) {
            samplingHandler.removeCallbacks(samplingRunnable);
        }
    }

    private Runnable samplingRunnable = new Runnable() {
        @Override
        public void run() {
            if (isRecording && mediaRecorder != null) {
                try {
                    int amplitude = mediaRecorder.getMaxAmplitude();
                    // 将振幅转换为 0-31 的值（5位）
                    int value = 0;
                    if (amplitude > 0) {
                        double db = 20 * Math.log10(amplitude / 100.0);
                        value = (int) ((db + 50) / 50 * 31);
                        value = Math.max(0, Math.min(31, value));
                    }
                    amplitudeList.add(value);
                } catch (Exception e) {
                    e.printStackTrace();
                }
                samplingHandler.postDelayed(this, SAMPLE_INTERVAL);
            }
        }
    };

    public void stopRecord() {
        if (!isRecording || mediaRecorder == null) return;
        stopSampling();
        try {
            mediaRecorder.stop();
            long duration = System.currentTimeMillis() - startTime;
            isRecording = false;
            if (listener != null) {
                listener.onRecordFinish(duration, filePath);
            }
        } catch (Exception e) {
            e.printStackTrace();
            if (listener != null) {
                listener.onRecordError();
            }
        } finally {
            if (mediaRecorder != null) {
                try {
                    mediaRecorder.release();
                } catch (Exception e) {
                    e.printStackTrace();
                }
                mediaRecorder = null;
            }
        }
    }

    public void cancelRecord() {
        if (!isRecording || mediaRecorder == null) return;
        stopSampling();
        try {
            mediaRecorder.stop();
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                mediaRecorder.release();
            } catch (Exception e) {
                e.printStackTrace();
            }
            mediaRecorder = null;
            isRecording = false;
            amplitudeList = null;
            // 删除文件
            if (filePath != null) {
                File file = new File(filePath);
                if (file.exists()) {
                    file.delete();
                }
            }
        }
    }

    public boolean isRecording() {
        return isRecording;
    }

    public int getMaxAmplitude() {
        if (mediaRecorder != null && isRecording) {
            try {
                return mediaRecorder.getMaxAmplitude();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        return 0;
    }

    public interface IAudioRecordListener {
        void onStartRecord();
        void onRecordFinish(long time, String filePath);
        void onRecordError();
    }

    /**
     * 返回 5-bit 压缩的波形数据（兼容 WaveformView 格式）
     */
    public byte[] getDbs() {
        if (amplitudeList == null || amplitudeList.isEmpty()) {
            return new byte[0];
        }
        // 将 0-31 的采样值打包成 5-bit 格式
        int numSamples = amplitudeList.size();
        int numBytes = (numSamples * 5 + 7) / 8; // 向上取整
        byte[] result = new byte[numBytes];

        int bitPos = 0; // 当前位位置
        for (int value : amplitudeList) {
            value = Math.max(0, Math.min(31, value)); // 确保 5-bit
            // 将 5-bit 值写入结果数组
            int byteIndex = bitPos / 8;
            int bitOffset = bitPos % 8;

            // 写入当前字节剩余的位
            int bitsInFirstByte = Math.min(5, 8 - bitOffset);
            int firstByteMask = (value >> (5 - bitsInFirstByte)) & ((1 << bitsInFirstByte) - 1);
            result[byteIndex] |= (byte) (firstByteMask << (8 - bitOffset - bitsInFirstByte));

            // 如果还有剩余位，写入下一个字节
            if (bitsInFirstByte < 5) {
                int remainingBits = 5 - bitsInFirstByte;
                int secondByteMask = value & ((1 << remainingBits) - 1);
                if (byteIndex + 1 < numBytes) {
                    result[byteIndex + 1] |= (byte) (secondByteMask << (8 - remainingBits));
                }
            }

            bitPos += 5;
        }
        return result;
    }

    public int getVolume() {
        return getMaxAmplitude();
    }

    public long getStartTime() {
        return startTime;
    }

    public String getFilePath() {
        return filePath;
    }
}
