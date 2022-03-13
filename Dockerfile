FROM ubuntu:20.04

EXPOSE 80

WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive 

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
  	librados-dev

RUN	git clone -b switch2osm git://github.com/SomeoneElseOSM/mod_tile.git && \
	cd mod_tile && \
	./autogen.sh && \
	./configure && \
	make -j $CORES && \
	make install && \
	make install-mod_tile

RUN	ldconfig 

RUN cp /usr/local/etc/renderd.conf /etc/renderd.conf 
#RUN	cp etc/apache2/renderd.conf /etc/apache2/conf-available/renderd.conf
	
RUN mkdir /var/lib/mod_tile && chown renderaccount /var/lib/mod_tile

RUN mkdir /var/run/renderd && chown renderaccount /var/run/renderd

RUN echo "LoadModule tile_module /usr/lib/apache2/modules/mod_tile.so" >> /etc/apache2/conf-available/mod_tile.conf && \
	a2enconf mod_tile


COPY 000-default.conf /etc/apache2/sites-available/000-default.conf

RUN service apache2 reload && service apache2 reload

CMD ["sh"]