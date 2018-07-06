FROM rocker/tidyverse:latest

RUN apt-get update -qq && apt-get -y --no-install-recommends install \
      autoconf \
      automake \
      g++ \
      gcc \
      gfortran \
      make \
      tcl8.6-dev \
      tk8.6-dev \
      && apt-get clean all \
      && rm -rf /var/lib/apt/lists/*

RUN mkdir -p $HOME/.R
COPY Makevars /root/.R/Makevars

RUN Rscript -e "install.packages('glmnet')" \
      -e "install.packages('pamr')" \
      -e "install.packages('ggplot2')" \
      -e "install.packages('survival')" \
      -e "source('http://bioconductor.org/biocLite.R')" \
      -e "biocLite('flowCore')" \
      -e "biocLite('impute')" \
      -e 'biocLite("cytofkit")' \
      -e "install.packages('samr')" \
      -e "install.packages('shiny')" \
      -e "install.packages('brew')" \
      -e "install.packages('Matrix')" \
      -e "install.packages(c('Rcpp','RcppEigen'),type='source')" \
      -e "install.packages('devtools')" \
      -e "library('devtools')" \
      -e "install_github('nolanlab/Rclusterpp')" \
      -e "install_github('nolanlab/citrus')" \
      && rm -rf /tmp/downloaded_packages
