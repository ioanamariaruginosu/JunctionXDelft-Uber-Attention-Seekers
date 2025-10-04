package com.attentionseekers.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class RestLocation {
    private String id;
    private String amenity;
    private String name;
    private Double latitude;
    private Double longitude;
}
