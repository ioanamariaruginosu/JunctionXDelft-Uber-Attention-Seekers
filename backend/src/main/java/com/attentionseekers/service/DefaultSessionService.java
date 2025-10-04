package com.attentionseekers.service;

import com.attentionseekers.model.SessionInfo;
import com.attentionseekers.model.SessionPeriod;

import java.time.Clock;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Default implementation that mirrors the original logic.
 * Uses Clock for testability.
 */
public class DefaultSessionService implements SessionService {

    private final Clock clock;

    public DefaultSessionService() {
        this(Clock.systemDefaultZone());
    }

    public DefaultSessionService(Clock clock) {
        this.clock = clock;
    }

    @Override
    public boolean startSession(SessionInfo info) {
        if (info.hasOngoingSession()) return false;
        info.setCurrentSessionStart(LocalDateTime.now(clock));
        return true;
    }

    @Override
    public boolean stopSession(SessionInfo info) {
        if (!info.hasOngoingSession()) return false;
        LocalDateTime start = info.getCurrentSessionStart();
        LocalDateTime end = LocalDateTime.now(clock);
        info.addSession(new SessionPeriod(start, end));
        info.clearCurrentSessionStart();
        return true;
    }

    @Override
    public int getContinuousMinutes(SessionInfo info) {
        if (!info.hasOngoingSession()) return 0;
        LocalDateTime now = LocalDateTime.now(clock);
        return (int) Duration.between(info.getCurrentSessionStart(), now).toMinutes();
    }

    @Override
    public int getTotalMinutesToday(SessionInfo info) {
        int total = 0;
        LocalDate today = LocalDate.now(clock);

        for (SessionPeriod p : info.getSessions()) {
            if (p.getStart().toLocalDate().isEqual(today)) {
                total += (int) Duration.between(p.getStart(), p.getEnd()).toMinutes();
            }
        }

        if (info.hasOngoingSession() && info.getCurrentSessionStart().toLocalDate().isEqual(today)) {
            total += getContinuousMinutes(info);
        }

        return total;
    }
}
