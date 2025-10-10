# ===== BUILD =====
FROM eclipse-temurin:24-jdk AS build
WORKDIR /app
COPY . .

# --- DEBUG: vérifier que les sources sont là dans l'image de build
RUN echo "== Tree of sources ==" \
 && ls -lR src/main/java/com/example/demodevops || true \

RUN chmod +x gradlew
RUN ./gradlew clean bootJar --no-daemon --stacktrace --info

# ===== RUNTIME =====
FROM eclipse-temurin:24-jre
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar

# Profil docker garanti au runtime
ENV SPRING_PROFILES_ACTIVE=docker

EXPOSE 8081
ENTRYPOINT ["java","-jar","app.jar"]
