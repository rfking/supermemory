# Dockerfile simplificado para Supermemory
FROM node:20-slim

# Instalar dependências do sistema necessárias
RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    make \
    g++ \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Instalar Bun
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:$PATH"

# Diretório de trabalho
WORKDIR /app

# Copiar todos os arquivos
COPY . .

# Instalar dependências
RUN bun install || npm install

# Build da aplicação
ENV NODE_ENV=production
RUN bun run build || npm run build

# Expor porta
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/ || exit 1

# Iniciar aplicação
CMD ["bun", "run", "start"]
