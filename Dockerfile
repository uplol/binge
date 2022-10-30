# Common base layer
FROM python:3.11-alpine as base
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    BINGE_PATH="/binge/"

FROM base as builder

# Install needed build deps
RUN apk add --no-cache bash cargo curl && \
    pip install poetry

# Install binge deps
WORKDIR $BINGE_PATH
COPY ./binge/poetry.lock ./binge/pyproject.toml ./
RUN poetry install --only main --no-interaction --no-ansi

# Download Vector
RUN curl --proto '=https' --tlsv1.2 -s https://packages.timber.io/vector/0.24.2/vector-0.24.2-x86_64-unknown-linux-musl.tar.gz | tar -xz -C /tmp && \
    cp /tmp/vector-x86_64-unknown-linux-musl/bin/vector /binge/

FROM base as production

# libgcc needed for orjson
RUN apk add --no-cache libgcc

COPY --from=builder $BINGE_PATH $BINGE_PATH
COPY ./docker/binge/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY ./docker/binge/vector.toml $BINGE_PATH
COPY ./binge/binge.py $BINGE_PATH

WORKDIR $BINGE_PATH
ENTRYPOINT /entrypoint.sh $0 $@
