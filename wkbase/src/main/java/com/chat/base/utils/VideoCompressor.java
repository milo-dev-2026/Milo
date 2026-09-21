package com.chat.base.utils;

import android.content.Context;
import android.media.MediaCodec;
import android.media.MediaCodecInfo;
import android.media.MediaCodecList;
import android.media.MediaExtractor;
import android.media.MediaFormat;
import android.media.MediaMuxer;
import android.opengl.EGL14;
import android.opengl.EGLConfig;
import android.opengl.EGLContext;
import android.opengl.EGLDisplay;
import android.opengl.EGLSurface;
import android.opengl.EGLExt;
import android.opengl.GLES20;
import android.os.Build;
import android.view.Surface;
import android.graphics.SurfaceTexture;

import java.io.File;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;

/**
 * 视频压缩工具：使用 MediaCodec 硬件编解码，将视频压缩到 720p + 2Mbps。
 * 参考 UTalk 的转码策略，在客户端发送前完成压缩，大幅减小文件体积，实现秒发秒收。
 */
public class VideoCompressor {

    private static final String TAG = "VideoCompressor";

    private static final int TARGET_RESOLUTION = 720;
    private static final int TARGET_BITRATE = 2_000_000;
    private static final int FRAME_RATE = 30;
    private static final int I_FRAME_INTERVAL = 2;
    private static final long TIMEOUT_USEC = 10000;

    public interface Callback {
        void onStart();
        void onProgress(int progress);
        void onSuccess(String compressedPath, long compressedSize);
        void onFailure(String error);
    }

    public static void compress(Context context, String inputPath, Callback callback) {
        new Thread(() -> doCompress(context, inputPath, callback)).start();
    }

    public static boolean shouldCompress(String videoPath) {
        File f = new File(videoPath);
        if (!f.exists() || f.length() < 2 * 1024 * 1024) return false;
        try {
            MediaExtractor ex = new MediaExtractor();
            ex.setDataSource(videoPath);
            int track = selectTrack(ex, false);
            if (track < 0) { ex.release(); return false; }
            MediaFormat fmt = ex.getTrackFormat(track);
            int width = fmt.getInteger(MediaFormat.KEY_WIDTH);
            int height = fmt.getInteger(MediaFormat.KEY_HEIGHT);
            int bitrate = fmt.containsKey(MediaFormat.KEY_BIT_RATE)
                    ? fmt.getInteger(MediaFormat.KEY_BIT_RATE) : 0;
            ex.release();
            return width > TARGET_RESOLUTION || height > TARGET_RESOLUTION || bitrate > TARGET_BITRATE * 2;
        } catch (Exception e) {
            return false;
        }
    }

