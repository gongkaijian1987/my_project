package com.example.demo.performance;

import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

import com.example.demo.support.SlowTestSupport;

class ParallelDemoBetaTest {

    @Test
    void betaScenarioOne() {
        SlowTestSupport.sleepMillis(1500L);
        assertTrue("circleci".contains("circle"));
    }

    @Test
    void betaScenarioTwo() {
        SlowTestSupport.sleepMillis(1500L);
        assertTrue("parallel".startsWith("par"));
    }
}

