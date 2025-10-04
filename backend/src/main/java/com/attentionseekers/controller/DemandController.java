package com.attentionseekers.controller;

import com.attentionseekers.dto.DemandResponse;
import com.attentionseekers.service.DemandService;
import com.attentionseekers.service.UserType;
import java.time.format.DateTimeParseException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/demand")
public class DemandController {

    private final DemandService demandService;

    public DemandController(DemandService demandService) {
        this.demandService = demandService;
    }

    @GetMapping("/now")
    public ResponseEntity<Object> now(@org.springframework.web.bind.annotation.RequestParam(name = "userType", required = false, defaultValue = "rider") String userType,
                                              @org.springframework.web.bind.annotation.RequestParam(name = "cityId", required = false) Integer cityId) {
        DemandResponse resp = cityId != null ? demandService.getCurrentDemand(UserType.from(userType), cityId) : demandService.getCurrentDemand(UserType.from(userType));
        return ResponseEntity.ok(filterResponse(resp, userType));
    }

    @GetMapping("/next2h")
    public ResponseEntity<Object> next2h(@org.springframework.web.bind.annotation.RequestParam(name = "userType", required = false, defaultValue = "rider") String userType,
                                                 @org.springframework.web.bind.annotation.RequestParam(name = "cityId", required = false) Integer cityId,
                                                 @org.springframework.web.bind.annotation.RequestParam(name = "datetime", required = false) String datetime) {
        try {
            if (datetime != null && !datetime.isBlank()) {
                ZonedDateTime dt = ZonedDateTime.parse(datetime);
                ZonedDateTime dtPlus2 = dt.plusHours(2);
                DemandResponse resp = cityId != null ? demandService.getDemandAt(UserType.from(userType), cityId, dtPlus2) : demandService.getDemandAt(UserType.from(userType), -1, dtPlus2);
                return ResponseEntity.ok(filterResponse(resp, userType));
            }
        } catch (DateTimeParseException ex) {
            return ResponseEntity.badRequest().build();
        }
        DemandResponse resp = cityId != null ? demandService.getNext2HoursDemand(UserType.from(userType), cityId) : demandService.getNext2HoursDemand(UserType.from(userType));
        return ResponseEntity.ok(filterResponse(resp, userType));
    }

    @GetMapping("/at")
    public ResponseEntity<Object> at(@org.springframework.web.bind.annotation.RequestParam(name = "userType", required = false, defaultValue = "rider") String userType,
                                             @org.springframework.web.bind.annotation.RequestParam(name = "cityId", required = false) Integer cityId,
                                             @org.springframework.web.bind.annotation.RequestParam(name = "datetime", required = true) String datetime) {
        try {
            ZonedDateTime dt = ZonedDateTime.parse(datetime);
            DemandResponse resp = cityId != null ? demandService.getDemandAt(UserType.from(userType), cityId, dt) : demandService.getDemandAt(UserType.from(userType), -1, dt);
            return ResponseEntity.ok(filterResponse(resp, userType));
        } catch (DateTimeParseException ex) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/cities")
    public ResponseEntity<java.util.List<Integer>> cities() {
        return ResponseEntity.ok(demandService.availableCityIds());
    }

    // Helper: returns a POJO-like map that only exposes fields relevant to the requested userType.
    // This avoids returning both rides and eats for a single request.
    private java.util.Map<String, Object> filterResponse(DemandResponse resp, String userTypeStr) {
        boolean isRider = "rider".equalsIgnoreCase(userTypeStr);
        boolean isFood = "food".equalsIgnoreCase(userTypeStr) || "eats".equalsIgnoreCase(userTypeStr);

        java.util.Map<String, Object> out = new java.util.LinkedHashMap<>();
        out.put("generatedAt", resp.getGeneratedAt());
        out.put("range", resp.getRange());

        java.util.Map<String, Object> zones = new java.util.LinkedHashMap<>();
        if (resp.getZones() != null) {
            for (java.util.Map.Entry<String, ?> e : resp.getZones().entrySet()) {
                Object val = e.getValue();
                java.util.Map<String, Object> entry = new java.util.LinkedHashMap<>();
                if (val instanceof com.attentionseekers.dto.ZoneDemandDto) {
                    com.attentionseekers.dto.ZoneDemandDto z = (com.attentionseekers.dto.ZoneDemandDto) val;
                    if (isRider) {
                        entry.put("ridesScore", z.getRidesScore());
                        entry.put("ridesLevel", z.getRidesLevel());
                        entry.put("recommendation", z.getRecommendation());
                    } else if (isFood) {
                        entry.put("eatsScore", z.getEatsScore());
                        entry.put("eatsLevel", z.getEatsLevel());
                        entry.put("recommendation", z.getRecommendation());
                    } else {
                        // default: include both if unknown userType
                        entry.put("ridesScore", z.getRidesScore());
                        entry.put("ridesLevel", z.getRidesLevel());
                        entry.put("eatsScore", z.getEatsScore());
                        entry.put("eatsLevel", z.getEatsLevel());
                        entry.put("recommendation", z.getRecommendation());
                    }
                } else {
                    // fallback - include the raw value
                    entry.put("value", val);
                }
                zones.put(e.getKey(), entry);
            }
        }
        out.put("zones", zones);
        return out;
    }
}