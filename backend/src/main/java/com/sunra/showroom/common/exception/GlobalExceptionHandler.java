package com.sunra.showroom.common.exception;

import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Maps database errors to clean HTTP responses.
 *
 * Stored procedures should raise business errors with:
 *   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock for product 3';
 * That message is returned to the frontend as a 400.
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final String BUSINESS_RULE_SQLSTATE = "45000";

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> fields = new LinkedHashMap<>();
        for (FieldError fe : ex.getBindingResult().getFieldErrors()) {
            fields.put(fe.getField(), fe.getDefaultMessage());
        }
        return ResponseEntity.badRequest()
                .body(ApiError.of(400, "Validation failed", "One or more fields are invalid", fields));
    }

    @ExceptionHandler(DataAccessException.class)
    public ResponseEntity<ApiError> handleDataAccess(DataAccessException ex) {
        SQLException sql = findSqlException(ex);

        // SIGNAL SQLSTATE '45000' from a stored procedure or trigger
        if (sql != null && BUSINESS_RULE_SQLSTATE.equals(sql.getSQLState())) {
            return ResponseEntity.badRequest()
                    .body(ApiError.of(400, "Business rule violated", sql.getMessage()));
        }

        // UNIQUE / FK / CHECK constraint violations
        if (ex instanceof DataIntegrityViolationException) {
            String msg = sql != null ? sql.getMessage() : ex.getMostSpecificCause().getMessage();
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(ApiError.of(409, "Data integrity violation", msg));
        }

        log.error("Database error", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiError.of(500, "Database error", "Unexpected database error"));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiError> handleIllegalArgument(IllegalArgumentException ex) {
        return ResponseEntity.badRequest().body(ApiError.of(400, "Bad request", ex.getMessage()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> handleOther(Exception ex) {
        log.error("Unhandled error", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiError.of(500, "Internal error", "Something went wrong"));
    }

    private SQLException findSqlException(Throwable t) {
        while (t != null) {
            if (t instanceof SQLException s) {
                return s;
            }
            t = t.getCause();
        }
        return null;
    }
}
