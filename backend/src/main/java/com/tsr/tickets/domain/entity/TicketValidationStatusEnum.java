package com.tsr.tickets.domain.entity;

public enum TicketValidationStatusEnum {
    VALID, // Ticket is valid and can be used for entry
    INVALID, // Ticket is invalid and cannot be used for entry
    EXPIRED // Ticket has expired and can no longer be used for entry
}
