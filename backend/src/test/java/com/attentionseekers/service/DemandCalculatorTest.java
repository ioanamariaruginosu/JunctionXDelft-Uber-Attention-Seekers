package com.attentionseekers.service;

import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

public class DemandCalculatorTest {

    @Test
    public void testHighRidesLowEats() {
        Map<String, Double> rides = Map.of("A", 1.0);
        Map<String, Double> eats  = Map.of("A", 0.0);
        Map<String, Double> surge = Map.of("A", 0.0);
        Map<String, Double> heat  = Map.of("A", 0.0);
        Map<String, Double> inc   = Map.of("A", 0.0);
        Map<String, Double> w     = Map.of("A", 1.0);
        Map<String, Double> c     = Map.of("A", 0.0);

        Map<String, DemandCalculator.ZoneDemand> out = DemandCalculator.calculateDemand(rides, eats, surge, heat, inc, w, c);
        assertTrue(out.containsKey("A"));
        DemandCalculator.ZoneDemand zd = out.get("A");
        assertEquals("high", zd.getRidesLevel());
        assertEquals("low", zd.getEatsLevel());
        assertEquals("rides", zd.getRecommendation());
    }

    @Test
    public void testHighEatsLowRides() {
        Map<String, Double> rides = Map.of("B", 0.0);
        Map<String, Double> eats  = Map.of("B", 1.0);
        Map<String, Double> surge = Map.of("B", 0.0);
        Map<String, Double> heat  = Map.of("B", 0.0);
        Map<String, Double> inc   = Map.of("B", 0.0);
        Map<String, Double> w     = Map.of("B", 1.0);
        Map<String, Double> c     = Map.of("B", 0.0);

        Map<String, DemandCalculator.ZoneDemand> out = DemandCalculator.calculateDemand(rides, eats, surge, heat, inc, w, c);
        assertTrue(out.containsKey("B"));
        DemandCalculator.ZoneDemand zd = out.get("B");
        assertEquals("low", zd.getRidesLevel());
        assertEquals("high", zd.getEatsLevel());
        assertEquals("eats", zd.getRecommendation());
    }

    @Test
    public void testMissingValuesHandled() {
        // All maps null should not throw and produce empty map
        Map<String, DemandCalculator.ZoneDemand> out = DemandCalculator.calculateDemand(null, null, null, null, null, null, null);
        assertNotNull(out);
        assertTrue(out.isEmpty());
    }
}
