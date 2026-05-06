package com.example.demo.service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import org.springframework.stereotype.Service;

@Service
public class GreetingService {

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    public String greet(String name) {
        String normalizedName = (name == null || name.trim().isEmpty()) ? "CircleCI" : name.trim();
        return String.format("Hello, %s! Build time: %s", normalizedName, LocalDateTime.now().format(FORMATTER));
    }
}

