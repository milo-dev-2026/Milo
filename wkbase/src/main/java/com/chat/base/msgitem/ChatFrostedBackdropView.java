package com.chat.base.msgitem;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapShader;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Shader;
import android.view.View;

public final class ChatFrostedBackdropView extends View {

    private final Paint noisePaint;

    public ChatFrostedBackdropView(Context context) {
        super(context);
        Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        Bitmap noiseBitmap = createNoiseBitmap();
        paint.setShader(new BitmapShader(noiseBitmap, Shader.TileMode.REPEAT, Shader.TileMode.REPEAT));
        paint.setAlpha(56);
        this.noisePaint = paint;
    }

    private void drawGlassGradient(Canvas canvas, int c1, int c2, int c3) {
        Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        paint.setShader(new LinearGradient(0, 0, 0, canvas.getHeight(),
                new int[]{c1, c2, c3}, new float[]{0f, 0.58f, 1f}, Shader.TileMode.CLAMP));
        canvas.drawRect(0, 0, canvas.getWidth(), canvas.getHeight(), paint);
    }

    private boolean isNightMode(Context context) {
        return (context.getResources().getConfiguration().uiMode & 48) == 32;
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        Context context = getContext();
        if (isNightMode(context)) {
            canvas.drawColor(Color.argb(176, 0, 0, 0));
            drawGlassGradient(canvas,
                    Color.argb(96, 52, 56, 52),
                    Color.argb(40, 28, 31, 29),
                    Color.argb(58, 58, 62, 56));
        } else {
            canvas.drawColor(Color.argb(46, 0, 0, 0));
            drawGlassGradient(canvas,
                    Color.argb(188, 238, 242, 234),
                    Color.argb(164, 216, 232, 222),
                    Color.argb(190, 234, 238, 229));
        }
        canvas.drawRect(0, 0, getWidth(), getHeight(), noisePaint);
    }

    private static Bitmap createNoiseBitmap() {
        Bitmap bitmap = Bitmap.createBitmap(64, 64, Bitmap.Config.ARGB_8888);
        int seed = 17;
        for (int y = 0; y < 64; y++) {
            for (int x = 0; x < 64; x++) {
                seed = (seed * 1103515245) + 12345;
                bitmap.setPixel(x, y, Color.argb(((seed >>> 16) & 31) / 2 + 14, 255, 255, 255));
            }
        }
        return bitmap;
    }
}
