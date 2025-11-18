# Usar Node.js como base (mais compatível)
FROM node:20-slim AS base

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Instalar Bun
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:$PATH"

WORKDIR /app

# Copiar arquivos de dependências
COPY package.json bun.lockb* package-lock.json* ./

# Instalar dependências
RUN bun install --frozen-lockfile || npm install

# Copiar código fonte
COPY . .

# Build da aplicação
RUN bun run build || npm run build

# Expor porta
EXPOSE 3000

# Variáveis de ambiente
ENV NODE_ENV=production
ENV PORT=3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/ || exit 1

# Comando de inicialização
CMD ["bun", "run", "start"]
