# -------- Build stage --------
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

COPY pom.xml .
COPY src ./src

# build WAR (skip test cho nhanh)
RUN mvn -q -DskipTests package

# -------- Runtime stage --------
FROM tomcat:10.1-jdk17-temurin

# Remove default apps
RUN rm -rf /usr/local/tomcat/webapps/*

# Deploy WAR as ROOT
COPY --from=build /app/target/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080