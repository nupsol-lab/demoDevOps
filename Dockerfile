# ===== BUILD =====
FROM eclipse-temurin:24-jdk AS build
WORKDIR /app
COPY . .

# Ensure no stray CR and gradlew is executable inside the image
RUN sed -i 's/\r$//' gradlew && chmod +x gradlew
RUN ./gradlew clean bootJar --no-daemon --stacktrace --info

# ===== RUNTIME =====
FROM eclipse-temurin:24-jre
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar

ENV SPRING_PROFILES_ACTIVE=docker
EXPOSE 8081
ENTRYPOINT ["java","-jar","/app/app.jar"]
