package com.chat.base.utils;

import android.text.TextUtils;
import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;
import java.util.List;

/**
 * MP4 FastStart 工具：将 moov atom 移到文件开头，
 * 使播放器无需下载完整文件即可开始播放（边下边播秒开）。
 * <p>
 * 正确处理 stco/co64 box 中的 chunk offset 重定位，
 * 修复移动 moov 后视频数据偏移不匹配导致的播放失败问题。
 */
public class MP4FastStart {
    private static final String TAG = "MP4FastStart";

    /**
     * 检查 MP4 文件是否已经是 faststart 格式（moov 在 mdat 前面）
     */
    public static boolean isFastStart(String filePath) {
        if (TextUtils.isEmpty(filePath)) return false;
        File f = new File(filePath);
        if (!f.exists() || f.length() < 1024) return false;

        try (RandomAccessFile raf = new RandomAccessFile(f, "r")) {
            long moovPos = -1;
            long mdatPos = -1;
            long pos = 0;
            long fileSize = f.length();

            while (pos < fileSize - 8) {
                raf.seek(pos);
                BoxHeader hdr = readBoxHeader(raf, pos);
                if (hdr == null) break;

                if ("moov".equals(hdr.type)) moovPos = pos;
                else if ("mdat".equals(hdr.type)) mdatPos = pos;

                if (moovPos >= 0 && mdatPos >= 0) {
                    return moovPos < mdatPos;
                }
                pos += hdr.size;
            }
        } catch (IOException e) {
            Log.w(TAG, "isFastStart check failed: " + e.getMessage());
        }
        return false;
    }

    /**
     * 将 MP4 文件转换为 faststart 格式（moov 前置，同时修正 stco/co64 偏移）
     *
     * @param inputPath  输入文件路径
     * @param outputPath 输出文件路径
     * @return 是否成功
     */
    public static boolean convert(String inputPath, String outputPath) {
        if (TextUtils.isEmpty(inputPath) || TextUtils.isEmpty(outputPath)) return false;
        File inputFile = new File(inputPath);
        if (!inputFile.exists() || inputFile.length() <= 0) return false;

        long startTime = System.currentTimeMillis();

        try (RandomAccessFile raf = new RandomAccessFile(inputFile, "r")) {
            long fileSize = inputFile.length();

            // 第一步：扫描所有顶层 box
            List<BoxInfo> boxes = scanTopBoxes(raf, fileSize);
            if (boxes.isEmpty()) {
                Log.w(TAG, "No boxes found");
                return false;
            }

            BoxInfo ftypBox = null;
            BoxInfo moovBox = null;
            BoxInfo mdatBox = null;
            List<BoxInfo> otherBoxes = new ArrayList<>();

            for (BoxInfo box : boxes) {
                switch (box.type) {
                    case "ftyp": ftypBox = box; break;
                    case "moov": moovBox = box; break;
                    case "mdat": mdatBox = box; break;
                    default: otherBoxes.add(box); break;
                }
            }

            if (moovBox == null || mdatBox == null) {
                Log.w(TAG, "moov or mdat not found");
                return false;
            }

            // 已经是 faststart，直接复制
            if (moovBox.offset < mdatBox.offset) {
                copyFile(inputFile, new File(outputPath));
                return true;
            }

            // 第二步：计算 mdat data 在新文件中的偏移量
            // 新文件结构: ftyp + 其他box + moov + mdat
            long newMdatDataOffset = 0;
            if (ftypBox != null) newMdatDataOffset += ftypBox.size;
            for (BoxInfo b : otherBoxes) newMdatDataOffset += b.size;
            newMdatDataOffset += moovBox.size;
            // mdat header 大小（8字节或16字节）
            newMdatDataOffset += (mdatBox.size >= 0xFFFFFFFFL) ? 16 : 8;

            // 旧的 mdat data 偏移量
            long oldMdatDataOffset = mdatBox.offset + ((mdatBox.size >= 0xFFFFFFFFL) ? 16 : 8);

            // 偏移量差值（stco 里的每个值都要加上这个 delta）
            long offsetDelta = newMdatDataOffset - oldMdatDataOffset;

            if (offsetDelta == 0) {
                Log.d(TAG, "Offset delta is 0, copy directly");
                copyFile(inputFile, new File(outputPath));
                return true;
            }

            // 第三步：读取并修改 moov box（更新所有 stco/co64）
            byte[] moovData = new byte[(int) moovBox.size];
            raf.seek(moovBox.offset);
            raf.readFully(moovData);

            // 在 moov 数据中查找并更新所有 stco/co64 box
            boolean updated = updateStcoOffsets(moovData, offsetDelta);
            if (!updated) {
                Log.w(TAG, "No stco/co64 found in moov, video may not play correctly");
            }

            // 第四步：按 faststart 顺序写出文件
            try (FileOutputStream fos = new FileOutputStream(outputPath);
                 FileInputStream fis = new FileInputStream(inputFile)) {

                // ftyp
                if (ftypBox != null) {
                    copyRange(fis, fos, ftypBox.offset, ftypBox.size);
                }
                // 其他 box
                for (BoxInfo box : otherBoxes) {
                    copyRange(fis, fos, box.offset, box.size);
                }
                // 修改后的 moov
                fos.write(moovData);
                // mdat
                copyRange(fis, fos, mdatBox.offset, mdatBox.size);
            }

            long duration = System.currentTimeMillis() - startTime;
            long origSize = inputFile.length();
            long newSize = new File(outputPath).length();
            Log.d(TAG, String.format("FastStart done: %dms, %dKB -> %dKB (offsetDelta=%d)",
                    duration, origSize / 1024, newSize / 1024, offsetDelta));

            return newSize > 0;
        } catch (Exception e) {
            Log.e(TAG, "FastStart convert failed: " + e.getMessage(), e);
            new File(outputPath).delete();
            return false;
        }
    }

