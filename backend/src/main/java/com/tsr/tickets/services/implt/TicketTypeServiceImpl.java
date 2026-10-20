package com.tsr.tickets.services.implt;

import com.tsr.tickets.domain.entity.Ticket;
import com.tsr.tickets.domain.entity.TicketStatusEnum;
import com.tsr.tickets.domain.entity.TicketType;
import com.tsr.tickets.domain.entity.User;
import com.tsr.tickets.exceptions.TicketSoldOutException;
import com.tsr.tickets.exceptions.TicketTypeNotFoundException;
import com.tsr.tickets.exceptions.UserNotFoundException;
import com.tsr.tickets.repository.TicketRepository;
import com.tsr.tickets.repository.TicketTypeRepository;
import com.tsr.tickets.repository.UserRepository;
import com.tsr.tickets.services.QrCodeService;
import com.tsr.tickets.services.TicketTypeService;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.UUID;
@Service
@RequiredArgsConstructor
public class TicketTypeServiceImpl implements TicketTypeService {

    private final UserRepository userRepository;
    private final TicketRepository ticketRepository;
    private final TicketTypeRepository ticketTypeRepository;
    private final QrCodeService qrCodeService;

    @Override
    @Transactional
    public Ticket purchaseTicket(UUID userId, UUID ticketTypeId) {
        User user = userRepository.findById(userId).orElseThrow(() -> new UserNotFoundException(
                String.format("User with ID %s was not found", userId)
        ));
        TicketType ticketType = ticketTypeRepository.findByIdWithLock(ticketTypeId).orElseThrow(() -> new TicketTypeNotFoundException(
                String.format("Ticket type with ID %s was not found", ticketTypeId)
        ));

        int purchasedTickets = ticketRepository.countByTicketTypeId(ticketType.getId());
        Integer totalAvailable = ticketType.getTotalAvailable();

        if(purchasedTickets +1 > totalAvailable){
            throw new TicketSoldOutException();
        }

        Ticket ticket = new Ticket();
        ticket.setStatus(TicketStatusEnum.PURCHASED);
        ticket.setTicketType(ticketType);
        ticket.setPurchaser(user);

        Ticket savedTicket = ticketRepository.save(ticket);
        qrCodeService.generateQrCode(savedTicket);

        return ticketRepository.save(savedTicket);
    }
}
