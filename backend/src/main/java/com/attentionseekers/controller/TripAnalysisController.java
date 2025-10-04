package com.attentionseekers.controller;

import com.attentionseekers.dto.TripAnalysisRequest;
import com.attentionseekers.dto.TripAnalysisResponse;
import com.attentionseekers.service.TripAnalysisService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class TripAnalysisController {

    @Autowired
    private TripAnalysisService tripAnalysisService;

    @PostMapping("/analyze-trip")
    public ResponseEntity<TripAnalysisResponse> analyzeTrip(@RequestBody TripAnalysisRequest request) {
        try {
            String suggestion = tripAnalysisService.analyzeTripRequest(request);

            TripAnalysisResponse response = new TripAnalysisResponse();
            response.setSuggestion(suggestion);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500)
                    .body(new TripAnalysisResponse("Failed to analyze trip"));
        }
    }
}