package com.chat.base.utils;

import android.annotation.SuppressLint;
import android.app.DownloadManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.Settings;
import android.text.TextUtils;
import android.widget.Toast;

import androidx.core.content.FileProvider;

import com.chat.base.WKBaseApplication;
import com.chat.base.R;

import java.io.File;


/**
 * DownloadManager工具类
 * 【稳定版】全面异常保护，杜绝更新闪退
 */
public class DownloadApkUtils {
    //下载器
    private DownloadManager downloadManager;
    //下载的ID
    private long downloadId;
    //下载url
    private String downloadUrl;
    private File localFiles;
    private boolean isdownload = false;
    // 下载状态监听
    private DownloadListener downloadListener;
    // 广播接收器是否已注册
    private boolean isReceiverRegistered = false;

    private DownloadApkUtils() {

    }

    private static class DownloadApkUtilsBinder {
        final static DownloadApkUtils download = new DownloadApkUtils();
    }

    public static DownloadApkUtils getInstance() {
        return DownloadApkUtilsBinder.download;
    }

    /**
     * 下载状态监听接口
     */
    public interface DownloadListener {
        void onStart();
        void onSuccess(File apkFile);
        void onFailed(String errorMsg);
    }

    public void setDownloadListener(DownloadListener listener) {
        this.downloadListener = listener;
    }


