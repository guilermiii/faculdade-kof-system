FROM koflang/kof:latest AS builder
WORKDIR /app
COPY . .
RUN kof build --target jvm -o app.jar

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /app/app.jar .
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
