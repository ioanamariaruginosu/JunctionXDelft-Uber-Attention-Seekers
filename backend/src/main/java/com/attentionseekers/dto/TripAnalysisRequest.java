package com.attentionseekers.dto;

import lombok.Data;

@Data
public class TripAnalysisRequest {
    private double profitabilityScore;
    private double totalEarnings;
    private int estimatedDuration; // in minutes
    private double distance; // in miles or km
    private Double surgeMultiplier; // nullable
    private String pickupLocation;
    private String dropoffLocation;
    private String pickupLat;
    private String pickupLon;
    private String dropOffLat;
    private String dropOffLon;
}