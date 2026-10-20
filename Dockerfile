# syntax=docker/dockerfile:1
#
# LOBBY-LOOP GM-Proxy — Deploy-Artefakt.
# Build:  docker build -t lobby-loop-gm-proxy .
# Run:    docker run -p 8787:8787 -e GEMINI_API_KEY=<key> lobby-loop-gm-proxy
FROM node:22-alpine

ENV GM_PROXY_PORT=8787

WORKDIR /app

# Reproduzierbares pnpm: Corepack-Shims + gepinnte Version (Lockfile 9.0).
RUN corepack enable && corepack prepare pnpm@9.15.9 --activate

# Dependency-Layer zuerst (Build-Cache): Manifest + Lockfile + vendored file:-Dep.
COPY package.json pnpm-lock.yaml ./
COPY vendor ./vendor
RUN pnpm install --frozen-lockfile

# Proxy-Quellen: tsconfig für tsx, Prompts werden zur Laufzeit eingelesen.
COPY tsconfig.json ./
COPY gm-proxy ./gm-proxy

# Router-State ist Laufzeit-State und muss für den non-root-User beschreibbar sein.
RUN rm -f /app/gm-proxy/router-state.json \
    && mkdir -p /app/gm-proxy/data/chronicles \
    && chown -R node:node /app/gm-proxy

USER node

EXPOSE 8787

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null "http://127.0.0.1:${GM_PROXY_PORT}/health" || exit 1

# Direkt via tsx starten (kein pnpm/Corepack zur Laufzeit: vermeidet Runtime-Download
# und Root-Rechte auf node_modules).
CMD ["node", "node_modules/tsx/dist/cli.mjs", "gm-proxy/src/server.ts"]
