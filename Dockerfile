# ===== BUILD =====
FROM eclipse-temurin:24-jdk AS build
WORKDIR /app
COPY . .
RUN chmod +x gradlew
RUN ./gradlew clean bootJar --no-daemon --stacktrace --info
# ===== RUNTIME =====
FROM eclipse-temurin:24-jre
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar
# Profil docker garanti au runtime
ENV SPRING_PROFILES_ACTIVE=docker
EXPOSE 8081 ENTRYPOINT ["java","-jar","app.jar"]