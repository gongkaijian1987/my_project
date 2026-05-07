package com.example.demo.performance;

import static org.junit.jupiter.api.Assertions.assertFalse;

import org.junit.jupiter.api.Test;

import com.example.demo.support.SlowTestSupport;

class ParallelDemoDeltaTest {

    @Test
    void deltaScenarioOne() {
        SlowTestSupport.sleepMillis(1500L);
        assertFalse("delta".isEmpty());
    }

    @Test
    void deltaScenarioTwo() {
        SlowTestSupport.sleepMillis(1500L);
        assertFalse("ci".isEmpty());
    }
}

