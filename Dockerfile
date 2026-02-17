
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app

COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY gradle.properties .
COPY settings.gradle* ./


RUN ./gradlew dependencies --no-daemon -q || true


COPY src src
RUN ./gradlew shadowJar --no-daemon -q


FROM eclipse-temurin:21-jre-alpine
WORKDIR /app


RUN addgroup -g 1000 app && adduser -u 1000 -G app -D app
USER app

COPY --from=build /app/build/libs/micronaut-crud-0.1-all.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
