# ====== Build stage: Gradle로 각 모듈 bootJar 생성 ======
FROM eclipse-temurin:17-jdk AS build
WORKDIR /src

# Gradle 캐시 최적화를 위해 래퍼와 스크립트 먼저 복사
COPY gradlew settings.gradle.kts build.gradle.kts ./
COPY gradle ./gradle

# 소스 복사
COPY modules ./modules

# 필요한 모듈만 빌드 (이름은 실제 모듈 경로에 맞게)
RUN ./gradlew --no-daemon clean \
  :modules:gateway:bootJar \
  :modules:order-command:bootJar \
  :modules:payment:bootJar \
  :modules:order-query:bootJar

# ====== Runtime stage: 단일 컨테이너에서 4개 서비스 실행 ======
FROM eclipse-temurin:17-jre
ENV TZ=Asia/Seoul
WORKDIR /app

# JAR 배치 (출력 경로는 프로젝트에 맞게 조정 가능)
COPY --from=build /src/modules/gateway/build/libs/*-SNAPSHOT.jar      /app/gateway.jar
COPY --from=build /src/modules/order-command/build/libs/*-SNAPSHOT.jar /app/order-command.jar
COPY --from=build /src/modules/payment/build/libs/*-SNAPSHOT.jar       /app/payment.jar
COPY --from=build /src/modules/order-query/build/libs/*-SNAPSHOT.jar   /app/order-query.jar

# 엔트리포인트 스크립트
COPY docker/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh && adduser --system --home /app appuser

# 서비스 포트들(게이트웨이/오더/페이먼트/쿼리)
EXPOSE 8080 8081 8082 8083

# 간단 헬스체크(게이트웨이 기준)
HEALTHCHECK --interval=15s --timeout=3s --retries=20 CMD \
  wget -qO- http://localhost:8080/actuator/health | grep -q '"status":"UP"' || exit 1

USER appuser
ENTRYPOINT ["/app/entrypoint.sh"]
