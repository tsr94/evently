package com.tsr.tickets.mappers;

import com.tsr.tickets.domain.CreateEventRequest;
import com.tsr.tickets.domain.CreateTicketTypeRequest;
import com.tsr.tickets.domain.UpdateEventRequest;
import com.tsr.tickets.domain.UpdateTicketTypeRequest;
import com.tsr.tickets.domain.dtos.*;
import com.tsr.tickets.domain.entity.Event;
import com.tsr.tickets.domain.entity.TicketType;
import org.mapstruct.Mapper;
import org.mapstruct.ReportingPolicy;

// MapStruct generates the implementation and registers the mapper as a Spring bean.
// Ignores target fields that are not explicitly mapped.
@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface EventMapper {

    // Converts ticket type DTO to service-layer request
    CreateTicketTypeRequest fromDto(CreateTicketTypeRequestDto dto);

    // Converts event DTO to service-layer request
    CreateEventRequest fromDto(CreateEventRequestDto dto);

    // Converts Event entity after we created to response DTO
    CreateEventResponseDto toDto(Event event);

    ListEventTicketTypeResponseDto toDto(TicketType ticketType);

    ListEventResponseDto toListEventResponseDto(Event event);

    GetEventDetailsTicketTypesResponseDto toGetEventDetailsTicketTypesResponseDto(TicketType ticketType);

    GetEventDetailsResponseDto toGetEventDetailsResponseDto(Event event);

    UpdateTicketTypeRequest fromDto(UpdateTicketTypeRequestDto dto);

    UpdateEventRequest fromDto(UpdateEventRequestDto dto);

    GetEventDetailsTicketTypesResponseDto.UpdateTicketTypeResponseDto toUpdateTicketTypeResponseDto(TicketType ticketType);

    ListEventTicketTypeResponseDto.UpdateEventResponseDto toUpdateEventResponseDto(Event event);

    ListPublishedEventResponseDto toListPublishedEventResponseDto(Event event);

    GetPublishedEventDetailsTicketTypesResponseDto toGetPublishedEventDetailsTicketTypesResponseDto(TicketType ticketType);

    GetPublishedEventDetailsResponseDto toGetPublishedEventDetailsResponseDto(Event event);
}