    private static void doCompress(Context context, String inputPath, Callback callback) {
        if (callback != null) callback.onStart();
        MediaExtractor videoExtractor = null;
        MediaExtractor audioExtractor = null;
        MediaCodec decoder = null;
        MediaCodec encoder = null;
        MediaMuxer muxer = null;
        InputSurface inputSurface = null;
        OutputSurface outputSurface = null;

        try {
            videoExtractor = new MediaExtractor();
            videoExtractor.setDataSource(inputPath);
            int videoTrackIndex = selectTrack(videoExtractor, false);
            if (videoTrackIndex < 0) throw new RuntimeException("No video track found");
            videoExtractor.selectTrack(videoTrackIndex);
            MediaFormat inputVideoFormat = videoExtractor.getTrackFormat(videoTrackIndex);

            int srcWidth = inputVideoFormat.getInteger(MediaFormat.KEY_WIDTH);
            int srcHeight = inputVideoFormat.getInteger(MediaFormat.KEY_HEIGHT);
            int rotation = inputVideoFormat.containsKey(MediaFormat.KEY_ROTATION)
                    ? inputVideoFormat.getInteger(MediaFormat.KEY_ROTATION) : 0;
            long duration = inputVideoFormat.containsKey(MediaFormat.KEY_DURATION)
                    ? inputVideoFormat.getLong(MediaFormat.KEY_DURATION) : 0;

            int[] dims = calculateTargetDimensions(srcWidth, srcHeight);
            int dstWidth = dims[0];
            int dstHeight = dims[1];

            File outputDir = new File(context.getExternalCacheDir(), "compressed_video");
            if (!outputDir.exists()) outputDir.mkdirs();
            String outputPath = new File(outputDir, "CMP_" + System.currentTimeMillis() + ".mp4").getAbsolutePath();

            String mimeType = "video/avc";
            MediaFormat encodeFormat = MediaFormat.createVideoFormat(mimeType, dstWidth, dstHeight);
            encodeFormat.setInteger(MediaFormat.KEY_COLOR_FORMAT,
                    MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface);
            encodeFormat.setInteger(MediaFormat.KEY_BIT_RATE, TARGET_BITRATE);
            encodeFormat.setInteger(MediaFormat.KEY_FRAME_RATE, FRAME_RATE);
            encodeFormat.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, I_FRAME_INTERVAL);
            if (rotation != 0) {
                encodeFormat.setInteger(MediaFormat.KEY_ROTATION, rotation);
            }

            encoder = MediaCodec.createEncoderByType(mimeType);
            encoder.configure(encodeFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE);
            Surface encoderInputSurface = encoder.createInputSurface();
            inputSurface = new InputSurface(encoderInputSurface);
            encoder.start();

            outputSurface = new OutputSurface();
            decoder = MediaCodec.createDecoderByType(inputVideoFormat.getString(MediaFormat.KEY_MIME));
            decoder.configure(inputVideoFormat, outputSurface.getSurface(), null, 0);
            decoder.start();

            muxer = new MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4);
            if (rotation != 0) muxer.setOrientationHint(rotation);

            int audioTrackIndex = -1;
            int audioExtractorTrack = selectTrack(videoExtractor, true);
            if (audioExtractorTrack >= 0) {
                audioExtractor = new MediaExtractor();
                audioExtractor.setDataSource(inputPath);
                int at = selectTrack(audioExtractor, true);
                if (at >= 0) {
                    audioExtractor.selectTrack(at);
                    audioTrackIndex = muxer.addTrack(audioExtractor.getTrackFormat(at));
                }
            }

            ByteBuffer[] decoderInputBuffers = decoder.getInputBuffers();
            ByteBuffer[] decoderOutputBuffers = decoder.getOutputBuffers();
            ByteBuffer[] encoderOutputBuffers = encoder.getOutputBuffers();
            MediaCodec.BufferInfo decoderInfo = new MediaCodec.BufferInfo();
            MediaCodec.BufferInfo encoderInfo = new MediaCodec.BufferInfo();

            int muxerVideoTrack = muxer.addTrack(encodeFormat);
            boolean muxerStarted = false;
            long videoFramesProcessed = 0;
            long estimatedFrameCount = duration > 0 ? (duration / 1000000) * FRAME_RATE : 0;
            if (estimatedFrameCount == 0) estimatedFrameCount = 100;

            boolean sawInputEOS = false;
            boolean sawOutputEOS = false;
            boolean encoderDone = false;

