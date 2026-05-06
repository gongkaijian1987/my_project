package com.example.demo.service;

import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class GreetingServiceTest {

    private final GreetingService greetingService = new GreetingService();

    @Test
    void shouldUseProvidedName() {
        String result = greetingService.greet("Codex");
        assertTrue(result.startsWith("Hello, Codex!"));
    }

    @Test
    void shouldFallbackToDefaultName() {
        String result = greetingService.greet(" ");
        assertTrue(result.startsWith("Hello, CircleCI!"));
    }
}

