FROM onosproject/onos:latest

USER root
RUN apt-get update && apt-get install -y net-tools iputils-ping curl procps

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER root
WORKDIR /root/onos
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]


# docker build -t henok/onos-diam:v3 .
# Login to docker
# Logout if you are logged in to the required account
    # docker logout
    # docker login
    #         put your username and password
# docker tag henok/onos-diam:v3 henok28/onos-diam:v3
# docker push henok28/onos-diam:v3