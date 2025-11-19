package com.attentionseekers.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Component
public class HistoricalTripDataLoader {

    private static final DateTimeFormatter DATE_TIME = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final List<TripRecord> allTrips;
    private final Map<CityHourKey, Double> surgeByHour;
    private final Map<CityHourKey, List<TripRecord>> tripsByZoneTime;

    @Autowired
    public HistoricalTripDataLoader(ResourceLoader resourceLoader) {
        this.allTrips = loadTrips(resourceLoader, "classpath:data/rides_trips.csv");
        this.surgeByHour = loadSurgeData(resourceLoader, "classpath:data/surge_by_hour.csv");
        this.tripsByZoneTime = indexTripsByZoneTime();
    }

    public List<TripRecord> getTripsForCityAndHour(int cityId, int hour) {
        return tripsByZoneTime.getOrDefault(new CityHourKey(cityId, hour), Collections.emptyList());
    }

    public double getSurgeForCityAndHour(int cityId, int hour) {
        return surgeByHour.getOrDefault(new CityHourKey(cityId, hour), 1.0);
    }

    public List<TripRecord> getAllTrips() {
        return allTrips;
    }

    public List<TripRecord> getTripsForHour(int hour) {
        return allTrips.stream()
                .filter(trip -> trip.startTime.getHour() == hour)
                .toList();
    }

    public double getAverageSurgeForHour(int hour) {
        return surgeByHour.entrySet().stream()
                .filter(entry -> entry.getKey().hour == hour)
                .mapToDouble(Map.Entry::getValue)
                .average()
                .orElse(1.0);
    }

    private List<TripRecord> loadTrips(ResourceLoader loader, String location) {
        List<TripRecord> trips = new ArrayList<>();
        Resource resource = loader.getResource(location);

        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8))) {

            String header = reader.readLine();
            if (header == null) {
                throw new IllegalStateException("CSV " + location + " is empty");
            }

            String line;
            while ((line = reader.readLine()) != null) {
                if (line.isBlank()) continue;

                try {
                    TripRecord trip = parseTripRecord(line);
                    if (trip != null) {
                        trips.add(trip);
                    }
                } catch (Exception e) {
                }
            }
        } catch (IOException e) {
            throw new IllegalStateException("Failed to load " + location, e);
        }

        return trips;
    }

    private TripRecord parseTripRecord(String line) {
        String[] fields = line.split(",", -1);
        if (fields.length < 24) return null;

        try {
            TripRecord trip = new TripRecord();
            trip.rideId = fields[0];
            trip.driverId = fields[1];
            trip.riderId = fields[2];
            trip.cityId = Integer.parseInt(fields[3]);
            trip.product = fields[4];
            trip.vehicleType = fields[5];
            trip.isEv = Boolean.parseBoolean(fields[6]);

            trip.startTime = LocalDateTime.parse(fields[7], DATE_TIME);
            trip.endTime = LocalDateTime.parse(fields[8], DATE_TIME);

            trip.pickupLat = parseDouble(fields[9]);
            trip.pickupLon = parseDouble(fields[10]);
            trip.pickupHexId = fields[11];
            trip.dropLat = parseDouble(fields[12]);
            trip.dropLon = parseDouble(fields[13]);
            trip.dropHexId = fields[14];

            trip.distanceKm = parseDouble(fields[15]);
            trip.durationMins = Integer.parseInt(fields[16]);
            trip.surgeMultiplier = parseDouble(fields[17]);
            trip.fareAmount = parseDouble(fields[18]);
            trip.uberFee = parseDouble(fields[19]);
            trip.netEarnings = parseDouble(fields[20]);
            trip.tips = parseDouble(fields[21]);
            trip.paymentType = fields[22];

            return trip;
        } catch (Exception e) {
            return null;
        }
    }

    private Map<CityHourKey, Double> loadSurgeData(ResourceLoader loader, String location) {
        Map<CityHourKey, Double> surgeMap = new HashMap<>();
        Resource resource = loader.getResource(location);

        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8))) {

            String header = reader.readLine();
            if (header == null) {
                throw new IllegalStateException("CSV " + location + " is empty");
            }

            String line;
            while ((line = reader.readLine()) != null) {
                if (line.isBlank()) continue;

                try {
                    String[] fields = line.split(",", -1);
                    if (fields.length >= 3) {
                        int cityId = Integer.parseInt(fields[0].trim());
                        int hour = Integer.parseInt(fields[1].trim());
                        double surge = parseDouble(fields[2].trim());

                        surgeMap.put(new CityHourKey(cityId, hour), surge);
                    }
                } catch (Exception e) {
                }
            }
        } catch (IOException e) {
            throw new IllegalStateException("Failed to load " + location, e);
        }

        return surgeMap;
    }

    private Map<CityHourKey, List<TripRecord>> indexTripsByZoneTime() {
        Map<CityHourKey, List<TripRecord>> index = new HashMap<>();

        for (TripRecord trip : allTrips) {
            int hour = trip.startTime.getHour();
            CityHourKey key = new CityHourKey(trip.cityId, hour);

            index.computeIfAbsent(key, k -> new ArrayList<>()).add(trip);
        }

        return index;
    }

    private double parseDouble(String value) {
        if (value == null || value.isBlank()) return 0.0;
        try {
            return Double.parseDouble(value.trim());
        } catch (NumberFormatException e) {
            return 0.0;
        }
    }
    
    public static class TripRecord {
        public String rideId;
        public String driverId;
        public String riderId;
        public int cityId;
        public String product;
        public String vehicleType;
        public boolean isEv;
        public LocalDateTime startTime;
        public LocalDateTime endTime;
        public double pickupLat;
        public double pickupLon;
        public String pickupHexId;
        public double dropLat;
        public double dropLon;
        public String dropHexId;
        public double distanceKm;
        public int durationMins;
        public double surgeMultiplier;
        public double fareAmount;
        public double uberFee;
        public double netEarnings;
        public double tips;
        public String paymentType;
    }

    private static class CityHourKey {
        private final int cityId;
        private final int hour;

        public CityHourKey(int cityId, int hour) {
            this.cityId = cityId;
            this.hour = hour;
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            CityHourKey that = (CityHourKey) o;
            return cityId == that.cityId && hour == that.hour;
        }

        @Override
        public int hashCode() {
            return Objects.hash(cityId, hour);
        }
    }
}
