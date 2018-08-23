# rstudio-nginx
# rstudio-nginx

This is a simple example of how to set up an containerised RStudio server, running behind an Nginx reverse proxy, and being served
via HTTPS using free [Let’s Encrypt](https://letsencrypt.org) certificates.  The Nginx containers are the work of https://github.com/gilyes/docker-nginx-letsencrypt-sample,
and more examples of how to add your own websites can be found there.

While this container setup can be run anywhere, this guide is primarily for users who wish to set up an RStudio server on Pawsey's cloud service, [Nimbus](https://www.pawsey.org.au/our-services/data/cloud-services/)

## Setup

To begin you'll need the following installed on your Nimbus VM:

* [docker](https://docs.docker.com/engine/installation/) (>= 1.10)
* [docker-compose](https://github.com/docker/compose/releases) (>= 1.8.1)

There are several ways to install Docker, and I recommend you use the official version from Docker, as the version available through most package managers (e.g. yum, apt, etc.) is outdated.  Detailed instructions can be found [here](https://docs.docker.com/install/linux/docker-ce/ubuntu/).

You'll also need a domain (or subdomain) name for your Nimbus VM (you can create a free one using something like [No-IP](www.noip.com)).  You can also just use the static IP address you associated with your Nimbus VM (log into your [dashboard](https://nimbus.pawsey.org.au) to find it).

## Quick Start

More detail about each part is given below, but for those who just want to get up and running, here's what you need to do:

* Clone this [repository](https://github.com/skjerven/rstudio-nginx)
* Edit `docker-compose.yaml`
	* Change `VIRTUAL_HOST` and `LETSENCRYPT_HOST` to either your static IP address, or your domain name
	* Change `USER` and  `PASSWORD` to your desired RStudio username and password
	* Change `LETSENCRYPT_EMAIL` to your preferred email address (it will be associated with the generated certificates)
	* If you want to mount any directories into your RStudio container you need to change the `VOLUMES TO BE MOUNTED` line in the `rstudio` section.  An example is given in the `docker-compose.yaml` file, where the directory `rstudio_data` is mounted to `/home/rstudio/data` in the cointainer
* Edit `Dockerfile` to install desired R pacakges, change RStudio version, install other packages, etc.
* Run `docker-compose up` to start the containers

You should now have a working RStudio server that you can access via a web browser at *https://mydomain.com* or *https://nimbus_static_ip*.
 

## How it Works

There are 4 containers that will be used:

* Ngninx reverse proxy container
* Nginx configuration container
* Let's Encrypt certificate container
* RStudio container 

These 4 containers work together to setup the HTTPS certificates, create and configure an Nginx server, and launch an RStudio server.  While it's possible to manually configure and start each container, it's much easier to use (docker-compose)[https://github.com/docker/compose] to handle all of this for us.  At the end of this, all we'll need to do is run 

`docker-compose up`

and have a fully functional, containerised RStudio server running behind Nginx with HTTPS certificates.

### Nginx reverse proxy container

We'd like to add some extra security to our RStudio server, as it's outside of Pawsey firewalls and visible to the entire internet.  We could try and configure RStudio's web server, but it's easier (and more secure) to use an existing web server...in our case, [Nginx](www.nginx.com).

We'll be using Nginx as a reverse proxy, meaning that all web traffic that would normally go to our RStudio server, will instead be handled by Nginx.  RStudio server normally runs on port 8787, and instead of opening up that port to the internet (and possibly exposing a vulnerability), we can simply open a single port for Nginx, and let Nginx route traffic to our internal services (like RStudio).

In this example, we'll be using Nginx's [Docker image](https://hub.docker.com/_/nginx/), and this will be the only externally visible container.  The **nginx** block in `docker-compose.yml` defines how this container will be configured:

```
services:
  nginx:
    restart: always
    image: nginx
    container_name: nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "/etc/nginx/conf.d"
      - "/etc/nginx/vhost.d"
      - "/usr/share/nginx/html"
      - "./volumes/proxy/certs:/etc/nginx/certs:ro"
```
We're exposing two ports, 80 (HTTP) and 443 (HTTPS), and we are also mounting several volumes into the container:

* Configuration folder: another container will generate the Nginx config, which will define how our Nginx reverse proxy server works
* Nginx root folder: used by the Let's Encrypt container as part of the certification process
* Certificate folder: A Let's Encrypt container will produce our HTTPS certifcates and store them here

### Nginx configuration container

This container handles setting up the configuration file for our main Nginx container.  We're using the (jwilder/docker-gen)[https://hub.docker.com/r/jwilder/docker-gen/] image for this.  

