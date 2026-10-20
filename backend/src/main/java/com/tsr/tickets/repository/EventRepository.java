package com.tsr.tickets.repository;

import com.tsr.tickets.domain.entity.Event;
import com.tsr.tickets.domain.entity.EventStatusEnum;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

public interface EventRepository extends JpaRepository<Event,UUID> {
    // Spring Data JPA will generate the implementation based on the method name. Pageable is a metadata abot page
    Page<Event> findByOrganizerId(UUID organizerId, Pageable pageable);
    Optional<Event> findByIdAndOrganizerId(UUID id, UUID organizerId);
    Page<Event> findByStatus(EventStatusEnum eventStatusEnum, Pageable pageable);
    Optional<Event> findByIdAndStatus(UUID id, EventStatusEnum status);
    @Query(value = "SELECT * FROM events WHERE " +
            "status = 'PUBLISHED' AND " +
            "to_tsvector('english', COALESCE(name, '') || ' ' || COALESCE(venue, '')) " +
            "@@ plainto_tsquery('english', :searchTerm)",
            countQuery = "SELECT count(*) FROM events WHERE " +
                    "status = 'PUBLISHED' AND " +
                    "to_tsvector('english', COALESCE(name, '') || ' ' || COALESCE(venue, '')) " +
                    "@@ plainto_tsquery('english', :searchTerm)",
            nativeQuery = true)
    Page<Event> searchEvents(@Param("searchTerm") String searchTerm, Pageable pageable);
}
/*
 Instead of returning a raw Event (which could be null if no match is found), it returns an Optional container.
 This forces the calling service to explicitly handle the possibility that the event does not exist, protecting
 your app from NullPointerException crashes
 */
/*
query
User
  │
  │ searches "Spring Boot"
  ▼
Frontend
  │
  │ GET /events/search?searchTerm=Spring Boot
  ▼
Spring Controller
  │
  ▼
Service
  │
  ▼
Repository
  │
  │ searchEvents("Spring Boot", pageable)
  ▼
PostgreSQL
  │
  ├── Only PUBLISHED events
  │
  ├── Combine name + venue
  │
  ├── Convert text → tsvector
  │
  ├── Convert search → tsquery
  │
  ├── Compare using @@
  │
  └── Return matching events
  ▼
Page<Event>
  │
  ▼
Frontend

"Give me a paginated list of published events whose name or venue matches the
 user's search text using PostgreSQL's English full-text search."
 */