package com.attentionseekers.model;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class SessionInfo {
    private final List<SessionPeriod> sessions = new ArrayList<>();
    private LocalDateTime currentSessionStart;

    // Accessors used by the service
    public List<SessionPeriod> getSessions() { return Collections.unmodifiableList(sessions); }
    public void addSession(SessionPeriod p) { sessions.add(p); }

    public LocalDateTime getCurrentSessionStart() { return currentSessionStart; }
    public void setCurrentSessionStart(LocalDateTime start) { this.currentSessionStart = start; }
    public void clearCurrentSessionStart() { this.currentSessionStart = null; }
    public boolean hasOngoingSession() { return currentSessionStart != null; }
}
