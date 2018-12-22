FROM rocker/geospatial:3.5.1

RUN set -x && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    fonts-font-awesome \
    libmagick++-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN set -x && \
  install2.r --error \
    assertr \ 
    conflicted \
    drake \ 
    ensurer \
    here \ 
    jpmesh \ 
    jpndistrict \
    mapdeck \
    RColorBrewer \
    scico && \
  rm -rf /tmp/downloaded_packages/ /tmp/*.rds