            while (!encoderDone) {
                if (!sawInputEOS) {
                    int inputBufIndex = decoder.dequeueInputBuffer(TIMEOUT_USEC);
                    if (inputBufIndex >= 0) {
                        ByteBuffer inputBuf = decoderInputBuffers[inputBufIndex];
                        int sampleSize = videoExtractor.readSampleData(inputBuf, 0);
                        if (sampleSize < 0) {
                            decoder.queueInputBuffer(inputBufIndex, 0, 0, 0L,
                                    MediaCodec.BUFFER_FLAG_END_OF_STREAM);
                            sawInputEOS = true;
                        } else {
                            decoder.queueInputBuffer(inputBufIndex, 0, sampleSize,
                                    videoExtractor.getSampleTime(), 0);
                            videoExtractor.advance();
                        }
                    }
                }

                if (!sawOutputEOS) {
                    int outputBufIndex = decoder.dequeueOutputBuffer(decoderInfo, TIMEOUT_USEC);
                    if (outputBufIndex >= 0) {
                        boolean isEOS = (decoderInfo.flags & MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0;
                        outputSurface.awaitNewImage();
                        outputSurface.drawImage();
                        inputSurface.setPresentationTime(decoderInfo.presentationTimeUs * 1000);
                        inputSurface.enableSwapBuffers();
                        inputSurface.swapBuffers();
                        decoder.releaseOutputBuffer(outputBufIndex, true);

                        if (isEOS) sawOutputEOS = true;
                        videoFramesProcessed++;
                        if (callback != null && estimatedFrameCount > 0) {
                            int prog = (int) Math.min(95, videoFramesProcessed * 100 / estimatedFrameCount);
                            callback.onProgress(prog);
                        }
                    }
                }

                while (true) {
                    int encOutputIdx = encoder.dequeueOutputBuffer(encoderInfo, TIMEOUT_USEC);
                    if (encOutputIdx == MediaCodec.INFO_TRY_AGAIN_LATER) {
                        break;
                    } else if (encOutputIdx == MediaCodec.INFO_OUTPUT_BUFFERS_CHANGED) {
                        encoderOutputBuffers = encoder.getOutputBuffers();
                    } else if (encOutputIdx == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                        MediaFormat newFormat = encoder.getOutputFormat();
                        if (!muxerStarted) {
                            muxerVideoTrack = muxer.addTrack(newFormat);
                            muxer.start();
                            muxerStarted = true;
                        }
                    } else if (encOutputIdx >= 0) {
                        ByteBuffer encData = encoderOutputBuffers[encOutputIdx];
                        if (encoderInfo.size > 0 && muxerStarted) {
                            byte[] outData = new byte[encoderInfo.size];
                            encData.position(encoderInfo.offset);
                            encData.get(outData, 0, encoderInfo.size);
                            muxer.writeSampleData(muxerVideoTrack, ByteBuffer.wrap(outData), encoderInfo);
                        }
                        encoder.releaseOutputBuffer(encOutputIdx, false);
                        if ((encoderInfo.flags & MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                            encoderDone = true;
                            break;
                        }
                    }
                }
            }

            if (audioExtractor != null && audioTrackIndex >= 0 && muxerStarted) {
                int maxBufSize = 256 * 1024;
                ByteBuffer audioBuf = ByteBuffer.allocate(maxBufSize);
                while (true) {
                    int sampleSize = audioExtractor.readSampleData(audioBuf, 0);
                    if (sampleSize < 0) break;
                    long pts = audioExtractor.getSampleTime();
                    byte[] copy = new byte[sampleSize];
                    audioBuf.position(0);
                    audioBuf.get(copy, 0, sampleSize);
                    MediaCodec.BufferInfo audioInfo = new MediaCodec.BufferInfo();
                    audioInfo.offset = 0;
                    audioInfo.size = sampleSize;
                    audioInfo.presentationTimeUs = pts;
                    audioInfo.flags = audioExtractor.getSampleFlags();
                    muxer.writeSampleData(audioTrackIndex, ByteBuffer.wrap(copy), audioInfo);
                    audioExtractor.advance();
                }
            }

            if (muxerStarted) {
                muxer.stop();
            } else {
                muxer.start();
                muxer.stop();
            }

            File outputFile = new File(outputPath);
            long compressedSize = outputFile.length();
            if (callback != null) {
                callback.onProgress(100);
                callback.onSuccess(outputPath, compressedSize);
            }
        } catch (Exception e) {
            if (callback != null) callback.onFailure(e.getMessage() != null ? e.getMessage() : "Unknown error");
        } finally {
            try { if (decoder != null) { decoder.stop(); decoder.release(); } } catch (Exception ignored) {}
            try { if (encoder != null) { encoder.stop(); encoder.release(); } } catch (Exception ignored) {}
            try { if (videoExtractor != null) videoExtractor.release(); } catch (Exception ignored) {}
            try { if (audioExtractor != null) audioExtractor.release(); } catch (Exception ignored) {}
            try { if (muxer != null) muxer.release(); } catch (Exception ignored) {}
            try { if (inputSurface != null) inputSurface.release(); } catch (Exception ignored) {}
            try { if (outputSurface != null) outputSurface.release(); } catch (Exception ignored) {}
        }
    }

