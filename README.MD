# Dockerised Seafile

## Requires
[Docker Compose](https://docs.docker.com/compose/ "Docker Compose")

## Instructions

`cp docker-compose.yml.default docker-compose.yml`

1. Edit docker-compose.yml, changing all \*env_variables\* to your chosen passwords / settings etc.
2. Ensure that the specified domain (SERVER_IP) is pointed at your host
3. Ensure that your host is connectable on port 80/443

`docker-compose up (-d)`
