package com.tsr.tickets.services.implt;

import com.tsr.tickets.domain.entity.*;
import com.tsr.tickets.exceptions.QrCodeNotFoundException;
import com.tsr.tickets.exceptions.TicketNotFoundException;
import com.tsr.tickets.repository.QrCodeRepository;
import com.tsr.tickets.repository.TicketRepository;
import com.tsr.tickets.repository.TicketValidationRepository;
import com.tsr.tickets.services.TicketValidationService;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.jetbrains.annotations.NotNull;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class TicketValidationServiceImpl implements TicketValidationService {

    private final QrCodeRepository qrCodeRepository;
    private final TicketValidationRepository ticketValidationRepository;
    private final TicketRepository ticketRepository;

    @Override
    public TicketValidation validateTicketByQrCode(UUID qrCodeId) {
        QrCode qrCode = qrCodeRepository.findByIdAndStatus(qrCodeId, QrCodeStatusEnum.ACTIVE)
                .orElseThrow(() -> new QrCodeNotFoundException(String.format(
                        "QR Code with ID %s was not found", qrCodeId
                )
                ));
        Ticket ticket = qrCode.getTicket();

        return validateTicket(ticket,TicketValidationMethod.QR_SCAN);
    }

    private TicketValidation validateTicket(Ticket ticket,TicketValidationMethod ticketValidationMethod) {
        TicketValidation ticketValidation = new TicketValidation();

        ticketValidation.setTicket(ticket);
        ticketValidation.setValidationMethod(ticketValidationMethod);
        TicketValidationStatusEnum ticketValidationStatus = ticket.getValidations().stream()
                .filter(v -> TicketValidationStatusEnum.VALID.equals(v.getStatus()))
                .findFirst()
                .map(v -> TicketValidationStatusEnum.INVALID)
                .orElse(TicketValidationStatusEnum.VALID);
        ticketValidation.setStatus(ticketValidationStatus);
        return ticketValidationRepository.save(ticketValidation);
    }

    @Override
    public TicketValidation validateTicketManually(UUID ticketId) {
        Ticket ticket = ticketRepository.findById(ticketId)
                .orElseThrow(TicketNotFoundException::new);
        return validateTicket(ticket,TicketValidationMethod.MANUAL);
    }
}
