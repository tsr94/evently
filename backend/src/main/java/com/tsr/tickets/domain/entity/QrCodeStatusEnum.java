package com.tsr.tickets.domain.entity;

public enum QrCodeStatusEnum {
    ACTIVE, // QR code is active and can be used for ticket validation
    EXPIRED // QR code has expired and can no longer be used for ticket validation
}
