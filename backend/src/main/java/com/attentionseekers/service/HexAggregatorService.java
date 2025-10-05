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
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.EnumMap;

@Component
public class HexAggregatorService {

    private static final DateTimeFormatter DATE_TIME = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private final ResourceLoader resourceLoader;

    public HexAggregatorService(ResourceLoader resourceLoader) {
        this.resourceLoader = resourceLoader;
    }

    public Map<String, Double> zoneRidesSignal(DemandBucket bucket, Integer cityId, DemandDataLoader loader) {
        try {
            EnumMap<DemandBucket, Map<String, Integer>> counts = loadHexCounts("classpath:data/rides_trips.csv", bucket, cityId);
            return aggregateHexCountsToZones(counts, loader);
        } catch (Exception e) {
            return loader.ridesFor(bucket);
        }
    }

    public Map<String, Double> zoneEatsSignal(DemandBucket bucket, Integer cityId, DemandDataLoader loader) {
        try {
            EnumMap<DemandBucket, Map<String, Integer>> counts = loadHexCounts("classpath:data/eats_orders.csv", bucket, cityId);
            return aggregateHexCountsToZones(counts, loader);
        } catch (Exception e) {
            return loader.eatsFor(bucket);
        }
    }

    private EnumMap<DemandBucket, Map<String, Integer>> loadHexCounts(String resourcePath, DemandBucket wantedBucket, Integer cityFilter) {
        Resource resource = resourceLoader.getResource(resourcePath);
        EnumMap<DemandBucket, Map<String, Integer>> counts = new EnumMap<>(DemandBucket.class);
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8))) {
            String header = reader.readLine();
            if (header == null) throw new IllegalStateException("Empty CSV: " + resourcePath);
            int cityIdIdx = findHeaderIndex(header, "city_id", 3);
            int startTimeIdx = findHeaderIndex(header, "start_time", 7);
            int pickupHexIdx = findHeaderIndex(header, "pickup_hex_id9", -1);

            String line;
            while ((line = reader.readLine()) != null) {
                if (line.isBlank()) continue;
                String[] fields = line.split(",", -1);
                try {
                    String start = safeGet(fields, startTimeIdx);
                    LocalDateTime dt = LocalDateTime.parse(start, DATE_TIME);
                    DemandBucket bucket = DemandBucket.from(dt.toLocalTime());
                    if (bucket != wantedBucket) continue;

                    if (cityFilter != null && cityFilter > 0) {
                        String cityRaw = safeGet(fields, cityIdIdx);
                        int cityId = Integer.parseInt(cityRaw);
                        if (cityId != cityFilter) continue;
                    }

                    String hex = pickupHexIdx >= 0 ? safeGet(fields, pickupHexIdx) : "";
                    if (hex == null || hex.isBlank()) continue;
                    Map<String, Integer> map = counts.computeIfAbsent(bucket, b -> new HashMap<>());
                    map.merge(hex, 1, Integer::sum);
                } catch (Exception ignored) {
                }
            }
        } catch (IOException e) {
            throw new IllegalStateException("Failed to load " + resourcePath, e);
        }
        return counts;
    }

    private Map<String, Double> aggregateHexCountsToZones(EnumMap<DemandBucket, Map<String, Integer>> hexCounts, DemandDataLoader loader) {
        Map<String, Integer> counts = hexCounts.values().stream().findFirst().orElse(new HashMap<>());
        int max = counts.values().stream().mapToInt(Integer::intValue).max().orElse(0);
        Map<String, Double> hexNorm = new LinkedHashMap<>();
        Map<String, Integer> hexActivity = new LinkedHashMap<>();
        for (Map.Entry<String, Integer> e : counts.entrySet()) {
            hexActivity.put(e.getKey(), e.getValue());
            double norm = max == 0 ? 0.0 : ((double) e.getValue()) / max;
            hexNorm.put(e.getKey(), Math.round(norm * 100.0) / 100.0);
        }

        Map<String, Double> zoneSum = new LinkedHashMap<>();
        Map<String, Integer> zoneWeight = new LinkedHashMap<>();
        for (Map.Entry<String, Double> he : hexNorm.entrySet()) {
            String hex = he.getKey();
            double norm = he.getValue();
            String zone = loader.zoneForHex(hex);
            if (zone == null) continue;
            int weight = hexActivity.getOrDefault(hex, 1);
            zoneSum.put(zone, zoneSum.getOrDefault(zone, 0.0) + norm * weight);
            zoneWeight.put(zone, zoneWeight.getOrDefault(zone, 0) + weight);
        }

        Map<String, Double> zoneSignal = new LinkedHashMap<>();
        for (String zone : loader.zones()) {
            double sum = zoneSum.getOrDefault(zone, 0.0);
            int w = zoneWeight.getOrDefault(zone, 0);
            double v = w == 0 ? 0.0 : Math.round((sum / w) * 100.0) / 100.0;
            zoneSignal.put(zone, v);
        }
        return zoneSignal;
    }

    private String safeGet(String[] fields, int idx) {
        if (idx < 0 || idx >= fields.length) return "";
        return fields[idx];
    }

    private int findHeaderIndex(String headerLine, String name, int fallback) {
        if (headerLine == null) return fallback;
        String[] cols = headerLine.split(",", -1);
        for (int i = 0; i < cols.length; i++) {
            if (cols[i].trim().equalsIgnoreCase(name)) return i;
        }
        return fallback;
    }
}
