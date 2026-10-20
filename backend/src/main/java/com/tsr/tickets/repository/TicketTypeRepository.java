package com.tsr.tickets.repository;


import com.tsr.tickets.domain.entity.TicketType;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface TicketTypeRepository extends JpaRepository<TicketType, UUID> {
    @Query("SELECT tt from TicketType tt where tt.id = :id")
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    Optional<TicketType> findByIdWithLock(@Param("id") UUID id);
}

/*
Handling Concurrent Access
To prevent overselling tickets when multiple users try to purchase at the same time,
we use a pessimistic lock:
This ensures that when one user is purchasing a ticket,
other users must wait until the transaction completes before they can access
the same ticket type.
 */