    /**
     * 下载apk
     * 【安全加固】全程异常捕获，任何失败都跳浏览器，绝不闪退
     */
    public void downloadAPK(Context context, String versionName, String url) {
        try {
            if (TextUtils.isEmpty(versionName)) {
                WKLogUtils.e("下载apk", "版本名称错误---versionName=" + versionName);
                return;
            }
            if (TextUtils.isEmpty(url)) {
                WKToastUtils.getInstance().showToastNormal("下载地址为空");
                return;
            }

            downloadUrl = url;
            Context appContext = getAppContext(context);

            File downloadPath = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
            try {
                WKFileUtils.getInstance().createFileDir(downloadPath);
            } catch (Exception e) {
                WKLogUtils.e("创建下载目录失败", e.getMessage());
            }

            //本地完整路径
            localFiles = new File(downloadPath, appContext.getPackageName() + versionName + ".apk");
            boolean isoknew = getAPKInfo(appContext, versionName, localFiles);
            if (isoknew && null != localFiles && localFiles.exists()) {
                //文件存在，检测了直接安装
                if (downloadListener != null) {
                    downloadListener.onSuccess(localFiles);
                }
                installAPK(localFiles);
            } else {
                if (isdownload) {
                    WKToastUtils.getInstance().showToastNormal("下载任务已经存在，可在通知栏中查看状态");
                    return;
                }
                isdownload = true;
                if (downloadListener != null) {
                    downloadListener.onStart();
                }
                //在线下载
                try {
                    WKFileUtils.delFileOrFolder(localFiles);
                } catch (Exception e) {
                    // 删除旧文件失败不影响下载
                }
                //创建下载任务
                DownloadManager.Request request;
                try {
                    request = new DownloadManager.Request(Uri.parse(url));
                } catch (Exception e) {
                    WKToastUtils.getInstance().showToastNormal("下载地址无效，请稍后重试");
                    isdownload = false;
                    safeOpenBrowser(appContext);
                    if (downloadListener != null) {
                        downloadListener.onFailed("下载地址无效");
                    }
                    return;
                }
                //移动网络情况下是否允许漫游
                request.setAllowedOverRoaming(false);
                //在通知栏中显示
                try {
                    request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
                } catch (Exception e) {
                    // 通知权限不足也不影响下载本身
                }
                try {
                    request.setTitle(appContext.getString(R.string.app_name) + "新版本下载");
                    request.setDescription("下载中...");
                    request.setVisibleInDownloadsUi(true);
                } catch (Exception e) {
                    // 忽略标题设置失败
                }
                //设置下载的路径
                try {
                    request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, localFiles.getName());
                } catch (Exception e) {
                    // 某些机型可能无法设置公共目录，尝试应用私有目录
                    try {
                        File privatePath = new File(appContext.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS), localFiles.getName());
                        localFiles = privatePath;
                        request.setDestinationUri(Uri.fromFile(privatePath));
                    } catch (Exception e2) {
                        WKToastUtils.getInstance().showToastNormal("下载失败，请使用浏览器下载");
                        isdownload = false;
                        safeOpenBrowser(appContext);
                        return;
                    }
                }

                WKLogUtils.e("新版本下载网络url地址=", url);
                WKLogUtils.e("新版本下载本地文件夹地址=", localFiles.getAbsolutePath());

                //获取DownloadManager
                if (null == downloadManager) {
                    downloadManager = (DownloadManager) appContext.getSystemService(Context.DOWNLOAD_SERVICE);
                }
                try {
                    //将下载请求加入下载队列
                    downloadId = downloadManager.enqueue(request);

                    //注册广播接收者（确保只注册一次）
                    registerReceiverSafely(appContext);

                    WKToastUtils.getInstance().showToastNormal("后台下载中，可在通知栏中查看状态");
                } catch (Exception e) {
                    e.printStackTrace();
                    isdownload = false;
                    WKToastUtils.getInstance().showToastNormal("下载失败，请重试或使用浏览器下载");
                    safeOpenBrowser(appContext);
                    if (downloadListener != null) {
                        downloadListener.onFailed("下载失败: " + e.getMessage());
                    }
                }
            }
        } catch (Throwable t) {
            // 终极兜底：任何异常都不闪退，跳浏览器
            t.printStackTrace();
            isdownload = false;
            try {
                WKToastUtils.getInstance().showToastNormal("下载启动失败，请用浏览器下载");
                safeOpenBrowser(context);
            } catch (Exception e2) {
                // 连Toast都失败了，就什么都不做了
            }
        }
    }

    /**
     * 安全注册广播接收器（确保只注册一次）
     */
    private void registerReceiverSafely(Context context) {
        if (isReceiverRegistered) {
            return;
        }
        try {
            Context appContext = getAppContext(context);
            appContext.registerReceiver(receiver,
                    new IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE));
            isReceiverRegistered = true;
        } catch (Exception e) {
            e.printStackTrace();
            // 注册失败也不影响，DownloadManager会在通知栏显示
        }
    }

    /**
     * 安全反注册广播接收器
     */
    private void unregisterReceiverSafely() {
        if (!isReceiverRegistered) {
            return;
        }
        try {
            Context ctx = WKBaseApplication.getInstance().getContext();
            if (ctx != null) {
                ctx.unregisterReceiver(receiver);
            }
            isReceiverRegistered = false;
        } catch (Exception e) {
            isReceiverRegistered = false;
            // 反注册失败忽略
        }
    }

    /**
     * 获取 Application context，避免内存泄漏
     */
    private Context getAppContext(Context context) {
        if (context == null) {
            return WKBaseApplication.getInstance().getContext();
        }
        Context appCtx = context.getApplicationContext();
        if (appCtx != null) {
            return appCtx;
        }
        return WKBaseApplication.getInstance().getContext();
    }

    //广播监听下载的各个状态
    private final BroadcastReceiver receiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            try {
                checkStatus(context);
            } catch (Throwable t) {
                t.printStackTrace();
                // 广播处理异常，绝不闪退
            }
        }
    };


    //检查下载状态
    private void checkStatus(Context mContext) {
        try {
            if (downloadManager == null) {
                return;
            }
            DownloadManager.Query query = new DownloadManager.Query();
            //通过下载的id查找
            query.setFilterById(downloadId);
            Cursor c = downloadManager.query(query);
            if (null == c) {
                return;
            }
            if (c.moveToFirst()) {
                @SuppressLint("Range") int status = c.getInt(c.getColumnIndex(DownloadManager.COLUMN_STATUS));
                switch (status) {
                    //下载暂停
                    case DownloadManager.STATUS_PAUSED:
                        WKLogUtils.e("新版本下载状态", "下载暂停");
                        isdownload = false;
                        break;
                    //下载延迟
                    case DownloadManager.STATUS_PENDING:
                        WKLogUtils.e("新版本下载状态", "下载延迟");
                        break;
                    //正在下载
                    case DownloadManager.STATUS_RUNNING:
                        WKLogUtils.e("新版本下载状态", "正在下载");
                        break;
                    //下载完成
                    case DownloadManager.STATUS_SUCCESSFUL:
                        //下载完成安装APK
                        isdownload = false;
                        WKToastUtils.getInstance().showToastNormal("下载成功");
                        // 下载成功后反注册广播
                        unregisterReceiverSafely();
                        if (downloadListener != null) {
                            downloadListener.onSuccess(localFiles);
                        }
                        installAPK(localFiles);
                        break;
                    //下载失败
                    case DownloadManager.STATUS_FAILED:
                        isdownload = false;
                        unregisterReceiverSafely();
                        WKLogUtils.e("新版本下载状态", "下载失败");
                        WKToastUtils.getInstance().showToastNormal("下载失败，正在跳转浏览器下载...");
                        // 下载失败时，自动跳转到浏览器下载
                        safeOpenBrowser(mContext);
                        if (downloadListener != null) {
                            downloadListener.onFailed("下载失败");
                        }
                        break;
                }
            }
            c.close();
        } catch (Throwable t) {
            t.printStackTrace();
            // 检查状态异常时，尝试跳浏览器兜底
            isdownload = false;
            unregisterReceiverSafely();
        }
    }


    /**
     * 比较两个版本号
     * @param version1 版本号1
     * @param version2 版本号2
     * @return 1: version1 > version2, -1: version1 < version2, 0: 相等
     */
    public static int compareVersion(String version1, String version2) {
        if (TextUtils.isEmpty(version1) || TextUtils.isEmpty(version2)) {
            return 0;
        }
        String[] v1 = version1.trim().split("\\.");
        String[] v2 = version2.trim().split("\\.");
        int len = Math.max(v1.length, v2.length);
        for (int i = 0; i < len; i++) {
            int num1 = i < v1.length ? parseIntSafe(v1[i]) : 0;
            int num2 = i < v2.length ? parseIntSafe(v2[i]) : 0;
            if (num1 > num2) return 1;
            if (num1 < num2) return -1;
        }
        return 0;
    }

    private static int parseIntSafe(String s) {
        try {
            return Integer.parseInt(s.trim());
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    /**
     * 检测本地apk 包是否正确
     */
    private static boolean getAPKInfo(Context context, String version, File apk_folder) {
        if (apk_folder == null || !apk_folder.exists()) {
            return false;
        }
        try {
            PackageInfo pkgInfo = context.getPackageManager().
                    getPackageArchiveInfo(apk_folder.getAbsolutePath(), PackageManager.GET_ACTIVITIES | PackageManager.GET_SERVICES);
            if (pkgInfo == null || TextUtils.isEmpty(pkgInfo.versionName)) {
                return false;
            }
            // 服务器版本 >= 本地APK版本，说明本地文件是正确的新版本
            int cmp = compareVersion(version, pkgInfo.versionName);
            if (cmp >= 0) {
                return true;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    //下载到本地后执行安装
    public void installAPK(File file) {
        Context context = WKBaseApplication.getInstance().getContext();
        if (context == null) {
            return;
        }
        try {
            if (file == null || !file.exists()) {
                WKLogUtils.e("文件异常=", "downloadFileUri=" + file);
                WKToastUtils.getInstance().showToastNormal("文件不存在，正在跳转浏览器下载...");
                safeOpenBrowser(context);
                return;
            }

            // 先检查安装权限（加try-catch防止ROM兼容问题）
            boolean hasInstallPermission = true;
            try {
                hasInstallPermission = checkPermissions();
            } catch (Exception e) {
                e.printStackTrace();
                // 权限检查失败，假设有权限，继续尝试安装
            }

            if (!hasInstallPermission) {
                WKToastUtils.getInstance().showToastNormal("请允许安装应用权限后重试");
                requestPermissions(context);
                return;
            }

            // 验证APK包是否有效
            PackageManager pm = context.getPackageManager();
            PackageInfo info = null;
            try {
                info = pm.getPackageArchiveInfo(file.getAbsolutePath(), PackageManager.GET_ACTIVITIES);
            } catch (Exception e) {
                e.printStackTrace();
            }

            if (info == null) {
                // APK文件损坏，跳转到浏览器下载
                WKLogUtils.e("文件异常=", "APK包解析失败");
                WKToastUtils.getInstance().showToastNormal("安装包损坏，正在跳转浏览器下载...");
                safeOpenBrowser(context);
                return;
            }

            // 【关键修复】统一使用 ACTION_VIEW 安装，兼容性最好
            // ACTION_INSTALL_PACKAGE 在部分机型/ROM上有兼容性问题
            Intent intent = new Intent(Intent.ACTION_VIEW);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

            Uri apkUri;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                try {
                    apkUri = FileProvider.getUriForFile(context, context.getPackageName() + ".fileProvider", file);
                    intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                } catch (Exception e) {
                    // FileProvider失败，尝试直接用file://uri（Android 7.0+可能不行，但试试）
                    e.printStackTrace();
                    WKToastUtils.getInstance().showToastNormal("安装失败，正在跳转浏览器下载...");
                    safeOpenBrowser(context);
                    return;
                }
            } else {
                apkUri = Uri.fromFile(file);
            }
            intent.setDataAndType(apkUri, "application/vnd.android.package-archive");

            // 检查有没有能处理这个Intent的Activity
            if (intent.resolveActivity(pm) != null) {
                context.startActivity(intent);
            } else {
                WKToastUtils.getInstance().showToastNormal("无法打开安装界面，正在跳转浏览器下载...");
                safeOpenBrowser(context);
            }

        } catch (Throwable t) {
            // 终极兜底：安装失败绝不闪退，跳浏览器下载
            t.printStackTrace();
            try {
                WKToastUtils.getInstance().showToastNormal("安装失败，正在跳转浏览器下载...");
                safeOpenBrowser(context);
            } catch (Exception e2) {
                // 连Toast都崩了，静默处理
            }
        }
    }

    /**
     * 安全打开浏览器（加异常保护）
     */
    private void safeOpenBrowser(Context context) {
        try {
            openBrowser(context);
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }

    /**
     * 调用第三方浏览器打开
     * 【重要】作为下载安装失败的备选方案，确保用户总能获取到新版本
     */
    public void openBrowser(Context context) {
        if (TextUtils.isEmpty(downloadUrl)) {
            WKToastUtils.getInstance().showToastNormal("下载地址为空");
            return;
        }
        try {
            final Intent intent = new Intent();
            intent.setAction(Intent.ACTION_VIEW);
            intent.setData(Uri.parse(downloadUrl));
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if (intent.resolveActivity(context.getPackageManager()) != null) {
                context.startActivity(Intent.createChooser(intent, "请选择浏览器下载"));
            } else {
                Toast.makeText(context.getApplicationContext(), "请下载浏览器后重试", Toast.LENGTH_SHORT).show();
            }
        } catch (Exception e) {
            e.printStackTrace();
            WKToastUtils.getInstance().showToastNormal("打开浏览器失败，请手动访问下载地址");
        }
    }

    /**
     * 检测安装权限
     */
    public boolean checkPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Context ctx = WKBaseApplication.getInstance().getContext();
            if (ctx == null) {
                return true; // context为空时假设有权限
            }
            //先获取是否有安装未知来源应用的权限
            return ctx.getPackageManager().canRequestPackageInstalls();
        } else {
            return true;
        }
    }

    /**
     * 申请权限
     */
    public void requestPermissions(Context activity) {
        try {
            Intent intent = new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES);
            Uri packageURI = Uri.parse("package:" + activity.getPackageName());
            intent.setData(packageURI);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            activity.startActivity(intent);

        } catch (Exception e) {
            e.printStackTrace();
            // 权限申请失败，跳转到浏览器下载
            WKToastUtils.getInstance().showToastNormal("无法获取安装权限，正在跳转浏览器下载...");
            safeOpenBrowser(activity);
        }
    }
}
