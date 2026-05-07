package com.example.demo.performance;

import static org.junit.jupiter.api.Assertions.assertNotNull;

import java.util.Arrays;
import java.util.List;
import org.junit.jupiter.api.Test;

import com.example.demo.support.SlowTestSupport;

class ParallelDemoGammaTest {

    @Test
    void gammaScenarioOne() {
        SlowTestSupport.sleepMillis(1500L);
        List<String> values = Arrays.asList("g", "a", "m", "m", "a");
        assertNotNull(values);
    }

    @Test
    void gammaScenarioTwo() {
        SlowTestSupport.sleepMillis(1500L);
        assertNotNull(System.getProperty("java.version"));
    }
}

