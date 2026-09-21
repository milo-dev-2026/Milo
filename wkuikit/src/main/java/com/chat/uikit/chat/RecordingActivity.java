package com.chat.uikit.chat;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.graphics.RectF;
import android.graphics.SurfaceTexture;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.params.StreamConfigurationMap;
import android.media.MediaMetadataRetriever;
import android.media.MediaRecorder;
import android.os.Bundle;
import android.os.Handler;
import android.os.HandlerThread;
import android.util.Size;
import android.util.DisplayMetrics;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.TextureView;
import android.view.View;
import android.view.WindowManager;
import android.widget.ImageView;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.chat.base.utils.WKFileUtils;
import com.chat.base.utils.WKMediaFileUtils;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.MP4FastStart;
import com.chat.uikit.R;
import com.chat.video.camera.CaptureLayout;
import com.chat.video.camera.FoucsView;
import com.chat.video.camera.listener.CaptureListener;
import com.chat.video.camera.listener.ClickListener;
import com.chat.video.camera.listener.TypeListener;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.msgmodel.WKImageContent;
import com.xinbida.wukongim.msgmodel.WKVideoContent;

import java.io.File;
import java.io.FileOutputStream;
import java.util.Arrays;

public class RecordingActivity extends AppCompatActivity {

    private static final int REQUEST_PERMISSIONS = 100;
    private static final int MAX_RECORD_DURATION = 15000;

    private TextureView cameraPreview;
    private CaptureLayout captureLayout;
    private FoucsView foucsView;
    private ImageView btnFlash;
    private ImageView btnSwitchCamera;

    private CameraDevice mCameraDevice;
    private CameraCaptureSession mCaptureSession;
    private MediaRecorder mMediaRecorder;
    private SurfaceTexture mSurfaceTexture;
    private Surface mPreviewSurface;
    private Size videoSize;
    private Size previewSize;
    private int sensorOrientation;
    private String currentCameraId;

    private boolean isFlashOn = false;
    private boolean isRecording = false;
    private boolean isFrontCamera = false;
    private HandlerThread mBackgroundThread;
    private Handler mBackgroundHandler;

    private String videoPath;
    private String coverPath;
    private String photoPath;
    private long recordedDuration;

    private String channelId;
    private int channelType;

    public static void start(Context context, String channelId, int channelType) {
        Intent intent = new Intent(context, RecordingActivity.class);
        intent.putExtra("channel_id", channelId);
        intent.putExtra("channel_type", channelType);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        context.startActivity(intent);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN);
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
        if (getSupportActionBar() != null) getSupportActionBar().hide();
        setContentView(R.layout.act_recording_layout);

        channelId = getIntent().getStringExtra("channel_id");
        channelType = getIntent().getIntExtra("channel_type", 1);

        cameraPreview = findViewById(R.id.camera_preview);
        captureLayout = findViewById(R.id.capture_layout);
        foucsView = findViewById(R.id.foucs_view);
        btnFlash = findViewById(R.id.btn_flash);
        btnSwitchCamera = findViewById(R.id.btn_switch_camera);

        captureLayout.setButtonFeatures(259);
        captureLayout.setDuration(MAX_RECORD_DURATION);
        captureLayout.setTip("长按录制视频");

        captureLayout.setCaptureLisenter(new CaptureListener() {
            @Override
            public void a(long remainingTime) {
                runOnUiThread(() -> {
                    WKToastUtils.getInstance().showToastNormal("录制时间太短");
                    cleanupRecording();
                    captureLayout.resetState();
                });
            }

            @Override
            public void b() {
                runOnUiThread(() -> capturePhoto());
            }

            @Override
            public void c(float zoom) {
            }

            @Override
            public void d() {
                runOnUiThread(() -> startRecording());
            }

            @Override
            public void e() {
            }

            @Override
            public void f(long recordedTime) {
                runOnUiThread(() -> stopRecording(recordedTime));
            }
        });

        captureLayout.setTypeLisenter(new TypeListener() {
            @Override
            public void cancel() {
                runOnUiThread(() -> {
                    cleanupRecording();
                    captureLayout.resetState();
                });
            }

            @Override
            public void a() {
                runOnUiThread(() -> {
                    if (videoPath != null && new File(videoPath).exists()) {
                        sendVideoMessage();
                    } else if (photoPath != null && new File(photoPath).exists()) {
                        sendPhotoMessage();
                    }
                    finish();
                });
            }
        });

