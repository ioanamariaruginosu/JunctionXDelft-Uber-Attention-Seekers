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
    public ResponseEntity<DemandResponse> now(@org.springframework.web.bind.annotation.RequestParam(name = "userType", required = false, defaultValue = "rider") String userType,
                                              @org.springframework.web.bind.annotation.RequestParam(name = "cityId", required = false) Integer cityId) {
    DemandResponse resp = cityId != null ? demandService.getCurrentDemand(UserType.from(userType), cityId) : demandService.getCurrentDemand(UserType.from(userType));
        return ResponseEntity.ok(resp);
    }

    @GetMapping("/next2h")
    public ResponseEntity<DemandResponse> next2h(@org.springframework.web.bind.annotation.RequestParam(name = "userType", required = false, defaultValue = "rider") String userType,
                                                 @org.springframework.web.bind.annotation.RequestParam(name = "cityId", required = false) Integer cityId,
                                                 @org.springframework.web.bind.annotation.RequestParam(name = "datetime", required = false) String datetime) {
        try {
            if (datetime != null && !datetime.isBlank()) {
                ZonedDateTime dt = ZonedDateTime.parse(datetime);
                ZonedDateTime dtPlus2 = dt.plusHours(2);
                DemandResponse resp = cityId != null ? demandService.getDemandAt(UserType.from(userType), cityId, dtPlus2) : demandService.getDemandAt(UserType.from(userType), -1, dtPlus2);
                return ResponseEntity.ok(resp);
            }
        } catch (DateTimeParseException ex) {
            return ResponseEntity.badRequest().build();
        }
        DemandResponse resp = cityId != null ? demandService.getNext2HoursDemand(UserType.from(userType), cityId) : demandService.getNext2HoursDemand(UserType.from(userType));
        return ResponseEntity.ok(resp);
    }

    @GetMapping("/at")
    public ResponseEntity<DemandResponse> at(@org.springframework.web.bind.annotation.RequestParam(name = "userType", required = false, defaultValue = "rider") String userType,
                                             @org.springframework.web.bind.annotation.RequestParam(name = "cityId", required = false) Integer cityId,
                                             @org.springframework.web.bind.annotation.RequestParam(name = "datetime", required = true) String datetime) {
        try {
            ZonedDateTime dt = ZonedDateTime.parse(datetime);
            DemandResponse resp = cityId != null ? demandService.getDemandAt(UserType.from(userType), cityId, dt) : demandService.getDemandAt(UserType.from(userType), -1, dt);
            return ResponseEntity.ok(resp);
        } catch (DateTimeParseException ex) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/cities")
    public ResponseEntity<java.util.List<Integer>> cities() {
        return ResponseEntity.ok(demandService.availableCityIds());
    }
}