package com.sunra.showroom.common.health;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** GET /api/health - quick check that the backend can reach MySQL. */
@RestController
@RequestMapping("/api/health")
@RequiredArgsConstructor
public class HealthController {

    private final JdbcTemplate jdbcTemplate;

    @GetMapping
    public Map<String, Object> health() {
        Map<String, Object> body = new LinkedHashMap<>();
        try {
            String version = jdbcTemplate.queryForObject("SELECT VERSION()", String.class);
            String database = jdbcTemplate.queryForObject("SELECT DATABASE()", String.class);
            Integer tables = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM information_schema.tables "
                            + "WHERE table_schema = DATABASE() AND table_name <> 'flyway_schema_history'",
                    Integer.class);
            List<String> migrations = jdbcTemplate.queryForList(
                    "SELECT script FROM flyway_schema_history WHERE success = 1 ORDER BY installed_rank",
                    String.class);

            body.put("status", "UP");
            body.put("database", database);
            body.put("mysqlVersion", version);
            body.put("tables", tables);
            body.put("migrations", migrations);
        } catch (Exception e) {
            body.put("status", "DOWN");
            body.put("error", e.getMessage());
        }
        return body;
    }
}
