# ===== BUILD =====
FROM eclipse-temurin:24-jdk AS build
WORKDIR /app

COPY gradlew gradlew
COPY gradle/ gradle/
COPY settings.gradle* build.gradle* ./

RUN chmod +x gradlew
RUN ./gradlew --no-daemon --version

COPY . .
RUN chmod +x gradlew
RUN ./gradlew --no-daemon clean bootJar

# ===== RUNTIME =====
FROM eclipse-temurin:24-jre
WORKDIR /app
COPY --from=build /app/build/libs/*.jar /app/app.jar
EXPOSE 8081
ENTRYPOINT ["java","-jar","/app/app.jar"]
