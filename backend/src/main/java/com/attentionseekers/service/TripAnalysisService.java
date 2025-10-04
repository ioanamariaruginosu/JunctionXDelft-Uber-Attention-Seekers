package com.attentionseekers.service;

import com.attentionseekers.dto.TripAnalysisRequest;
import org.springframework.stereotype.Service;

@Service
public class TripAnalysisService {

    public String analyzeTripRequest(TripAnalysisRequest request) {
        double profitScore = request.getProfitabilityScore();
        String recommendation;
        String reason;

        if (profitScore >= 7) {
            recommendation = "✅ ACCEPT - Excellent opportunity!";
            reason = "High profitability, good surge, likely return trip";
        } else if (profitScore >= 5) {
            recommendation = "⚠️ ACCEPT - Decent trip";
            reason = "Average profitability, consider if positioning helps";
        } else {
            recommendation = "❌ SKIP - Low value";
            reason = "Low earnings per minute, no surge active";
        }

        return String.format(
                "%s\n%s\n\n💰 Earnings: $%.2f\n⏱️ Time: %d mins\n📍 Distance: %.1f miles",
                recommendation,
                reason,
                request.getTotalEarnings(),
                request.getEstimatedDuration(),
                request.getDistance()
        );
    }
}