    private static int[] calculateTargetDimensions(int srcW, int srcH) {
        if (srcW <= TARGET_RESOLUTION && srcH <= TARGET_RESOLUTION) {
            return new int[]{srcW, srcH};
        }
        float ratio = (float) srcW / srcH;
        if (srcW >= srcH) {
            int w = TARGET_RESOLUTION;
            int h = Math.round(TARGET_RESOLUTION / ratio);
            h = (h / 2) * 2;
            return new int[]{w, h};
        } else {
            int h = TARGET_RESOLUTION;
            int w = Math.round(TARGET_RESOLUTION * ratio);
            w = (w / 2) * 2;
            return new int[]{w, h};
        }
    }

    private static int selectTrack(MediaExtractor extractor, boolean audio) {
        for (int i = 0; i < extractor.getTrackCount(); i++) {
            MediaFormat format = extractor.getTrackFormat(i);
            String mime = format.getString(MediaFormat.KEY_MIME);
            if (audio) {
                if (mime.startsWith("audio/")) return i;
            } else {
                if (mime.startsWith("video/")) return i;
            }
        }
        return -1;
    }

    // ===================== EGL Input Surface (encoder input) =====================
    private static class InputSurface {
        private EGLDisplay eglDisplay;
        private EGLContext eglContext;
        private EGLSurface eglSurface;
        private Surface surface;

        InputSurface(Surface surface) {
            this.surface = surface;
            eglDisplay = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY);
            EGL14.eglInitialize(eglDisplay, null, 0, null, 0);

            int[] configsAttribs = new int[]{
                    EGL14.EGL_RED_SIZE, 8,
                    EGL14.EGL_GREEN_SIZE, 8,
                    EGL14.EGL_BLUE_SIZE, 8,
                    EGL14.EGL_ALPHA_SIZE, 8,
                    EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
                    EGL_RECORDABLE_ANDROID, 1,
                    EGL14.EGL_NONE
            };
            android.opengl.EGLConfig[] configs = new android.opengl.EGLConfig[1];
            int[] numConfigs = new int[1];
            EGL14.eglChooseConfig(eglDisplay, configsAttribs, 0, configs, 0, configs.length, numConfigs, 0);

            int[] contextAttribs = new int[]{
                    EGL14.EGL_CONTEXT_CLIENT_VERSION, 2,
                    EGL14.EGL_NONE
            };
            eglContext = EGL14.eglCreateContext(eglDisplay, configs[0], EGL14.EGL_NO_CONTEXT, contextAttribs, 0);

            int[] surfaceAttribs = new int[]{EGL14.EGL_NONE};
            eglSurface = EGL14.eglCreateWindowSurface(eglDisplay, configs[0], surface, surfaceAttribs, 0);
            EGL14.eglMakeCurrent(eglDisplay, eglSurface, eglSurface, eglContext);
        }

        void setPresentationTime(long pts) {
            EGLExt.eglPresentationTimeANDROID(eglDisplay, eglSurface, pts);
        }

        void enableSwapBuffers() {}

        void swapBuffers() {
            EGL14.eglSwapBuffers(eglDisplay, eglSurface);
        }

