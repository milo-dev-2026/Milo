package com.xian.leihuhu;

import android.content.Context;
import android.os.Environment;
import android.os.Process;

import java.io.File;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class CrashHandler implements Thread.UncaughtExceptionHandler {

    private static CrashHandler instance;
    private Context context;
    private Thread.UncaughtExceptionHandler defaultHandler;

    private CrashHandler() {}

    public static CrashHandler getInstance() {
        if (instance == null) {
            synchronized (CrashHandler.class) {
                if (instance == null) {
                    instance = new CrashHandler();
                }
            }
        }
        return instance;
    }

    public void init(Context ctx) {
        context = ctx.getApplicationContext();
        defaultHandler = Thread.getDefaultUncaughtExceptionHandler();
        Thread.setDefaultUncaughtExceptionHandler(this);
    }

    @Override
    public void uncaughtException(Thread thread, Throwable ex) {
        try {
            saveCrashInfo(thread, ex);
        } catch (Exception e) {
            e.printStackTrace();
        }
        // 延迟 2 秒让日志写入完成，然后杀掉进程
        try {
            Thread.sleep(2000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        if (defaultHandler != null) {
            defaultHandler.uncaughtException(thread, ex);
        } else {
            Process.killProcess(Process.myPid());
            System.exit(1);
        }
    }

    private void saveCrashInfo(Thread thread, Throwable ex) {
        StringWriter sw = new StringWriter();
        PrintWriter pw = new PrintWriter(sw);
        ex.printStackTrace(pw);
        Throwable cause = ex.getCause();
        while (cause != null) {
            cause.printStackTrace(pw);
            cause = cause.getCause();
        }
        pw.close();
        String stackTrace = sw.toString();

        StringBuilder sb = new StringBuilder();
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault());
        sb.append("崩溃时间: ").append(sdf.format(new Date())).append("\n");
        sb.append("崩溃线程: ").append(thread.getName()).append("\n");
        sb.append("异常类型: ").append(ex.getClass().getName()).append("\n");
        sb.append("异常消息: ").append(ex.getMessage()).append("\n");
        sb.append("========================================\n");
        sb.append(stackTrace);
        sb.append("\n========================================\n");

        // 保存到外部存储
        try {
            File dir = new File(Environment.getExternalStorageDirectory(), "xianleihuhu_crash");
            if (!dir.exists()) {
                dir.mkdirs();
            }
            String fileName = "crash_" + sdf.format(new Date()).replace(" ", "_").replace(":", "") + ".txt";
            File file = new File(dir, fileName);
            FileWriter fw = new FileWriter(file);
            fw.write(sb.toString());
            fw.close();
        } catch (Exception e) {
            e.printStackTrace();
        }

        // 同时保存到应用内部存储
        try {
            File dir = new File(context.getFilesDir(), "crash");
            if (!dir.exists()) {
                dir.mkdirs();
            }
            File file = new File(dir, "last_crash.txt");
            FileWriter fw = new FileWriter(file);
            fw.write(sb.toString());
            fw.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static String getLastCrash(Context context) {
        try {
            File file = new File(context.getFilesDir(), "crash/last_crash.txt");
            if (file.exists()) {
                java.io.FileReader fr = new java.io.FileReader(file);
                char[] buffer = new char[(int) file.length()];
                fr.read(buffer);
                fr.close();
                return new String(buffer);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public static void clearLastCrash(Context context) {
        try {
            File file = new File(context.getFilesDir(), "crash/last_crash.txt");
            if (file.exists()) {
                file.delete();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
