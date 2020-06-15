FROM php:fpm-buster

ENV DEBIAN_FRONTEND=noninteractive

ADD https://github.com/just-containers/s6-overlay/releases/download/v2.0.0.1/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

RUN \
    apt-get -y update && \
    apt-get -y install --no-install-recommends \
    nginx zip unzip\
    imagemagick webp libmagickwand-dev libyaml-dev \
    python3 python3-numpy libopencv-dev python3-setuptools opencv-data \
    gcc git libnginx-mod-http-lua \
    # gcc nasm build-essential make wget vim git \
    ghostscript ffmpeg && \ 
    # cmake autoconf automake libtool nasm pkg-config && \
    rm -rf /var/lib/apt/lists/*

#opcache
RUN docker-php-ext-install opcache

#xdebug
RUN pecl install xdebug imagick yaml && \
    echo "/usr/local/lib/php/extensions/no-debug-non-zts-20190902/xdebug.so" > /usr/local/etc/php/conf.d/xdebug.ini && \
    echo "extension=imagick.so" > /usr/local/etc/php/conf.d/imagick.ini && \
    echo "extension=yaml.so" > /usr/local/etc/php/conf.d/yaml.ini && \
    echo "expose_php=off" > /usr/local/etc/php/conf.d/expose_php.ini

#install MozJPEG
# RUN \
#     wget "https://github.com/mozilla/mozjpeg/archive/v3.3.1.tar.gz" && \
#     tar xvf "v3.3.1.tar.gz" && \
#     rm "v3.3.1.tar.gz" && \
#     cd mozjpeg-3.3.1/ && \
#     ./configure && \
#     make && \
#     make install

ADD https://mozjpeg.codelove.de/bin/mozjpeg_3.3.1_amd64.deb /tmp/mozjpeg.deb
RUN dpkg -i /tmp/mozjpeg.deb && ln -s /opt/mozjpeg/bin/jpegtran /usr/local/bin/mozjpeg && rm -rf /tmp/mozjpeg.deb 

#facedetect script
RUN \
    cd /var && \
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python3 get-pip.py && \
    pip3 install numpy && \
    pip3 install opencv-python && \
    git clone https://github.com/flyimg/facedetect.git && \
    chmod +x /var/facedetect/facedetect && \
    ln -s /var/facedetect/facedetect /usr/local/bin/facedetect

#Smart Cropping python plugin
RUN pip install git+https://github.com/flyimg/python-smart-crop

#composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#disable output access.log to stdout
RUN sed -i -e 's#access.log = /proc/self/fd/2#access.log = /proc/self/fd/1#g'  /usr/local/etc/php-fpm.d/docker.conf

RUN ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log
#copy etc/
COPY resources/etc/ /etc/

ENV PORT 80

COPY resources/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

WORKDIR /var/www/html

CMD ["docker-entrypoint", "/init"]

