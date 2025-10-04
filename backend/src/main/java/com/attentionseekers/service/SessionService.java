package com.attentionseekers.service;

import com.attentionseekers.model.SessionInfo;

/** Business operations on SessionInfo. */
public interface SessionService {
    /** Starts a session if none is active. @return true if started, false if already running. */
    boolean startSession(SessionInfo info);

    /** Stops the active session and stores it. @return true if stopped, false if none running. */
    boolean stopSession(SessionInfo info);

    /** Minutes since current session start; 0 if none running. */
    int getContinuousMinutes(SessionInfo info);

    /** Sum of minutes for sessions that started today + ongoing (if started today). */
    int getTotalMinutesToday(SessionInfo info);
}
