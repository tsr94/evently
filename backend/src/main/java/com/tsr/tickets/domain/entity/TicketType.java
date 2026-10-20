package com.tsr.tickets.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

@Entity
@Getter
@Setter
@Table(name = "ticket_types")
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TicketType {
    @Id
    @Column(name = "id", nullable = false, updatable = false)
    @GeneratedValue(strategy = GenerationType.UUID)// Automatically generates a unique identifier for each ticket type using UUID
    private UUID id;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "price", nullable = false)
    private Double price;

    @Column(name = "total_available")
    private Integer totalAvailable;

    @Column(name = "description")
    private String description;

    @ManyToOne(fetch = FetchType.LAZY)// fetch type -Don't load the related data from the database until I actually need it.
    @JoinColumn(name = "event_id") // Foreign key column in the ticket_types table that references the events table
    private Event event;

    @OneToMany(mappedBy = "ticketType",cascade = CascadeType.ALL)
    private List<Ticket> tickets = new ArrayList<>();

    @CreatedDate // Automatically sets the creation timestamp when the entity is persisted for the first time
    @Column(name = "created_at", updatable = false, nullable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate // Automatically updates the timestamp whenever the entity is updated
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @Override
    public boolean equals(Object o) {
        if (o == null || getClass() != o.getClass()) return false;
        TicketType that = (TicketType) o;
        return Objects.equals(id, that.id) && Objects.equals(name, that.name) && Objects.equals(price, that.price) && Objects.equals(totalAvailable, that.totalAvailable) && Objects.equals(description, that.description) && Objects.equals(createdAt, that.createdAt) && Objects.equals(updatedAt, that.updatedAt);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, name, price, totalAvailable, description, createdAt, updatedAt);
    }
}
