# vim:set ft=dockerfile
ARG BASE=dellelce/timescaledb-base
FROM $BASE as build

LABEL maintainer="Antonio Dell'Elce"

ARG PREFIX=/app/pg
ENV INSTALLDIR  ${PREFIX}

# commands are intended for busybox: if BASE is changed to non-BusyBox these may fail!
ARG GID=2001
ARG UID=2000
ARG USERNAME=pg
ARG GROUP=${USERNAME}
ARG DATA=/app/data/${USERNAME}
ARG PGPORT=5432
ARG PGHOME=/home/${USERNAME}

ENV ENV   $PGHOME/.profile
ENV LANG  en_GB.utf8

# Remove unneeded base package build-related files & add replacement su
# Note: terminfo needed if accessing the docker instance interactively
RUN rm  -rf ${PREFIX}/include && \
    apk add --no-cache su-exec pwgen

RUN addgroup -g "${GID}" "${GROUP}" && adduser -D -s /bin/sh \
             -g "Database user" \
             -G "${GROUP}" -u "${UID}" \
                "${USERNAME}" \
 && chown -R "${USERNAME}:${GROUP}" "${PREFIX}" \
 && mkdir -p "${DATA}" && chown "${USERNAME}":"${GROUP}" "${DATA}" \
 && echo 'export PATH="'${PREFIX}'/bin:$PATH"' >> ${PGHOME}/.profile

# ..
RUN sample="${PREFIX}/share/postgresql/postgresql.conf.sample" && \
    extensions="timescaledb" && \
    sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" ${sample} && \
    sed -ri "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = '"${extensions}",\2'/;s/,'/'/"  ${sample} && \
    echo "${extensions}" > /tmp/extensions.txt

VOLUME ${DATA}
ENV PGDATA  ${DATA}

COPY docker-entrypoint.sh "${PREFIX}/bin"

EXPOSE ${PGPORT}

ENTRYPOINT ["docker-entrypoint.sh"]

#CMD ["postgres"]
