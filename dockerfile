
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
# Stage 2: Tomcat Runtime (Non-root, Secure)
# -------------------------------------------------------
FROM tomcat:10.1-jdk21-temurin-jammy

LABEL org.opencontainers.image.title="vProfile App" \
      org.opencontainers.image.description="Secure Java Tomcat container for vProfile" \
      org.opencontainers.image.vendor="vProfile" \
      org.opencontainers.image.licenses="Apache-2.0"

# Clean default apps
RUN rm -rf /usr/local/tomcat/webapps/*

WORKDIR /usr/local/tomcat/webapps

# Copy WAR from builder
COPY --chown=root:root --from=build /app/target/vprofile-v2.war ./ROOT.war

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -q -O - http://localhost:8080/ || exit 1

RUN useradd -m -s /bin/false appuser
RUN chown -R root:root /usr/local/tomcat && chmod -R go+r /usr/local/tomcat

USER appuser

CMD ["catalina.sh", "run"]
