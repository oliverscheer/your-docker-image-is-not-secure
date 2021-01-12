FROM ubuntu:18.04

ARG SECRETPASSWORD

# Steps to install some prerequisites from an internal source with requires a SECRETPASSWORD to access
COPY install_prerequisities.sh . 
RUN chmod +x install_prerequisities.sh 
RUN ["./install_prerequisities.sh", "${SECRETPASSWORD}"] 

COPY entrypoint.sh . 

# App entry point
ENTRYPOINT [ "./entrypoint.sh" ]