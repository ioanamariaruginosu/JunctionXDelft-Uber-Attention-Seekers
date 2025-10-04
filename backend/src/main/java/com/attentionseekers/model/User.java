package com.attentionseekers.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class User {
    private String id;
    private String fullName;
    private String email;
    private String phoneNumber;
    private String password;
    private String vehicleType;
    private String licenseNumber;
    private Double rating;
    private Integer totalTrips;
    private Double totalEarnings;
    private LocalDateTime joinedDate;
}