package com.tsr.tickets.domain.dtos;

import com.tsr.tickets.domain.entity.Event;
import com.tsr.tickets.domain.entity.TicketStatusEnum;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ListTicketResponseDto {
    private UUID id;
    private TicketStatusEnum status;
    private ListTicketTicketTypeResponseDto ticketType;
    private ListPublishedEventResponseDto event;
}
