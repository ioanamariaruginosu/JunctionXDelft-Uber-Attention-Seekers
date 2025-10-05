package com.attentionseekers.service;

import org.junit.jupiter.api.Test;
import org.springframework.core.io.DefaultResourceLoader;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;

public class DemandDataLoaderTest {

    @Test
    public void pickupHexMappingAndNormalization() {
        DefaultResourceLoader loader = new DefaultResourceLoader();
        DemandDataLoader dl = new DemandDataLoader(loader);

        // pick MORNING bucket (6-12). The test data in src/test/resources/data_small.csv will be used
        Map<String, Double> ridesMorning = dl.ridesFor(DemandBucket.MORNING);

        // There should be non-empty zones A/B/C keys
        assertEquals(3, ridesMorning.size());

        // Values are normalized (max -> 1.0). Check at least one value is 1.0
        boolean hasOne = ridesMorning.values().stream().anyMatch(v -> v == 1.0);
        assertEquals(true, hasOne);
    }
}
