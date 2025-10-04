package com.attentionseekers.service;

import java.time.LocalTime;

public enum DemandBucket {
    MORNING("morning"),
    EVENING("evening"),
    NIGHT("night");

    private final String label;

    DemandBucket(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    public static DemandBucket from(LocalTime time) {
        int hour = time.getHour();
        if (hour >= 6 && hour < 12) {
            return MORNING;
        }
        if (hour >= 16 && hour < 22) {
            return EVENING;
        }
        return NIGHT;
    }

    public DemandBucket next() {
        return switch (this) {
            case MORNING -> EVENING;
            case EVENING -> NIGHT;
            case NIGHT -> MORNING;
        };
    }
}
