# ====== Build stage: Gradle로 각 모듈 bootJar 생성 ======
FROM eclipse-temurin:17-jdk AS build
WORKDIR /src

# Gradle 래퍼/설정 먼저 복사 (캐시 최적화)
COPY gradlew settings.gradle.kts build.gradle.kts ./
COPY gradle ./gradle

# Windows에서 개행/실행권한 이슈 예방
RUN sed -i 's/\r$//' gradlew && chmod +x gradlew

# 소스 복사
COPY modules ./modules

# 모듈별 JAR 빌드
RUN ./gradlew --no-daemon \
  :modules:gateway:bootJar \
  :modules:order-command:bootJar \
  :modules:payment:bootJar \
  :modules:order-query:bootJar

# ====== Runtime stage ======
FROM eclipse-temurin:17-jre
ENV TZ=Asia/Seoul
WORKDIR /app

# JAR/entrypoint
COPY --from=build /src/modules/gateway/build/libs/*-SNAPSHOT.jar       /app/gateway.jar
COPY --from=build /src/modules/order-command/build/libs/*-SNAPSHOT.jar /app/order-command.jar
COPY --from=build /src/modules/payment/build/libs/*-SNAPSHOT.jar       /app/payment.jar
COPY --from=build /src/modules/order-query/build/libs/*-SNAPSHOT.jar   /app/order-query.jar
COPY docker/entrypoint.sh /app/entrypoint.sh

# 패키지 및 유저/그룹 생성, 권한 설정 (+ HEALTHCHECK용 wget)
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends wget ca-certificates; \
    rm -rf /var/lib/apt/lists/*; \
    groupadd -r appgroup; \
    useradd  -r -g appgroup -d /app -s /usr/sbin/nologin appuser; \
    mkdir -p /app/logs; \
    chown -R appuser:appgroup /app; \
    chmod +x /app/entrypoint.sh

USER appuser
EXPOSE 8080 8081 8082 8083

# HEALTHCHECK (게이트웨이 UP 체크)
HEALTHCHECK --interval=15s --timeout=3s --retries=20 CMD \
  wget -qO- http://localhost:8080/actuator/health | grep -q '"status":"UP"' || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
