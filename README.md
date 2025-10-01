# 1) 빌드(멀티스테이지: Gradle 빌드 → 런타임 이미지)
docker compose build bspay

# 2) 전체 기동(MySQL, Kafka, bspay)
docker compose up -d

# 3) 테스트(게이트웨이 경유)
curl -X POST http://localhost:8080/api/orders \
-H "Content-Type: application/json" \
-d '{"userId":1,"amount":129900}'