package com.attentionseekers.dto;

public class ZoneDemandDto {
    private final double ridesScore;
    private final String ridesLevel;
    private final double eatsScore;
    private final String eatsLevel;
    private final String recommendation;

    public ZoneDemandDto(double ridesScore, String ridesLevel, double eatsScore, String eatsLevel, String recommendation) {
        this.ridesScore = ridesScore;
        this.ridesLevel = ridesLevel;
        this.eatsScore = eatsScore;
        this.eatsLevel = eatsLevel;
        this.recommendation = recommendation;
    }

    public double getRidesScore() {
        return ridesScore;
    }

    public String getRidesLevel() {
        return ridesLevel;
    }

    public double getEatsScore() {
        return eatsScore;
    }

    public String getEatsLevel() {
        return eatsLevel;
    }

    public String getRecommendation() {
        return recommendation;
    }
}
