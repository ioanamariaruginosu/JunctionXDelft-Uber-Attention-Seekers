package com.attentionseekers.service;

import com.attentionseekers.model.SessionInfo;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.File;
import java.io.IOException;

@Service
public class HoursService {

    private java.util.Map<String, SessionInfo> userSessions = new java.util.HashMap<>();

    private static final String SESSION_DIR = "sessions";
    private ObjectMapper objectMapper = new ObjectMapper();

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

    private void saveSessionInfo(String userId) {
        File dir = new File(SESSION_DIR);
        if (!dir.exists()) dir.mkdirs();
        File file = new File(dir, userId + ".json");
        try {
            objectMapper.writeValue(file, getSessionInfo(userId));
        } catch (IOException e) {
            // Handle error (log, etc.)
        }
    }

    private SessionInfo loadSessionInfo(String userId) {
        File file = new File(SESSION_DIR, userId + ".json");
        if (file.exists()) {
            try {
                return objectMapper.readValue(file, SessionInfo.class);
            } catch (IOException e) {
                // Handle error (log, etc.)
            }
        }
        return new SessionInfo();
    }

    private SessionInfo getSessionInfo(String userId) {
        if (!userSessions.containsKey(userId)) {
            userSessions.put(userId, loadSessionInfo(userId));
        }
        return userSessions.get(userId);
    }

    public void startSession(String userId) {
        getSessionInfo(userId).startSession();
    }

    public void stopSession(String userId) {
        getSessionInfo(userId).stopSession();
    }

    public int getContinuousMinutes(String userId) {
        return getSessionInfo(userId).getContinuousMinutes();
    }

    public int getTotalMinutesToday(String userId) {
        return getSessionInfo(userId).getTotalMinutesToday();
    }

    public int getDrivingMinutes(String userId) {
        // Implement driving minutes logic per user if needed
        return 0;
    }

    public int getTotalDrivingMinutesToday(String userId) {
        // Implement total driving minutes today logic per user if needed
        return 0;
    }
}