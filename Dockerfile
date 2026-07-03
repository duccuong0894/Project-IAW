# ================================================================
# IAW401-Lab03 | Antiqua Library — Multi-stage Web Exploitation
#
# Platform   : F-CTF / Kubernetes
# Constraints: USER 1000 · read-only rootfs · write /tmp only
#              log → stdout/stderr · single port 5000
#
# Mục tiêu lab:
#   App cố ý có các lỗ hổng SQL Injection, Integer Overflow và
#   Race Condition (TOCTOU). Sinh viên khai thác qua 3 màn để
#   thu thập đủ 3 flags.
# ================================================================

# ── build stage ── bắt buộc --release (Act 2 dựa vào overflow-checks=false)
FROM rust:slim AS build
WORKDIR /app

# Cache dependencies (Cargo.lock để khóa phiên bản -> build tái lập được)
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs \
    && cargo build --release --locked || true
RUN rm -rf src

# Build application
COPY src ./src
COPY templates ./templates
RUN touch src/main.rs && cargo build --release --locked

# ── runtime stage ──
FROM debian:stable-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 1. Tạo user UID 1000 (bắt buộc theo K8s spec)
RUN useradd -u 1000 -m appuser

WORKDIR /app

# 2. Copy binary và static files từ build stage
COPY --from=build /app/target/release/antiqua-library /app/antiqua-library
COPY static ./static

# 3. Phân quyền cho UID 1000 trước khi chuyển USER
RUN chown -R 1000:1000 /app

USER 1000

ENV DATABASE_URL=sqlite:///tmp/antiqua.db
ENV TMPDIR=/tmp
ENV PORT=5000

EXPOSE 5000

# 4. Runtime: xóa DB cũ (để đảm bảo state sạch mỗi lần khởi động) rồi chạy ứng dụng
CMD ["sh", "-c", "rm -f /tmp/antiqua.db /tmp/antiqua.db-wal /tmp/antiqua.db-shm 2>/dev/null || true && exec /app/antiqua-library"]
