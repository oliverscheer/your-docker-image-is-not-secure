FROM ubuntu:18.04 as installstage
ARG SECRETPASSWORD

COPY install_prerequisities.sh .
RUN chmod +x install_prerequisities.sh
RUN ["./install_prerequisities.sh", "${SECRETPASSWORD}"]

FROM ubuntu:18.04 as runstage
# COPY --from=installstage /opt/othersources /opt/othersources

COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

ENTRYPOINT [ "./entrypoint.sh" ]