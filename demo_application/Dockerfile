# syntax=docker/dockerfile:1
FROM --platform=linux/amd64 python:slim
COPY --from=docker/buildx-bin:latest /buildx /usr/libexec/docker/cli-plugins/docker-buildx

ARG APP_WORKDIR=/app

ARG APP_USER_NAME=demo_application
ARG APP_USER_UID=1234

ARG APP_GROUP_NAME=${APP_USER_NAME}
ARG APP_GROUP_GID=1234

RUN addgroup \
      --gid ${APP_GROUP_GID} \
      ${APP_GROUP_NAME} && \
    adduser \
      --ingroup ${APP_GROUP_NAME} \
      --no-create-home \
      --disabled-password \
      --uid ${APP_USER_UID} \
      ${APP_USER_NAME}

RUN mkdir -p ${APP_WORKDIR}

WORKDIR ${APP_WORKDIR}

COPY ./requirements.txt ${APP_WORKDIR}/requirements.txt

RUN pip install --no-cache-dir --upgrade -r ${APP_WORKDIR}/requirements.txt

COPY ./app.py ${APP_WORKDIR}

RUN chown -R ${APP_USER_NAME}:${APP_GROUP_NAME} ${APP_WORKDIR}

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "80"]