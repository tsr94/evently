package com.tsr.tickets.domain.dtos;

import com.tsr.tickets.domain.entity.TicketStatusEnum;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class GetTicketResponseDto {
    private UUID id;
    private TicketStatusEnum status;
    private Double price;
    private String description;
    private String eventName;
    private String eventVenue;
    private LocalDateTime eventStart;
    private LocalDateTime eventEnd;
}
/*
The GetTicketResponseDto will combine information from the ticket, ticket type, and event entities.

Instead of nesting this information in separate objects, we'll flatten it into a single DTO for simplicity:
 */