package com.tsr.tickets.repository;

import com.tsr.tickets.domain.entity.TicketValidation;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface TicketValidationRepository extends JpaRepository<TicketValidation, UUID> {
}
