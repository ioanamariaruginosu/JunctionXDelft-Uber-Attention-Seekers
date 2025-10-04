package com.attentionseekers.service;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/**
 * Utility that computes demand scores and categorical levels per zone.
 *
 * This class intentionally does not read CSVs or perform I/O. It receives
 * normalized signals (0..1 where applicable) as maps keyed by zone id
 * (for example 'A','B','C' or hex->zone mapped keys) and returns a map of
 * ZoneDemand results. Keeping it pure makes it easy to unit test and wire
 * into any DataLoader or controller in later steps.
 */
public class DemandCalculator {

    /**
     * Compute per-zone demand using the provided signals.
     *
     * All maps may be null or missing keys; missing numeric values are treated as 0.
     * Weather factors should be around 1.0 (no effect). Cancellation rates should be 0..1.
     *
     * @param rides normalized rides activity (0..1)
     * @param eats normalized eats activity (0..1)
     * @param surge normalized surge signal (0..1)
     * @param heat normalized heatmap/epH signal (0..1)
     * @param incentives normalized incentive score (0..1)
     * @param weatherFactor multiplier around 1.0 (e.g. 1.05 for rain boosting eats)
     * @param cancellation cancellation rates (0..1) that penalize rides
     * @return map zone -> ZoneDemand
     */
    public static Map<String, ZoneDemand> calculateDemand(
            Map<String, Double> rides,
            Map<String, Double> eats,
            Map<String, Double> surge,
            Map<String, Double> heat,
            Map<String, Double> incentives,
            Map<String, Double> weatherFactor,
            Map<String, Double> cancellation
    ) {
        Map<String, ZoneDemand> out = new HashMap<>();

        // collect all zone keys
        Set<String> zones = new HashSet<>();
        if (rides != null) zones.addAll(rides.keySet());
        if (eats != null) zones.addAll(eats.keySet());
        if (surge != null) zones.addAll(surge.keySet());
        if (heat != null) zones.addAll(heat.keySet());
        if (incentives != null) zones.addAll(incentives.keySet());
        if (weatherFactor != null) zones.addAll(weatherFactor.keySet());
        if (cancellation != null) zones.addAll(cancellation.keySet());

        for (String z : zones) {
            double r = safeGet(rides, z, 0.0);
            double e = safeGet(eats, z, 0.0);
            double s = safeGet(surge, z, 0.0);
            double h = safeGet(heat, z, 0.0);
            double i = safeGet(incentives, z, 0.0);
            double w = safeGet(weatherFactor, z, 1.0);
            double c = safeGet(cancellation, z, 0.0);

            // scoring weights (tweakable)
            // Increase primary weights so a normalized activity of 1.0 maps to a "high" score.
            double ridesScore = clamp(0.9 * r + 0.05 * s + 0.03 * h + 0.02 * (w - 1.0) - 0.05 * c + 0.0 * i);
            double eatsScore  = clamp(0.9 * e + 0.05 * s + 0.03 * h + 0.02 * (w - 1.0) + 0.0 * i);

            String ridesLevel = toLevel(ridesScore);
            String eatsLevel  = toLevel(eatsScore);

            String recommendation = "either";
            if (ridesScore - eatsScore > 0.15) recommendation = "rides";
            else if (eatsScore - ridesScore > 0.15) recommendation = "eats";
            else if (ridesScore < 0.33 && eatsScore < 0.33) recommendation = "stay";

            ZoneDemand zd = new ZoneDemand(round(ridesScore), ridesLevel, round(eatsScore), eatsLevel, recommendation);
            out.put(z, zd);
        }

        return out;
    }

    private static double safeGet(Map<String, Double> m, String key, double def) {
        if (m == null) return def;
        Double v = m.get(key);
        return v == null ? def : v;
    }

    private static double clamp(double v) {
        if (Double.isNaN(v)) return 0.0;
        if (v < 0.0) return 0.0;
        if (v > 1.0) return 1.0;
        return v;
    }

    private static double round(double v) {
        return Math.round(v * 100.0) / 100.0;
    }

    private static String toLevel(double score) {
        if (score < 0.33) return "low";
        if (score < 0.66) return "med";
        return "high";
    }

    /**
     * Simple DTO to hold demand results for a zone.
     */
    public static class ZoneDemand {
        private final double ridesScore;
        private final String ridesLevel;
        private final double eatsScore;
        private final String eatsLevel;
        private final String recommendation;

        public ZoneDemand(double ridesScore, String ridesLevel, double eatsScore, String eatsLevel, String recommendation) {
            this.ridesScore = ridesScore;
            this.ridesLevel = ridesLevel;
            this.eatsScore = eatsScore;
            this.eatsLevel = eatsLevel;
            this.recommendation = recommendation;
        }

        public double getRidesScore() { return ridesScore; }
        public String getRidesLevel() { return ridesLevel; }
        public double getEatsScore() { return eatsScore; }
        public String getEatsLevel() { return eatsLevel; }
        public String getRecommendation() { return recommendation; }
    }
}