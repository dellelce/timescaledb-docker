ARG BASE=dellelce/pgbase
FROM $BASE as build

LABEL maintainer="Antonio Dell'Elce"

ARG PREFIX=/app/pg
ENV INSTALLDIR  ${PREFIX}

# commands are intended for busybox if BASE is changed to non-BusyBox these may fail!
ARG GID=2001
ARG UID=2000
ARG GROUP=pg
ARG USERNAME=pg
RUN addgroup -g "${GID}" "${GROUP}" && adduser -G "${pg}" -u "${UID}" "${USERNAME}" \
    && chown -R "${USERNAME}:${GROUP}" "${PREFIX}"

ARG DATA=/app/data
VOLUME ${DATA}

#WORKDIR ${INSTALLDIR}
#COPY --from=build ${INSTALLDIR} .
