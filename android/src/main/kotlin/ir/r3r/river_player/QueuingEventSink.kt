// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
package ir.r3r.river_player

import io.flutter.plugin.common.EventChannel.EventSink
import java.util.ArrayList

/**
 * An implementation of [EventSink] which can wrap an underlying sink.
 * It delivers messages immediately when downstream is available, but it queues messages before
 * the delegate event sink is set with setDelegate.
 * This class is thread-safe through synchronization.
 */
internal class QueuingEventSink : EventSink {
    private val lock = Any()
    private var delegate: EventSink? = null
    private val eventQueue = ArrayList<Any>()
    private var done = false

    fun setDelegate(delegate: EventSink?) {
        synchronized(lock) {
            this.delegate = delegate
            maybeFlush()
        }
    }

    override fun endOfStream() {
        synchronized(lock) {
            enqueue(EndOfStreamEvent())
            maybeFlush()
            done = true
        }
    }

    override fun error(code: String, message: String?, details: Any?) {
        synchronized(lock) {
            enqueue(ErrorEvent(code, message ?: "", details))
            maybeFlush()
        }
    }

    override fun success(event: Any?) {
        synchronized(lock) {
            if (event != null) {
                enqueue(event)
                maybeFlush()
            }
        }
    }

    private fun enqueue(event: Any) {
        if (done) {
            return
        }
        eventQueue.add(event)
    }

    private fun maybeFlush() {
        val currentDelegate = delegate ?: return
        for (event in eventQueue) {
            when (event) {
                is EndOfStreamEvent -> {
                    currentDelegate.endOfStream()
                }
                is ErrorEvent -> {
                    currentDelegate.error(event.code, event.message, event.details)
                }
                else -> {
                    currentDelegate.success(event)
                }
            }
        }
        eventQueue.clear()
    }

    private class EndOfStreamEvent
    private class ErrorEvent(
        var code: String,
        var message: String,
        var details: Any?
    )
}