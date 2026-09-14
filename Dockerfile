FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        nginx \
        fcgiwrap \
        perl \
        librrds-perl \
        libdate-manip-perl \
        libcgi-pm-perl \
        rrdtool \
        apache2-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/tstat

COPY cgi-bin/tstat_rrd.cgi ./tstat_rrd.cgi
COPY htdocs/javascript ./javascript
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x tstat_rrd.cgi /usr/local/bin/docker-entrypoint.sh \
    && mkdir -p rrd_data rrd_images rrd_gallery \
    && rm -f /etc/nginx/sites-enabled/default

EXPOSE 80

# Mount one or more Tstat RRD folders under here, e.g.:
#   -v /path/to/probe1:/var/www/tstat/rrd_data/probe1
VOLUME ["/var/www/tstat/rrd_data"]

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
