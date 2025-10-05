package com.attentionseekers.service;

import com.attentionseekers.dto.FeatureCollection;
import com.attentionseekers.model.RestLocation;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class RestLocationService {

    private final List<RestLocation> locations;

    public RestLocationService(ObjectMapper mapper) throws IOException {
        // Try multiple candidate locations so the service works whether the working
        // directory is the repo root, the backend module root, or when the file is
        // packaged on the classpath.
        File candidate = new File("./backend/src/data/rest_locations.json");
        if (!candidate.exists()) candidate = new File("./src/data/rest_locations.json");
        if (!candidate.exists()) candidate = new File("./src/main/resources/data/rest_locations.json");

        FeatureCollection data = null;
        if (candidate.exists()) {
            data = mapper.readValue(candidate, FeatureCollection.class);
        } else {
            // try loading from classpath
            InputStream is = getClass().getClassLoader().getResourceAsStream("rest_locations.json");
            if (is == null) {
                is = getClass().getClassLoader().getResourceAsStream("data/rest_locations.json");
            }
            if (is != null) {
                data = mapper.readValue(is, FeatureCollection.class);
            }
        }

        if (data == null) {
            // file not found on disk or classpath - disable locations gracefully
            this.locations = Collections.emptyList();
            return;
        }

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

        System.out.println(locations.stream().limit(10).collect(Collectors.toList()));
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
