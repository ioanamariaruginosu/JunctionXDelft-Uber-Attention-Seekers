# ---- Build stage ----
FROM maven:3.9.6-eclipse-temurin-21 AS build
WORKDIR /app

# copy only pom first to warm the cache
COPY pom.xml ./
RUN mvn -q -DskipTests dependency:go-offline

# now copy sources and build
COPY src ./src
RUN mvn -q -DskipTests package

# ---- Run stage ----
# you can use JRE or JDK; JRE is smaller. If JRE tag isn't available for you, use 21-jdk.
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java","-jar","app.jar"]
