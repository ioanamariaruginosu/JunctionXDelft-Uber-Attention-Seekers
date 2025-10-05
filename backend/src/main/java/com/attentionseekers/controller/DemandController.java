// package com.attentionseekers.controller;

// import com.attentionseekers.dto.DemandResponse;
// import com.attentionseekers.service.DemandService;
// import org.springframework.http.ResponseEntity;
// import org.springframework.web.bind.annotation.GetMapping;
// import org.springframework.web.bind.annotation.RequestMapping;
// import org.springframework.web.bind.annotation.RestController;

// @RestController
// @RequestMapping("api/demand")
// public class DemandController {

//     private final DemandService demandService;

//     public DemandController(DemandService demandService) {
//         this.demandService = demandService;
//     }

//     @GetMapping("/now")
//     public ResponseEntity<DemandResponse> now() {
//         return ResponseEntity.ok(demandService.getCurrentDemand());
//     }

//     @GetMapping("/next2h")
//     public ResponseEntity<DemandResponse> next2h() {
//         return ResponseEntity.ok(demandService.getNext2HoursDemand());
//     }
// }
package com.attentionseekers.controller;

import com.attentionseekers.dto.DemandResponse;
import com.attentionseekers.service.DemandService;
import com.attentionseekers.service.UserType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

@RestController
@RequestMapping("api/demand")
public class DemandController {

    private final DemandService demandService;

    public DemandController(DemandService demandService) {
        this.demandService = demandService;
    }

    @GetMapping("/now")
    public ResponseEntity<DemandResponse> now(@RequestParam(value = "userType", required = false) String userType) {
        UserType type = parseUserType(userType);
        return ResponseEntity.ok(demandService.getCurrentDemand(type));
    }

    @GetMapping("/next2h")
    public ResponseEntity<DemandResponse> next2h(@RequestParam(value = "userType", required = false) String userType) {
        UserType type = parseUserType(userType);
        return ResponseEntity.ok(demandService.getNext2HoursDemand(type));
    }

    private UserType parseUserType(String raw) {
        try {
            return UserType.from(raw);
        } catch (IllegalArgumentException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage(), e);
        }
    }
}