        void release() {
            EGL14.eglMakeCurrent(eglDisplay, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_CONTEXT);
            EGL14.eglDestroySurface(eglDisplay, eglSurface);
            EGL14.eglDestroyContext(eglDisplay, eglContext);
            EGL14.eglTerminate(eglDisplay);
            if (surface != null) surface.release();
        }
    }

    private static final int EGL_RECORDABLE_ANDROID = 0x3142;
    private static final int GL_TEXTURE_EXTERNAL_OES = 0x8D65;

    // ===================== Output Surface (decoder output) =====================
    private static class OutputSurface implements SurfaceTexture.OnFrameAvailableListener {
        private EGLDisplay eglDisplay;
        private EGLContext eglContext;
        private EGLSurface eglSurface;
        private SurfaceTexture surfaceTexture;
        private Surface surface;
        private int textureId;
        private boolean frameAvailable = false;
        private boolean EGLReady = false;
        private final Object frameSync = new Object();
        private TextureRenderer renderer;

        OutputSurface() {
            setupEGL();
            setupTexture();
        }

        private void setupEGL() {
            eglDisplay = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY);
            EGL14.eglInitialize(eglDisplay, null, 0, null, 0);

            int[] configsAttribs = new int[]{
                    EGL14.EGL_RED_SIZE, 8,
                    EGL14.EGL_GREEN_SIZE, 8,
                    EGL14.EGL_BLUE_SIZE, 8,
                    EGL14.EGL_ALPHA_SIZE, 8,
                    EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
                    EGL_RECORDABLE_ANDROID, 1,
                    EGL14.EGL_NONE
            };
            android.opengl.EGLConfig[] configs = new android.opengl.EGLConfig[1];
            int[] numConfigs = new int[1];
            EGL14.eglChooseConfig(eglDisplay, configsAttribs, 0, configs, 0, configs.length, numConfigs, 0);

            int[] contextAttribs = new int[]{
                    EGL14.EGL_CONTEXT_CLIENT_VERSION, 2,
                    EGL14.EGL_NONE
            };
            eglContext = EGL14.eglCreateContext(eglDisplay, configs[0], EGL14.EGL_NO_CONTEXT, contextAttribs, 0);

            int[] surfaceAttribs = new int[]{EGL14.EGL_NONE};
            eglSurface = EGL14.eglCreatePbufferSurface(eglDisplay, configs[0], surfaceAttribs, 0);
            EGL14.eglMakeCurrent(eglDisplay, eglSurface, eglSurface, eglContext);
            EGLReady = true;
        }

        private void setupTexture() {
            int[] textures = new int[1];
            GLES20.glGenTextures(1, textures, 0);
            textureId = textures[0];
            GLES20.glBindTexture(GL_TEXTURE_EXTERNAL_OES, textureId);
            GLES20.glTexParameterf(GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_NEAREST);
            GLES20.glTexParameterf(GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);

            surfaceTexture = new SurfaceTexture(textureId);
            surfaceTexture.setOnFrameAvailableListener(this);
            surface = new Surface(surfaceTexture);
            renderer = new TextureRenderer();
        }

        Surface getSurface() {
            return surface;
        }

        void awaitNewImage() {
            synchronized (frameSync) {
                while (!frameAvailable) {
                    try {
                        frameSync.wait(500);
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                        return;
                    }
                }
                frameAvailable = false;
            }
            surfaceTexture.updateTexImage();
        }

        void drawImage() {
            if (renderer != null && EGLReady) {
                renderer.draw(textureId);
            }
        }

        @Override
        public void onFrameAvailable(SurfaceTexture st) {
            synchronized (frameSync) {
                frameAvailable = true;
                frameSync.notifyAll();
            }
        }

        void release() {
            if (surface != null) { surface.release(); surface = null; }
            if (surfaceTexture != null) { surfaceTexture.release(); surfaceTexture = null; }
            if (eglDisplay != null) {
                EGL14.eglMakeCurrent(eglDisplay, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_CONTEXT);
                EGL14.eglDestroySurface(eglDisplay, eglSurface);
                EGL14.eglDestroyContext(eglDisplay, eglContext);
                EGL14.eglTerminate(eglDisplay);
            }
        }
    }

    // ===================== Texture Renderer =====================
    private static class TextureRenderer {
        private int program;
        private int aPositionLoc;
        private int aTexCoordLoc;
        private int uTextureLoc;

        private final FloatBuffer vertexBuffer;
        private final FloatBuffer texBuffer;

        private static final float[] VERTICES = {
                -1.0f, -1.0f,
                1.0f, -1.0f,
                -1.0f, 1.0f,
                1.0f, 1.0f
        };

        private static final float[] TEX_COORDS = {
                0.0f, 0.0f,
                1.0f, 0.0f,
                0.0f, 1.0f,
                1.0f, 1.0f
        };

        TextureRenderer() {
            vertexBuffer = ByteBuffer.allocateDirect(VERTICES.length * 4)
                    .order(ByteOrder.nativeOrder()).asFloatBuffer();
            vertexBuffer.put(VERTICES).position(0);

            texBuffer = ByteBuffer.allocateDirect(TEX_COORDS.length * 4)
                    .order(ByteOrder.nativeOrder()).asFloatBuffer();
            texBuffer.put(TEX_COORDS).position(0);

            String vertexShader =
                    "attribute vec4 aPosition;\n" +
                    "attribute vec2 aTexCoord;\n" +
                    "varying vec2 vTexCoord;\n" +
                    "void main() {\n" +
                    "  gl_Position = aPosition;\n" +
                    "  vTexCoord = aTexCoord;\n" +
                    "}\n";

            String fragmentShader =
                    "#extension GL_OES_EGL_image_external : require\n" +
                    "precision mediump float;\n" +
                    "varying vec2 vTexCoord;\n" +
                    "uniform samplerExternalOES uTexture;\n" +
                    "void main() {\n" +
                    "  gl_FragColor = texture2D(uTexture, vTexCoord);\n" +
                    "}\n";

            int vs = loadShader(GLES20.GL_VERTEX_SHADER, vertexShader);
            int fs = loadShader(GLES20.GL_FRAGMENT_SHADER, fragmentShader);
            program = GLES20.glCreateProgram();
            GLES20.glAttachShader(program, vs);
            GLES20.glAttachShader(program, fs);
            GLES20.glLinkProgram(program);
            aPositionLoc = GLES20.glGetAttribLocation(program, "aPosition");
            aTexCoordLoc = GLES20.glGetAttribLocation(program, "aTexCoord");
            uTextureLoc = GLES20.glGetUniformLocation(program, "uTexture");
        }

        void draw(int textureId) {
            GLES20.glUseProgram(program);

            GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
            GLES20.glBindTexture(GL_TEXTURE_EXTERNAL_OES, textureId);
            GLES20.glUniform1i(uTextureLoc, 0);

            vertexBuffer.position(0);
            GLES20.glVertexAttribPointer(aPositionLoc, 2, GLES20.GL_FLOAT, false, 8, vertexBuffer);
            GLES20.glEnableVertexAttribArray(aPositionLoc);

            texBuffer.position(0);
            GLES20.glVertexAttribPointer(aTexCoordLoc, 2, GLES20.GL_FLOAT, false, 8, texBuffer);
            GLES20.glEnableVertexAttribArray(aTexCoordLoc);

            GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);

            GLES20.glDisableVertexAttribArray(aPositionLoc);
            GLES20.glDisableVertexAttribArray(aTexCoordLoc);
        }

        private int loadShader(int type, String shaderCode) {
            int shader = GLES20.glCreateShader(type);
            GLES20.glShaderSource(shader, shaderCode);
            GLES20.glCompileShader(shader);
            return shader;
        }
    }
}
