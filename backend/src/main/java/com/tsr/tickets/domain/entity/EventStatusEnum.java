package com.tsr.tickets.domain.entity;

public enum EventStatusEnum {
    DRAFT, // Event is being created and not yet published
    PUBLISHED, // Event is published and visible to users
    CANCELLED, // Event is cancelled and no longer available
    COMPLETED // Event has taken place and is no longer active
}