        captureLayout.setLeftClickListener(new ClickListener() {
            @Override
            public void onClick() {
                finish();
            }
        });

        btnFlash.setOnClickListener(v -> toggleFlash());
        btnSwitchCamera.setOnClickListener(v -> switchCamera());

        cameraPreview.setSurfaceTextureListener(new TextureView.SurfaceTextureListener() {
            @Override
            public void onSurfaceTextureAvailable(@NonNull SurfaceTexture surface, int width, int height) {
                mSurfaceTexture = surface;
                openCamera();
            }

            @Override
            public void onSurfaceTextureSizeChanged(@NonNull SurfaceTexture surface, int width, int height) {
                updateTransform();
            }

            @Override
            public boolean onSurfaceTextureDestroyed(@NonNull SurfaceTexture surface) {
                return true;
            }

            @Override
            public void onSurfaceTextureUpdated(@NonNull SurfaceTexture surface) {
            }
        });

        cameraPreview.setOnTouchListener((v, event) -> {
            if (event.getAction() == MotionEvent.ACTION_UP) {
                showFocus(event.getX(), event.getY());
            }
            return true;
        });

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED
                || ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this,
                    new String[]{Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO},
                    REQUEST_PERMISSIONS);
        } else {
            startBackgroundThread();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_PERMISSIONS) {
            boolean allGranted = true;
            for (int result : grantResults) {
                if (result != PackageManager.PERMISSION_GRANTED) {
                    allGranted = false;
                    break;
                }
            }
            if (allGranted) {
                startBackgroundThread();
            } else {
                WKToastUtils.getInstance().showToastNormal("需要相机和录音权限");
                finish();
            }
        }
    }

    private void startBackgroundThread() {
        mBackgroundThread = new HandlerThread("CameraBackground");
        mBackgroundThread.start();
        mBackgroundHandler = new Handler(mBackgroundThread.getLooper());
        if (cameraPreview.isAvailable()) {
            openCamera();
        }
    }

    private void stopBackgroundThread() {
        if (mBackgroundThread != null) {
            mBackgroundThread.quitSafely();
            try {
                mBackgroundThread.join();
                mBackgroundThread = null;
                mBackgroundHandler = null;
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }

    private void openCamera() {
        CameraManager cameraManager = (CameraManager) getSystemService(Context.CAMERA_SERVICE);
        if (cameraManager == null) {
            WKToastUtils.getInstance().showToastNormal("无法获取相机服务");
            finish();
            return;
        }
        try {
            String[] cameraIdList = cameraManager.getCameraIdList();
            if (cameraIdList == null || cameraIdList.length == 0) {
                WKToastUtils.getInstance().showToastNormal("未找到可用相机");
                finish();
                return;
            }
            for (String id : cameraIdList) {
                CameraCharacteristics characteristics = cameraManager.getCameraCharacteristics(id);
                if (characteristics == null) continue;
                Integer facing = characteristics.get(CameraCharacteristics.LENS_FACING);
                if (isFrontCamera && facing != null && facing == CameraCharacteristics.LENS_FACING_FRONT) {
                    currentCameraId = id;
                    setupCameraCharacteristics(cameraManager, characteristics);
                    break;
                } else if (!isFrontCamera && facing != null && facing == CameraCharacteristics.LENS_FACING_BACK) {
                    currentCameraId = id;
                    setupCameraCharacteristics(cameraManager, characteristics);
                    break;
                }
            }
            if (currentCameraId == null) {
                WKToastUtils.getInstance().showToastNormal("未找到可用相机");
                finish();
                return;
            }
            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
                cameraManager.openCamera(currentCameraId, new CameraDevice.StateCallback() {
                    @Override
                    public void onOpened(@NonNull CameraDevice camera) {
                        mCameraDevice = camera;
                        createPreviewSession();
                    }

                    @Override
                    public void onDisconnected(@NonNull CameraDevice camera) {
                        camera.close();
                        mCameraDevice = null;
                    }

                    @Override
                    public void onError(@NonNull CameraDevice camera, int error) {
                        camera.close();
                        mCameraDevice = null;
                        WKToastUtils.getInstance().showToastNormal("相机打开失败");
                        finish();
                    }
                }, mBackgroundHandler);
            }
        } catch (CameraAccessException e) {
            e.printStackTrace();
            WKToastUtils.getInstance().showToastNormal("无法打开相机");
            finish();
        }
    }

    private void setupCameraCharacteristics(CameraManager cameraManager, CameraCharacteristics characteristics) {
        try {
            StreamConfigurationMap map = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP);
            if (map != null) {
                videoSize = chooseVideoSize(map.getOutputSizes(MediaRecorder.class));
                Size[] previewSizes = map.getOutputSizes(SurfaceTexture.class);
                previewSize = choosePreviewSize(previewSizes);
            }
            sensorOrientation = characteristics.get(CameraCharacteristics.SENSOR_ORIENTATION) != null
                    ? characteristics.get(CameraCharacteristics.SENSOR_ORIENTATION) : 90;
            Boolean flashAvailable = characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE);
            btnFlash.setVisibility(flashAvailable != null && flashAvailable ? View.VISIBLE : View.GONE);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private Size chooseVideoSize(Size[] choices) {
        if (choices == null || choices.length == 0) return new Size(1280, 720);
        // 获取屏幕比例
        float screenRatio = getScreenRatio();
        Size bestSize = null;
        float bestDiff = Float.MAX_VALUE;
        // 优先选择 720p 左右且比例接近屏幕的（聊天视频不需要1080p，720p足够且体积小一半）
        for (Size size : choices) {
            if (size.getWidth() >= 960 && size.getWidth() <= 1280) {
                float ratio = (float) Math.max(size.getWidth(), size.getHeight()) / Math.min(size.getWidth(), size.getHeight());
                float diff = Math.abs(ratio - screenRatio);
                if (diff < bestDiff) {
                    bestDiff = diff;
                    bestSize = size;
                }
            }
        }
        if (bestSize != null) return bestSize;
        // 回退到 720p
        for (Size size : choices) {
            if (size.getWidth() == 1280 && size.getHeight() == 720) return size;
        }
        // 再回退找最接近的
        for (Size size : choices) {
            if (size.getWidth() <= 1280 && size.getHeight() <= 1280) return size;
        }
        return choices[0];
    }

    private Size choosePreviewSize(Size[] choices) {
        if (choices == null || choices.length == 0) return new Size(1280, 720);
        float screenRatio = getScreenRatio();
        // 优先选择与视频尺寸相同的
        if (videoSize != null) {
            for (Size size : choices) {
                if (size.getWidth() == videoSize.getWidth() && size.getHeight() == videoSize.getHeight())
                    return size;
            }
        }
        // 选择与屏幕比例最接近且尺寸适中的
        Size bestSize = null;
        float bestDiff = Float.MAX_VALUE;
        for (Size size : choices) {
            if (size.getWidth() >= 1280 && size.getWidth() <= 1920) {
                float ratio = (float) Math.max(size.getWidth(), size.getHeight()) / Math.min(size.getWidth(), size.getHeight());
                float diff = Math.abs(ratio - screenRatio);
                if (diff < bestDiff) {
                    bestDiff = diff;
                    bestSize = size;
                }
            }
        }
        if (bestSize != null) return bestSize;
        // 回退方案
        for (Size size : choices) {
            if (size.getWidth() == 1280 && size.getHeight() == 720) return size;
        }
        for (Size size : choices) {
            if (size.getWidth() <= 1280 && size.getHeight() <= 720) return size;
        }
        return choices[0];
    }

    private float getScreenRatio() {
        if (cameraPreview != null && cameraPreview.getWidth() > 0 && cameraPreview.getHeight() > 0) {
            return (float) Math.max(cameraPreview.getWidth(), cameraPreview.getHeight())
                    / Math.min(cameraPreview.getWidth(), cameraPreview.getHeight());
        }
        DisplayMetrics metrics = getResources().getDisplayMetrics();
        return (float) Math.max(metrics.widthPixels, metrics.heightPixels)
                / Math.min(metrics.widthPixels, metrics.heightPixels);
    }

    private void createPreviewSession() {
        if (mCameraDevice == null || mSurfaceTexture == null || previewSize == null) return;
        try {
            mSurfaceTexture.setDefaultBufferSize(previewSize.getWidth(), previewSize.getHeight());
            mPreviewSurface = new Surface(mSurfaceTexture);
            CaptureRequest.Builder builder = mCameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);
            builder.addTarget(mPreviewSurface);
            builder.set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE);
            if (isFlashOn) {
                builder.set(CaptureRequest.FLASH_MODE, CaptureRequest.FLASH_MODE_TORCH);
            }
            mCameraDevice.createCaptureSession(Arrays.asList(mPreviewSurface),
                    new CameraCaptureSession.StateCallback() {
                        @Override
                        public void onConfigured(@NonNull CameraCaptureSession session) {
                            mCaptureSession = session;
                            try {
                                if (mCameraDevice != null) {
                                    session.setRepeatingRequest(builder.build(), null, mBackgroundHandler);
                                }
                            } catch (CameraAccessException | IllegalStateException e) {
                                e.printStackTrace();
                            }
                            // 预览配置完成后，在 UI 线程更新变换
                            cameraPreview.post(new Runnable() {
                                @Override
                                public void run() {
                                    updateTransform();
                                }
                            });
                        }

                        @Override
                        public void onConfigureFailed(@NonNull CameraCaptureSession session) {
                            WKToastUtils.getInstance().showToastNormal("预览配置失败");
                        }
                    }, mBackgroundHandler);
        } catch (CameraAccessException e) {
            e.printStackTrace();
        }
    }

    private void startRecording() {
        if (mCameraDevice == null || mSurfaceTexture == null || videoSize == null || previewSize == null) {
            captureLayout.resetState();
            return;
        }
        try {
            File dir = new File(getExternalFilesDir(null), "WKRecord");
            if (!dir.exists()) dir.mkdirs();
            videoPath = new File(dir, "VID_" + System.currentTimeMillis() + ".mp4").getAbsolutePath();

            mMediaRecorder = new MediaRecorder();
            mMediaRecorder.setAudioSource(MediaRecorder.AudioSource.MIC);
            mMediaRecorder.setVideoSource(MediaRecorder.VideoSource.SURFACE);
            mMediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4);
            mMediaRecorder.setVideoEncoder(MediaRecorder.VideoEncoder.H264);
            mMediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC);
            mMediaRecorder.setVideoEncodingBitRate(1500000);
            mMediaRecorder.setVideoFrameRate(24);
            mMediaRecorder.setVideoSize(videoSize.getWidth(), videoSize.getHeight());
            mMediaRecorder.setOutputFile(videoPath);
            mMediaRecorder.setOrientationHint(getOrientationHint());
            mMediaRecorder.prepare();

            mSurfaceTexture.setDefaultBufferSize(previewSize.getWidth(), previewSize.getHeight());
            Surface previewSurface = new Surface(mSurfaceTexture);
            Surface recorderSurface = mMediaRecorder.getSurface();

            CaptureRequest.Builder builder = mCameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_RECORD);
            builder.addTarget(previewSurface);
            builder.addTarget(recorderSurface);
            builder.set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_VIDEO);
            if (isFlashOn) {
                builder.set(CaptureRequest.FLASH_MODE, CaptureRequest.FLASH_MODE_TORCH);
            }

            mCameraDevice.createCaptureSession(Arrays.asList(previewSurface, recorderSurface),
                    new CameraCaptureSession.StateCallback() {
                        @Override
                        public void onConfigured(@NonNull CameraCaptureSession session) {
                            mCaptureSession = session;
                            try {
                                session.setRepeatingRequest(builder.build(), null, mBackgroundHandler);
                                mMediaRecorder.start();
                                isRecording = true;
                            } catch (Exception e) {
                                e.printStackTrace();
                                WKToastUtils.getInstance().showToastNormal("录制启动失败");
                                cleanupRecording();
                                captureLayout.resetState();
                            }
                        }

                        @Override
                        public void onConfigureFailed(@NonNull CameraCaptureSession session) {
                            WKToastUtils.getInstance().showToastNormal("录制配置失败");
                            cleanupRecording();
                            captureLayout.resetState();
                        }
                    }, mBackgroundHandler);
        } catch (Exception e) {
            e.printStackTrace();
            WKToastUtils.getInstance().showToastNormal("录制初始化失败");
            cleanupRecording();
            captureLayout.resetState();
        }
    }

    private void stopRecording(long recordedTime) {
        isRecording = false;
        recordedDuration = recordedTime;

        if (mMediaRecorder != null) {
            try {
                mMediaRecorder.stop();
            } catch (Exception e) {
                // Recording too short
            }
            mMediaRecorder.release();
            mMediaRecorder = null;
        }

        if (videoPath != null && new File(videoPath).exists()) {
            extractCover();
            // 录制完成后后台立即做 faststart 转换（moov前置），发送时零延迟
            // 用户预览视频的时间里转换已完成，不影响发送速度
            // 已修复stco偏移问题，转换后的视频可正常边下边播
            new Thread(() -> MP4FastStart.convertInPlace(videoPath), "faststart-bg").start();
        }

        createPreviewSession();
    }

    private void extractCover() {
        if (videoPath == null || !new File(videoPath).exists()) return;
        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        try {
            retriever.setDataSource(videoPath);
            Bitmap bitmap = retriever.getFrameAtTime(0, MediaMetadataRetriever.OPTION_CLOSEST_SYNC);
            if (bitmap != null) {
                File coverFile = new File(new File(videoPath).getParentFile(),
                        "COVER_" + System.currentTimeMillis() + ".jpg");
                FileOutputStream fos = new FileOutputStream(coverFile);
                bitmap.compress(Bitmap.CompressFormat.JPEG, 90, fos);
                fos.close();
                bitmap.recycle();
                coverPath = coverFile.getAbsolutePath();
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                retriever.release();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    private void capturePhoto() {
        Bitmap bitmap = cameraPreview.getBitmap();
        if (bitmap == null) {
            WKToastUtils.getInstance().showToastNormal("拍照失败");
            captureLayout.resetState();
            return;
        }
        try {
            File dir = new File(getExternalFilesDir(null), "WKPhoto");
            if (!dir.exists()) dir.mkdirs();
            File photoFile = new File(dir, "IMG_" + System.currentTimeMillis() + ".jpg");
            FileOutputStream fos = new FileOutputStream(photoFile);
            bitmap.compress(Bitmap.CompressFormat.JPEG, 90, fos);
            fos.close();
            bitmap.recycle();
            photoPath = photoFile.getAbsolutePath();
            captureLayout.showConfirmCancel();
        } catch (Exception e) {
            e.printStackTrace();
            WKToastUtils.getInstance().showToastNormal("保存照片失败");
            captureLayout.resetState();
        }
    }

    private void cleanupRecording() {
        if (videoPath != null) {
            new File(videoPath).delete();
            videoPath = null;
        }
        if (coverPath != null) {
            new File(coverPath).delete();
            coverPath = null;
        }
        if (photoPath != null) {
            new File(photoPath).delete();
            photoPath = null;
        }
        isRecording = false;
    }

    private void sendVideoMessage() {
        if (videoPath == null) return;
        WKVideoContent videoContent = new WKVideoContent();
        videoContent.coverLocalPath = coverPath;
        videoContent.localPath = videoPath;
        videoContent.second = WKMediaFileUtils.getInstance().getVideoTime(videoPath) / 1000;
        videoContent.size = WKFileUtils.getInstance().getFileSize(videoPath);
        if (coverPath != null && new File(coverPath).exists()) {
            BitmapFactory.Options options = new BitmapFactory.Options();
            options.inJustDecodeBounds = true;
            BitmapFactory.decodeFile(coverPath, options);
            videoContent.width = options.outWidth;
            videoContent.height = options.outHeight;
        }
        if (channelId != null && !channelId.isEmpty()) {
            WKIM.getInstance().getMsgManager().sendMessage(videoContent, channelId, (byte) channelType);
        }
    }

    private void sendPhotoMessage() {
        if (photoPath == null) return;
        WKImageContent imageContent = new WKImageContent(photoPath);
        if (channelId != null && !channelId.isEmpty()) {
            WKIM.getInstance().getMsgManager().sendMessage(imageContent, channelId, (byte) channelType);
        }
    }

    private void toggleFlash() {
        isFlashOn = !isFlashOn;
        btnFlash.setImageResource(isFlashOn ? R.drawable.ic_flash_on : R.drawable.ic_flash_off);
        updatePreviewRequest();
    }

    private void updatePreviewRequest() {
        if (mCaptureSession == null || mCameraDevice == null || mPreviewSurface == null) return;
        try {
            CaptureRequest.Builder builder = mCameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);
            builder.addTarget(mPreviewSurface);
            builder.set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE);
            if (isFlashOn) {
                builder.set(CaptureRequest.FLASH_MODE, CaptureRequest.FLASH_MODE_TORCH);
            }
            mCaptureSession.setRepeatingRequest(builder.build(), null, mBackgroundHandler);
        } catch (CameraAccessException e) {
            e.printStackTrace();
        }
    }

    private void switchCamera() {
        if (mCameraDevice != null) {
            mCameraDevice.close();
            mCameraDevice = null;
        }
        mCaptureSession = null;
        isFlashOn = false;
        btnFlash.setImageResource(R.drawable.ic_flash_off);
        isFrontCamera = !isFrontCamera;
        currentCameraId = null;
        openCamera();
    }

    private void showFocus(float x, float y) {
        if (foucsView.getVisibility() == View.VISIBLE) return;
        foucsView.setVisibility(View.VISIBLE);
        foucsView.setX(x - foucsView.getWidth() / 2f);
        foucsView.setY(y - foucsView.getHeight() / 2f);
        foucsView.setAlpha(1f);
        foucsView.animate().alpha(0f).setDuration(1000).withEndAction(() -> {
            foucsView.setVisibility(View.INVISIBLE);
            foucsView.setAlpha(1f);
        });
    }

    private int getOrientationHint() {
        int rotation = getWindowManager().getDefaultDisplay().getRotation();
        int degrees = 0;
        switch (rotation) {
            case Surface.ROTATION_0: degrees = 0; break;
            case Surface.ROTATION_90: degrees = 90; break;
            case Surface.ROTATION_180: degrees = 180; break;
            case Surface.ROTATION_270: degrees = 270; break;
        }
        if (isFrontCamera) {
            return (sensorOrientation + degrees) % 360;
        } else {
            return (sensorOrientation - degrees + 360) % 360;
        }
    }

    private void updateTransform() {
        if (cameraPreview == null || previewSize == null) return;
        int viewWidth = cameraPreview.getWidth();
        int viewHeight = cameraPreview.getHeight();
        if (viewWidth == 0 || viewHeight == 0) return;

        int bufferW = previewSize.getWidth();
        int bufferH = previewSize.getHeight();

        float cx = viewWidth / 2f;
        float cy = viewHeight / 2f;

        Matrix matrix = new Matrix();

        // 计算需要旋转的角度
        // 注意：TextureView 的 postRotate 方向可能与预期相反
        // 先尝试 0 度观察基础方向，再根据结果调整
        int rotationAngle;
        if (isFrontCamera) {
            rotationAngle = 270; // 前置
        } else {
            rotationAngle = 0;  // 后置：先试 0 度
        }

        android.util.Log.d("Camera2", "updateTransform: isFront=" + isFrontCamera +
                " rotationAngle=" + rotationAngle +
                " view=" + viewWidth + "x" + viewHeight +
                " buffer=" + bufferW + "x" + bufferH);

        // 1. 先旋转
        matrix.postRotate(rotationAngle, cx, cy);

        // 2. 旋转后宽高互换，计算 CENTER_CROP 缩放
        float scaledBufferW = bufferH;
        float scaledBufferH = bufferW;
        float scale = Math.max(viewWidth / scaledBufferW, viewHeight / scaledBufferH);
        matrix.postScale(scale, scale, cx, cy);

        // 3. 前置摄像头镜像
        if (isFrontCamera) {
            matrix.postScale(-1, 1, cx, cy);
        }

        cameraPreview.setTransform(matrix);
    }

    private void closeCamera() {
        if (mCaptureSession != null) {
            try {
                mCaptureSession.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
            mCaptureSession = null;
        }
        if (mCameraDevice != null) {
            mCameraDevice.close();
            mCameraDevice = null;
        }
        if (mMediaRecorder != null) {
            try {
                if (isRecording) mMediaRecorder.stop();
            } catch (Exception e) {
                // Ignore
            }
            mMediaRecorder.release();
            mMediaRecorder = null;
        }
        isRecording = false;
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (mBackgroundThread == null) {
            startBackgroundThread();
        }
    }

    @Override
    protected void onPause() {
        closeCamera();
        stopBackgroundThread();
        super.onPause();
    }

    @Override
    public void onBackPressed() {
        if (isRecording) {
            if (mMediaRecorder != null) {
                try {
                    mMediaRecorder.stop();
                } catch (Exception e) {
                    // Ignore
                }
                mMediaRecorder.release();
                mMediaRecorder = null;
            }
            isRecording = false;
            cleanupRecording();
            createPreviewSession();
            captureLayout.resetState();
        } else {
            super.onBackPressed();
        }
    }

    @Override
    protected void onDestroy() {
        closeCamera();
        stopBackgroundThread();
        super.onDestroy();
    }
}
