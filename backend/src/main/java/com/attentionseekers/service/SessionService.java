package com.attentionseekers.service;

import com.attentionseekers.model.SessionInfo;
import com.attentionseekers.model.SessionPeriod;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import org.springframework.stereotype.Service;


@Service
public class SessionService {

    private final Clock clock;

    public SessionService() {
        this(Clock.systemDefaultZone());
    }

    public SessionService(Clock clock) {
        this.clock = clock;
    }

    public boolean startSession(SessionInfo info) {
        if (info.hasOngoingSession()) return false;
        info.setCurrentSessionStart(LocalDateTime.now(clock));
        return true;
    }

    public boolean stopSession(SessionInfo info) {
        if (!info.hasOngoingSession()) return false;
        LocalDateTime start = info.getCurrentSessionStart();
        LocalDateTime end   = LocalDateTime.now(clock);
        info.addSession(new SessionPeriod(start, end));
        info.clearCurrentSessionStart();
        return true;
    }

    public int getContinuousMinutes(SessionInfo info) {
        if (!info.hasOngoingSession()) return 0;
        return (int) Duration.between(info.getCurrentSessionStart(), LocalDateTime.now(clock)).toMinutes();
    }

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
