# ==============================================================================
# Multi-stage Dockerfile for DevSecOps Java Application
# Stage 1: Build with Maven
# Stage 2: Deploy on Tomcat
# ==============================================================================

# Stage 1: Build
FROM maven:3.9.6-eclipse-temurin-17 AS builder

WORKDIR /app

# Copy pom.xml first for dependency caching
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build
COPY src ./src
RUN mvn clean package -DskipTests -B

# Stage 2: Production - Deploy on Tomcat
FROM tomcat:9.0-jdk17-temurin-jammy AS production

LABEL maintainer="fairozb"
LABEL org.opencontainers.image.source="https://github.com/fairozb/devsecops-project"
LABEL org.opencontainers.image.description="DevSecOps Application - Java Spring Boot on Tomcat"

# Remove default Tomcat webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy WAR file from builder stage
COPY --from=builder /app/target/devsecops-app.war /usr/local/tomcat/webapps/ROOT.war

# Security: Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Security: Set file permissions
RUN chown -R appuser:appuser /usr/local/tomcat/
RUN chmod -R 550 /usr/local/tomcat/conf
RUN chmod -R 770 /usr/local/tomcat/webapps /usr/local/tomcat/logs /usr/local/tomcat/temp /usr/local/tomcat/work

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=45s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Expose Tomcat port
EXPOSE 8080

# Switch to non-root user
USER appuser

# Start Tomcat
CMD ["catalina.sh", "run"]
