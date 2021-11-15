FROM debian:bullseye-slim

ARG ARCH=amd64
ENV ARCH=$ARCH
ARG OS
ARG LIB
ARG NGX_VERSION

ENV TAG_LABEL=$OS-$LIB-nginx-$NGX_VERSION

RUN echo "$ARCH $TAG_LABEL"

# Add Brotli module
COPY --from=$ARCH/ngx_http_brotli_filter_module:$TAG_LABEL /usr/lib/nginx/modules/ngx_http_brotli_filter_module.so /usr/lib/nginx/modules/ngx_http_brotli_filter_module.so
COPY --from=$ARCH/ngx_http_brotli_filter_module:$TAG_LABEL /usr/lib/nginx/modules/ngx_http_brotli_static_module.so /usr/lib/nginx/modules/ngx_http_brotli_static_module.so
# Add Open Telemetry module
COPY --from=$ARCH/ngx_otel_module:$TAG_LABEL /usr/lib/nginx/modules/otel_ngx_module.so /usr/lib/nginx/modules/otel_ngx_module.so
