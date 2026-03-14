package com.visualpathit.account.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.event.ContextRefreshedEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;

@Component
public class DatabaseConnectionMonitor {

    private static final Logger logger = LoggerFactory.getLogger(DatabaseConnectionMonitor.class);

    @Autowired
    private DataSource dataSource;

    @EventListener(ContextRefreshedEvent.class)
    public void checkDatabaseConnection() {
        try (Connection connection = dataSource.getConnection()) {
            if (connection.isValid(5)) {
                logger.info("DATABASE_CONNECTION_SUCCESS: Successfully connected to database - URL: {}", 
                    connection.getMetaData().getURL());
            }
        } catch (SQLException e) {
            logger.error("DATABASE_CONNECTION_FAILURE: Failed to connect to database - Error: {} - SQLState: {} - ErrorCode: {}", 
                e.getMessage(), e.getSQLState(), e.getErrorCode(), e);
        }
    }

    public boolean testConnection() {
        try (Connection connection = dataSource.getConnection()) {
            boolean valid = connection.isValid(5);
            if (valid) {
                logger.info("DATABASE_HEALTH_CHECK_SUCCESS: Database connection is healthy");
            } else {
                logger.warn("DATABASE_HEALTH_CHECK_WARNING: Database connection validation failed");
            }
            return valid;
        } catch (SQLException e) {
            logger.error("DATABASE_HEALTH_CHECK_FAILURE: Database health check failed - Error: {} - SQLState: {} - ErrorCode: {}", 
                e.getMessage(), e.getSQLState(), e.getErrorCode(), e);
            return false;
        }
    }
}
