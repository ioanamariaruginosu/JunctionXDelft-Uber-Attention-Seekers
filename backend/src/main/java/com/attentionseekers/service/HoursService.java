package com.attentionseekers.service;

import com.attentionseekers.model.SessionInfo;
import com.attentionseekers.model.SessionPeriod;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;

import java.io.File;
import java.io.IOException;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class HoursService {

    private final Map<String, SessionInfo> userSessions = new ConcurrentHashMap<>();
    private static final String SESSION_DIR = "sessions";

    private final ObjectMapper objectMapper;
    private final SessionService sessionService;

    public HoursService(SessionService sessionService, ObjectMapper objectMapper) {
        this.sessionService = sessionService != null ? sessionService : new SessionService();
        this.objectMapper = (objectMapper != null ? objectMapper.copy() : new ObjectMapper())
                .registerModule(new JavaTimeModule())
                .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
    }

    private void saveSessionInfo(String userId, SessionInfo info) {
        File dir = new File(SESSION_DIR);
        if (!dir.exists()) dir.mkdirs();

        File file = new File(dir, userId + ".json");
        try {
            objectMapper.writeValue(file, SessionSnapshot.from(info));
        } catch (IOException e) {
            // TODO: log error
        }
    }

    private SessionInfo loadSessionInfo(String userId) {
        File file = new File(SESSION_DIR, userId + ".json");
        if (file.exists()) {
            try {
                SessionSnapshot snap = objectMapper.readValue(file, SessionSnapshot.class);
                return snap.toModel();
            } catch (IOException e) {
                // TODO: log error
            }
        }
        return new SessionInfo();
    }

    private SessionInfo getSessionInfo(String userId) {
        return userSessions.computeIfAbsent(userId, this::loadSessionInfo);
    }

    /* ===================== Public API ===================== */

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

    private static class SessionSnapshot {
        public java.util.List<SessionPeriod> sessions = new java.util.ArrayList<>();
        public LocalDateTime currentSessionStart;

        static SessionSnapshot from(SessionInfo info) {
            SessionSnapshot s = new SessionSnapshot();
            s.sessions.addAll(info.getSessions());
            s.currentSessionStart = info.getCurrentSessionStart();
            return s;
        }

        SessionInfo toModel() {
            SessionInfo m = new SessionInfo();
            if (currentSessionStart != null) {
                m.setCurrentSessionStart(currentSessionStart);
            }
            for (SessionPeriod p : sessions) {
                m.addSession(p);
            }
            return m;
        }
    }
}
