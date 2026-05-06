package com.example.demo.controller;

import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.service.GreetingService;

@RestController
@RequestMapping("/api")
public class HealthController {

    private final GreetingService greetingService;

    public HealthController(GreetingService greetingService) {
        this.greetingService = greetingService;
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> payload = new LinkedHashMap<String, Object>();
        payload.put("status", "UP");
        payload.put("service", "springboot-circleci-demo");
        payload.put("javaVersion", System.getProperty("java.version"));
        return ResponseEntity.ok(payload);
    }

    @GetMapping("/greeting")
    public ResponseEntity<Map<String, Object>> greeting(@RequestParam(value = "name", required = false) String name) {
        Map<String, Object> payload = new LinkedHashMap<String, Object>();
        payload.put("message", greetingService.greet(name));
        return ResponseEntity.ok(payload);
    }
}

