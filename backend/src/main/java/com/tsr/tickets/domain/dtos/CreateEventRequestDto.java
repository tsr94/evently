package com.tsr.tickets.domain.dtos;

import com.tsr.tickets.domain.entity.EventStatusEnum;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;


import java.time.LocalDateTime;
import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class CreateEventRequestDto {

    // Ensures event name is not null, empty, or whitespace
    @NotBlank(message = "Event name is required")
    private String name;

    private LocalDateTime start;
    private LocalDateTime end;

    // Ensures venue is not null, empty, or whitespace
    @NotBlank(message = "Venue information is required")
    private String venue;

    private LocalDateTime salesStart;
    private LocalDateTime salesEnd;

    // Ensures event status is provided
    @NotNull(message = "Event status must be provided")
    private EventStatusEnum status;

    // Ensures at least one ticket type is provided
    @NotEmpty(message = "At least one ticket type is required")

    // Validates each ticket type using its own validation rules
    @Valid
    private List<CreateTicketTypeRequestDto> ticketTypes;
}