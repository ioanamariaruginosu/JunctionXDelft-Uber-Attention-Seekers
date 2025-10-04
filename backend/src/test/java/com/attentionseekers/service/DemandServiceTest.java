package com.attentionseekers.service;

import com.attentionseekers.dto.DemandResponse;
import com.attentionseekers.dto.DriverDemandDto;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.DefaultResourceLoader;

import java.time.ZoneId;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

public class DemandServiceTest {

    @Test
    void demandForMorningContainsAllZonesForRiders() {
        DemandDataLoader loader = new DemandDataLoader(new DefaultResourceLoader());
        DemandService service = new DemandService(loader, ZoneId.systemDefault());

        DemandResponse response = service.getDemandForBucket(DemandBucket.MORNING, UserType.RIDER);
        Map<String, DriverDemandDto> zones = response.getZones();

        assertEquals(3, zones.size());
        for (DriverDemandDto dto : zones.values()) {
            assertNotNull(dto);
            assertNotNull(dto.getLevel());
            assertNotNull(dto.getAction());
        }
    }

    @Test
    void nextTwoHoursDemandReturnsZonesForFood() {
        DemandDataLoader loader = new DemandDataLoader(new DefaultResourceLoader());
        DemandService service = new DemandService(loader, ZoneId.systemDefault());

        DemandResponse response = service.getNext2HoursDemand(UserType.FOOD);
        assertEquals(3, response.getZones().size());
        assertEquals(UserType.FOOD, response.getUserType());
    }
}
