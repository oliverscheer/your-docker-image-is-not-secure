# Your Docker Image Is Not Secure

This title is very sensational, and should be better called:  
> Multistage docker builds to avoid storing sensitive data in container image

During a recent project, our team recognized some challenges when you work with arguments passed to docker build process.
When you pass arguments to docker build via `--build-arg` and use them in the docker file, those
are persisted in the docker history and can be retrieved by everyone.

## The Problem

Imagine you have the following dockerfile ([Sourcefile](problem/dockerfile)):

```dockerfile
FROM ubuntu:18.04

ARG SECRETPASSWORD

# Steps to install some prerequisites from an internal source with requires a SECRETPASSWORD to access
COPY install-some-prerequisites.sh . 
RUN chmod +x install-some-prerequisites.sh 
RUN ["./install-some-prerequisites.sh", "${SECRETPASSWORD}"] 

COPY entrypoint.sh . 

# App entry point
ENTRYPOINT [ "./entrypoint.sh" ]
```

The critical line the line starting with `ARG`. Everything else is only for demostration purpose.  
The line with the `install-some-prerequisites.sh` file is required to install requirements that are not public available, for example special private packages.

You can build the image with the following command, where you pass a secret password (P@ssw0rd) to docker with the `--builad-arg` argument. You may need `--build-arg` for retrieve some packages from internal/local/remote/non-public repositories.

```bash
docker build -t myunsecureimage --build-arg SECRETPASSWORD=P@assw0rd .
```

You publish this image to any repository for usage by others. Those "others" can now retrieve important data from your image with the `docker history` [command](https://docs.docker.com/engine/reference/commandline/history/):

```bash
docker history myunsecureimage:latest
```

The Output will look similar to this:

```text
IMAGE          CREATED        CREATED BY                                      SIZE      COMMENT
577ef3504b21   14 hours ago   ENTRYPOINT ["./entrypoint.sh"]                  0B        buildkit.dockerfile.v0
<missing>      14 hours ago   RUN |1 SECRETPASSWORD=P@assw0rd ./install-so…   0B        buildkit.dockerfile.v0
<missing>      14 hours ago   RUN |1 SECRETPASSWORD=P@assw0rd /bin/sh -c c…   74B       buildkit.dockerfile.v0
<missing>      14 hours ago   COPY install-some-prerequisites.sh . # build…   74B       buildkit.dockerfile.v0
<missing>      14 hours ago   ARG SECRETPASSWORD                              0B        buildkit.dockerfile.v0
<missing>      6 weeks ago    /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B        
<missing>      6 weeks ago    /bin/sh -c mkdir -p /run/systemd && echo 'do…   7B        
<missing>      6 weeks ago    /bin/sh -c [ -z "$(apt-get indextargets)" ]     0B        
<missing>      6 weeks ago    /bin/sh -c set -xe   && echo '#!/bin/sh' > /…   745B      
<missing>      6 weeks ago    /bin/sh -c #(nop) ADD file:6ef542de9959c3061…   63.3MB    
...
```

> The "secret" password isn't that secret anymore in this history of the docker image.

## The Solution

In our project we need access to some internal sources in a private repository, to install some prerequisites.
After the installation, we don't need access to these repositories anymore, and therefore we don't need the password anymore.

> With simple one stage dockerfile, we keep those credentials in the history. And this is a big security thread.
> It would enable everyone with access to the container access to retrieve the password.

We can avoid this problem with the following approach:

1. Dockerfile for Multistage Build ([Sourcefile](solution/dockerfile)):

    ```dockerfile
    FROM ubuntu:18.04 as installstage
    ARG SECRETPASSWORD

    COPY install-some-prerequisites.sh .
    RUN chmod +x install-some-prerequisites.sh
    RUN ["./install-some-prerequisites.sh", "${SECRETPASSWORD}"]

    FROM ubuntu:18.04 as runstage
    # COPY --from=installstage /opt/othersources /opt/othersources

    COPY entrypoint.sh .
    RUN chmod +x entrypoint.sh

    ENTRYPOINT [ "./entrypoint.sh" ]
    ```

1. Build the container:

    ```bash
    docker build -t mysecureimage --build-arg secretpassword=P@assw0rd .
    ```

1. Validate the history:

    ```bash
    docker history mysecureimage:latest
    ```

    The Output will look like these, without the secret password:

    ``` text
    IMAGE          CREATED        CREATED BY                                      SIZE      COMMENT
    42e0e9ded62b   1 second ago   ENTRYPOINT ["./entrypoint.sh"]                  0B        buildkit.dockerfile.v0
    <missing>      1 second ago   RUN /bin/sh -c chmod +x entrypoint.sh # buil…   81B       buildkit.dockerfile.v0
    <missing>      1 second ago   COPY entrypoint.sh . # buildkit                 81B       buildkit.dockerfile.v0
    <missing>      6 weeks ago    /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B        
    <missing>      6 weeks ago    /bin/sh -c mkdir -p /run/systemd && echo 'do…   7B        
    <missing>      6 weeks ago    /bin/sh -c [ -z "$(apt-get indextargets)" ]     0B        
    <missing>      6 weeks ago    /bin/sh -c set -xe   && echo '#!/bin/sh' > /…   745B      
    <missing>      6 weeks ago    /bin/sh -c #(nop) ADD file:6ef542de9959c3061…   63.3MB    
    ```

    > You don't the secret password here.

## Summary

Using multistage builds has a lot of advantages. One of them is keeping secrets in earlier stages secret in later stages.

## Links

* [Docker Documentation - Use multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/)
* [Docker History Reference](https://docs.docker.com/engine/reference/commandline/history/)
