package com.attentionseekers.dto;

public class DriverDemandDto {
    private final double score;
    private final String level;
    private final String action;

    public DriverDemandDto(double score, String level, String action) {
        this.score = score;
        this.level = level;
        this.action = action;
    }

    public double getScore() {
        return score;
    }

    public String getLevel() {
        return level;
    }

    public String getAction() {
        return action;
    }
}
