package com.attentionseekers.service;

import com.attentionseekers.dto.FeatureCollection;
import com.attentionseekers.model.RestLocation;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class RestLocationService {

    private final List<RestLocation> locations;

    public RestLocationService(ObjectMapper mapper) throws IOException {

        FeatureCollection data = mapper.readValue(new File("C:\\Users\\thea\\JunctionXDelft-Uber-Attention-Seekers\\backend\\src\\data\\rest_locations.json"), FeatureCollection.class);

        this.locations = data.getFeatures().stream()
                .map(f -> {
                    List<Double> coords = f.getGeometry().getCoordinates();
                    return new RestLocation(
                            f.getId(),
                            (String) f.getProperties().getOrDefault("amenity", ""),
                            (String) f.getProperties().getOrDefault("name", f.getProperties().get("name")),
                            coords.size() > 1 ? coords.get(1) : 0.0,
                            coords.size() > 0 ? coords.get(0) : 0.0
                    );
                })
                .collect(Collectors.toList());
    }

    public List<RestLocation> findClosest(double lat, double lon, int limit) {
        return locations.stream()
                .sorted((a, b) -> {
                    double d1 = distance(lat, lon, a.getLatitude(), a.getLongitude());
                    double d2 = distance(lat, lon, b.getLatitude(), b.getLongitude());
                    return Double.compare(d1, d2);
                })
                .limit(limit)
                .collect(Collectors.toList());
    }

    private double distance(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                        Math.sin(dLon/2) * Math.sin(dLon/2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        return R * c;
    }
}
