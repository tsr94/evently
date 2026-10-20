package com.tsr.tickets.services.implt;

import com.tsr.tickets.domain.UpdateEventRequest;
import com.tsr.tickets.domain.UpdateTicketTypeRequest;
import com.tsr.tickets.domain.entity.Event;
import com.tsr.tickets.domain.entity.EventStatusEnum;
import com.tsr.tickets.domain.entity.TicketType;
import com.tsr.tickets.domain.entity.User;
import com.tsr.tickets.domain.CreateEventRequest;
import com.tsr.tickets.exceptions.EventNotFoundException;
import com.tsr.tickets.exceptions.EventUpdateException;
import com.tsr.tickets.exceptions.TicketTypeNotFoundException;
import com.tsr.tickets.exceptions.UserNotFoundException;
import com.tsr.tickets.repository.EventRepository;
import com.tsr.tickets.repository.UserRepository;
import com.tsr.tickets.services.EventService;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class EventServiceImpl implements EventService {

    private final UserRepository userRepository;
    private final EventRepository eventRepository;

    @Override
    public Event createEvent(UUID organizerId, CreateEventRequest event) {
        User organizer = userRepository.findById(organizerId).orElseThrow(()-> new UserNotFoundException(
           String.format("User with ID '%s' not found",organizerId))
        );

        Event eventToCreate = new Event();

        List<TicketType> ticketTypesToCreate = event.getTicketTypes().stream().map(ticketType->{
            TicketType ticketTypeToCreate = new TicketType();
            ticketTypeToCreate.setName(ticketType.getName());
            ticketTypeToCreate.setPrice(ticketType.getPrice());
            ticketTypeToCreate.setTotalAvailable(ticketType.getTotalAvailable());
            ticketTypeToCreate.setDescription(ticketType.getDescription());
            ticketTypeToCreate.setEvent(eventToCreate);
            return ticketTypeToCreate;
        }).toList();


        eventToCreate.setName(event.getName());
        eventToCreate.setStart(event.getStart());
        eventToCreate.setEnd(event.getEnd());
        eventToCreate.setVenue(event.getVenue());
        eventToCreate.setSalesStart(event.getSalesStart());
        eventToCreate.setSalesEnd(event.getSalesEnd());
        eventToCreate.setStatus(event.getStatus());
        eventToCreate.setOrganizer(organizer);
        eventToCreate.setTicketTypes(ticketTypesToCreate);
        return eventRepository.save(eventToCreate);
    }

    @Override
    public Page<Event> listEventsForOrganizer(UUID organizerId, Pageable pageable) {

        return eventRepository.findByOrganizerId(organizerId,pageable);
    }

    @Override
    public Optional<Event> getEventForOrganizer(UUID organizerId, UUID id) {
        return eventRepository.findByIdAndOrganizerId(id,organizerId);
    }

    @Override
    @Transactional // for multiple db changes occuring in this particular service -> treated as on transaction
    public Event updateEventForOrganizer(UUID organizerId, UUID id, UpdateEventRequest event) {
        if(null == event.getId()) {
            throw new EventUpdateException("Event ID cannot be null");
        }

        if(!id.equals(event.getId())) {
            throw new EventUpdateException("Cannot update the ID of an event");
        }

        Event existingEvent = eventRepository.findByIdAndOrganizerId(id, organizerId)
                .orElseThrow(()->new EventNotFoundException(String.format("Event with ID '%s' does not exist", id)));

        existingEvent.setName(event.getName());
        existingEvent.setStart(event.getStart());
        existingEvent.setEnd(event.getEnd());
        existingEvent.setVenue(event.getVenue());
        existingEvent.setSalesStart(event.getSalesStart());
        existingEvent.setSalesEnd(event.getSalesEnd());
        existingEvent.setStatus(event.getStatus());

        // Get IDs of ticket types present in the update request (ignores new ticket types with null ID).
        Set<UUID> requestTicketTypeIds = event.getTicketTypes()
                .stream()
                .map(UpdateTicketTypeRequest::getId) // Extract ticket type ID from each request.
                .filter(Objects::nonNull)             // Keep only existing ticket types.
                .collect(Collectors.toSet());        // Store IDs in a Set for quick lookup.

    // Remove existing ticket types that are missing from the update request.
        existingEvent.getTicketTypes().removeIf(existingTicketType ->
                !requestTicketTypeIds.contains(existingTicketType.getId()));

   // Create a Map: TicketType ID → existing TicketType object.
        Map<UUID, TicketType> existingTicketTypesIndex = existingEvent.getTicketTypes()
                .stream()
                .collect(Collectors.toMap(
                        TicketType::getId,      // Use TicketType ID as the Map key.
                        Function.identity()     // Use the TicketType object as the Map value.
                ));

   // Process every ticket type received in the update request.
        for (UpdateTicketTypeRequest ticketType : event.getTicketTypes()) {

            // No ID means this is a new ticket type → CREATE.
            if (null == ticketType.getId()) {

                TicketType ticketTypeToCreate = new TicketType();

                // Copy request data into the new TicketType entity.
                ticketTypeToCreate.setName(ticketType.getName());
                ticketTypeToCreate.setPrice(ticketType.getPrice());
                ticketTypeToCreate.setDescription(ticketType.getDescription());
                ticketTypeToCreate.setTotalAvailable(ticketType.getTotalAvailable());

                // Associate the new ticket type with the existing event.
                ticketTypeToCreate.setEvent(existingEvent);

                // Add the new ticket type to the event's collection.
                existingEvent.getTicketTypes().add(ticketTypeToCreate);

                // ID exists and belongs to this event → UPDATE.
            } else if (existingTicketTypesIndex.containsKey(ticketType.getId())) {

                // Find the existing TicketType object using its ID.
                TicketType existingTicketType =
                        existingTicketTypesIndex.get(ticketType.getId());

                // Update the existing TicketType with the new values.
                existingTicketType.setName(ticketType.getName());
                existingTicketType.setPrice(ticketType.getPrice());
                existingTicketType.setDescription(ticketType.getDescription());
                existingTicketType.setTotalAvailable(ticketType.getTotalAvailable());

                // ID exists but does not belong to this event → ERROR.
            } else {
                throw new TicketTypeNotFoundException(
                        String.format(
                                "Ticket type with ID '%s' does not exist",
                                ticketType.getId()
                        )
                );
            }
        }

// Save the event and its ticket type changes.
        return eventRepository.save(existingEvent);
    }

    @Override
    @Transactional
    public void deleteEventForOrganizer(UUID organizerId, UUID id) {

        Optional<Event> event = getEventForOrganizer(organizerId,id);

        event.ifPresent(eventRepository::delete);//call delete method of eventRepo.. , event will be passed automatically.
        // shorthand for event.ifPresent(event->eventRepository.delete(event));

    }

    @Override
    public Page<Event> listPublishedEvents(Pageable pageable) {
        return eventRepository.findByStatus(EventStatusEnum.PUBLISHED, pageable);
    }

    @Override
    public Page<Event> searchPublishedEvents(String query, Pageable pageable) {
        return eventRepository.searchEvents(query, pageable);
    }

    @Override
    public Optional<Event> getPublishedEvent(UUID id) {
        // Only return events that are both published and match the ID
        return eventRepository.findByIdAndStatus(id,EventStatusEnum.PUBLISHED);
    }
}
