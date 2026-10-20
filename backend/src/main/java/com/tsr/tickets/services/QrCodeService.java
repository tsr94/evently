package com.tsr.tickets.services;

import com.tsr.tickets.domain.entity.QrCode;
import com.tsr.tickets.domain.entity.Ticket;
import org.springframework.stereotype.Service;

import java.util.UUID;


public interface QrCodeService {
    QrCode generateQrCode(Ticket ticket);
    byte[] getQrCodeImageForUserAndTicket(UUID userId, UUID ticketId);
}
