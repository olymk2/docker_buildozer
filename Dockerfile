FROM     ubuntu:16.04
MAINTAINER Oliver Marks "oly@digitaloctave.com"


# make sure the package repository is up to date
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install -y \
        wget nano curl unzip zlib1g-dev lib32z1 \
        software-properties-common build-essential libc6-dev-i386 \
        python-dev python-pil git python-virtualenv python-pip python-markupsafe \
        default-jre openjdk-8-jre openjdk-8-jdk ragel android-tools-adb android-tools-fastboot expect


# Set permissions and create folders
WORKDIR /opt
RUN chmod -R 777 /opt 
RUN mkdir -p /opt/app/
RUN mkdir -p /opt/android/
# RUN mkdir -p /opt/app/.buildozer/android/
RUN mkdir /opt/test_build
RUN mkdir -p /opt/app/.buildozer/android/platform/python-for-android


# install cython and buildozer and add a user
RUN pip install cython==0.21.2 buildozer

RUN adduser --disabled-password --gecos 'builduser' builduser
RUN usermod -G plugdev,builduser builduser


# Get the adroid development environment and extract it
RUN wget http://dl.google.com/android/android-sdk_r22-linux.tgz && \
    wget http://dl.google.com/android/ndk/android-ndk-r8c-linux-x86.tar.bz2

RUN tar xvf /opt/android-sdk_r22-linux.tgz --directory /opt/android/ && \
    tar xvf /opt/android-ndk-r8c-linux-x86.tar.bz2 --directory /opt/android/ 
    
RUN tar xvf /opt/android-sdk_r22-linux.tgz --directory /opt/app/.buildozer/android/ && \
    tar xvf /opt/android-ndk-r8c-linux-x86.tar.bz2 --directory /opt/app/.buildozer/android/

RUN cd /opt/android/ && \
    git clone https://github.com/kivy/python-for-android.git

RUN cd /home/builduser


WORKDIR /opt/app

RUN chmod -R 777 /opt

USER builduser

#set android enviroment vars
ENV ANDROIDSDK /opt/android/android-sdk-linux_86/
ENV ANDROIDNDK /opt/android/android-ndk-r8c/
ENV ANDROIDNDKVER r8c
ENV ANDROIDAPI 14


#create a test build folder so we can run buildozer and get the android platform
WORKDIR /opt/test_build
RUN buildozer init
RUN buildozer android update
RUN buildozer android debug 

#switch to folder with sdk tools and pull in the missing SDK
WORKDIR /home/builduser/.buildozer/android/platform/android-sdk-20/tools 

RUN ./android list sdk --no-ui --all 
RUN echo y | ./android update sdk -u -a -t 1,2,5

EXPOSE 5037

# WORKDIR /opt/test_build
# RUN buildozer init
# RUN buildozer android update
# RUN buildozer android debug
RUN echo "builddir = /opt/buildozer/app" >> /opt/test_build/buildozer.spec
WORKDIR /opt/app

#RUN buildozer android update


#ENTRYPOINT ["/bin/bash", "-c", "echo 'buildozer android debug deploy run'"]
#ENTRYPOINT ["/bin/bash", "-c", "pwd && ls -la && buildozer android clean && buildozer android update"]
ENTRYPOINT ["/bin/bash", "-c", "buildozer android debug deploy run"]


