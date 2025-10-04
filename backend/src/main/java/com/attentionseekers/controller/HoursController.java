package com.attentionseekers.controller;

import com.attentionseekers.service.HoursService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/hours")
public class HoursController {

    @Autowired
    private HoursService hoursService;

    @PostMapping("/start")
    public void startSession(@RequestParam String userId) {
        hoursService.startSession(userId);
    }

    @PostMapping("/stop")
    public void stopSession(@RequestParam String userId) {
        hoursService.stopSession(userId);
    }

    @GetMapping("/status")
    public Map<String, Object> getStatus(@RequestParam String userId) {
        Map<String, Object> status = new HashMap<>();
        status.put("continuous", hoursService.getContinuousMinutes(userId));
        status.put("driving", hoursService.getDrivingMinutes(userId));
        status.put("totalContinuousToday", hoursService.getTotalMinutesToday(userId));
        status.put("totalDrivingToday", hoursService.getTotalDrivingMinutesToday(userId));

        // Add these so the client relies on the backend clock
        status.put("active", hoursService.isActive(userId)); // boolean

        LocalDateTime startedAt = hoursService.getCurrentSessionStart(userId);    // may be null
        status.put("startedAt", startedAt != null ? startedAt.toString() : null); // ISO-8601 string

        return status;
    }
}
