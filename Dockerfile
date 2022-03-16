FROM ubuntu:20.04

EXPOSE 80

WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive 

ENV RENDERD_NUM_THREADS 8
ENV RENDERD_TILE_DIR  /var/lib/mod_tile
ENV RENDERD_STATS_FILE /var/run/renderd/renderd.stats
ENV MAPNIK_PLUGINS_DIR /usr/lib/mapnik/3.0/input
ENV MAPNIK_FONT_DIR /usr/share/fonts/truetype
ENV MAPNIK_FONT_DIR_RECURSE 1
ENV AJT_HOT_URI /hot/
ENV AJT_TILEDIR /var/lib/mod_tile
ENV AJT_MAPNIK_XML /init/mapnik.xml
ENV AJT_MAPNIK_HOST localhost
ENV AJT_TILESIZE 256
ENV MAXZOOM 20

RUN export CORES=$(getconf _NPROCESSORS_ONLN)

RUN useradd renderaccount && \
	usermod -aG sudo renderaccount

RUN apt update && \
 	apt install -y osmosis git apache2 apache2-dev

RUN apt install -y build-essential \
  	autoconf \
  	apache2-dev \
  	libcairo2-dev \
  	libcurl4-gnutls-dev \
  	libglib2.0-dev \
  	libiniparser-dev \
  	libmapnik-dev \
  	libmemcached-dev \
  	librados-dev \
  	fonts-noto-cjk fonts-noto-hinted fonts-noto-unhinted ttf-unifont

RUN	git clone -b switch2osm https://github.com/SomeoneElseOSM/mod_tile.git && \
	cd mod_tile && \
	./autogen.sh && \
	./configure && \
	make -j $CORES && \
	make install && \
	make install-mod_tile

RUN	ldconfig 

COPY renderd.conf.template .
COPY entrypoint.sh .
RUN envsubst < renderd.conf.template > /etc/renderd.conf && \
	cp /etc/renderd.conf /usr/local/etc/renderd.conf

	
RUN mkdir /var/lib/mod_tile && chown renderaccount /var/lib/mod_tile

RUN mkdir /var/run/renderd && chown renderaccount /var/run/renderd && cp /usr/local/bin/renderd /var/run/renderd/renderd

RUN cp /app/mod_tile/debian/renderd.init /etc/init.d/renderd && \
	chmod u+x /etc/init.d/renderd && \
	cp /app/mod_tile/debian/renderd.service /lib/systemd/system/

RUN echo "LoadModule tile_module /usr/lib/apache2/modules/mod_tile.so" >> /etc/apache2/conf-available/mod_tile.conf && \
	a2enconf mod_tile


COPY 000-default.conf /etc/apache2/sites-available/000-default.conf


ENTRYPOINT ["/app/entrypoint.sh"]

CMD ["/bin/bash"]
