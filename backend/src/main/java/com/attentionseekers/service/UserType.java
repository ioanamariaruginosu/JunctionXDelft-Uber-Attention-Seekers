package com.attentionseekers.service;

import com.fasterxml.jackson.annotation.JsonValue;

public enum UserType {
    RIDER("rider"),
    FOOD("food");

    private final String code;

    UserType(String code) {
        this.code = code;
    }

    @JsonValue
    public String getCode() {
        return code;
    }

    public static UserType from(String value) {
        if (value == null || value.isBlank()) {
            return RIDER;
        }
        String normalized = value.trim().toLowerCase();
        for (UserType type : values()) {
            if (type.code.equals(normalized)) {
                return type;
            }
        }
        throw new IllegalArgumentException("Unsupported userType: " + value);
    }
}
