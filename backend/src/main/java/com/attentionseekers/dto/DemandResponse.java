package com.attentionseekers.dto;

import java.time.Instant;
import java.util.Map;

public class DemandResponse {
    private final Instant generatedAt;
    private final String range;
    private final Map<String, ZoneDemandDto> zones;

    public DemandResponse(Instant generatedAt, String range, Map<String, ZoneDemandDto> zones) {
        this.generatedAt = generatedAt;
        this.range = range;
        this.zones = zones;
    }

    public Instant getGeneratedAt() {
        return generatedAt;
    }

    public String getRange() {
        return range;
    }

    public Map<String, ZoneDemandDto> getZones() {
        return zones;
    }
}
