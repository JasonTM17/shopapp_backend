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

### Cách nhanh nhất (Windows)

```powershell
.\start-all.cmd
```

Lệnh trên sẽ:

- dựng MySQL, Redis, Kafka, Zookeeper
- kiểm tra trạng thái container
- import `database.sql` nếu schema đang trống
- compile backend
- chạy backend và đợi health endpoint sẵn sàng

Tắt toàn bộ:

```powershell
.\stop-all.cmd
```

Reset sạch (xóa volumes):

```powershell
.\scripts\stop-all.ps1 -RemoveVolumes
```

### 1) Clone source

```bash
git clone <repo-url>
cd shopapp-backend
```

### 2) Chạy hạ tầng

```bash
docker compose -f docker-compose.yml up -d mysql8-container redis-container zookeeper-01 zookeeper-02 zookeeper-03 kafka-broker-01
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

## Script Tự Động Hóa

- `scripts/start-all.ps1`
- `scripts/stop-all.ps1`
- `start-all.cmd`
- `stop-all.cmd`

## Docker Compose (1 file)

File chính: `docker-compose.yml`

Chạy hạ tầng:

```bash
docker compose -f docker-compose.yml up -d mysql8-container redis-container zookeeper-01 zookeeper-02 zookeeper-03 kafka-broker-01
```

Chạy cả backend bằng container (profile `app`):

```bash
docker compose -f docker-compose.yml --profile app up -d
```

Tắt toàn bộ:

```bash
docker compose -f docker-compose.yml down
```

## Run Prebuilt Image

Image Docker Hub:

- `nguyenson1710/shopapp-backend:latest`

Chạy container backend (map cổng `8088`):

```bash
docker run -d --name shopapp-backend-image-run --network shopapp-network -p 8088:8088 \
  -e SPRING_DATASOURCE_URL="jdbc:mysql://mysql8-container:3306/ShopApp?serverTimezone=UTC&allowPublicKeyRetrieval=true" \
  -e MYSQL_ROOT_PASSWORD="Abc123456789@" \
  -e REDIS_HOST="redis-container" \
  -e REDIS_PORT="6379" \
  -e KAFKA_BROKER_SERVER="kafka-broker-01" \
  -e KAFKA_BROKER_PORT="19092" \
  nguyenson1710/shopapp-backend:latest
```

Kiểm tra:

```bash
curl -i http://localhost:8088/api/v1/actuator/health
```

Ví dụ:

```powershell
.\scripts\start-all.ps1 -SkipBuild
.\scripts\start-all.ps1 -SkipDbImport
.\scripts\start-all.ps1 -ForceDbImport
.\scripts\start-all.ps1 -NoBackend
.\scripts\start-all.ps1 -ForegroundBackend
.\scripts\stop-all.ps1 -RemoveVolumes
```

## API Tài Liệu

- Swagger UI: `http://localhost:8088/swagger-ui.html`
- OpenAPI docs: `http://localhost:8088/api-docs`

## Test Nhanh Bằng Postman

Thư mục Postman đã có sẵn:

- `postman/ShopApp_Backend.postman_collection.json`
- `postman/ShopApp_Local.postman_environment.json`

Các bước:

1. Import cả 2 file vào Postman.
2. Chọn environment `ShopApp Local`.
3. Chạy request `Health - Actuator` để kiểm tra backend cổng `8088`.
4. Nếu cần test API cần đăng nhập:
   - cập nhật `login_email`, `login_password`, `role_id` trong environment
   - chạy `Auth - Login` (token sẽ tự lưu vào `access_token`)
   - chạy `Users - Details (Authorized)`.

Lưu ý lỗi `Invalid character in header content ["Authorization"]`:

- Không tự dán header `Authorization` trong tab Headers.
- Chỉ dùng tab Authorization (Bearer Token) với biến token trong collection.
- Nếu token có xuống dòng, dấu `"` hoặc tiền tố `Bearer ` bị dán lặp, collection đã tự làm sạch trước khi gửi.

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
docker compose -f docker-compose.yml down -v
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
