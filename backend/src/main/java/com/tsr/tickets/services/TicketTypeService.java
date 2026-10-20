package com.tsr.tickets.services;

import com.tsr.tickets.domain.entity.Ticket;

import java.util.UUID;

public interface TicketTypeService {
    public Ticket purchaseTicket(UUID userId, UUID ticketTypeId);
}
