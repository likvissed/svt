FROM nginx:1.19.6-alpine

ARG RAILS_ROOT
ENV RAILS_ROOT ${RAILS_ROOT}

WORKDIR ${RAILS_ROOT}
RUN mkdir log
COPY public/ public/

COPY docker/nginx/nginx.prod.conf /tmp/nginx.prod.conf
COPY docker/tls/ /etc/pki/tls/nginx/

RUN envsubst '$RAILS_ROOT $HOSTNAME' < /tmp/nginx.prod.conf > /etc/nginx/conf.d/default.conf

EXPOSE 80
EXPOSE 443
