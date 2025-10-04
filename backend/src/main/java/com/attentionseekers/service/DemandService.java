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
    private final ZoneId zoneId;

    @Autowired
    public DemandService(DemandDataLoader dataLoader) {
        this(dataLoader, ZoneId.systemDefault());
    }

    DemandService(DemandDataLoader dataLoader, ZoneId zoneId) {
        this.dataLoader = dataLoader;
        this.zoneId = zoneId;
    }

    public DemandResponse getCurrentDemand(UserType userType) {
        ZonedDateTime now = ZonedDateTime.now(zoneId);
        DemandBucket bucket = DemandBucket.from(now.toLocalTime());
        return buildResponse(bucket, "now", userType);
    }

    public DemandResponse getCurrentDemand() {
        return getCurrentDemand(UserType.RIDER);
    }

    public DemandResponse getNext2HoursDemand(UserType userType) {
        ZonedDateTime future = ZonedDateTime.now(zoneId).plusHours(2);
        DemandBucket bucket = DemandBucket.from(future.toLocalTime());
        return buildResponse(bucket, "next2h", userType);
    }

    public DemandResponse getNext2HoursDemand() {
        return getNext2HoursDemand(UserType.RIDER);
    }

    public DemandResponse getDemandForBucket(DemandBucket bucket, UserType userType) {
        return buildResponse(bucket, bucket.getLabel(), userType);
    }

    private DemandResponse buildResponse(DemandBucket bucket, String label, UserType userType) {
        Map<String, Double> rides = dataLoader.ridesFor(bucket);
        Map<String, Double> eats = dataLoader.eatsFor(bucket);

        Map<String, DemandCalculator.ZoneDemand> calculations = DemandCalculator.calculateDemand(
                rides,
                eats,
                null,
                null,
                null,
                null,
                null
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
