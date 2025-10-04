package com.attentionseekers.service;

import com.attentionseekers.model.SessionInfo;
import com.attentionseekers.model.SessionPeriod;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import org.springframework.stereotype.Service;   // <-- add this import


/** Stateless service that operates on SessionInfo. */
@Service
public class SessionService {

    private final Clock clock;

    public SessionService() {
        this(Clock.systemDefaultZone()); // <-- fix here
    }

    public SessionService(Clock clock) {
        this.clock = clock;
    }

    /** Starts a session if none is active. @return true if started, false if already running. */
    public boolean startSession(SessionInfo info) {
        if (info.hasOngoingSession()) return false;
        info.setCurrentSessionStart(LocalDateTime.now(clock));
        return true;
    }

    /** Stops the active session and stores it. @return true if stopped, false if none running. */
    public boolean stopSession(SessionInfo info) {
        if (!info.hasOngoingSession()) return false;
        LocalDateTime start = info.getCurrentSessionStart();
        LocalDateTime end   = LocalDateTime.now(clock);
        info.addSession(new SessionPeriod(start, end));
        info.clearCurrentSessionStart();
        return true;
    }

    /** Minutes since current session start; 0 if none running. */
    public int getContinuousMinutes(SessionInfo info) {
        if (!info.hasOngoingSession()) return 0;
        return (int) Duration.between(info.getCurrentSessionStart(), LocalDateTime.now(clock)).toMinutes();
    }

    /** Sum of minutes for sessions that started today + ongoing (if started today). */
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
