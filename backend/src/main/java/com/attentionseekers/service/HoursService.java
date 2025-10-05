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

    /* ===================== Persistence helpers (DB instead of JSON) ===================== */

    /**
     * Persist a full snapshot: delete all rows for the user and re-insert
     * closed sessions + one open session (if any).
     * Simple and robust; fine for our scale.
     */
    @Transactional
    protected void saveSessionInfo(String userId, SessionInfo info) {
        // Remove any previous rows for this user's history
        jdbc.update("DELETE FROM demand.hours_session WHERE user_id = ?", userId);

        // Insert closed sessions
        for (SessionPeriod p : info.getSessions()) {
            // guard: only persist closed sessions
            if (p.getEnd() != null) {
                jdbc.update(
                    "INSERT INTO demand.hours_session (user_id, started_at, ended_at) VALUES (?,?,?)",
                    userId,
                    Timestamp.valueOf(p.getStart()),
                    Timestamp.valueOf(p.getEnd())
                );
            }
        }

        // Insert open session if exists
        LocalDateTime openStart = info.getCurrentSessionStart();
        if (openStart != null) {
            jdbc.update(
                "INSERT INTO demand.hours_session (user_id, started_at, ended_at) VALUES (?,?,NULL)",
                userId,
                Timestamp.valueOf(openStart)
            );
        }
    }

    /**
     * Rebuild SessionInfo from DB rows.
     * - closed rows -> SessionPeriod(start,end)
     * - one open row (ended_at NULL) -> currentSessionStart
     */
    protected SessionInfo loadSessionInfo(String userId) {
        SessionInfo info = new SessionInfo();

        // Load all rows for the user
        jdbc.query(
            "SELECT started_at, ended_at " +
            "  FROM demand.hours_session " +
            " WHERE user_id = ? " +
            " ORDER BY started_at ASC",
            rs -> {
                LocalDateTime start = rs.getTimestamp("started_at").toLocalDateTime();
                Timestamp endedTs = rs.getTimestamp("ended_at");
                if (endedTs == null) {
                    // open session
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

    /* ===================== Public API (unchanged) ===================== */

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
        // Keep as-is for now
        return 0;
    }

    public int getTotalDrivingMinutesToday(String userId) {
        // Keep as-is for now
        return 0;
    }

    public boolean isActive(String userId) {
        return getSessionInfo(userId).hasOngoingSession();
    }

    public LocalDateTime getCurrentSessionStart(String userId) {
        return getSessionInfo(userId).getCurrentSessionStart();
    }
}
