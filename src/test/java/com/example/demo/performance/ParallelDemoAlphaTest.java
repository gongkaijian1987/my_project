package com.example.demo.performance;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

import com.example.demo.support.SlowTestSupport;

class ParallelDemoAlphaTest {

    @Test
    void alphaScenarioOne() {
        SlowTestSupport.sleepMillis(1500L);
        assertEquals("alpha-1", "alpha-1");
    }

    @Test
    void alphaScenarioTwo() {
        SlowTestSupport.sleepMillis(1500L);
        assertEquals("alpha-2", "alpha-2");
    }
}

