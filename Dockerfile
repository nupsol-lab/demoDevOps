# ===== BUILD =====
FROM eclipse-temurin:24-jdk AS build
WORKDIR /app

COPY . .
RUN chmod +x gradlew
RUN ./gradlew clean bootJar --no-daemon

# ===== RUNTIME =====
FROM eclipse-temurin:24-jre
WORKDIR /app

COPY --from=build /app/build/libs/*.jar app.jar

# ✅ Force le profil docker
ENV SPRING_PROFILES_ACTIVE=docker

EXPOSE 8081
ENTRYPOINT ["java", "-jar", "app.jar"]
