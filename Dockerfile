# Stage 1: Build with official KofLang release (https://github.com/KofLang/Kof4j)
FROM eclipse-temurin:25-jdk-noble AS builder
WORKDIR /app

ARG KOF_VERSION=0.6.5
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates tar \
    && curl -fsSL "https://github.com/KofLang/Kof4j/releases/download/kof-${KOF_VERSION}-linux-x86_64/kof-${KOF_VERSION}-linux-x86_64.tar.gz" \
       -o /tmp/kof.tar.gz \
    && mkdir -p /opt/kof \
    && tar -xzf /tmp/kof.tar.gz -C /opt/kof --strip-components=1 \
    && ln -s /opt/kof/bin/kof /usr/local/bin/kof \
    && rm -rf /tmp/kof.tar.gz /var/lib/apt/lists/*

COPY . .
RUN kof build app.kf --target jvm --fat --output /app/out

# Stage 2: Minimal JVM Runtime (Java 25 required by kof 0.6.5 bytecode v69.0)
FROM eclipse-temurin:25-jre-noble
WORKDIR /app
COPY --from=builder /app/out/kof-app.jar /app/app.jar

EXPOSE 8080
ENTRYPOINT ["java", "--enable-native-access=ALL-UNNAMED", "-jar", "/app/app.jar"]
