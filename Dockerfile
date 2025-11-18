# Multi-stage build para Supermemory
FROM node:20-slim AS base

# Instalar dependências do sistema
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

WORKDIR /app

# ============================================
# Stage 1: Dependências
# ============================================
FROM base AS deps

# Copiar arquivos de dependências
COPY package.json bun.lockb* package-lock.json* ./
COPY apps/web/package.json ./apps/web/
COPY apps/extension/package.json ./apps/extension/ 2>/dev/null || true

# Instalar dependências
RUN bun install --frozen-lockfile || bun install

# ============================================
# Stage 2: Build
# ============================================
FROM base AS builder

WORKDIR /app

# Copiar dependências instaladas
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/apps ./apps

# Copiar código fonte
COPY . .

# Build da aplicação
ENV NODE_ENV=production
RUN bun run build || npm run build

# ============================================
# Stage 3: Runner
# ============================================
FROM base AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

# Criar usuário não-root
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copiar apenas arquivos necessários
COPY --from=builder --chown=nextjs:nodejs /app/apps/web/.next ./apps/web/.next
COPY --from=builder --chown=nextjs:nodejs /app/apps/web/public ./apps/web/public
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nextjs:nodejs /app/package.json ./package.json

USER nextjs

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/api/health || exit 1

# Comando de inicialização
CMD ["bun", "run", "start"]
