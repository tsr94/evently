package com.tsr.tickets.controllers;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TestController {
    @GetMapping("/test")
    public ResponseEntity<String> test() {
        System.out.println("========== TEST CONTROLLER HIT ==========");
        return ResponseEntity
                .ok()
                .header("X-Test", "spring-reached")
                .body("HELLO-FROM-SPRING");
    }
}