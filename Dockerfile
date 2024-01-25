FROM eclipse-temurin:21.0.2_13-jre AS builder

WORKDIR /tmp/aem

COPY ./tmp/aem-sdk-quickstart.jar ./aem-sdk-quickstart.jar

RUN java -jar ./aem-sdk-quickstart.jar -unpack && \
    mkdir crx-quickstart/install && \
    rm aem-sdk-quickstart.jar && \
    rm crx-quickstart/bin/*.bat && \
    rm crx-quickstart/readme.txt && \
    rm crx-quickstart/eula-*.html

COPY ./tmp/license.properties ./license.properties
COPY ./install/* ./crx-quickstart/install/
COPY ./scripts/start.sh ./start.sh
RUN chmod +x ./start.sh

########################################################################################################################

FROM eclipse-temurin:21.0.2_13-jre

ARG PKG
ARG LOCALE="en_GB.UTF-8"
ARG JVM_XMX="4g"
ARG JVM_META="256m"
ARG AEM_RUNMODE="author"

ENV LC_ALL="${LOCALE}" \
    LANG="${LOCALE}" \
    LANGUAGE="${LOCALE}" \
    JVM_XMX="${JVM_XMX}" \
    JVM_META="${JVM_META}" \
    AEM_RUNMODE="${AEM_RUNMODE}"

WORKDIR /aem

COPY --from=builder /tmp/aem ./

EXPOSE 4000 30303 8686 57345 57346 58242 65000

VOLUME ["/aem/crx-quickstart/repository", "/aem/crx-quickstart/logs", "/aem/crx-quickstart/install"]

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt full-upgrade -y --no-install-recommends && \
    DEBIAN_FRONTEND=noninteractive apt install -y tini --no-install-recommends && \
    \
    if [ ! "x$PKG" = "x" ]; then \
        DEBIAN_FRONTEND=noninteractive apt install -y ${PKG} --no-install-recommends ; \
    fi && \
    DEBIAN_FRONTEND=noninteractive apt autoremove -y && \
    \
    locale-gen ${LOCALE} && \
    \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/usr/bin/tini", "--", "/aem/start.sh"]