    /**
     * 原地转换
     */
    public static boolean convertInPlace(String filePath) {
        if (TextUtils.isEmpty(filePath)) return false;
        File origFile = new File(filePath);
        if (!origFile.exists()) return false;

        if (isFastStart(filePath)) {
            Log.d(TAG, "Already faststart, skip");
            return true;
        }

        String tmpPath = filePath + ".fs.tmp";
        boolean success = convert(filePath, tmpPath);
        if (success) {
            File tmpFile = new File(tmpPath);
            if (tmpFile.exists() && tmpFile.length() > 0) {
                if (origFile.delete()) {
                    return tmpFile.renameTo(origFile);
                }
            }
            tmpFile.delete();
        }
        return false;
    }

    // ========== 内部工具 ==========

    private static class BoxHeader {
        String type;
        long offset;
        long size;
        int headerSize; // 8 或 16

        BoxHeader(String type, long offset, long size, int headerSize) {
            this.type = type;
            this.offset = offset;
            this.size = size;
            this.headerSize = headerSize;
        }
    }

    private static class BoxInfo {
        String type;
        long offset;
        long size;

        BoxInfo(String type, long offset, long size) {
            this.type = type;
            this.offset = offset;
            this.size = size;
        }
    }

    private static BoxHeader readBoxHeader(RandomAccessFile raf, long offset) throws IOException {
        raf.seek(offset);
        byte[] buf = new byte[8];
        int read = raf.read(buf);
        if (read < 8) return null;

        long size = ((long) (buf[0] & 0xFF) << 24) |
                ((long) (buf[1] & 0xFF) << 16) |
                ((long) (buf[2] & 0xFF) << 8) |
                ((long) (buf[3] & 0xFF));
        String type = new String(buf, 4, 4);
        int headerSize = 8;

        if (size == 1) {
            // 64-bit extended size
            byte[] extBuf = new byte[8];
            if (raf.read(extBuf) < 8) return null;
            size = ((long) (extBuf[0] & 0xFF) << 56) |
                    ((long) (extBuf[1] & 0xFF) << 48) |
                    ((long) (extBuf[2] & 0xFF) << 40) |
                    ((long) (extBuf[3] & 0xFF) << 32) |
                    ((long) (extBuf[4] & 0xFF) << 24) |
                    ((long) (extBuf[5] & 0xFF) << 16) |
                    ((long) (extBuf[6] & 0xFF) << 8) |
                    ((long) (extBuf[7] & 0xFF));
            headerSize = 16;
        }

        if (size < headerSize) return null;
        return new BoxHeader(type, offset, size, headerSize);
    }

