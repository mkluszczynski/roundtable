# Build from the project root with:
# docker build -f roundtable_server/Dockerfile .

# Build stage
FROM dart:3.12.2 AS build

# Create a minimal workspace that preserves locked server dependency versions.
# roundtable_agent_runner and roundtable_client are included too, so the
# agent-runner binary served at /agent-runner-bin (see server.dart) can be
# compiled here instead of on the target machine.
WORKDIR /app
COPY pubspec.lock .
COPY roundtable_server roundtable_server
COPY roundtable_agent_runner roundtable_agent_runner
COPY roundtable_client roundtable_client
COPY scripts scripts
RUN mkdir -p roundtable_server/web/static \
  && cp scripts/install-agent.sh roundtable_server/web/static/install-agent.sh \
  && cp scripts/uninstall-agent.sh roundtable_server/web/static/uninstall-agent.sh
RUN printf '%s\n' \
  'name: _' \
  'environment:' \
  '  sdk: ^3.12.2' \
  'workspace:' \
  '  - roundtable_server' \
  '  - roundtable_agent_runner' \
  '  - roundtable_client' \
  > pubspec.yaml
RUN dart pub get

# Compile the server executable.
WORKDIR /app/roundtable_server
RUN dart build cli --target bin/main.dart --output build
RUN mv build/bundle/bin/main build/bundle/bin/server

# Compile the agent-runner executable and package it under web/static so
# install-agent.sh can download and install it without a Dart SDK or repo
# checkout on the target machine (design doc §6.8).
WORKDIR /app/roundtable_agent_runner
RUN dart build cli --target bin/roundtable_agent_runner.dart --output build
RUN mkdir -p /app/roundtable_server/web/static/bin \
  && cp build/bundle/bin/roundtable_agent_runner \
    /app/roundtable_server/web/static/bin/roundtable-agent-runner

# Same for the permission-prompt-tool executable (design doc §6.4) — the
# daemon spawns it as an MCP server during planning-phase runs, and it needs
# its own compiled artifact for the same reason as above. `dart build cli`
# wipes its whole --output directory on each invocation, so this must run
# (and be copied out) only after the agent-runner binary above is already
# copied out of build/.
RUN dart build cli --target bin/permission_prompt_tool.dart --output build
RUN cp build/bundle/bin/permission_prompt_tool \
    /app/roundtable_server/web/static/bin/roundtable-permission-prompt-tool

# Add a fallback for the copy of possibly missing directories.
WORKDIR /app/roundtable_server
RUN mkdir -p config web migrations

# Final stage
FROM alpine:latest
WORKDIR /app

# Environment variables
ENV runmode=production
ENV serverid=default
ENV logging=normal
ENV role=monolith

# Copy runtime dependencies
COPY --from=build /runtime/ /

# Copy compiled server executable and native libraries
COPY --from=build /app/roundtable_server/build/bundle/ ./

# Copy configuration files and resources
COPY --from=build /app/roundtable_server/config/ config/
COPY --from=build /app/roundtable_server/web/ web/
COPY --from=build /app/roundtable_server/migrations/ migrations/

# This file is required to enable the endpoint log filter in Insights.
COPY --from=build /app/roundtable_server/lib/src/generated/protocol.yaml lib/src/generated/protocol.yaml

# Expose ports
EXPOSE 8080
EXPOSE 8081
EXPOSE 8082

# Define the entrypoint command
ENTRYPOINT ./bin/server --mode=$runmode --server-id=$serverid --logging=$logging --role=$role
