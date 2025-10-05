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
    private final ResourceLoader resourceLoader;

    public DemandDataLoader(ResourceLoader resourceLoader) {
        this.resourceLoader = resourceLoader;
        this.ridesSignals = loadSignals(resourceLoader, "classpath:data/rides_trips.csv");
        this.eatsSignals = loadSignals(resourceLoader, "classpath:data/eats_orders.csv");
    }

    // Public helpers to load per-city normalized signals on-demand (quick-and-dirty for demo)
    public Map<String, Double> ridesFor(DemandBucket bucket, int cityId) {
        EnumMap<DemandBucket, Map<String, Integer>> counts = loadSignalsForCity(resourceLoader, "classpath:data/rides_trips.csv", cityId);
        ensureBuckets(counts);
        EnumMap<DemandBucket, Map<String, Double>> normalized = normalize(counts);
        return normalized.getOrDefault(bucket, emptySignal());
    }

    public Map<String, Double> eatsFor(DemandBucket bucket, int cityId) {
        EnumMap<DemandBucket, Map<String, Integer>> counts = loadSignalsForCity(resourceLoader, "classpath:data/eats_orders.csv", cityId);
        ensureBuckets(counts);
        EnumMap<DemandBucket, Map<String, Double>> normalized = normalize(counts);
        return normalized.getOrDefault(bucket, emptySignal());
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

    public ResourceLoader getResourceLoader() {
        return this.resourceLoader;
    }

    // Return distinct city ids present in the rides CSV (quick scan)
    public java.util.List<Integer> getAvailableCityIds() {
        java.util.Set<Integer> cities = new java.util.TreeSet<>();
        Resource resource = resourceLoader.getResource("classpath:data/rides_trips.csv");
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8))) {
            String header = reader.readLine();
            String line;
            while ((line = reader.readLine()) != null) {
                if (line.isBlank()) continue;
                String[] fields = line.split("", -1);
                if (fields.length <= 3) continue;
                try {
                    int cityId = Integer.parseInt(fields[3]);
                    if (cityId > 0) cities.add(cityId);
                } catch (Exception ignored) {}
            }
        } catch (IOException e) {
            // ignore and return empty
        }
        return new java.util.ArrayList<>(cities);
    }

    /**
     * Return a normalized rides signal (0..1) for the given city & bucket.
     * Normalization is done per-city across the three buckets so values don't overlap
     * between different city ids (each city is scaled independently).
     */
    public double ridesSignalForCity(DemandBucket bucket, int cityId) {
        EnumMap<DemandBucket, Map<String, Integer>> counts = loadSignalsForCity(resourceLoader, "classpath:data/rides_trips.csv", cityId);
        ensureBuckets(counts);
        int value = totalForBucket(counts, bucket);
        int max = counts.values().stream().mapToInt(m -> m.values().stream().mapToInt(Integer::intValue).sum()).max().orElse(0);
        return max == 0 ? 0.0 : round(((double) value) / max);
    }

    /**
     * Return a normalized eats signal (0..1) for the given city & bucket.
     * Normalized per-city across buckets.
     */
    public double eatsSignalForCity(DemandBucket bucket, int cityId) {
        EnumMap<DemandBucket, Map<String, Integer>> counts = loadSignalsForCity(resourceLoader, "classpath:data/eats_orders.csv", cityId);
        ensureBuckets(counts);
        int value = totalForBucket(counts, bucket);
        int max = counts.values().stream().mapToInt(m -> m.values().stream().mapToInt(Integer::intValue).sum()).max().orElse(0);
        return max == 0 ? 0.0 : round(((double) value) / max);
    }

    private int totalForBucket(EnumMap<DemandBucket, Map<String, Integer>> counts, DemandBucket bucket) {
        Map<String, Integer> map = counts.get(bucket);
        if (map == null) return 0;
        return map.values().stream().mapToInt(Integer::intValue).sum();
    }

    // Count events for a given city at a specific hour and weekday (1=Monday..7=Sunday)
    private int countEventsForCityAt(ResourceLoader loader, String location, int wantedCityId, int hour, int dayOfWeek) {
        Resource resource = loader.getResource(location);
        int count = 0;
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8))) {
            String header = reader.readLine();
            if (header == null) return 0;
            String line;
            while ((line = reader.readLine()) != null) {
                if (line.isBlank()) continue;
                String[] fields = line.split(",", -1);
                if (fields.length <= 7) continue;
                try {
                    int cityIdIdx = findHeaderIndex(header, "city_id", 3);
                    int startTimeIdx = findHeaderIndex(header, "start_time", 7);
                    String cityRaw = safeGet(fields, cityIdIdx);
                    int cityId = Integer.parseInt(cityRaw);
                    if (cityId != wantedCityId) continue;
                    String startTimeRaw = safeGet(fields, startTimeIdx);
                    LocalDateTime startTime = LocalDateTime.parse(startTimeRaw, DATE_TIME);
                    if (startTime.getHour() == hour && startTime.getDayOfWeek().getValue() == dayOfWeek) {
                        count++;
                    }
                } catch (Exception ignored) {}
            }
        } catch (IOException e) {
            // ignore
        }
        return count;
    }

    // For a given city and weekday, return the maximum events observed across all hours (0-23)
    private int maxEventsForCityWeekday(ResourceLoader loader, String location, int wantedCityId, int dayOfWeek) {
        int max = 0;
        for (int h = 0; h < 24; h++) {
            int c = countEventsForCityAt(loader, location, wantedCityId, h, dayOfWeek);
            if (c > max) max = c;
        }
        return max;
    }

    public double ridesSignalForCityAt(java.time.LocalDateTime dt, int cityId) {
        int hour = dt.getHour();
        int dow = dt.getDayOfWeek().getValue();
        int count = countEventsForCityAt(resourceLoader, "classpath:data/rides_trips.csv", cityId, hour, dow);
        int max = maxEventsForCityWeekday(resourceLoader, "classpath:data/rides_trips.csv", cityId, dow);
        return max == 0 ? 0.0 : round(((double) count) / max);
    }

    public double eatsSignalForCityAt(java.time.LocalDateTime dt, int cityId) {
        int hour = dt.getHour();
        int dow = dt.getDayOfWeek().getValue();
        int count = countEventsForCityAt(resourceLoader, "classpath:data/eats_orders.csv", cityId, hour, dow);
        int max = maxEventsForCityWeekday(resourceLoader, "classpath:data/eats_orders.csv", cityId, dow);
        return max == 0 ? 0.0 : round(((double) count) / max);
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
                        // determine column indices robustly using header names
                        int cityIdIdx = findHeaderIndex(header, "city_id", 3);
                        int startTimeIdx = findHeaderIndex(header, "start_time", 7);
                        int pickupHexIdx = findHeaderIndex(header, "pickup_hex_id9", -1);

                        String startTimeRaw = safeGet(fields, startTimeIdx);
                        LocalDateTime startTime = LocalDateTime.parse(startTimeRaw, DATE_TIME);
                        DemandBucket bucket = DemandBucket.from(startTime.toLocalTime());

                        String zone = null;
                        // Prefer pickup_hex_id9 when available; otherwise fall back to cityId
                        if (pickupHexIdx >= 0) {
                            String hex = safeGet(fields, pickupHexIdx);
                            zone = toZone(hex);
                        }
                        if (zone == null) {
                            String cityRaw = safeGet(fields, cityIdIdx);
                            int cityId = Integer.parseInt(cityRaw);
                            zone = toZone(cityId);
                        }

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

    private EnumMap<DemandBucket, Map<String, Integer>> loadSignalsForCity(ResourceLoader loader, String location, int wantedCityId) {
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
                    int cityIdIdx = findHeaderIndex(header, "city_id", 3);
                    int startTimeIdx = findHeaderIndex(header, "start_time", 7);
                    int pickupHexIdx = findHeaderIndex(header, "pickup_hex_id9", -1);

                    String startTimeRaw = safeGet(fields, startTimeIdx);
                    LocalDateTime startTime = LocalDateTime.parse(startTimeRaw, DATE_TIME);
                    DemandBucket bucket = DemandBucket.from(startTime.toLocalTime());

                    String cityRaw = safeGet(fields, cityIdIdx);
                    int cityId = Integer.parseInt(cityRaw);
                    if (cityId != wantedCityId) continue;

                    String zone = null;
                    if (pickupHexIdx >= 0) {
                        String hex = safeGet(fields, pickupHexIdx);
                        zone = toZone(hex);
                    }
                    if (zone == null) {
                        zone = toZone(cityId);
                    }
                    if (zone == null) continue;

                    Map<String, Integer> zoneCounts = counts.computeIfAbsent(bucket, b -> new HashMap<>());
                    zoneCounts.merge(zone, 1, Integer::sum);
                } catch (Exception ignored) {
                    // skip malformed rows
                }
            }
        } catch (IOException e) {
            throw new IllegalStateException("Failed to load " + location, e);
        }

        return counts;
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

    // new: map pickup_hex_id9 to zone deterministically
    // simple rule: look at last hex digit/char and map by its numeric value
    private String toZone(String hex) {
        if (hex == null || hex.isBlank()) return null;
        // strip possible quotes/spaces
        String h = hex.trim();
        char last = h.charAt(h.length() - 1);
        int bucket = 0;
        if (Character.isDigit(last)) {
            bucket = Character.getNumericValue(last) % ZONES.size();
        } else if ((last >= 'a' && last <= 'f') || (last >= 'A' && last <= 'F')) {
            // map hex letter to 10..15
            int v = Integer.parseInt(String.valueOf(last), 16);
            bucket = v % ZONES.size();
        } else {
            bucket = (last % ZONES.size());
        }
        return ZONES.get(bucket);
    }

    // Public accessor used by aggregator
    public String zoneForHex(String hex) {
        return toZone(hex);
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
