FROM node:22-alpine

WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev --no-audit --no-fund || npm install --no-audit --no-fund
COPY . .

ENV PORT=4000
EXPOSE 4000

# tsx exécute le TypeScript directement (pas d'étape de build nécessaire).
CMD ["npm", "run", "start"]
