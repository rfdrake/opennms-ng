# Docker container for testing opennms-ng

FROM debian:testing
MAINTAINER rdrake@ipsek.net

# needed to ensure postgresql installs with UTF-8
RUN apt-get update && apt-get install -y locales
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && /usr/sbin/locale-gen
RUN update-locale LANG=en_US.UTF-8

RUN apt-get update && apt-get install -y \
    build-essential \
    postgresql \
    activemq \
    maven \
    default-jre \
    default-jdk \
    default-mta \
    git \
    curl \
    supervisor \
    make

RUN curl -L http://debian.opennms.org/OPENNMS-GPG-KEY | apt-key add -
RUN echo "deb http://debian.opennms.org stable main" > /etc/apt/sources.list.d/opennms.list
RUN apt-get update && apt-get install -y opennms-server


# fix postgres auth
RUN echo "local all all trust\nhost all all 127.0.0.1/32 trust\nhost all all ::1/32 trust" > /etc/postgresql/$(pg_lsclusters -h | head -n 1 | cut -d' ' -f1)/main/pg_hba.conf

RUN git clone https://github.com/rfdrake/opennms-ng.git /opennms-ng
RUN git clone https://github.com/savoirtech/aetos /aetos
RUN /etc/init.d/postgresql start && /usr/share/opennms/bin/runjava -s && \
    /usr/share/opennms/bin/install -dis && \
    cd /opennms-ng && ln -s /var/lib/opennms opennms && mvn install && \
    cd /aetos && mvn install
#RUN echo "opennms.home=${karaf.home}/opennms" >> etc/system.properties

ENTRYPOINT ["/usr/bin/supervisord"]
