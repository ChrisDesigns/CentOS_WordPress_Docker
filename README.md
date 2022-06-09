# CentOS_WordPress_Docker
Docker image to add support for running WordPress on CentOS

# Running 
This repository comes with an example directly from the [offical image](https://hub.docker.com/_/wordpress/), in order to run as docker-compose. Just clone this repository and run the following to bring up the containers:
```sh
docker-compose up --build -d
```


## Note:
This work is based on the previous works of [WordPress Docker image](https://github.com/docker-library/wordpress). 
However, all the supported underlying operating systems were Debian/Alpine based and lacked support for CentOS.
While it is not recommended to use this version over the prior, mostly due to image size, this could be useful for verfiying the install process.
