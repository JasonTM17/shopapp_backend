# ShopApp Backend

Spring Boot backend cho hệ thống ShopApp.

## Tech Stack

- Java 21+ (khuyến nghị Java 21)
- Spring Boot 3.3.x
- Maven Wrapper (`mvnw`, `mvnw.cmd`)
- MySQL 8
- Redis 7
- Kafka + Zookeeper

## Yêu Cầu Môi Trường

- Docker Desktop
- JDK 21 hoặc cao hơn
- PowerShell (Windows) hoặc terminal tương đương

## Cấu Hình Mặc Định

- Backend port: `8088`
- MySQL host/port: `localhost:3307`
- Redis host/port: `localhost:6379`
- Kafka broker: `localhost:9092`

## Chạy Dự Án (Khuyến Nghị)

### 1) Clone source

```bash
git clone <repo-url>
cd shopapp-backend
```

### 2) Chạy hạ tầng

```bash
docker compose -f deployment.yaml up -d mysql8-container redis-container
docker compose -f kafka-deployment.yaml up -d zookeeper-01 zookeeper-02 zookeeper-03 kafka-broker-01
```

### 3) Import dữ liệu mẫu

Windows PowerShell:

```powershell
Get-Content -Raw database.sql | docker exec -i mysql8-container mysql -uroot -pAbc123456789@ ShopApp
```

macOS/Linux:

```bash
docker exec -i mysql8-container mysql -uroot -pAbc123456789@ ShopApp < database.sql
```

### 4) Chạy backend

Windows:

```powershell
.\mvnw.cmd spring-boot:run
```

macOS/Linux:

```bash
./mvnw spring-boot:run
```

### 5) Kiểm tra service

```bash
curl -i http://localhost:8088/api/v1/actuator/health
```

Kết quả mong đợi: `HTTP 200` và status `UP`.

## API Tài Liệu

- Swagger UI: `http://localhost:8088/swagger-ui.html`
- OpenAPI docs: `http://localhost:8088/api-docs`

## Biến Môi Trường Quan Trọng

Bạn có thể override bằng environment variables:

- `SPRING_DATASOURCE_URL`
- `MYSQL_ROOT_PASSWORD`
- `REDIS_HOST`
- `REDIS_PORT`
- `KAFKA_BROKER_SERVER`
- `KAFKA_BROKER_PORT`
- `GOOGLE_REDIRECT_URI`
- `FACEBOOK_REDIRECT_URI`
- `VNPAY_RETURN_URI`

Tham khảo file `.env.example`.

## Lưu Ý Quan Trọng

- Flyway trong project kỳ vọng schema có sẵn bảng nền. Vì vậy cần import `database.sql` trước khi chạy backend.
- Nếu đã lỡ migrate sai hoặc DB lỗi, reset nhanh:

```bash
docker compose -f deployment.yaml down -v
docker compose -f kafka-deployment.yaml down -v
```

Sau đó chạy lại từ bước 2.

## Build Nhanh

```bash
./mvnw -DskipTests compile
```

Windows:

```powershell
.\mvnw.cmd -DskipTests compile
```