    private static List<BoxInfo> scanTopBoxes(RandomAccessFile raf, long fileSize) throws IOException {
        List<BoxInfo> boxes = new ArrayList<>();
        long pos = 0;
        while (pos < fileSize - 8) {
            BoxHeader hdr = readBoxHeader(raf, pos);
            if (hdr == null || pos + hdr.size > fileSize + 1024) break;
            boxes.add(new BoxInfo(hdr.type, pos, hdr.size));
            pos += hdr.size;
        }
        return boxes;
    }

    /**
     * 在 moov 数据中递归查找所有 stco/co64 box，并更新 chunk offset
     *
     * @return 是否找到并更新了 stco/co64
     */
    private static boolean updateStcoOffsets(byte[] moovData, long offsetDelta) {
        boolean[] found = {false};
        // moov box header 占 8 字节（size + type），从第8字节开始是子box
        updateStcoInBox(moovData, 8, moovData.length - 8, offsetDelta, found);
        return found[0];
    }

    /**
     * 在指定范围内的子 box 中递归查找 stco/co64
     */
    private static void updateStcoInBox(byte[] data, int start, int length, long offsetDelta, boolean[] found) {
        int pos = start;
        int end = start + length;

        while (pos + 8 <= end) {
            int size = ((data[pos] & 0xFF) << 24) |
                    ((data[pos + 1] & 0xFF) << 16) |
                    ((data[pos + 2] & 0xFF) << 8) |
                    ((data[pos + 3] & 0xFF));
            String type = new String(data, pos + 4, 4);
            int headerSize = 8;

            if (size == 1) {
                // 64-bit size
                if (pos + 16 > end) break;
                size = (int) (((long) (data[pos + 8] & 0xFF) << 56) |
                        ((long) (data[pos + 9] & 0xFF) << 48) |
                        ((long) (data[pos + 10] & 0xFF) << 40) |
                        ((long) (data[pos + 11] & 0xFF) << 32) |
                        ((long) (data[pos + 12] & 0xFF) << 24) |
                        ((long) (data[pos + 13] & 0xFF) << 16) |
                        ((long) (data[pos + 14] & 0xFF) << 8) |
                        ((long) (data[pos + 15] & 0xFF)));
                headerSize = 16;
            }

            if (size < headerSize || pos + size > end) break;

            if ("stco".equals(type)) {
                // stco box: version(1) + flags(3) + entry_count(4) + entry_count * chunk_offset(4)
                int dataStart = pos + headerSize;
                int entryCount = ((data[dataStart + 4] & 0xFF) << 24) |
                        ((data[dataStart + 5] & 0xFF) << 16) |
                        ((data[dataStart + 6] & 0xFF) << 8) |
                        ((data[dataStart + 7] & 0xFF));
                int entriesStart = dataStart + 8;
                for (int i = 0; i < entryCount; i++) {
                    int entryPos = entriesStart + i * 4;
                    if (entryPos + 4 > data.length) break;
                    long oldOffset = ((long) (data[entryPos] & 0xFF) << 24) |
                            ((long) (data[entryPos + 1] & 0xFF) << 16) |
                            ((long) (data[entryPos + 2] & 0xFF) << 8) |
                            ((long) (data[entryPos + 3] & 0xFF));
                    long newOffset = oldOffset + offsetDelta;
                    data[entryPos] = (byte) ((newOffset >> 24) & 0xFF);
                    data[entryPos + 1] = (byte) ((newOffset >> 16) & 0xFF);
                    data[entryPos + 2] = (byte) ((newOffset >> 8) & 0xFF);
                    data[entryPos + 3] = (byte) (newOffset & 0xFF);
                }
                found[0] = true;
                Log.d(TAG, "Updated stco: " + entryCount + " entries, delta=" + offsetDelta);
            } else if ("co64".equals(type)) {
                // co64 box: 64-bit offsets
                int dataStart = pos + headerSize;
                int entryCount = ((data[dataStart + 4] & 0xFF) << 24) |
                        ((data[dataStart + 5] & 0xFF) << 16) |
                        ((data[dataStart + 6] & 0xFF) << 8) |
                        ((data[dataStart + 7] & 0xFF));
                int entriesStart = dataStart + 8;
                for (int i = 0; i < entryCount; i++) {
                    int entryPos = entriesStart + i * 8;
                    if (entryPos + 8 > data.length) break;
                    long oldOffset = ((long) (data[entryPos] & 0xFF) << 56) |
                            ((long) (data[entryPos + 1] & 0xFF) << 48) |
                            ((long) (data[entryPos + 2] & 0xFF) << 40) |
                            ((long) (data[entryPos + 3] & 0xFF) << 32) |
                            ((long) (data[entryPos + 4] & 0xFF) << 24) |
                            ((long) (data[entryPos + 5] & 0xFF) << 16) |
                            ((long) (data[entryPos + 6] & 0xFF) << 8) |
                            ((long) (data[entryPos + 7] & 0xFF));
                    long newOffset = oldOffset + offsetDelta;
                    data[entryPos] = (byte) ((newOffset >> 56) & 0xFF);
                    data[entryPos + 1] = (byte) ((newOffset >> 48) & 0xFF);
                    data[entryPos + 2] = (byte) ((newOffset >> 40) & 0xFF);
                    data[entryPos + 3] = (byte) ((newOffset >> 32) & 0xFF);
                    data[entryPos + 4] = (byte) ((newOffset >> 24) & 0xFF);
                    data[entryPos + 5] = (byte) ((newOffset >> 16) & 0xFF);
                    data[entryPos + 6] = (byte) ((newOffset >> 8) & 0xFF);
                    data[entryPos + 7] = (byte) (newOffset & 0xFF);
                }
                found[0] = true;
                Log.d(TAG, "Updated co64: " + entryCount + " entries");
            } else {
                // 可能是容器 box（trak, mdia, minf, stbl 等），递归查找
                // 常见容器: moov, trak, mdia, minf, stbl, edts, etc.
                if (size > headerSize) {
                    updateStcoInBox(data, pos + headerSize, size - headerSize, offsetDelta, found);
                }
            }

            pos += size;
        }
    }

    private static void copyFile(File src, File dst) throws IOException {
        try (FileInputStream fis = new FileInputStream(src);
             FileOutputStream fos = new FileOutputStream(dst)) {
            byte[] buf = new byte[8192];
            int n;
            while ((n = fis.read(buf)) > 0) {
                fos.write(buf, 0, n);
            }
        }
    }

    private static void copyRange(FileInputStream fis, FileOutputStream fos, long offset, long size) throws IOException {
        fis.getChannel().position(offset);
        byte[] buf = new byte[64 * 1024];
        long remaining = size;
        while (remaining > 0) {
            int toRead = (int) Math.min(buf.length, remaining);
            int n = fis.read(buf, 0, toRead);
            if (n <= 0) break;
            fos.write(buf, 0, n);
            remaining -= n;
        }
    }
}
