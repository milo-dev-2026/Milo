package com.chat.base.net.sign;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.UUID;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

/**
 * API请求签名工具
 * 移植自utalk的SignatureUtils
 */
public class SignatureUtils {

    private static final SignatureUtils INSTANCE = new SignatureUtils();

    public static SignatureUtils getInstance() {
        return INSTANCE;
    }

    private static final String SECRET_KEY = "release_secret_key_&%$&^#AADFS[_1nafay:&*523e?sd!";

    private static final byte[] CHAR_MAP = {
            65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80,
            81, 82, 83, 84, 85, 86, 87, 88, 89, 90,
            43, 50, 45, 38, 60, 62, 35, 126, 40, 41,
            107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122,
            48, 49, 50, 51, 52, 53, 54, 55, 56, 57,
            97, 98, 99, 100, 101, 102, 103, 104, 105, 106
    };

    private SignatureUtils() {
    }

    /**
     * 生成签名
     */
    public String sign(String input) {
        if (input == null) input = "";
        byte[] inputBytes = input.getBytes(StandardCharsets.UTF_8);
        byte[] xored = xorTransform(inputBytes, (byte) 3);
        byte[] hmac = hmacSha256(SECRET_KEY, xored);
        String prefix = getPrefix();
        int[][] matrix = generateMatrix(prefix);
        byte[][] transformed = transform(hmac, matrix);
        byte[] flattened = flatten(transformed);
        return prefix + mapToChars(flattened);
    }

    private String getPrefix() {
        return "1C2s";
    }

    /**
     * 字节XOR变换：每个字节与当前状态异或，状态循环左移1位
     */
    private byte[] xorTransform(byte[] input, byte initial) {
        byte[] result = new byte[input.length];
        int state = initial & 0xFF;
        for (int i = 0; i < input.length; i++) {
            result[i] = (byte) (input[i] ^ state);
            state = ((state >>> 7) | (state << 1)) & 0xFF;
        }
        return result;
    }

    /**
     * HMAC-SHA256
     */
    private byte[] hmacSha256(String key, byte[] data) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(key.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return mac.doFinal(data);
        } catch (Exception e) {
            throw new RuntimeException("HMAC-SHA256 error", e);
        }
    }

    /**
     * 从字符串生成8x8矩阵
     */
    private int[][] generateMatrix(String str) {
        int[][] matrix = new int[8][8];
        byte[] hmac = hmacSha256(str, str.getBytes(StandardCharsets.UTF_8));
        // 取前8字节作为种子
        long seed = 0;
        for (int i = 0; i < 8; i++) {
            seed = (seed << 8) | (hmac[i] & 0xFFL);
        }
        // 使用xorshift64*生成随机数
        XorShift64Star rng = new XorShift64Star(seed);
        for (int i = 0; i < 8; i++) {
            for (int j = 0; j < 8; j++) {
                long next = rng.next();
                int val = (int) ((next >>> 48) & 0xFFFF);
                matrix[i][j] = (val % 1536) + 512;
            }
        }
        return matrix;
    }

    /**
     * PKCS7风格填充到指定长度
     */
    private byte[] pad(byte[] input, int size) {
        int padLen = size - (input.length % size);
        byte[] result = Arrays.copyOf(input, input.length + padLen);
        for (int i = input.length; i < result.length; i++) {
            result[i] = (byte) padLen;
        }
        return result;
    }

    /**
     * 核心变换函数
     */
    private byte[][] transform(byte[] input, int[][] matrix) {
        byte[][] grid = new byte[8][8];
        byte[] padded = pad(input, 64);

        // 用matrix值初始化网格
        for (int i = 0; i < 8; i++) {
            for (int j = 0; j < 8; j++) {
                grid[i][j] = (byte) (matrix[i][j] & 0xFF);
            }
        }

        // 与填充后的输入异或
        for (int i = 0; i < 8; i++) {
            for (int j = 0; j < 8; j++) {
                grid[i][j] = (byte) (grid[i][j] ^ padded[i * 8 + j]);
            }
        }

        // 行循环移位：第i行向右循环移i位
        for (int i = 0; i < 8; i++) {
            byte[] newRow = new byte[8];
            for (int j = 0; j < 8; j++) {
                newRow[(j + i) % 8] = grid[i][j];
            }
            grid[i] = newRow;
        }

        // 列循环移位：第j列向下循环移j位
        for (int j = 0; j < 8; j++) {
            byte[] newCol = new byte[8];
            for (int i = 0; i < 8; i++) {
                newCol[(i + j) % 8] = grid[i][j];
            }
            for (int i = 0; i < 8; i++) {
                grid[i][j] = newCol[i];
            }
        }

        // 非线性变换：每个字节 = (byte >>> 2) ^ (byte * 7)
        for (int i = 0; i < 8; i++) {
            for (int j = 0; j < 8; j++) {
                int val = grid[i][j] & 0xFF;
                grid[i][j] = (byte) (((val >>> 2) & 0xFF) ^ ((val * 7) & 0xFF));
            }
        }

        // 与上方和左方邻居异或
        for (int i = 0; i < 8; i++) {
            for (int j = 0; j < 8; j++) {
                if (i > 0) {
                    grid[i][j] = (byte) (grid[i][j] ^ grid[i - 1][j]);
                }
                if (j > 0) {
                    grid[i][j] = (byte) (grid[i][j] ^ grid[i][j - 1]);
                }
            }
        }

        return grid;
    }

    /**
     * 将二维数组展平为一维
     */
    private byte[] flatten(byte[][] grid) {
        byte[] result = new byte[grid.length * grid[0].length];
        int idx = 0;
        for (byte[] row : grid) {
            System.arraycopy(row, 0, result, idx, row.length);
            idx += row.length;
        }
        return result;
    }

    /**
     * 将字节映射到字符表
     */
    private String mapToChars(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append((char) CHAR_MAP[(b & 0xFF) % 72]);
        }
        return sb.toString();
    }

    /**
     * Xorshift64* 随机数生成器
     */
    private static class XorShift64Star {
        private long state;

        XorShift64Star(long seed) {
            this.state = seed;
        }

        long next() {
            long x = state;
            x ^= (x >>> 12);
            x ^= (x << 25);
            x ^= (x >>> 27);
            state = x;
            return x * 2685821657736338717L;
        }
    }

    /**
     * 生成nonce（UUID）
     */
    public String generateNonce() {
        return UUID.randomUUID().toString();
    }

    /**
     * 获取当前时间戳（毫秒）
     */
    public String getTimestamp() {
        return String.valueOf(System.currentTimeMillis());
    }
}
