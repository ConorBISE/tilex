ARG MIX_ENV="dev"

#############################
# Stage one                 #
# Build our frontend assets #
#############################
FROM node:19-slim as node_builder

WORKDIR /app
COPY . /app/
RUN npm install --prefix assets/

################################
# Stage two                    #
# Build our backend elixir app #
################################ 
FROM elixir:1.14.1-slim as elixir_builder

ARG MIX_ENV
WORKDIR /app
COPY . /app

RUN apt -y update && \
    apt install -y git python3 make g++ openssl && \
    apt clean && rm -f /var/lib/apt/lists/*_*

COPY --from=node_builder /app/assets /app/assets

RUN mix local.hex --force
RUN mix local.rebar --force

RUN mix deps.get
RUN mix gettext.extract --merge --no-fuzzy
RUN mix assets.deploy
RUN mix release

#########################################################
# Stage three                                           #
# Our final release stage.                              #
# Copy everything from our last two stages, and run it. #
#########################################################
FROM debian:bullseye

ARG MIX_ENV
WORKDIR /app

# Network variables
# Where is the app binding to?
ENV HOST="0.0.0.0"
ENV PORT="4000"
ENV CANONICAL_DOMAIN="http://localhost:4000"
ENV HOSTED_DOMAIN="localhost:4000"

# Database variables
ENV DATABASE_HOST="host.docker.internal"
ENV DATABASE_USERNAME="postgres"
ENV DATABASE_PASSWORD=""
ENV DATABASE_NAME="tilex_dev"

# Oauth config
ENV GOOGLE_CLIENT_ID="<REPLACEME-CLIENT_ID>"
ENV GOOGLE_CLIENT_SECRET="<REPLACEME-CLIENT_SECRET>"
ENV GUEST_AUTHOR_ALLOWLIST="<REPLACEME-ALLOWLIST>"

# Misc
ENV MIX_ENV=${MIX_ENV}
ENV SECRET_KEY_BASE=123
ENV DATE_DISPLAY_TZ=America/Chicago
ENV PHX_SERVER=true

# Install runtime dependencies
RUN apt update -y && \
    apt install -y locales libodbc1 libssl1.1 libsctp1 inotify-tools  \
    && apt clean && rm -f /var/lib/apt/lists/*_*

ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US    
RUN printf '%s\n' LANG=en_US LC_ALL=en_US.UTF-8 >/etc/default/locale
RUN echo en_US.UTF-8 UTF-8 >>/etc/locale.gen
RUN locale-gen

COPY --from=node_builder /app/assets /app/assets
COPY --from=elixir_builder /app/_build /app/_build

ENV RUN_COMMAND="/app/_build/${MIX_ENV}/rel/tilex/bin/tilex start"
CMD $RUN_COMMAND