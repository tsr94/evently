package com.tsr.tickets.mappers;

import com.tsr.tickets.domain.dtos.GetTicketResponseDto;
import com.tsr.tickets.domain.dtos.ListTicketResponseDto;
import com.tsr.tickets.domain.dtos.ListTicketTicketTypeResponseDto;
import com.tsr.tickets.domain.entity.Ticket;
import com.tsr.tickets.domain.entity.TicketType;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface TicketMapper {

    ListTicketTicketTypeResponseDto toListTicketTicketTypeResponseDto(TicketType ticketType);

    @Mapping(source = "ticketType.event", target = "event")
    ListTicketResponseDto toListTicketResponseDto(Ticket ticket);

    //The @Mapping annotations tell MapStruct how to navigate the relationships between our entities to get the right information.
    @Mapping(target = "price", source = "ticket.ticketType.price")
    @Mapping(target = "description", source = "ticket.ticketType.description")
    @Mapping(target = "eventName", source = "ticket.ticketType.event.name")
    @Mapping(target = "eventVenue", source = "ticket.ticketType.event.venue")
    @Mapping(target = "eventStart", source = "ticket.ticketType.event.start")
    @Mapping(target = "eventEnd", source = "ticket.ticketType.event.end")
    GetTicketResponseDto toGetTicketResponseDto(Ticket ticket);


}
