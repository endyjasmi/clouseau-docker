FROM maven:3.5.2-jdk-7

# Add Clouseau user account
RUN groupadd -r clouseau && useradd -d /opt/clouseau -g clouseau clouseau

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    erlang-base \
    libjansi-java \
  && rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root and tini for signal handling
ENV GOSU_VERSION 1.10
ENV TINI_VERSION 0.16.1
ENV SCALA_VERSION 2.9.3
RUN set -ex; \
  \
  apt-get update; \
  apt-get install -y --no-install-recommends wget; \
  rm -rf /var/lib/apt/lists/*; \
  \
  dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
  \
# install gosu
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	chmod +x /usr/local/bin/gosu; \
	gosu nobody true; \
	\
# install tini
  wget -O /usr/local/bin/tini "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-$dpkgArch"; \
  wget -O /usr/local/bin/tini.asc "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-$dpkgArch.asc"; \
  export GNUPGHOME="$(mktemp -d)"; \
  gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7; \
  gpg --batch --verify /usr/local/bin/tini.asc /usr/local/bin/tini; \
  rm -r "$GNUPGHOME" /usr/local/bin/tini.asc; \
  chmod +x /usr/local/bin/tini; \
  tini --version; \
  \
# install scala
  cd /usr/share; \
  wget -O /usr/share/scala.deb "https://scala-lang.org/files/archive/scala-${SCALA_VERSION}.deb"; \
  dpkg -i scala.deb; \
  rm scala.deb; \
  apt-get purge -y --auto-remove wget

# Acquire Clouseau source code
RUN cd /usr/src \
  && git clone https://github.com/cloudant-labs/clouseau.git \
  && cd clouseau \
# Build the release and install into /opt
  && mvn package -DskipTests \
  && mkdir /opt/clouseau \
  && tar -xvzf $(ls target/clouseau-*.tar.gz) -C /opt/clouseau --strip-components=1 \
  && cp -r target/test-classes /opt/clouseau \
  && cd /opt/clouseau \
# Cleanup build detritus
  && rm -rf /usr/src/clouseau* \
  && mkdir /opt/clouseau/data \
  && chown -R clouseau:clouseau /opt/clouseau

# Setup JAVA_HOME environment variable
ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64
RUN touch ${JAVA_HOME}/release

# Add configuration
COPY clouseau.ini /opt/clouseau/
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

# Setup directories and permissions
RUN chown -R clouseau:clouseau /opt/clouseau/clouseau.ini

WORKDIR /opt/clouseau
VOLUME [ "/opt/clouseau/data" ]

ENTRYPOINT [ "tini", "--", "/docker-entrypoint.sh" ]
CMD [ "clouseau" ]
