# -------------------------------------------------------
# Stage 1: Build Java WAR using Maven
# -------------------------------------------------------
FROM maven:3.9.9-eclipse-temurin-21-jammy AS build

WORKDIR /app

# Copy only the build descriptor first (caching dependencies)
COPY pom.xml .

RUN mvn -B dependency:resolve dependency:resolve-plugins

# Copy source code
COPY src ./src

# Build WAR
RUN mvn -B -DskipTests clean package


# -------------------------------------------------------
# Stage 2: Secure Tomcat Runtime
# -------------------------------------------------------
FROM tomcat:10.1-jdk21-temurin-jammy

LABEL org.opencontainers.image.title="vProfile App" \
      org.opencontainers.image.description="Secure Java Tomcat container for vProfile" \
      org.opencontainers.image.vendor="vProfile" \
      org.opencontainers.image.licenses="Apache-2.0"

# Remove default apps to reduce attack surface
RUN rm -rf /usr/local/tomcat/webapps/*

# Create a non-root user for Tomcat
RUN groupadd -r appgroup && useradd -r -g appgroup -d /usr/local/tomcat -s /bin/false appuser

# Set working directory
WORKDIR /usr/local/tomcat/webapps

# Copy WAR from builder and give appuser ownership
COPY --from=build /app/target/vprofile-v2.war ./ROOT.war
RUN chown -R appuser:appgroup /usr/local/tomcat

# Switch to non-root user
USER appuser

# Expose Tomcat port
EXPOSE 8080

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -q -O - http://localhost:8080/ || exit 1

# Start Tomcat in the foreground (Docker-friendly)
CMD ["catalina.sh", "run"]
