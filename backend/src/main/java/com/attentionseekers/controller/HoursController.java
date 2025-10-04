package com.attentionseekers.controller;

import com.attentionseekers.service.HoursService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

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
    public Map<String, Integer> getStatus(@RequestParam String userId) {
        Map<String, Integer> status = new HashMap<>();
        status.put("continuous", hoursService.getContinuousMinutes(userId));
        status.put("driving", hoursService.getDrivingMinutes(userId));
        status.put("totalContinuousToday", hoursService.getTotalMinutesToday(userId));
        status.put("totalDrivingToday", hoursService.getTotalDrivingMinutesToday(userId));
        return status;
    }

}