package com.attentionseekers.service;

import com.attentionseekers.dto.DemandResponse;
import com.attentionseekers.dto.DriverDemandDto;

import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class DemandService {

    private final DemandDataLoader dataLoader;
    private final HexAggregatorService hexAggregator;
    private final ZoneId zoneId;

    @Autowired
    public DemandService(DemandDataLoader dataLoader, HexAggregatorService hexAggregator) {
        this(dataLoader, hexAggregator, ZoneId.systemDefault());
    }

    // Compatibility constructor used by tests that pass (DemandDataLoader, ZoneId)
    public DemandService(DemandDataLoader dataLoader, ZoneId zoneId) {
        this(dataLoader, new HexAggregatorService(dataLoader.getResourceLoader()), zoneId);
    }

    public java.util.List<Integer> availableCityIds() {
        return dataLoader.getAvailableCityIds();
    }

    DemandService(DemandDataLoader dataLoader, HexAggregatorService hexAggregator, ZoneId zoneId) {
        this.dataLoader = dataLoader;
        this.hexAggregator = hexAggregator;
        this.zoneId = zoneId;
    }

    public DemandResponse getCurrentDemand(UserType userType) {
        ZonedDateTime now = ZonedDateTime.now(zoneId);
        DemandBucket bucket = DemandBucket.from(now.toLocalTime());
        return buildResponse(bucket, "now", userType, -1);
    }

    public DemandResponse getCurrentDemand() {
        return getCurrentDemand(UserType.RIDER);
    }

    public DemandResponse getNext2HoursDemand(UserType userType) {
        ZonedDateTime future = ZonedDateTime.now(zoneId).plusHours(2);
        DemandBucket bucket = DemandBucket.from(future.toLocalTime());
        return buildResponse(bucket, "next2h", userType, -1);
    }

    public DemandResponse getNext2HoursDemand() {
        return getNext2HoursDemand(UserType.RIDER);
    }

    public DemandResponse getDemandForBucket(DemandBucket bucket, UserType userType) {
        return buildResponse(bucket, bucket.getLabel(), userType, -1);
    }

    public DemandResponse getCurrentDemand(UserType userType, int cityId) {
        ZonedDateTime now = ZonedDateTime.now(zoneId);
        DemandBucket bucket = DemandBucket.from(now.toLocalTime());
        return buildResponse(bucket, "now", userType, cityId);
    }

    public DemandResponse getNext2HoursDemand(UserType userType, int cityId) {
        ZonedDateTime future = ZonedDateTime.now(zoneId).plusHours(2);
        DemandBucket bucket = DemandBucket.from(future.toLocalTime());
        return buildResponse(bucket, "next2h", userType, cityId);
    }

    public DemandResponse getDemandAt(UserType userType, int cityId, ZonedDateTime dateTime) {
        DemandBucket bucket = DemandBucket.from(dateTime.toLocalTime());
        // temporarily set the zone clock to the requested datetime when computing
        // we'll compute representative LocalDateTime inside buildResponse using the provided ZonedDateTime
        return buildResponseForDatetime(bucket, "at", userType, cityId, dateTime);
    }

    // internal helper to route to time-aware city computation
    private DemandResponse buildResponseForDatetime(DemandBucket bucket, String label, UserType userType, int cityId, ZonedDateTime dateTime) {
        if (cityId <= 0) return buildResponse(bucket, label, userType, cityId);
        java.time.LocalDateTime rep = java.time.LocalDateTime.of(dateTime.getYear(), dateTime.getMonth(), dateTime.getDayOfMonth(), dateTime.getHour(), 0);
        double ridesSignal = dataLoader.ridesSignalForCityAt(rep, cityId);
        double eatsSignal = dataLoader.eatsSignalForCityAt(rep, cityId);
        String key = String.valueOf(cityId);
        Map<String, Double> rides = new LinkedHashMap<>();
        Map<String, Double> eats = new LinkedHashMap<>();
        rides.put(key, ridesSignal);
        eats.put(key, eatsSignal);

        Map<String, DemandCalculator.ZoneDemand> calculations = DemandCalculator.calculateDemand(
                rides,
                eats,
                null,
                null,
                null,
                null,
                null,
                userType == UserType.RIDER ? DemandCalculator.UserType.RIDER : DemandCalculator.UserType.FOOD
        );

        Map<String, DriverDemandDto> out = new LinkedHashMap<>();
        DemandCalculator.ZoneDemand d = calculations.get(key);
        if (d == null) {
            out.put(key, new DriverDemandDto(0.0, "low", "rest"));
        } else {
            double score = userType == UserType.RIDER ? d.getRidesScore() : d.getEatsScore();
            String level = userType == UserType.RIDER ? d.getRidesLevel() : d.getEatsLevel();
            out.put(key, new DriverDemandDto(score, level, actionFor(level)));
        }
        return new DemandResponse(Instant.now(), label, userType, out);
    }

    private DemandResponse buildResponse(DemandBucket bucket, String label, UserType userType, int cityId) {
        // If a specific cityId is provided, compute a single per-city demand
        // value (no zones) so city-level signals do not overlap.
        if (cityId > 0) {
            // compute a representative LocalDateTime for the bucket (use bucket midpoint hour)
            java.time.LocalTime rep = switch (bucket) {
                case MORNING -> java.time.LocalTime.of(9, 0);
                case EVENING -> java.time.LocalTime.of(18, 0);
                default -> java.time.LocalTime.of(2, 0);
            };
            java.time.LocalDateTime now = java.time.LocalDateTime.now(zoneId).withHour(rep.getHour()).withMinute(0).withSecond(0).withNano(0);
            double ridesSignal = dataLoader.ridesSignalForCityAt(now, cityId);
            double eatsSignal = dataLoader.eatsSignalForCityAt(now, cityId);

            // build maps with a single key = cityId string
            String key = String.valueOf(cityId);
            Map<String, Double> rides = new LinkedHashMap<>();
            Map<String, Double> eats = new LinkedHashMap<>();
            rides.put(key, ridesSignal);
            eats.put(key, eatsSignal);

        Map<String, DemandCalculator.ZoneDemand> calculations = DemandCalculator.calculateDemand(
            rides,
            eats,
            null,
            null,
            null,
            null,
            null,
            userType == UserType.RIDER ? DemandCalculator.UserType.RIDER : DemandCalculator.UserType.FOOD
        );

            Map<String, DriverDemandDto> out = new LinkedHashMap<>();
            DemandCalculator.ZoneDemand d = calculations.get(key);
            if (d == null) {
                out.put(key, new DriverDemandDto(0.0, "low", "rest"));
            } else {
                double score = userType == UserType.RIDER ? d.getRidesScore() : d.getEatsScore();
                String level = userType == UserType.RIDER ? d.getRidesLevel() : d.getEatsLevel();
                out.put(key, new DriverDemandDto(score, level, actionFor(level)));
            }
            return new DemandResponse(Instant.now(), label, userType, out);
        }

        // Fallback: compute per-zone demand using existing hex/zone aggregation
        Map<String, Double> rides;
        Map<String, Double> eats;
        try {
            Integer cid = null;
            rides = hexAggregator.zoneRidesSignal(bucket, cid, dataLoader);
            eats = hexAggregator.zoneEatsSignal(bucket, cid, dataLoader);
        } catch (Exception e) {
            rides = dataLoader.ridesFor(bucket);
            eats = dataLoader.eatsFor(bucket);
        }

    Map<String, DemandCalculator.ZoneDemand> calculations = DemandCalculator.calculateDemand(
        rides,
        eats,
        null,
        null,
        null,
        null,
        null,
        userType == UserType.RIDER ? DemandCalculator.UserType.RIDER : DemandCalculator.UserType.FOOD
    );

        Map<String, DriverDemandDto> zones = new LinkedHashMap<>();
        for (String zone : dataLoader.zones()) {
            DemandCalculator.ZoneDemand demand = calculations.get(zone);
            if (demand == null) {
                zones.put(zone, new DriverDemandDto(0.0, "low", "rest"));
                continue;
            }
            double score = userType == UserType.RIDER ? demand.getRidesScore() : demand.getEatsScore();
            String level = userType == UserType.RIDER ? demand.getRidesLevel() : demand.getEatsLevel();
            String action = actionFor(level);
            zones.put(zone, new DriverDemandDto(score, level, action));
        }

        return new DemandResponse(Instant.now(), label, userType, zones);
    }

    private String actionFor(String level) {
        return switch (level) {
            case "high" -> "go now";
            case "med" -> "stay ready";
            default -> "rest";
        };
    }
}
