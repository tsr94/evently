package com.tsr.tickets.controllers;

import com.tsr.tickets.domain.dtos.ErrorDto;
import com.tsr.tickets.exceptions.*;
import jakarta.validation.ConstraintViolationException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.List;

// Tells Spring that this class handles exceptions globally
// for all REST controllers in the application.
@RestControllerAdvice

// Lombok creates a logger called "log" for this class.
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(TicketNotFoundException.class)
    public ResponseEntity<ErrorDto> handleTicketNotFoundException(TicketNotFoundException ex) {
        log.error("Caught TicketNotFoundException.class\n", ex);
        ErrorDto errorDto = new ErrorDto();
        errorDto.setError("Ticket not found");
        return new ResponseEntity<>(errorDto, HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(TicketSoldOutException.class)
    public ResponseEntity<ErrorDto> handleTicketSoldOutException(TicketSoldOutException ex) {
        log.error("Caught TicketSoldOutException.class\n", ex);
        ErrorDto errorDto = new ErrorDto();
        errorDto.setError("Tickets are sold out for this ticket type");
        return new ResponseEntity<>(errorDto, HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(QrCodeNotFoundException.class)
    public ResponseEntity<ErrorDto> handleQrCodeNotFoundException(QrCodeNotFoundException ex) {
        log.error("Caught QrCodeNotFoundException", ex);
        ErrorDto errorDto = new ErrorDto();
        errorDto.setError("QR Code not found");
        return new ResponseEntity<>(errorDto, HttpStatus.INTERNAL_SERVER_ERROR);
    }


    @ExceptionHandler(QrCodeGenerationException.class)
    public ResponseEntity<ErrorDto> handleQrCodeGenerationException(QrCodeGenerationException ex) {
        log.error("Caught QrCodeGenerationException", ex);
        ErrorDto errorDto = new ErrorDto();
        errorDto.setError("Unable to generate QR Code");
        return new ResponseEntity<>(errorDto, HttpStatus.INTERNAL_SERVER_ERROR);
    }

    @ExceptionHandler(EventUpdateException.class)
    public ResponseEntity<ErrorDto> handleEventUpdateException(EventUpdateException ex) {
        log.error("Caught EventUpdateException", ex);
        ErrorDto errorDto = new ErrorDto();
        errorDto.setError("Unable to update event");
        return new ResponseEntity<>(errorDto, HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(TicketTypeNotFoundException.class)
    public ResponseEntity<ErrorDto> handleTicketTypeNotFoundException(TicketTypeNotFoundException ex) {
        log.error("Caught TicketTypeNotFoundException", ex);
        ErrorDto errorDto = new ErrorDto();
        errorDto.setError("Ticket type not found");
        return new ResponseEntity<>(errorDto, HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(EventNotFoundException.class)
    public ResponseEntity<ErrorDto> handleEventNotFoundException(EventNotFoundException ex) {
        log.error("Caught EventNotFoundException", ex);
        ErrorDto errorDto = new ErrorDto();
        errorDto.setError("Event not found");
        return new ResponseEntity<>(errorDto, HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<ErrorDto> handleUserNotFoundException(UserNotFoundException ex) {
        log.error("Caught UserNotFoundException", ex);
        ErrorDto errorDto = new ErrorDto();
        errorDto.setError("User not found");
        return new ResponseEntity<>(errorDto, HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorDto> handleMethodArgumentNotValidException(
            MethodArgumentNotValidException ex
    ) {
        // Log the validation exception for debugging.
        log.error("Caught MethodArgumentNotValidException", ex);

        // Create the object that will be sent back to the client.
        ErrorDto errorDto = new ErrorDto();

        // Get the validation result from the exception.
        // It contains information about which fields failed validation.
        BindingResult bindingResult = ex.getBindingResult();

        // Get all fields that failed validation.
        List<FieldError> fieldErrors = bindingResult.getFieldErrors();

        // Take the first validation error.
        String errorMessage = fieldErrors.stream()
                .findFirst()

                // Create a readable message:
                // fieldName: validation message
                .map(fieldError ->
                        fieldError.getField()
                                + ": "
                                + fieldError.getDefaultMessage()
                )

                // Fallback message if no field error is available.
                .orElse("Validation error occurred");

        // Put the validation message into the response DTO.
        errorDto.setError(errorMessage);

        // Return HTTP 400 Bad Request because
        // the client sent invalid data.
        return new ResponseEntity<>(
                errorDto,
                HttpStatus.BAD_REQUEST
        );
    }

    // Tells Spring to call this method whenever
    // a ConstraintViolationException occurs.
    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ErrorDto> handleConstraintViolation(
            ConstraintViolationException ex
    ) {

        // Logs the exception details for debugging/monitoring.
        log.error("Caught ConstraintViolationException", ex);

        // Create an object that will be returned
        // as the error response.
        ErrorDto errorDto = new ErrorDto();

        // Get all validation errors and take the first one.
        String errorMessage = ex.getConstraintViolations()
                .stream()
                .findFirst()

                // Build a readable error message:
                // fieldName: validation message
                .map(violation ->
                        violation.getPropertyPath() + ": "
                                + violation.getMessage()
                )

                // Use this message if no validation error was found.
                .orElse("Constraint violation occurred");

        // Put the error message into our response DTO.
        errorDto.setError(errorMessage);

        // Return the error response with HTTP 400 Bad Request.
        return new ResponseEntity<>(
                errorDto,
                HttpStatus.BAD_REQUEST
        );
    }


    // Handles any other exception that was not handled
    // by a more specific @ExceptionHandler.
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorDto> handleException(Exception ex) {

        // Log the actual exception so developers can investigate it.
        log.error("Caught exception", ex);

        // Create an object for the error response.
        ErrorDto errorDto = new ErrorDto();

        // Don't expose internal exception details to the client.
        errorDto.setError("An unknown error occurred");

        // Return HTTP 500 Internal Server Error.
        return new ResponseEntity<>(
                errorDto,
                HttpStatus.INTERNAL_SERVER_ERROR
        );
    }
}