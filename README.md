# AEM Container Image

A container image to run Adobe Experience Manager Cloud SDK in a container. It
provides a vanilla AEM instance with minimal configuration. The type of instance
(author, publish) is defined at runtime via an environment variable. In
addition, it is build as a multiarch image (amd64, arm64) to support different
OS and platforms.

Also check out https://github.com/frieder/dispatcher for a container image of Adobe
Dispatcher and https://github.com/frieder/aemdev for an example project how to use
those containers in an actual development environment both locally and on AWS cloud.

# How To Use

> The namespace `frieder/*` and the registry `ghcr.io` are just for demo purposes.
> Replace it with your company namespace and push it to your own private registry.

First you have to log into your corporate container registry.

```shell
export TOKEN=***
export USER=frieder
# docker.io | ghcr.io | ...
export REGISTRY=ghcr.io

echo ${TOKEN} | docker login ${REGISTRY} -u ${USER} --password-stdin
```

Next you can pull the images from your container registry. We distinguish between a
`stable` version representing the installation on production and `latest` being in 
sync with the Cloud Manager dev environment. This way you can test your code against
the next SDK version prior to upgrading production.

```shell
export NAMESPACE=frieder

docker pull ${REGISTRY}/${NAMESPACE}/aem:stable
docker pull ${REGISTRY}/${NAMESPACE}/aem:2023.11

docker pull ${REGISTRY}/${NAMESPACE}/aem:latest
docker pull ${REGISTRY}/${NAMESPACE}/aem:2023.12
```

Once you are able to successfully pull the container image from the registry you can
then start the containers. Please adapt the arguments according to your needs.

```shell
# aem instance
docker run -d \
  --name author \
  -e TZ="Europe/Zurich" \
  -e JVM_XMX="4g" \
  -e JVM_META="256m" \
  -e AEM_RUNMODE="author,aemdev" \
  -p 4502:4000 \     # http
  -p 14502:30303 \   # debug
  -p 24502:8686 \    # jmx
  -v $(pwd)/author/repo:/aem/crx-quickstart/repository \
  -v $(pwd)/author/logs:/aem/crx-quickstart/logs \
  -v $(pwd)/author/install:/aem/crx-quickstart/install \
  ${REGISTRY}/${NAMESPACE}/aem:stable
```

The command for the publish instance is basically the same except for
the ports and the runmode.

Once the containers are created you can use the following commands to start/stop
the containers.

```shell
docker start author
docker stop author -t 180
```

When stopping the AEM container make sure to set the wait time to an appropriate
value (e.g. `180s`). By default, Docker will only wait for `10s` for a container
to stop and then just kill it. This however could lead to issues with the
repository, so we should try to avoid this from happening.

# How To Build

The pipeline script at [.github/workflows/build.yml](.github/workflows/build.yml)
shows a working example of a GH build pipeline that pulls the data from a remote
artifact repository (Nexus OSS) and prepares them for the use in the build pipeline.
Another way to do it is with gitlfs and then apply gitops to build new images upon
code commits. Since we cannot share the AEM binaries and license file publicly, you'll 
have to adapt the build pipeline yourself if you want to go this route.

Before you can start building the image you have to make sure the quickstart jar is
available at `./tmp/aem-sdk-quickstart.jar` and the license file exists at
`./tmp/license.properties`. The Dockerfile will then pick up the files and add them
to the image.

Once this is done the image can be built by running the following command.

```shell
# aem image
docker build \
  --build-arg PKG="curl wget" \
  --build-arg LOCALE="en_GB.UTF-8" \
  --tag ghcr.io/frieder/aem:latest \
  .
```

All build arguments are optional. When absent, the `LOCALE` argument uses `en_GB.UTF-8`
to support the 24h time format and the `PKG` argument is empty by default. There are
also some hard-coded arguments in [scripts/start.sh](scripts/start.sh) that are provided
to both the JVM and AEM and cannot be changed directly. If you don't like those settings
I'd suggest you either adapt the bash script to your needs or make them available as
build arguments.

Also consider using [Docker buildx](https://docs.docker.com/engine/reference/commandline/buildx/)
to create native container images for different platforms like `amd64` and `arm64`. This
can greatly improve the performance of the local AEM container instance (e.g. when
using Macbooks). An example on how to do this can also be found in the GH build pipeline.
