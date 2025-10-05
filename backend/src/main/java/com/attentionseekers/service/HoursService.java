package com.attentionseekers.service;

import com.attentionseekers.model.SessionInfo;
import com.attentionseekers.model.SessionPeriod;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class HoursService {

    private final Map<String, SessionInfo> userSessions = new ConcurrentHashMap<>();

    private final SessionService sessionService;
    private final JdbcTemplate jdbc;

    public HoursService(SessionService sessionService, JdbcTemplate jdbc) {
        this.sessionService = (sessionService != null ? sessionService : new SessionService());
        this.jdbc = jdbc;
    }

    @Transactional
    protected void saveSessionInfo(String userId, SessionInfo info) {
        jdbc.update("DELETE FROM demand.hours_session WHERE user_id = ?", userId);

        for (SessionPeriod p : info.getSessions()) {
            if (p.getEnd() != null) {
                jdbc.update(
                    "INSERT INTO demand.hours_session (user_id, started_at, ended_at) VALUES (?,?,?)",
                    userId,
                    Timestamp.valueOf(p.getStart()),
                    Timestamp.valueOf(p.getEnd())
                );
            }
        }

        LocalDateTime openStart = info.getCurrentSessionStart();
        if (openStart != null) {
            jdbc.update(
                "INSERT INTO demand.hours_session (user_id, started_at, ended_at) VALUES (?,?,NULL)",
                userId,
                Timestamp.valueOf(openStart)
            );
        }
    }

    protected SessionInfo loadSessionInfo(String userId) {
        SessionInfo info = new SessionInfo();

        jdbc.query(
            "SELECT started_at, ended_at " +
            "  FROM demand.hours_session " +
            " WHERE user_id = ? " +
            " ORDER BY started_at ASC",
            rs -> {
                LocalDateTime start = rs.getTimestamp("started_at").toLocalDateTime();
                Timestamp endedTs = rs.getTimestamp("ended_at");
                if (endedTs == null) {
                    info.setCurrentSessionStart(start);
                } else {
                    LocalDateTime end = endedTs.toLocalDateTime();
                    info.addSession(new SessionPeriod(start, end));
                }
            },
            userId
        );

        return info;
    }

    private SessionInfo getSessionInfo(String userId) {
        return userSessions.computeIfAbsent(userId, this::loadSessionInfo);
    }

    public void startSession(String userId) {
        SessionInfo info = getSessionInfo(userId);
        boolean changed = sessionService.startSession(info);
        if (changed) saveSessionInfo(userId, info);
    }

    public void stopSession(String userId) {
        SessionInfo info = getSessionInfo(userId);
        boolean changed = sessionService.stopSession(info);
        if (changed) saveSessionInfo(userId, info);
    }

    public int getContinuousMinutes(String userId) {
        return sessionService.getContinuousMinutes(getSessionInfo(userId));
    }

    public int getTotalMinutesToday(String userId) {
        return sessionService.getTotalMinutesToday(getSessionInfo(userId));
    }

    public int getDrivingMinutes(String userId) {
        return 0;
    }

    public int getTotalDrivingMinutesToday(String userId) {
        return 0;
    }

    public boolean isActive(String userId) {
        return getSessionInfo(userId).hasOngoingSession();
    }

    public LocalDateTime getCurrentSessionStart(String userId) {
        return getSessionInfo(userId).getCurrentSessionStart();
    }
}
