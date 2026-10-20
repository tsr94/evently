package com.tsr.tickets.domain.dtos;

import com.tsr.tickets.domain.entity.EventStatusEnum;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ListEventTicketTypeResponseDto {
    private UUID id;
    private String name;
    private Double price;
    private String description;
    private Integer totalAvailable;

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class UpdateEventResponseDto {

        private UUID id;
        private String name;
        private LocalDateTime start;
        private LocalDateTime end;
        private String venue;
        private LocalDateTime salesStart;
        private LocalDateTime salesEnd;
        private EventStatusEnum status;
        private List<GetEventDetailsTicketTypesResponseDto.UpdateTicketTypeResponseDto> ticketTypes;
        private LocalDateTime createdAt;
        private LocalDateTime updatedAt;
    }
}
