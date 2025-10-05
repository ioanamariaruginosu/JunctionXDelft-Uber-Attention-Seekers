package com.attentionseekers.controller;

import com.attentionseekers.dto.DemandResponse;
import com.attentionseekers.service.DemandService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/demand")
public class DemandController {

    private final DemandService demandService;

    public DemandController(DemandService demandService) {
        this.demandService = demandService;
    }

    @GetMapping("/api/now")
    public ResponseEntity<DemandResponse> now() {
        return ResponseEntity.ok(demandService.getCurrentDemand());
    }

    @GetMapping("/api/next2h")
    public ResponseEntity<DemandResponse> next2h() {
        return ResponseEntity.ok(demandService.getNext2HoursDemand());
    }
}