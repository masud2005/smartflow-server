FROM node:20 AS build
WORKDIR /software

# Copy dependency files
COPY package.json pnpm-lock.yaml ./

# Install pnpm and dependencies
RUN npm install -g pnpm
RUN pnpm install

# Copy Prisma files
COPY prisma ./prisma
COPY prisma.config.ts ./

# Copy all source code
COPY . .

# Generate Prisma Client and build
RUN npx prisma generate
RUN npm run build

# Production stage
FROM node:20-alpine
WORKDIR /software

# Copy only necessary files from build stage
COPY --from=build /software/package.json .
COPY --from=build /software/node_modules ./node_modules
COPY --from=build /software/dist ./dist
COPY --from=build /software/prisma ./prisma
COPY --from=build /software/prisma.config.ts ./

# Set environment
ENV NODE_ENV=production

# Expose port
EXPOSE 6545

# Start server
CMD ["npm", "run", "server:run:under:dockerimage"]