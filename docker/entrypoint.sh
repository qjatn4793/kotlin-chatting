#!/usr/bin/env bash
set -euo pipefail

# 종료 시 자식 프로세스 모두 정리
cleanup() {
  echo "[bspay] shutting down..."
  pkill -P $$ || true
  wait || true
}
trap cleanup SIGTERM SIGINT EXIT

# ====== 환경변수 기본값 ======
: "${JAVA_OPTS:=}"
: "${SPRING_PROFILES_ACTIVE:=docker}"

# 포트
: "${GATEWAY_PORT:=8080}"
: "${ORDER_CMD_PORT:=8081}"
: "${PAYMENT_PORT:=8082}"
: "${ORDER_QRY_PORT:=8083}"

# DB (order-command, order-query가 사용)
: "${DB_HOST:=mysql}"
: "${DB_PORT:=3306}"
: "${DB_NAME:=ops}"
: "${DB_USER:=root}"
: "${DB_PASS:=root}"

# Kafka (추후 이벤트 방식으로 전환할 때 사용)
: "${KAFKA_BOOTSTRAP_SERVERS:=kafka:9092}"

echo "[bspay] starting services..."
echo "        profile=${SPRING_PROFILES_ACTIVE}"
echo "        db=jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}"
echo "        kafka=${KAFKA_BOOTSTRAP_SERVERS}"
echo "        logs=${LOG_DIR}"

# ====== payment ======
java $JAVA_OPTS -jar /app/payment.jar \
  --server.port=${PAYMENT_PORT} \
  --spring.profiles.active=${SPRING_PROFILES_ACTIVE} \
  --spring.kafka.bootstrap-servers=${KAFKA_BOOTSTRAP_SERVERS} \
  2>&1 | tee -a "$LOG_DIR/payment.log" &
PAYMENT_PID=$!
echo "[bspay] payment started pid=${PAYMENT_PID} port=${PAYMENT_PORT}"

# ====== order-command ======
java $JAVA_OPTS -jar /app/order-command.jar \
  --server.port=${ORDER_CMD_PORT} \
  --spring.profiles.active=${SPRING_PROFILES_ACTIVE} \
  --spring.datasource.url=jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC \
  --spring.datasource.username=${DB_USER} \
  --spring.datasource.password=${DB_PASS} \
  --spring.kafka.bootstrap-servers=${KAFKA_BOOTSTRAP_SERVERS} \
  2>&1 | tee -a "$LOG_DIR/order-command.log" &
ORDER_CMD_PID=$!
echo "[bspay] order-command started pid=${ORDER_CMD_PID} port=${ORDER_CMD_PORT}"

# ====== order-query ======
java $JAVA_OPTS -jar /app/order-query.jar \
  --server.port=${ORDER_QRY_PORT} \
  --spring.profiles.active=${SPRING_PROFILES_ACTIVE} \
  --spring.datasource.url=jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC \
  --spring.datasource.username=${DB_USER} \
  --spring.datasource.password=${DB_PASS} \
  --spring.kafka.bootstrap-servers=${KAFKA_BOOTSTRAP_SERVERS} \
  2>&1 | tee -a "$LOG_DIR/order-query.log" &
ORDER_QRY_PID=$!
echo "[bspay] order-query started pid=${ORDER_QRY_PID} port=${ORDER_QRY_PORT}"

# ====== gateway ======
java $JAVA_OPTS -jar /app/gateway.jar \
  --server.port=${GATEWAY_PORT} \
  --spring.profiles.active=${SPRING_PROFILES_ACTIVE} \
  --spring.cloud.gateway.routes[0].id=order \
  --spring.cloud.gateway.routes[0].uri=http://localhost:${ORDER_CMD_PORT} \
  --spring.cloud.gateway.routes[0].predicates[0]=Path=/api/orders/** \
  --spring.cloud.gateway.routes[0].filters[0]=StripPrefix=1 \
  --spring.cloud.gateway.routes[1].id=payment \
  --spring.cloud.gateway.routes[1].uri=http://localhost:${PAYMENT_PORT} \
  --spring.cloud.gateway.routes[1].predicates[0]=Path=/api/payments/** \
  --spring.cloud.gateway.routes[1].filters[0]=StripPrefix=1 \
  --spring.cloud.gateway.routes[2].id=query \
  --spring.cloud.gateway.routes[2].uri=http://localhost:${ORDER_QRY_PORT} \
  --spring.cloud.gateway.routes[2].predicates[0]=Path=/api/query/** \
  --spring.cloud.gateway.routes[2].filters[0]=StripPrefix=1 \
  2>&1 | tee -a "$LOG_DIR/gateway.log" &
GATEWAY_PID=$!
echo "[bspay] gateway started pid=${GATEWAY_PID} port=${GATEWAY_PORT}"

# 가장 먼저 종료되는 프로세스를 기다렸다가 전체 종료
wait -n
