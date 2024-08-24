######################
# Build Image        #
######################
FROM python:3.11-slim-bullseye as builder

RUN pip install --upgrade pip \
    && pip install poetry

ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache \
    # prevent Python from writing .pyc
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

COPY pyproject.toml poetry.lock ./

ARG BUILD_ENV=dev

#RUN --mount=type=cache,target=$POETRY_CACHE_DIR poetry install $([ "$BUILD_ENV" = "dev" ] || echo "--without dev") --no-root

# Download the punkt dataset for nltk into a specific directory. This is then
# copied into the runtime image to prevent LlamaIndex from downloading it at
# runtime.
# See https://www.nltk.org/data.html for additional information.
#RUN poetry run python -m nltk.downloader punkt --dir /usr/share/nltk_data

######################
# Runtime Image      #
######################
FROM python:3.12-slim-bullseye as runtime

RUN mkdir /app
RUN mkdir /app/.data
RUN useradd -ms /bin/bash appuser
RUN chown appuser:appuser /app/.data
USER appuser

ENV VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH" \
    PYTHONPATH=$PYTHONPATH:/app/response_orchestration \
    # prevent Python from writing .pyc
    PYTHONDONTWRITEBYTECODE=1

#clearCOPY --from=builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}
# Copy the punkt dataset for nltk from the builder image.
#COPY --from=builder /usr/share/nltk_data /usr/share/nltk_data
COPY . /app
ADD . /script
WORKDIR /app
# Make port 7003 available to the world outside this container
EXPOSE 7003

# Run app.py when the container launches
CMD ["./script/setup.sh"]

LABEL org.label-schema.name="assignment.dml.1" \
    org.label-schema.version="1.0.0"
