package com.sunra.showroom.common.db;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Sets MySQL session variables that triggers read (audit log, stock movement).
 *
 * Call setAppUser(...) as the FIRST line inside any @Transactional service
 * method that writes data, so the trigger sees who made the change:
 *
 *   @Transactional
 *   public void createSale(...) {
 *       dbSessionContext.setAppUser(currentUserId);
 *       ... call sp_create_sale ...
 *   }
 *
 * It must run inside the same transaction, otherwise the connection pool may
 * hand the variable to a different request.
 */
@Component
@RequiredArgsConstructor
public class DbSessionContext {

    private final JdbcTemplate jdbcTemplate;

    @Transactional(propagation = Propagation.MANDATORY)
    public void setAppUser(Integer userId) {
        jdbcTemplate.update("SET @app_user_id = ?", userId);
    }
}
