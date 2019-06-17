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
RUN rm -rf ${PREFIX}/share/terminfo ${PREFIX}/include && \
    apk add --no-cache su-exec pwgen

RUN addgroup -g "${GID}" "${GROUP}" && adduser -D -s /bin/sh \
             -g "Database user" \
             -G "${GROUP}" -u "${UID}" \
                "${USERNAME}" \
 && chown -R "${USERNAME}:${GROUP}" "${PREFIX}" \
 && mkdir -p "${DATA}" && chown "${USERNAME}":"${GROUP}" "${DATA}" \
 && echo 'export PATH="'${PREFIX}'/bin:$PATH"' >> ${PGHOME}/.profile

VOLUME ${DATA}
ENV PGDATA  ${DATA}

COPY docker-entrypoint.sh "${PREFIX}/bin"
# list of extensions to enabled, to be processed by docker-entrypoint.sh
COPY extensions.txt /tmp/

EXPOSE ${PGPORT}

ENTRYPOINT ["docker-entrypoint.sh"]

#CMD ["postgres"]
