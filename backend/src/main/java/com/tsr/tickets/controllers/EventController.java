package com.tsr.tickets.controllers;

import com.tsr.tickets.domain.CreateEventRequest;
import com.tsr.tickets.domain.UpdateEventRequest;
import com.tsr.tickets.domain.dtos.*;
import com.tsr.tickets.domain.entity.Event;
import com.tsr.tickets.mappers.EventMapper;
import com.tsr.tickets.services.EventService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

import static com.tsr.tickets.util.JwtUtil.parseUserId;

// Marks this class as a REST API controller
@RestController

// Defines the base URL for all endpoints in this controller
@RequestMapping("/api/v1/events")


// Generates a constructor for all final fields (dependency injection)
@RequiredArgsConstructor
public class EventController {

    private final EventMapper eventMapper;
    private final EventService eventService;


    // Maps POST requests to /api/v1/events
    @PostMapping
    public ResponseEntity<CreateEventResponseDto> createEvent(

            // Gets the authenticated user's JWT token
            @AuthenticationPrincipal Jwt jwt,

            // Converts JSON request body to DTO and validates it
            @Valid @RequestBody CreateEventRequestDto createEventRequestDto) {

        // Convert DTO to service-layer request
        CreateEventRequest createEventRequest =
                eventMapper.fromDto(createEventRequestDto);

        // Extract user ID from JWT subject
        UUID userId = parseUserId(jwt);

        // Create the event through the service layer
        Event createdEvent =
                eventService.createEvent(userId, createEventRequest);

        // Convert entity to response DTO
        CreateEventResponseDto createEventResponseDto =
                eventMapper.toDto(createdEvent);

        // Return the created event with HTTP 201 Created
        return new ResponseEntity<>(
                createEventResponseDto,
                HttpStatus.CREATED
        );
    }

    // Pageable is automatically created by Spring from ?page=0&size=10 in the request.
    //URL parameters → Spring creates Pageable → Repository uses it for pagination.
    @GetMapping
    public ResponseEntity<Page<ListEventResponseDto>> listEvents(@AuthenticationPrincipal Jwt jwt, Pageable pageable){
        UUID userId = parseUserId(jwt);
        Page<Event> events = eventService.listEventsForOrganizer(userId, pageable);
        return ResponseEntity.ok(events.map(eventMapper :: toListEventResponseDto));
        //Map every Event inside the Page to a ListEventResponseDto, while keeping the pagination information.
    }

    @GetMapping(path = "/{eventId}")
    public ResponseEntity<GetEventDetailsResponseDto> getEvent(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID eventId
    ) {
        // Get the user's ID from the JWT token
        UUID userId = parseUserId(jwt);

        // Call the service layer and transform the response
        return eventService.getEventForOrganizer(userId, eventId)
                .map(eventMapper::toGetEventDetailsResponseDto)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping(path = "/{eventId}")
    public ResponseEntity<ListEventTicketTypeResponseDto.UpdateEventResponseDto> updateEvent(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID eventId,
                                                                                             @Valid @RequestBody UpdateEventRequestDto updateEventRequestDto) {
        UpdateEventRequest updateEventRequest = eventMapper.fromDto(updateEventRequestDto);
        UUID userId = parseUserId(jwt);
        Event updatedEvent = eventService.updateEventForOrganizer(userId, eventId, updateEventRequest);
        ListEventTicketTypeResponseDto.UpdateEventResponseDto updateEventResponseDto = eventMapper.toUpdateEventResponseDto(updatedEvent);

        return ResponseEntity.ok(updateEventResponseDto);
    }

    @DeleteMapping(path = "/{eventId}")
    public ResponseEntity<Void> deleteEvent(@AuthenticationPrincipal Jwt jwt,@PathVariable UUID eventId){
        UUID userId = parseUserId(jwt);
        eventService.deleteEventForOrganizer(userId,eventId);
        return ResponseEntity.noContent().build();//is used in Spring Boot to generate and return an HTTP 204 No Content status code
    }
}