package com.attentionseekers.service;

import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Collections;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class DemandDataLoader {

    private static final DateTimeFormatter DATE_TIME = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final List<String> ZONES = List.of("A", "B", "C");

    private final EnumMap<DemandBucket, Map<String, Double>> ridesSignals;
    private final EnumMap<DemandBucket, Map<String, Double>> eatsSignals;

    public DemandDataLoader(ResourceLoader resourceLoader) {
        this.ridesSignals = loadSignals(resourceLoader, "classpath:data/rides_trips.csv");
        this.eatsSignals = loadSignals(resourceLoader, "classpath:data/eats_orders.csv");
    }

    public Map<String, Double> ridesFor(DemandBucket bucket) {
        return ridesSignals.getOrDefault(bucket, emptySignal());
    }

    public Map<String, Double> eatsFor(DemandBucket bucket) {
        return eatsSignals.getOrDefault(bucket, emptySignal());
    }

    public List<String> zones() {
        return ZONES;
    }

    private EnumMap<DemandBucket, Map<String, Double>> loadSignals(ResourceLoader loader, String location) {
        Resource resource = loader.getResource(location);
        EnumMap<DemandBucket, Map<String, Integer>> counts = new EnumMap<>(DemandBucket.class);
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8))) {
            String header = reader.readLine();
            if (header == null) {
                throw new IllegalStateException("CSV " + location + " is empty");
            }
            String line;
            while ((line = reader.readLine()) != null) {
                if (line.isBlank()) {
                    continue;
                }
                String[] fields = line.split(",", -1);
                if (fields.length <= 7) {
                    continue;
                }
                try {
                    int cityId = Integer.parseInt(fields[3]);
                    LocalDateTime startTime = LocalDateTime.parse(fields[7], DATE_TIME);
                    DemandBucket bucket = DemandBucket.from(startTime.toLocalTime());
                    String zone = toZone(cityId);
                    if (zone == null) {
                        continue;
                    }
                    Map<String, Integer> zoneCounts = counts.computeIfAbsent(bucket, b -> new HashMap<>());
                    zoneCounts.merge(zone, 1, Integer::sum);
                } catch (Exception ignored) {
                    // skip malformed rows
                }
            }
        } catch (IOException e) {
            throw new IllegalStateException("Failed to load " + location, e);
        }

        ensureBuckets(counts);
        return normalize(counts);
    }

    private void ensureBuckets(EnumMap<DemandBucket, Map<String, Integer>> counts) {
        for (DemandBucket bucket : DemandBucket.values()) {
            Map<String, Integer> zoneCounts = counts.computeIfAbsent(bucket, b -> new HashMap<>());
            for (String zone : ZONES) {
                zoneCounts.putIfAbsent(zone, 0);
            }
        }
    }

    private EnumMap<DemandBucket, Map<String, Double>> normalize(EnumMap<DemandBucket, Map<String, Integer>> counts) {
        EnumMap<DemandBucket, Map<String, Double>> normalized = new EnumMap<>(DemandBucket.class);
        for (DemandBucket bucket : DemandBucket.values()) {
            Map<String, Integer> zoneCounts = counts.get(bucket);
            double max = zoneCounts.values().stream().mapToInt(Integer::intValue).max().orElse(0);
            Map<String, Double> zoneSignals = new LinkedHashMap<>();
            for (String zone : ZONES) {
                int value = zoneCounts.getOrDefault(zone, 0);
                double signal = max == 0 ? 0.0 : round(((double) value) / max);
                zoneSignals.put(zone, signal);
            }
            normalized.put(bucket, Collections.unmodifiableMap(zoneSignals));
        }
        return normalized;
    }

    private Map<String, Double> emptySignal() {
        Map<String, Double> signal = new LinkedHashMap<>();
        for (String zone : ZONES) {
            signal.put(zone, 0.0);
        }
        return signal;
    }

    private double round(double value) {
        return Math.round(value * 100.0) / 100.0;
    }

    private String toZone(int cityId) {
        if (cityId <= 0) {
            return null;
        }
        int index = (cityId - 1) % ZONES.size();
        return ZONES.get(index);
    }
}
