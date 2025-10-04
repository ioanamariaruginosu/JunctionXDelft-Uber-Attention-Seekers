package com.attentionseekers.service;

import com.attentionseekers.dto.TripAnalysisRequest;
import org.springframework.stereotype.Service;

import java.time.LocalTime;
import java.util.*;

@Service
public class TripAnalysisService {

    private final HistoricalTripDataLoader dataLoader;

    public TripAnalysisService(HistoricalTripDataLoader dataLoader) {
        this.dataLoader = dataLoader;
    }

    public String analyzeTripRequest(TripAnalysisRequest request) {
        // Get current time context
        int currentHour = LocalTime.now().getHour();

        // Use aggregated data across all cities since we don't have cityId from frontend
        HistoricalAnalysis analysis = analyzeHistoricalData(request, currentHour);

        // Calculate comprehensive score
        double finalScore = calculateFinalScore(request, analysis);

        // Generate recommendation
        String recommendation = getRecommendation(finalScore);
        String reason = buildReason(request, analysis, finalScore);
        String waitAdvice = getWaitAdvice(analysis, currentHour);
        String competitorInsight = getCompetitorInsight(analysis);

        return String.format(
                "%s\n%s\n\n💰 Earnings: $%.2f\n⏱️ Time: %d mins\n📍 Distance: %.1f miles\n🎯 Score: %.1f/10\n\n%s\n%s",
                recommendation,
                reason,
                request.getTotalEarnings(),
                request.getEstimatedDuration(),
                request.getDistance(),
                finalScore,
                waitAdvice,
                competitorInsight
        );
    }

    private HistoricalAnalysis analyzeHistoricalData(TripAnalysisRequest request, int currentHour) {
        HistoricalAnalysis analysis = new HistoricalAnalysis();

        // Get all historical trips for this hour across all cities
        List<HistoricalTripDataLoader.TripRecord> historicalTrips = dataLoader.getTripsForHour(currentHour);

        if (!historicalTrips.isEmpty()) {
            // Calculate average earnings per minute in this time slot
            analysis.avgEarningsPerMinute = historicalTrips.stream()
                    .mapToDouble(t -> t.netEarnings / t.durationMins)
                    .average()
                    .orElse(0.0);

            // Calculate average surge in this hour
            analysis.avgSurgeThisHour = historicalTrips.stream()
                    .mapToDouble(t -> t.surgeMultiplier)
                    .average()
                    .orElse(1.0);

            // Get 75th percentile earnings (top performers)
            List<Double> earningsPerMin = historicalTrips.stream()
                    .map(t -> t.netEarnings / t.durationMins)
                    .sorted()
                    .toList();
            int p75Index = (int) (earningsPerMin.size() * 0.75);
            analysis.topPerformerEarningsPerMin = earningsPerMin.get(Math.min(p75Index, earningsPerMin.size() - 1));

            // Calculate average distance and duration
            analysis.avgDistance = historicalTrips.stream()
                    .mapToDouble(t -> t.distanceKm)
                    .average()
                    .orElse(0.0);
            analysis.avgDuration = historicalTrips.stream()
                    .mapToDouble(t -> t.durationMins)
                    .average()
                    .orElse(0.0);
        }

        // Get surge forecast for next hours (average across all cities)
        analysis.nextHourSurge = dataLoader.getAverageSurgeForHour((currentHour + 1) % 24);
        analysis.twoHoursLaterSurge = dataLoader.getAverageSurgeForHour((currentHour + 2) % 24);

        return analysis;
    }

    private double calculateFinalScore(TripAnalysisRequest request, HistoricalAnalysis analysis) {
        double score = 0.0;

        // 1. Earnings efficiency (30% weight) - MUCH STRICTER
        double requestEarningsPerMin = request.getTotalEarnings() / request.getEstimatedDuration();
        if (analysis.avgEarningsPerMinute > 0) {
            double efficiencyRatio = requestEarningsPerMin / analysis.avgEarningsPerMinute;
            // Need to be 50% above average to get full points
            if (efficiencyRatio >= 1.5) {
                score += 3.0;
            } else if (efficiencyRatio >= 1.2) {
                score += 2.0;
            } else if (efficiencyRatio >= 1.0) {
                score += 1.2;
            } else if (efficiencyRatio >= 0.8) {
                score += 0.6;
            }
        } else {
            score += requestEarningsPerMin > 0.5 ? 1.5 : 0.5;
        }

        // 2. Surge comparison (25% weight) - STRICTER
        double currentSurge = request.getSurgeMultiplier() != null ? request.getSurgeMultiplier() : 1.0;
        if (currentSurge >= 2.5) {
            score += 2.5; // Only very high surge gets full points
        } else if (currentSurge >= 1.8) {
            score += 1.8;
        } else if (currentSurge >= 1.3) {
            score += 1.0;
        } else if (currentSurge > 1.0) {
            score += 0.3;
        }

        // 3. Distance efficiency (20% weight) - STRICTER
        double earningsPerMile = request.getTotalEarnings() / request.getDistance();
        if (earningsPerMile > 3.5) {
            score += 2.0;
        } else if (earningsPerMile > 2.5) {
            score += 1.5;
        } else if (earningsPerMile > 1.8) {
            score += 1.0;
        } else if (earningsPerMile > 1.2) {
            score += 0.5;
        } else {
            score += 0.2;
        }

        // 4. Comparison to top performers (15% weight) - STRICTER
        if (analysis.topPerformerEarningsPerMin > 0) {
            double vsTopPerformers = requestEarningsPerMin / analysis.topPerformerEarningsPerMin;
            if (vsTopPerformers >= 0.9) {
                score += 1.5; // Close to top performers
            } else if (vsTopPerformers >= 0.7) {
                score += 1.0;
            } else if (vsTopPerformers >= 0.5) {
                score += 0.5;
            } else {
                score += 0.2;
            }
        } else {
            score += 0.5;
        }

        // 5. Time investment (10% weight) - STRICTER with penalties
        if (request.getEstimatedDuration() <= 10) {
            score += 1.0;
        } else if (request.getEstimatedDuration() <= 20) {
            score += 0.7;
        } else if (request.getEstimatedDuration() <= 35) {
            score += 0.4;
        } else if (request.getEstimatedDuration() <= 50) {
            score += 0.1;
        } else {
            score -= 0.3; // Penalty for very long trips
        }

        // Add slight randomness for variety
        score += (Math.random() - 0.5) * 0.8;

        return Math.max(0.0, Math.min(score, 10.0));
    }

