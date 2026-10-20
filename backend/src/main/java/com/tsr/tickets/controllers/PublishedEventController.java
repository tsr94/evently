package com.tsr.tickets.controllers;

import com.tsr.tickets.domain.dtos.GetPublishedEventDetailsResponseDto;
import com.tsr.tickets.domain.dtos.ListPublishedEventResponseDto;
import com.tsr.tickets.domain.entity.Event;
import com.tsr.tickets.mappers.EventMapper;
import com.tsr.tickets.services.EventService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping(path = "/api/v1/published-events")
@RequiredArgsConstructor
public class PublishedEventController {

    private final EventService eventService;
    private final EventMapper eventMapper;

    @GetMapping
    public ResponseEntity<Page<ListPublishedEventResponseDto>> listPublishedEvents(
            @RequestParam(required = false) String q, Pageable pageable) {

        Page<Event> events;
        if(q != null && !q.trim().isEmpty()){
            events = eventService.searchPublishedEvents(q,pageable);
        }else{
            events = eventService.listPublishedEvents(pageable);
        }
        // Map the events to DTOs and return them in the response
        return ResponseEntity.ok(events.map(eventMapper::toListPublishedEventResponseDto));
    }

    @GetMapping(path = "/{eventId}")
    public ResponseEntity<GetPublishedEventDetailsResponseDto> getPublishEventDetail(@PathVariable UUID eventId){

        return eventService.getPublishedEvent(eventId)
                .map(eventMapper::toGetPublishedEventDetailsResponseDto)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

}