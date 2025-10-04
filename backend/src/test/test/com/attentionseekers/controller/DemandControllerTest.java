package com.attentionseekers.controller;

import com.attentionseekers.dto.DemandResponse;
import com.attentionseekers.dto.DriverDemandDto;
import com.attentionseekers.service.DemandService;
import com.attentionseekers.service.UserType;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.Map;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = DemandController.class)
public class DemandControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private DemandService demandService;

    @Test
    public void testNowEndpointForRider() throws Exception {
        Map<String, DriverDemandDto> zones = Map.of(
                "A", new DriverDemandDto(0.78, "high", "go now"),
                "B", new DriverDemandDto(0.46, "med", "stay ready"),
                "C", new DriverDemandDto(0.20, "low", "rest")
        );
        DemandResponse resp = new DemandResponse(Instant.now(), "now", UserType.RIDER, zones);
        when(demandService.getCurrentDemand(UserType.RIDER)).thenReturn(resp);

        mockMvc.perform(get("/demand/now").param("userType", "rider"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.window").value("now"))
                .andExpect(jsonPath("$.userType").value("rider"))
                .andExpect(jsonPath("$.zones.A.level").value("high"))
                .andExpect(jsonPath("$.zones.B.action").value("stay ready"));
    }

    @Test
    public void testNext2hEndpointForFood() throws Exception {
        Map<String, DriverDemandDto> zones = Map.of(
                "A", new DriverDemandDto(0.58, "med", "stay ready"),
                "B", new DriverDemandDto(0.76, "high", "go now"),
                "C", new DriverDemandDto(0.22, "low", "rest")
        );
        DemandResponse resp = new DemandResponse(Instant.now(), "next2h", UserType.FOOD, zones);
        when(demandService.getNext2HoursDemand(UserType.FOOD)).thenReturn(resp);

        mockMvc.perform(get("/demand/next2h").param("userType", "food"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.window").value("next2h"))
                .andExpect(jsonPath("$.userType").value("food"))
                .andExpect(jsonPath("$.zones.B.level").value("high"))
                .andExpect(jsonPath("$.zones.B.action").value("go now"));
    }
}