    private String getRecommendation(double score) {
        if (score >= 8.0) {
            return "🔥 ACCEPT NOW - Exceptional deal!";
        } else if (score >= 6.5) {
            return "✅ ACCEPT - Strong opportunity";
        } else if (score >= 5.0) {
            return "⚠️ CONSIDER - Decent but not great";
        } else if (score >= 3.5) {
            return "🤔 MARGINAL - Only if desperate";
        } else {
            return "❌ SKIP - Poor value";
        }
    }

    private String buildReason(TripAnalysisRequest request, HistoricalAnalysis analysis, double score) {
        List<String> reasons = new ArrayList<>();

        double requestEarningsPerMin = request.getTotalEarnings() / request.getEstimatedDuration();
        double currentSurge = request.getSurgeMultiplier() != null ? request.getSurgeMultiplier() : 1.0;

        // Earnings comparison
        if (analysis.avgEarningsPerMinute > 0) {
            double ratio = requestEarningsPerMin / analysis.avgEarningsPerMinute;
            if (ratio > 1.2) {
                reasons.add("Earnings " + String.format("%.0f%%", (ratio - 1) * 100) + " above average");
            } else if (ratio < 0.8) {
                reasons.add("Earnings " + String.format("%.0f%%", (1 - ratio) * 100) + " below average");
            }
        }

        // Surge analysis
        if (currentSurge >= 1.5) {
            reasons.add("Strong surge active (" + String.format("%.1fx", currentSurge) + ")");
        } else if (currentSurge > 1.0) {
            reasons.add("Moderate surge (" + String.format("%.1fx", currentSurge) + ")");
        }

        // Distance efficiency
        double earningsPerMile = request.getTotalEarnings() / request.getDistance();
        if (earningsPerMile > 2.5) {
            reasons.add("Excellent per-mile earnings ($" + String.format("%.2f", earningsPerMile) + "/mi)");
        } else if (earningsPerMile < 1.0) {
            reasons.add("Low per-mile earnings ($" + String.format("%.2f", earningsPerMile) + "/mi)");
        }

        // Time investment
        if (request.getEstimatedDuration() > 45) {
            reasons.add("Long trip reduces flexibility");
        } else if (request.getEstimatedDuration() <= 15) {
            reasons.add("Quick turnaround time");
        }

        return reasons.isEmpty() ? "Average trip for this time" : String.join(", ", reasons);
    }

    private String getWaitAdvice(HistoricalAnalysis analysis, int currentHour) {
        double currentSurge = analysis.avgSurgeThisHour;

        if (analysis.nextHourSurge > currentSurge * 1.2) {
            return "⏰ Wait advice: Surge expected to increase " +
                    String.format("%.0f%%", (analysis.nextHourSurge / currentSurge - 1) * 100) +
                    " in next hour";
        } else if (analysis.twoHoursLaterSurge > currentSurge * 1.3) {
            return "⏰ Wait advice: Much better surge expected in 2 hours";
        } else if (currentSurge > analysis.nextHourSurge * 1.15) {
            return "⏰ Wait advice: Take it now, surge declining soon";
        } else {
            return "⏰ Wait advice: Stable demand, no urgency";
        }
    }

    private String getCompetitorInsight(HistoricalAnalysis analysis) {
        if (analysis.topPerformerEarningsPerMin > 0 && analysis.avgEarningsPerMinute > 0) {
            double gap = ((analysis.topPerformerEarningsPerMin / analysis.avgEarningsPerMinute) - 1) * 100;
            return String.format("📊 Top 25%% of drivers earn %.0f%% more at this time", gap);
        }
        return "📊 Limited competitor data available";
    }

    private static class HistoricalAnalysis {
        double avgEarningsPerMinute = 0.0;
        double avgSurgeThisHour = 1.0;
        double topPerformerEarningsPerMin = 0.0;
        double avgDistance = 0.0;
        double avgDuration = 0.0;
        double nextHourSurge = 1.0;
        double twoHoursLaterSurge = 1.0;
    }
}