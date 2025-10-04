package com.attentionseekers.controller;

import com.attentionseekers.model.RestLocation;
import com.attentionseekers.service.RestLocationService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/locations")
public class RestLocationController {

    private final RestLocationService service;

    public RestLocationController(RestLocationService service) {
        this.service = service;
    }

    @GetMapping("/nearby")
    public List<RestLocation> getNearby(
            @RequestParam double lat,
            @RequestParam double lon,
            @RequestParam(defaultValue = "3") int limit) {
        return service.findClosest(lat, lon, limit);
    }
}
