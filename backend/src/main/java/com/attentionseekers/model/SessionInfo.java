package com.attentionseekers.model;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class SessionInfo {
    private List<SessionPeriod> sessions = new ArrayList<>();
    private LocalDateTime currentSessionStart;

    public void startSession() {
        if (currentSessionStart == null) {
            currentSessionStart = LocalDateTime.now();
        }
    }

    public void stopSession() {
        if (currentSessionStart != null) {
            sessions.add(new SessionPeriod(currentSessionStart, LocalDateTime.now()));
            currentSessionStart = null;
        }
    }

    public int getContinuousMinutes() {
        if (currentSessionStart == null) return 0;
        return (int) java.time.Duration.between(currentSessionStart, LocalDateTime.now()).toMinutes();
    }

    public int getTotalMinutesToday() {
        int total = 0;
        LocalDateTime today = LocalDateTime.now();
        for (SessionPeriod period : sessions) {
            if (period.getStart().toLocalDate().equals(today.toLocalDate())) {
                total += java.time.Duration.between(period.getStart(), period.getEnd()).toMinutes();
            }
        }
        if (currentSessionStart != null && currentSessionStart.toLocalDate().equals(today.toLocalDate())) {
            total += getContinuousMinutes();
        }
        return total;
    }

    // Inner class to represent a session period
    public static class SessionPeriod {
        private LocalDateTime start;
        private LocalDateTime end;

        public SessionPeriod(LocalDateTime start, LocalDateTime end) {
            this.start = start;
            this.end = end;
        }

        public LocalDateTime getStart() { return start; }
        public LocalDateTime getEnd() { return end; }
    }
}