+++
Description = ""
comments = "yes"
date = "2015-04-23T21:50:49+01:00"
share = "yes"
tags = ["busybox", "ssl"]
categories = ["devop", "tutorial"]
title = "SSL support for Busybox docker containers"
+++

I am running my [official website](http://www.ralch.com) and this blog on busybox
docker containers. I noticed today that this image does not support
certificate trust stores and therefore cannot request an SSL-enabled web services.

My website is using [Google recaptcha](https://www.google.com/recaptcha/intro/index.html)
to handle spam requests on its contact form. However, the website throws the following
exception when recaptch API is requested:

`x509: failed to load system roots and no roots provided`

First approach would be to use [COPY](https://docs.docker.com/reference/builder/#copy)
command to load the certificate store bundle in to the image.

I do not want to keep the certificates on docker image, so I fixed the issue
by mounting the host's certificate store in to the container file system.

The following command is solving the issue for me:

```
CERT_DIR=/etc/ssl/certs

docker run -v $CERT_DIR:$CERT_DIR --name web -d busybox
```
