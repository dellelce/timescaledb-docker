ARG BASE=dellelce/pgbase
FROM $BASE as build

LABEL maintainer="Antonio Dell'Elce"

ARG PREFIX=/app/pg
ENV INSTALLDIR  ${PREFIX}

# commands are intended for busybox: if BASE is changed to non-BusyBox these may fail!
ARG GID=2001
ARG UID=2000
ARG GROUP=pg
ARG USERNAME=pg
ARG DATA=/app/data

RUN addgroup -g "${GID}" "${GROUP}" && adduser -D -s /bin/sh \
    -g "PostGreSQL user" \
    -G "${GROUP}" -u "${UID}" \
    "${USERNAME}" \
    && chown -R "${USERNAME}:${GROUP}" "${PREFIX}" && \
    && mkdir "${DATA}" && chown "${USERNAME}" "${DATA}"

USER ${USERNAME}

VOLUME ${DATA}

#WORKDIR ${INSTALLDIR}
#COPY --from=build ${INSTALLDIR} .
