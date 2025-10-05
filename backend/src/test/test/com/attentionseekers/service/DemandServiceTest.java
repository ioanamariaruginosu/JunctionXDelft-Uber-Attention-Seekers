package com.attentionseekers.service;

import com.attentionseekers.dto.DemandResponse;
import com.attentionseekers.dto.ZoneDemandDto;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.DefaultResourceLoader;

import java.time.ZoneId;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

public class DemandServiceTest {

    @Test
    void demandForMorningContainsAllZones() {
        DemandDataLoader loader = new DemandDataLoader(new DefaultResourceLoader());
        DemandService service = new DemandService(loader, ZoneId.systemDefault());

        DemandResponse response = service.getDemandForBucket(DemandBucket.MORNING);
        Map<String, ZoneDemandDto> zones = response.getZones();

        assertEquals(3, zones.size());
        for (ZoneDemandDto dto : zones.values()) {
            assertNotNull(dto);
            assertNotNull(dto.getRidesLevel());
            assertNotNull(dto.getEatsLevel());
        }
    }

    @Test
    void nextTwoHoursDemandReturnsZones() {
        DemandDataLoader loader = new DemandDataLoader(new DefaultResourceLoader());
        DemandService service = new DemandService(loader, ZoneId.systemDefault());

        DemandResponse response = service.getNext2HoursDemand();
        assertEquals(3, response.getZones().size());
    }
}
