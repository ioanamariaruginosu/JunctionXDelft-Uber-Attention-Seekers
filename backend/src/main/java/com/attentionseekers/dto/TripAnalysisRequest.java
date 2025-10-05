package com.attentionseekers.dto;

import lombok.Data;

@Data
public class TripAnalysisRequest {
    private double profitabilityScore;
    private double totalEarnings;
    private int estimatedDuration;
    private double distance;
    private Double surgeMultiplier;
    private String pickupLocation;
    private String dropoffLocation;
    private String pickupLat;
    private String pickupLon;
    private String dropOffLat;
    private String dropOffLon;
}
