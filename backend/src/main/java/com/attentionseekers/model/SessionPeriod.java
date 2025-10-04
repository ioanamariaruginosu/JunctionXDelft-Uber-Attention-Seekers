package com.attentionseekers.model;

import java.time.LocalDateTime;

public class SessionPeriod {
    private final LocalDateTime start;
    private final LocalDateTime end;

    public SessionPeriod(LocalDateTime start, LocalDateTime end) {
        if (start == null || end == null) {
            throw new IllegalArgumentException("start and end must not be null");
        }
        if (end.isBefore(start)) {
            throw new IllegalArgumentException("end must not be before start");
        }
        this.start = start;
        this.end = end;
    }

    public LocalDateTime getStart() { return start; }
    public LocalDateTime getEnd() { return end; }
}
