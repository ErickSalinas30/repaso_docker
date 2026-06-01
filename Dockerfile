# ==========================================
# ETAPA 1: Compilación y Build de la App
# ==========================================
FROM maven:3.9.6-eclipse-temurin-21-alpine AS builder
WORKDIR /build

# Copiar configuración de dependencias para aprovechar la caché de Docker
COPY pom.xml .
RUN mvc dependency:go-offline -B

# Copiar el código fuente y compilar
COPY src ./src
RUN mvn clean package -DskipTests

# ==========================================
# ETAPA 2: Imagen de Ejecución (Producción)
# ==========================================
FROM eclipse-temurin:21-jre-alpine

# Instalar Nginx y Supervisor
RUN apk add --no-cache nginx supervisor

# Crear directorios necesarios para la app, datos y configuración
WORKDIR /app
RUN mkdir -p /app/data /run/nginx /var/log/supervisor

# Copiar el jar desde la etapa de compilación
COPY --from=builder /build/target/inventario-1.0.0.jar app.jar

# Copiar configuraciones de Nginx y Supervisor
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisord.conf

# Variables de entorno para la persistencia de H2
ENV DB_PATH=jdbc:h2:file:/app/data/inventario

# Exponer el puerto del Servidor Web (Nginx)
EXPOSE 80

# Declarar volumen para la persistencia de datos
VOLUME [ "/app/data" ]

# Comando de entrada ejecutado por Supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

