package com.attentionseekers.dto;

import lombok.Data;
import java.util.List;
import java.util.Map;

@Data
public class FeatureCollection {
    private String type;
    private List<Feature> features;

    @Data
    public static class Feature {
        private String type;
        private Map<String, Object> properties;
        private Geometry geometry;
        private String id;
    }

    @Data
    public static class Geometry {
        private String type;
        private List<Double> coordinates;
    }
}
