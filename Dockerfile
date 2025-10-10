# ===== BUILD =====
FROM eclipse-temurin:24-jdk AS build
WORKDIR /app

# 1) Copier uniquement les fichiers qui influencent la résolution des deps
COPY gradlew gradlew
COPY gradle gradle
COPY settings.gradle.kts settings.gradle.kts
COPY build.gradle.kts build.gradle.kts

# 2) Perms + warm-up des dépendances avec cache Gradle
#    (nécessite BuildKit activé — par défaut sur Docker récent)
RUN chmod +x gradlew
# Cache Gradle (évite de re-télécharger à chaque build)
RUN --mount=type=cache,target=/root/.gradle ./gradlew -g /root/.gradle \
    dependencies --no-daemon || true

# 3) Copier les sources seulement maintenant (pour préserver le cache deps)
COPY src src

# 4) Build rapide (réutilise le cache Gradle)
RUN --mount=type=cache,target=/root/.gradle ./gradlew -g /root/.gradle \
    clean bootJar --no-daemon --stacktrace --info

# ===== RUNTIME =====
FROM eclipse-temurin:24-jre
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar

ENV SPRING_PROFILES_ACTIVE=docker
EXPOSE 8081
ENTRYPOINT ["java","-jar","app.jar"]
