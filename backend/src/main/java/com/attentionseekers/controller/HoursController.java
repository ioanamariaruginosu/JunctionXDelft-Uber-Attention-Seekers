package com.attentionseekers.controller;

import com.attentionseekers.service.HoursService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/hours")
public class HoursController {

    @Autowired
    private HoursService hoursService;

    @PostMapping("/start/{userId}")
    public void startSession(@PathVariable String userId) {
        hoursService.startSession(userId);
    }

    @PostMapping("/stop/{userId}")
    public void stopSession(@PathVariable String userId) {
        hoursService.stopSession(userId);
    }

    @GetMapping("/status/{userId}")
    public Map<String, Integer> getStatus(@PathVariable String userId) {
        Map<String, Integer> status = new HashMap<>();
        status.put("continuous", hoursService.getContinuousMinutes(userId));
        status.put("totalContinuousToday", hoursService.getTotalMinutesToday(userId));
        return status;
    }

}