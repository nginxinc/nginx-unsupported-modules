![Unsupported](https://badgen.net/badge/support/none/orange)
[![Project Status: Abandoned – Initial development has started, but there has not yet been a stable, usable release; the project has been abandoned and the author(s) do not intend on continuing development.](https://www.repostatus.org/badges/latest/abandoned.svg)](https://www.repostatus.org/#abandoned)

# NGINX Unsupported Modules

This repository provides container images that contain unsupported NGINX
modules. Each container image *only* contains the module binaries and is not
a runnable image.

# Module Version Matrix

Currently, binaries are available for the following NGINX versions, platforms
and modules.

| NGINX Version | OS    | System Library | Module                         |
|---------------|-------|----------------|--------------------------------|
| 1.19.10       | linux | libc/musl      | brotli filter (v1.0.0 rc)      |
| 1.20.1        | linux | libc/musl      | brotli filter (v1.0.0 rc)      |
| 1.21.6        | linux | libc/musl      | brotli filter (v1.0.0 rc)      |
| 1.23.3        | linux | libc/musl      | brotli filter (v1.0.0 rc)      |
| 1.19.10       | linux | libc/musl      | open telemetry (latest commit) |
| 1.20.1        | linux | libc/musl      | open telemetry (latest commit) |
| 1.21.6        | linux | libc/musl      | open telemetry (latest commit) |
| 1.23.3        | linux | libc/musl      | open telemetry (latest commit) |

# Usage

To use the module binaries:

1. Find the container image for your architecture, operating system, 
   NGINX version, system library (libc or musl). The container image will
   be coded with a label in the format: 
   `<module_image_name>:<os>-<system library>-nginx-<nginx version>`.
2. Copy the needed module binary into your container image using the
   following Dockerfile syntax:

```Dockerfile
COPY --from=ngx_http_brotli_filter_module:linux-libc-nginx-1.19.10 /usr/lib/nginx/modules/ngx_http_brotli_static_module.so /usr/lib/nginx/modules/ngx_http_brotli_static_module.so
```

3. Add the necessary changes to your configuration files to support the new
   module(s).

# Notes

These modules as distributed here are not officially supported by NGINX or
F5. Use your own discretion regarding if these modules make sense in your
development or distribution toolchain.

# License

This project is licensed under the [Apache 2.0 license](LICENSE).

Each module is licensed under its own respective license:

 * Brotli Filter Module - [BSD 2](https://github.com/google/ngx_brotli/blob/master/LICENSE)
 * Open Telemetry Module - [Apache 2.0](https://github.com/open-telemetry/opentelemetry-cpp-contrib/blob/main/LICENSE)
