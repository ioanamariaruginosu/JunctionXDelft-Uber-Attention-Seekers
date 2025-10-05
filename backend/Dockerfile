FROM --platform=linux/amd64 maven:3.9.6-eclipse-temurin-21 AS build
WORKDIR /app

COPY pom.xml ./
RUN mvn -q -DskipTests dependency:go-offline

COPY src ./src
RUN mvn -q -DskipTests package

# ---- Run stage ----
FROM --platform=linux/amd64 eclipse-temurin:21-jre
WORKDIR /app

# Copy everything from build stage - source, target, dependencies, etc.
COPY --from=build /app /app

EXPOSE 8080
ENTRYPOINT ["sh", "-c", "java -jar target/*.jar"]