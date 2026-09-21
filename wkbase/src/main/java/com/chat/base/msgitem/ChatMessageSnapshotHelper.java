package com.chat.base.msgitem;

import android.app.Activity;
import android.content.Context;
import android.content.ContextWrapper;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Rect;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.view.PixelCopy;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;

import com.chat.base.R;

import kotlin.Unit;
import kotlin.jvm.functions.Function1;

public final class ChatMessageSnapshotHelper {

    public static final ChatMessageSnapshotHelper INSTANCE = new ChatMessageSnapshotHelper();

    public static class Snapshot {
        private final Bitmap bitmap;
        private final View sourceView;
        private final Rect rectInHost;

        public Snapshot(Bitmap bitmap, View sourceView, Rect rectInHost) {
            this.bitmap = bitmap;
            this.sourceView = sourceView;
            this.rectInHost = rectInHost;
        }

        public Bitmap getBitmap() { return bitmap; }
        public View getSourceView() { return sourceView; }
        public Rect getRectInHost() { return rectInHost; }
    }

    private ChatMessageSnapshotHelper() {}

    private Activity findActivity(Context context) {
        while (!(context instanceof Activity)) {
            if (context instanceof ContextWrapper) {
                context = ((ContextWrapper) context).getBaseContext();
            } else {
                return null;
            }
        }
        return (Activity) context;
    }

    private Rect rectInHost(View sourceView, View hostView) {
        int[] sourceLoc = new int[2];
        int[] hostLoc = new int[2];
        sourceView.getLocationOnScreen(sourceLoc);
        hostView.getLocationOnScreen(hostLoc);
        int left = sourceLoc[0] - hostLoc[0];
        int top = sourceLoc[1] - hostLoc[1];
        return new Rect(left, top, left + sourceView.getWidth(), top + sourceView.getHeight());
    }

    public Snapshot create(View sourceView, View hostView) {
        if (sourceView.getWidth() <= 0 || sourceView.getHeight() <= 0) {
            return null;
        }
        try {
            Bitmap bitmap = Bitmap.createBitmap(sourceView.getWidth(), sourceView.getHeight(), Bitmap.Config.ARGB_8888);
            sourceView.draw(new Canvas(bitmap));
            return new Snapshot(bitmap, sourceView, rectInHost(sourceView, hostView));
        } catch (OutOfMemoryError e) {
            return null;
        }
    }

    public void createAsync(View sourceView, View hostView, boolean usePixelCopy, Function1<Snapshot, Unit> callback) {
        if (!usePixelCopy) {
            Snapshot snapshot = create(sourceView, hostView);
            callback.invoke(snapshot);
            return;
        }
        if (Build.VERSION.SDK_INT >= 26 && sourceView.isAttachedToWindow() && sourceView.getWidth() > 0 && sourceView.getHeight() > 0) {
            Activity activity = findActivity(sourceView.getContext());
            if (activity == null) {
                callback.invoke(create(sourceView, hostView));
                return;
            }
            Window window = activity.getWindow();
            if (window == null) {
                callback.invoke(create(sourceView, hostView));
                return;
            }
            try {
                Bitmap bitmap = Bitmap.createBitmap(sourceView.getWidth(), sourceView.getHeight(), Bitmap.Config.ARGB_8888);
                int[] locationInWindow = new int[2];
                sourceView.getLocationInWindow(locationInWindow);
                int left = locationInWindow[0];
                int top = locationInWindow[1];
                PixelCopy.request(window, new Rect(left, top, left + sourceView.getWidth(), top + sourceView.getHeight()),
                        bitmap, (copyResult) -> {
                            if (copyResult == 0) {
                                callback.invoke(new Snapshot(bitmap, sourceView, rectInHost(sourceView, hostView)));
                            } else {
                                bitmap.recycle();
                                callback.invoke(create(sourceView, hostView));
                            }
                        }, new Handler(Looper.getMainLooper()));
            } catch (IllegalArgumentException | OutOfMemoryError e) {
                callback.invoke(create(sourceView, hostView));
            }
        } else {
            callback.invoke(create(sourceView, hostView));
        }
    }

    public void hideSourceUntilDetached(View sourceView) {
        sourceView.setAlpha(0f);
        sourceView.addOnAttachStateChangeListener(new View.OnAttachStateChangeListener() {
            @Override
            public void onViewAttachedToWindow(View v) {}

            @Override
            public void onViewDetachedFromWindow(View v) {
                v.setAlpha(1f);
                v.removeOnAttachStateChangeListener(this);
            }
        });
    }

    public void restoreSource(View sourceView) {
        if (sourceView != null) {
            sourceView.setAlpha(1f);
        }
    }

    public View resolveSourceView(View view) {
        if (view instanceof com.chat.base.views.BubbleLayout) {
            return view;
        }
        View result = view;
        while (view != null) {
            if (view.getId() == R.id.fullContentLayout) {
                return view;
            }
            if (view.getId() == R.id.wkBaseContentLayout) {
                result = view;
            }
            Object parent = view.getParent();
            if (parent instanceof View) {
                view = (View) parent;
            } else {
                view = null;
            }
        }
        return result;
    }
}
