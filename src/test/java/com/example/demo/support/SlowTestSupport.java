package com.example.demo.support;

import java.util.concurrent.TimeUnit;

public final class SlowTestSupport {

    private SlowTestSupport() {
    }

    public static void sleepMillis(long millis) {
        try {
            TimeUnit.MILLISECONDS.sleep(millis);
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Slow test interrupted", ex);
        }
    }
}

