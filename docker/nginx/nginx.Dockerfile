# ARG IMAGE_NAME=${CI_REGISTRY_IMAGE}/${DEPLOY_PROJECT_NAME}_app
ARG CI_REGISTRY_IMAGE=$CI_REGISTRY_IMAGE
ARG DEPLOY_PROJECT_NAME=$DEPLOY_PROJECT_NAME
FROM alpine
RUN echo $CI_REGISTRY_IMAGE
RUN echo $DEPLOY_PROJECT_NAME

ARG CI_REGISTRY_IMAGE=$CI_REGISTRY_IMAGE
ARG DEPLOY_PROJECT_NAME=$DEPLOY_PROJECT_NAME
FROM  ${CI_REGISTRY_IMAGE}/${DEPLOY_PROJECT_NAME}_app:latest AS app
# FROM docker-hub.***REMOVED***.ru/***REMOVED***/***REMOVED***/svt/svt_app:latest AS app
FROM nginx:1.19.6-alpine

ARG RAILS_ROOT
ENV RAILS_ROOT ${RAILS_ROOT}

WORKDIR ${RAILS_ROOT}
RUN mkdir log
COPY --from=app /app/public/ public/

COPY docker/nginx/nginx.prod.conf /tmp/nginx.prod.conf
COPY docker/tls/ /etc/pki/tls/nginx/

RUN envsubst '$RAILS_ROOT $APPNAME' < /tmp/nginx.prod.conf > /etc/nginx/conf.d/default.conf

EXPOSE 80
EXPOSE 443
