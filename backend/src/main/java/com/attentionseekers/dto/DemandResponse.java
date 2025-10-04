package com.attentionseekers.dto;

import com.attentionseekers.service.UserType;

import java.time.Instant;
import java.util.Map;

public class DemandResponse {
    private final Instant generatedAt;
    private final String window;
    private final UserType userType;
    private final Map<String, DriverDemandDto> zones;

    public DemandResponse(Instant generatedAt, String window, UserType userType, Map<String, DriverDemandDto> zones) {
        this.generatedAt = generatedAt;
        this.window = window;
        this.userType = userType;
        this.zones = zones;
    }

    public Instant getGeneratedAt() {
        return generatedAt;
    }

    public String getWindow() {
        return window;
    }

    public UserType getUserType() {
        return userType;
    }

    public Map<String, DriverDemandDto> getZones() {
        return zones;
    }
}
