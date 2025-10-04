package com.attentionseekers.service;

import com.attentionseekers.dto.TripAnalysisRequest;
import org.springframework.stereotype.Service;

import java.time.LocalTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class TripAnalysisService {

    private final HistoricalTripDataLoader dataLoader;
    private static final double NEARBY_RADIUS_KM = 5.0;
    private static final double EARTH_RADIUS_KM = 6371.0;

    public TripAnalysisService(HistoricalTripDataLoader dataLoader) {
        this.dataLoader = dataLoader;
    }

    public String analyzeTripRequest(TripAnalysisRequest request) {
        int currentHour = LocalTime.now().getHour();

        // Parse coordinates
        Double pickupLat = parseCoordinate(request.getPickupLat());
        Double pickupLon = parseCoordinate(request.getPickupLon());
        Double dropoffLat = parseCoordinate(request.getDropOffLat());
        Double dropoffLon = parseCoordinate(request.getDropOffLon());

        // Analyze with full location awareness
        HistoricalAnalysis analysis = analyzeHistoricalData(
                currentHour, pickupLat, pickupLon, dropoffLat, dropoffLon);

        // Calculate comprehensive score including location factors
        double finalScore = calculateFinalScore(request, analysis);

        // Generate recommendation with location insights
        String recommendation = getRecommendation(finalScore);
        String reason = buildReason(request, analysis);
        String pickupInsight = getPickupLocationInsight(analysis, pickupLat, pickupLon);
        String dropoffInsight = getDropoffLocationInsight(analysis, dropoffLat, dropoffLon);
        String waitAdvice = getWaitAdvice(analysis, currentHour);
        String competitorInsight = getCompetitorInsight(analysis);

        return String.format(
                "%s\n%s\n\n💰 Earnings: $%.2f\n⏱️ Time: %d mins\n📍 Distance: %.1f miles\n🎯 Score: %.1f/10\n\n%s\n%s\n%s\n%s",
                recommendation,
                reason,
                request.getTotalEarnings(),
                request.getEstimatedDuration(),
                request.getDistance(),
                finalScore,
                pickupInsight,
                dropoffInsight,
                waitAdvice,
                competitorInsight
        );
    }

    private HistoricalAnalysis analyzeHistoricalData(int currentHour,
                                                     Double pickupLat, Double pickupLon,
                                                     Double dropoffLat, Double dropoffLon) {
        HistoricalAnalysis analysis = new HistoricalAnalysis();

        List<HistoricalTripDataLoader.TripRecord> allHourTrips = dataLoader.getTripsForHour(currentHour);

        if (!allHourTrips.isEmpty()) {
            // Overall hour statistics
            analysis.avgEarningsPerMinute = allHourTrips.stream()
                    .mapToDouble(t -> t.netEarnings / t.durationMins)
                    .average()
                    .orElse(0.0);

            analysis.avgSurgeThisHour = allHourTrips.stream()
                    .mapToDouble(t -> t.surgeMultiplier)
                    .average()
                    .orElse(1.0);

            // PICKUP LOCATION ANALYSIS
            if (pickupLat != null && pickupLon != null) {
                List<HistoricalTripDataLoader.TripRecord> nearbyPickupTrips = allHourTrips.stream()
                        .filter(t -> calculateDistance(pickupLat, pickupLon, t.pickupLat, t.pickupLon) <= NEARBY_RADIUS_KM)
                        .toList();

                if (!nearbyPickupTrips.isEmpty()) {
                    analysis.nearbyPickupTripsCount = nearbyPickupTrips.size();

                    analysis.nearbyPickupAvgEarningsPerMinute = nearbyPickupTrips.stream()
                            .mapToDouble(t -> t.netEarnings / t.durationMins)
                            .average()
                            .orElse(0.0);

                    analysis.nearbyPickupAvgSurge = nearbyPickupTrips.stream()
                            .mapToDouble(t -> t.surgeMultiplier)
                            .average()
                            .orElse(1.0);

                    analysis.nearbyPickupAvgDistance = nearbyPickupTrips.stream()
                            .mapToDouble(t -> t.distanceKm)
                            .average()
                            .orElse(0.0);

                    analysis.pickupLocationProfitabilityIndex =
                            analysis.nearbyPickupAvgEarningsPerMinute / Math.max(0.01, analysis.avgEarningsPerMinute);

                    analysis.pickupHasHotspotDestinations = nearbyPickupTrips.stream()
                            .filter(t -> t.netEarnings / t.durationMins > analysis.avgEarningsPerMinute * 1.2)
                            .count() > nearbyPickupTrips.size() * 0.3;

                    double pickupVariance = calculateVariance(
                            nearbyPickupTrips.stream()
                                    .mapToDouble(t -> t.netEarnings / t.durationMins)
                                    .toArray()
                    );
                    analysis.pickupLocationConsistency = pickupVariance < 0.5 ? 1.0 : (pickupVariance < 1.0 ? 0.7 : 0.4);
                }
            }

            // DROPOFF LOCATION ANALYSIS
            if (dropoffLat != null && dropoffLon != null) {
                // Find trips that dropped off near this location
                List<HistoricalTripDataLoader.TripRecord> nearbyDropoffTrips = allHourTrips.stream()
                        .filter(t -> calculateDistance(dropoffLat, dropoffLon, t.dropLat, t.dropLon) <= NEARBY_RADIUS_KM)
                        .toList();

                if (!nearbyDropoffTrips.isEmpty()) {
                    analysis.nearbyDropoffTripsCount = nearbyDropoffTrips.size();

                    // Check how many trips STARTED from this dropoff area (return trip potential)
                    List<HistoricalTripDataLoader.TripRecord> returnTripPotential = allHourTrips.stream()
                            .filter(t -> calculateDistance(dropoffLat, dropoffLon, t.pickupLat, t.pickupLon) <= NEARBY_RADIUS_KM)
                            .toList();

                    analysis.returnTripCount = returnTripPotential.size();

                    if (!returnTripPotential.isEmpty()) {
                        analysis.returnTripAvgEarnings = returnTripPotential.stream()
                                .mapToDouble(t -> t.netEarnings / t.durationMins)
                                .average()
                                .orElse(0.0);

                        analysis.returnTripAvgSurge = returnTripPotential.stream()
                                .mapToDouble(t -> t.surgeMultiplier)
                                .average()
                                .orElse(1.0);

                        // Calculate return trip quality index
                        analysis.returnTripQualityIndex =
                                analysis.returnTripAvgEarnings / Math.max(0.01, analysis.avgEarningsPerMinute);
                    }

                    // Analyze dropoff area characteristics
                    analysis.dropoffAvgEarningsPerMinute = nearbyDropoffTrips.stream()
                            .mapToDouble(t -> t.netEarnings / t.durationMins)
                            .average()
                            .orElse(0.0);

                    analysis.dropoffLocationProfitabilityIndex =
                            analysis.dropoffAvgEarningsPerMinute / Math.max(0.01, analysis.avgEarningsPerMinute);

                    // Check if dropoff area has high demand (good for immediate return trips)
                    double dropoffVariance = calculateVariance(
                            returnTripPotential.stream()
                                    .mapToDouble(t -> t.netEarnings / t.durationMins)
                                    .toArray()
                    );
                    analysis.dropoffAreaConsistency = dropoffVariance < 0.5 ? 1.0 : (dropoffVariance < 1.0 ? 0.7 : 0.4);
                }
            }

            // Top performers (75th percentile)
            List<Double> earningsPerMin = allHourTrips.stream()
                    .map(t -> t.netEarnings / t.durationMins)
                    .sorted()
                    .toList();
            int p75Index = (int) (earningsPerMin.size() * 0.75);
            analysis.topPerformerEarningsPerMin = earningsPerMin.get(Math.min(p75Index, earningsPerMin.size() - 1));

            analysis.avgDistance = allHourTrips.stream()
                    .mapToDouble(t -> t.distanceKm)
                    .average()
                    .orElse(0.0);

            analysis.avgDuration = allHourTrips.stream()
                    .mapToDouble(t -> t.durationMins)
                    .average()
                    .orElse(0.0);
        }

        // Surge forecasting
        analysis.nextHourSurge = dataLoader.getAverageSurgeForHour((currentHour + 1) % 24);
        analysis.twoHoursLaterSurge = dataLoader.getAverageSurgeForHour((currentHour + 2) % 24);

        return analysis;
    }

    private double calculateFinalScore(TripAnalysisRequest request, HistoricalAnalysis analysis) {
        double score = 0.0;
        double requestEarningsPerMin = request.getTotalEarnings() / request.getEstimatedDuration();

        // 1. Earnings efficiency (20% weight)
        if (analysis.avgEarningsPerMinute > 0) {
            double efficiencyRatio = requestEarningsPerMin / analysis.avgEarningsPerMinute;
            if (efficiencyRatio >= 1.5) {
                score += 2.0;
            } else if (efficiencyRatio >= 1.2) {
                score += 1.5;
            } else if (efficiencyRatio >= 1.0) {
                score += 1.0;
            } else if (efficiencyRatio >= 0.8) {
                score += 0.5;
            }
        } else {
            score += requestEarningsPerMin > 0.5 ? 1.0 : 0.4;
        }

        // 2. Pickup location analysis (18% weight)
        if (analysis.nearbyPickupAvgEarningsPerMinute > 0) {
            double locationRatio = requestEarningsPerMin / analysis.nearbyPickupAvgEarningsPerMinute;
            if (locationRatio >= 1.3) {
                score += 1.8;
            } else if (locationRatio >= 1.1) {
                score += 1.3;
            } else if (locationRatio >= 0.9) {
                score += 0.9;
            } else if (locationRatio >= 0.7) {
                score += 0.4;
            }

            if (analysis.pickupLocationProfitabilityIndex > 1.2) {
                score += 0.5;
            }

            score += analysis.pickupLocationConsistency * 0.5;
        } else {
            score += 0.7;
        }

        // 3. Dropoff location & return trip potential (17% weight) - NEW
        if (analysis.returnTripCount > 0) {
            // Strong return trip potential
            if (analysis.returnTripQualityIndex > 1.2) {
                score += 1.7; // Excellent return trip area
            } else if (analysis.returnTripQualityIndex > 1.0) {
                score += 1.3; // Good return trip area
            } else if (analysis.returnTripQualityIndex > 0.8) {
                score += 0.9; // Average return trip area
            } else {
                score += 0.5; // Below-average return trip area
            }

            // Bonus for high demand at dropoff
            if (analysis.returnTripCount > 20) {
                score += 0.5; // High trip volume from this area
            } else if (analysis.returnTripCount > 10) {
                score += 0.3;
            }

            // Bonus for consistency
            score += analysis.dropoffAreaConsistency * 0.3;
        } else if (analysis.nearbyDropoffTripsCount > 0) {
            // Has dropoff data but no return trip data
            if (analysis.dropoffLocationProfitabilityIndex > 1.1) {
                score += 0.8;
            } else {
                score += 0.5;
            }
        } else {
            score += 0.6; // Neutral if no dropoff data
        }

        // 4. Surge comparison (20% weight)
        double currentSurge = request.getSurgeMultiplier() != null ? request.getSurgeMultiplier() : 1.0;
        if (currentSurge >= 2.5) {
            score += 2.0;
        } else if (currentSurge >= 1.8) {
            score += 1.5;
        } else if (currentSurge >= 1.3) {
            score += 1.0;
        } else if (currentSurge > 1.0) {
            score += 0.3;
        }

        if (analysis.nearbyPickupAvgSurge > 0 && currentSurge > analysis.nearbyPickupAvgSurge * 1.1) {
            score += 0.5;
        }

        // 5. Distance efficiency (15% weight)
        double earningsPerMile = request.getTotalEarnings() / request.getDistance();
        if (earningsPerMile > 3.5) {
            score += 1.5;
        } else if (earningsPerMile > 2.5) {
            score += 1.2;
        } else if (earningsPerMile > 1.8) {
            score += 0.9;
        } else if (earningsPerMile > 1.2) {
            score += 0.5;
        } else {
            score += 0.2;
        }

        // 6. Time investment (10% weight)
        if (request.getEstimatedDuration() <= 10) {
            score += 1.0;
        } else if (request.getEstimatedDuration() <= 20) {
            score += 0.7;
        } else if (request.getEstimatedDuration() <= 35) {
            score += 0.4;
        } else if (request.getEstimatedDuration() <= 50) {
            score += 0.1;
        } else {
            score -= 0.3;
        }

        score += (Math.random() - 0.5) * 0.4;

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

    private String buildReason(TripAnalysisRequest request, HistoricalAnalysis analysis) {
        List<String> reasons = new ArrayList<>();

        double requestEarningsPerMin = request.getTotalEarnings() / request.getEstimatedDuration();
        double currentSurge = request.getSurgeMultiplier() != null ? request.getSurgeMultiplier() : 1.0;

        // Pickup location insights
        if (analysis.nearbyPickupAvgEarningsPerMinute > 0) {
            double locationRatio = requestEarningsPerMin / analysis.nearbyPickupAvgEarningsPerMinute;
            if (locationRatio > 1.2) {
                reasons.add(String.format("%.0f%% above pickup area avg", (locationRatio - 1) * 100));
            } else if (locationRatio < 0.8) {
                reasons.add(String.format("%.0f%% below pickup area avg", (1 - locationRatio) * 100));
            }
        }

        // Return trip potential
        if (analysis.returnTripQualityIndex > 1.2) {
            reasons.add("Excellent return trip potential");
        } else if (analysis.returnTripQualityIndex > 0.8 && analysis.returnTripCount > 10) {
            reasons.add("Good return trip area");
        } else if (analysis.returnTripCount < 5 && analysis.nearbyDropoffTripsCount > 0) {
            reasons.add("Low return trip demand");
        }

        // Overall comparison
        if (analysis.avgEarningsPerMinute > 0) {
            double ratio = requestEarningsPerMin / analysis.avgEarningsPerMinute;
            if (ratio > 1.3) {
                reasons.add(String.format("%.0f%% above city avg", (ratio - 1) * 100));
            } else if (ratio < 0.7) {
                reasons.add(String.format("%.0f%% below city avg", (1 - ratio) * 100));
            }
        }

        // Surge
        if (currentSurge >= 1.5) {
            reasons.add(String.format("Strong surge (%.1fx)", currentSurge));
        } else if (currentSurge > 1.0) {
            reasons.add(String.format("Moderate surge (%.1fx)", currentSurge));
        }

        // Distance efficiency
        double earningsPerMile = request.getTotalEarnings() / request.getDistance();
        if (earningsPerMile > 2.5) {
            reasons.add(String.format("Great $/mi ($%.2f)", earningsPerMile));
        } else if (earningsPerMile < 1.2) {
            reasons.add(String.format("Low $/mi ($%.2f)", earningsPerMile));
        }

        // Time
        if (request.getEstimatedDuration() > 45) {
            reasons.add("Long trip limits flexibility");
        } else if (request.getEstimatedDuration() <= 15) {
            reasons.add("Quick turnaround");
        }

        return reasons.isEmpty() ? "Average trip for this time" : String.join("; ", reasons);
    }

    private String getPickupLocationInsight(HistoricalAnalysis analysis, Double pickupLat, Double pickupLon) {
        if (pickupLat == null || pickupLon == null || analysis.nearbyPickupTripsCount == 0) {
            return "📍 Pickup: No historical data";
        }

        StringBuilder insight = new StringBuilder("📍 Pickup: ");

        if (analysis.pickupLocationProfitabilityIndex > 1.2) {
            insight.append("Hot zone! ");
        } else if (analysis.pickupLocationProfitabilityIndex < 0.8) {
            insight.append("Below-avg zone. ");
        } else {
            insight.append("Average zone. ");
        }

        insight.append(String.format("$%.2f/min avg", analysis.nearbyPickupAvgEarningsPerMinute));

        if (analysis.pickupHasHotspotDestinations) {
            insight.append(" • High-value destinations");
        }

        if (analysis.pickupLocationConsistency > 0.7) {
            insight.append(" • Consistent");
        }

        insight.append(String.format(" (%d trips)", analysis.nearbyPickupTripsCount));

        return insight.toString();
    }

    private String getDropoffLocationInsight(HistoricalAnalysis analysis, Double dropoffLat, Double dropoffLon) {
        if (dropoffLat == null || dropoffLon == null) {
            return "🎯 Dropoff: No coordinates provided";
        }

        if (analysis.nearbyDropoffTripsCount == 0) {
            return "🎯 Dropoff: No historical data";
        }

        StringBuilder insight = new StringBuilder("🎯 Dropoff: ");

        if (analysis.returnTripCount > 0) {
            if (analysis.returnTripQualityIndex > 1.2) {
                insight.append("Excellent return area! ");
            } else if (analysis.returnTripQualityIndex > 1.0) {
                insight.append("Good return area. ");
            } else if (analysis.returnTripQualityIndex > 0.8) {
                insight.append("Average return area. ");
            } else {
                insight.append("Below-avg return area. ");
            }

            insight.append(String.format("$%.2f/min avg from here", analysis.returnTripAvgEarnings));

            if (analysis.returnTripCount > 20) {
                insight.append(" • High demand");
            } else if (analysis.returnTripCount < 5) {
                insight.append(" • Low demand");
            }

            insight.append(String.format(" (%d return trips)", analysis.returnTripCount));
        } else {
            insight.append(String.format("Limited return trip data (%d dropoffs)", analysis.nearbyDropoffTripsCount));
        }

        return insight.toString();
    }

    private String getWaitAdvice(HistoricalAnalysis analysis, int currentHour) {
        double currentSurge = analysis.avgSurgeThisHour;

        if (analysis.nextHourSurge > currentSurge * 1.2) {
            return String.format("⏰ Surge rising %.0f%% next hour",
                    (analysis.nextHourSurge / currentSurge - 1) * 100);
        } else if (analysis.twoHoursLaterSurge > currentSurge * 1.3) {
            return "⏰ Much better surge in 2 hours";
        } else if (currentSurge > analysis.nextHourSurge * 1.15) {
            return "⏰ Take now, surge declining";
        } else {
            return "⏰ Stable demand";
        }
    }

    private String getCompetitorInsight(HistoricalAnalysis analysis) {
        if (analysis.topPerformerEarningsPerMin > 0 && analysis.avgEarningsPerMinute > 0) {
            double gap = ((analysis.topPerformerEarningsPerMin / analysis.avgEarningsPerMinute) - 1) * 100;
            return String.format("📊 Top 25%% earn %.0f%% more now", gap);
        }
        return "📊 Limited competitor data";
    }

    private double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);

        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);

        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return EARTH_RADIUS_KM * c;
    }

    private double calculateVariance(double[] values) {
        if (values.length == 0) return 0.0;

        double mean = Arrays.stream(values).average().orElse(0.0);
        double sumSquaredDiff = Arrays.stream(values)
                .map(v -> Math.pow(v - mean, 2))
                .sum();

        return sumSquaredDiff / values.length;
    }

    private Double parseCoordinate(String coord) {
        if (coord == null || coord.isBlank()) return null;
        try {
            return Double.parseDouble(coord.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static class HistoricalAnalysis {
        double avgEarningsPerMinute = 0.0;
        double avgSurgeThisHour = 1.0;
        double topPerformerEarningsPerMin = 0.0;
        double avgDistance = 0.0;
        double avgDuration = 0.0;
        double nextHourSurge = 1.0;
        double twoHoursLaterSurge = 1.0;

        // Pickup location metrics
        int nearbyPickupTripsCount = 0;
        double nearbyPickupAvgEarningsPerMinute = 0.0;
        double nearbyPickupAvgSurge = 1.0;
        double nearbyPickupAvgDistance = 0.0;
        double pickupLocationProfitabilityIndex = 1.0;
        boolean pickupHasHotspotDestinations = false;
        double pickupLocationConsistency = 0.5;

        // Dropoff location metrics
        int nearbyDropoffTripsCount = 0;
        double dropoffAvgEarningsPerMinute = 0.0;
        double dropoffLocationProfitabilityIndex = 1.0;
        double dropoffAreaConsistency = 0.5;

        // Return trip potential
        int returnTripCount = 0;
        double returnTripAvgEarnings = 0.0;
        double returnTripAvgSurge = 1.0;
        double returnTripQualityIndex = 0.0;
    }
}