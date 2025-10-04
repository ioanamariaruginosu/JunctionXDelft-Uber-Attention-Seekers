package com.attentionseekers.dto;

import lombok.Data;

@Data
public class TripAnalysisRequest {
    private double profitabilityScore;
    private double totalEarnings;
    private int estimatedDuration; // in minutes
    private double distance;
    private Double surgeMultiplier; // nullable
    private String pickupLocation;
    private String dropoffLocation;
}