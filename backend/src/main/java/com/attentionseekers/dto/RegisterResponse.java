package com.attentionseekers.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class RegisterResponse {
    private String id;
    private String fullName;
    private String email;
    private String phoneNumber;
    private String vehicleType;
    private String licenseNumber;
    private Double rating;
    private Integer totalTrips;
    private Double totalEarnings;
    private String joinedDate;
}