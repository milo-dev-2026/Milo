package com.chat.base.net.ud

import android.os.Handler
import android.os.Looper
import com.chat.base.utils.WKLogUtils
import okhttp3.MediaType
import okhttp3.RequestBody
import okio.Buffer
import okio.BufferedSink
import okio.ForwardingSink
import okio.buffer
import java.io.IOException


class FileRequestBody(private val requestBody: RequestBody, private val tag: Any) : RequestBody() {
    private var mCurrentLength: Long = 0
    private var handler = Handler(Looper.getMainLooper())
    private var lastProgressUpdate: Long = 0

    override fun contentLength(): Long {
        try {
            return requestBody.contentLength()
        } catch (e: Exception) {
            return -1
        }
    }

    override fun contentType(): MediaType? {
        return requestBody.contentType()
    }

    override fun writeTo(sink: BufferedSink) {
        val contentLength = contentLength()
        val hasValidLength = contentLength > 0
        val forwardingSink: ForwardingSink = object : ForwardingSink(sink) {
            @Throws(IOException::class)
            override fun write(source: Buffer, byteCount: Long) {
                mCurrentLength += byteCount
                if (hasValidLength) {
                    val now = System.currentTimeMillis()
                    // 进度回调 500ms 一次即可，减少主线程开销
                    if (now - lastProgressUpdate > 500) {
                        lastProgressUpdate = now
                        val f1 = mCurrentLength / contentLength.toFloat()
                        handler.post {
                            var p = (f1 * 100).toInt()
                            if (p > 100) {
                                p = 100
                            }
                            WKProgressManager.instance.seekProgress(tag, p)
                        }
                    }
                }
                super.write(source, byteCount)
            }
        }
        val bufferedSink: BufferedSink = forwardingSink.buffer()
        requestBody.writeTo(bufferedSink)
        bufferedSink.flush()
    }
}
