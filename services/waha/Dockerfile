FROM devlikeapro/waha:latest

# Install additional dependencies if needed
USER root
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy custom configuration files
COPY config/ /app/config/
COPY tsconfig.json /app/
COPY scripts/ /app/scripts/

# Set proper permissions
RUN chmod +x /app/scripts/*.sh || true
RUN chown -R 1000:1000 /app/config /app/scripts
RUN mkdir -p /app/.sessions && chown -R 1000:1000 /app/.sessions
RUN mkdir -p /app/media && chown -R 1000:1000 /app/media

# Switch back to non-root user
USER 1000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1

# Default command
CMD ["npm", "start"]