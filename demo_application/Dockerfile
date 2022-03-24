# syntax=docker/dockerfile:1

ARG PYTHON_VERSION=3.9

FROM --platform=linux/amd64 python:${PYTHON_VERSION}-slim AS build-env
COPY --from=docker/buildx-bin:latest /buildx /usr/libexec/docker/cli-plugins/docker-buildx

COPY ./requirements.txt /app/requirements.txt
WORKDIR /app

RUN pip3 install --upgrade pip
RUN pip install -r ./requirements.txt
COPY ./app.py /app/app.py
RUN chmod 660 /app/app.py


FROM --platform=linux/amd64 gcr.io/distroless/python3:nonroot
ARG PYTHON_VERSION=3.9

COPY --from=build-env --chown=65532:65532 /app /app
COPY --from=build-env --chown=65532:65532 /usr/local/lib/python${PYTHON_VERSION}/site-packages /usr/local/lib/python${PYTHON_VERSION}/site-packages

ENV PYTHONPATH=/usr/local/lib/python3.9/site-packages
WORKDIR /app
ENV APP /app
CMD ["app.py"]
