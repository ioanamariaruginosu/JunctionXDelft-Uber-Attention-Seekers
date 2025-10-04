package com.attentionseekers.service;

import com.attentionseekers.dto.DemandResponse;
import com.attentionseekers.dto.ZoneDemandDto;

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

    public DemandResponse getCurrentDemand() {
        ZonedDateTime now = ZonedDateTime.now(zoneId);
        DemandBucket bucket = DemandBucket.from(now.toLocalTime());
        return buildResponse(bucket, "now");
    }

    public DemandResponse getNext2HoursDemand() {
        ZonedDateTime future = ZonedDateTime.now(zoneId).plusHours(2);
        DemandBucket bucket = DemandBucket.from(future.toLocalTime());
        return buildResponse(bucket, "next2h");
    }

    public DemandResponse getDemandForBucket(DemandBucket bucket) {
        return buildResponse(bucket, bucket.getLabel());
    }

    private DemandResponse buildResponse(DemandBucket bucket, String label) {
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

        Map<String, ZoneDemandDto> zones = new LinkedHashMap<>();
        for (String zone : dataLoader.zones()) {
            DemandCalculator.ZoneDemand demand = calculations.get(zone);
            if (demand == null) {
                demand = new DemandCalculator.ZoneDemand(0.0, "low", 0.0, "low", "stay");
            }
            zones.put(zone, new ZoneDemandDto(
                    demand.getRidesScore(),
                    demand.getRidesLevel(),
                    demand.getEatsScore(),
                    demand.getEatsLevel(),
                    demand.getRecommendation()
            ));
        }

        return new DemandResponse(Instant.now(), label, zones);
    }
}
