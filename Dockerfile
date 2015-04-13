FROM busybox 

MAINTAINER Svett Ralchev <svetlin.ralchev@gmail.com>

ENV TMP_DIR /tmp
ENV HOME_DIR /var/vcap
ENV LOG_DIR ${HOME_DIR}/sys/log
ENV JOB_DIR ${HOME_DIR}/jobs
ENV WEB_DIR ${JOB_DIR}/ralch-blog

ENV HUGO_VERSION 0.13
ENV HUGO_ARCHIVE hugo_${HUGO_VERSION}_linux_amd64.tar.gz
ENV HUGO_URL https://github.com/spf13/hugo/releases/download/v${HUGO_VERSION}/${HUGO_ARCHIVE}
ENV HUGO_DIR hugo_${HUGO_VERSION}_linux_amd64
ENV HUGO_BINARY hugo_${HUGO_VERSION}_linux_amd64

RUN mkdir -p $HOME_DIR 
RUN mkdir -p $LOG_DIR
RUN mkdir -p $JOB_DIR 
RUN mkdir -p $WEB_DIR

RUN apt-get update
RUN apt-get install wget -y
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

WORKDIR $TMP_DIR

RUN wget $HUGO_URL 
RUN tar xzvf $HUGO_ARCHIVE
RUN cp $TMP_DIR/$HUGO_DIR/$HUGO_BINARY /bin/hugo

RUN rm -fr $HUGO_ARCHIVE
RUN rm -fr $HUGO_DIR

ADD  ./web $WEB_DIR

WORKDIR $WEB_DIR

EXPOSE 1313

ENTRYPOINT ["hugo", "server", "-w"]

