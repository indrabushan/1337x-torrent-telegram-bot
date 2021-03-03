FROM node:12 as builder

WORKDIR /app/

COPY package.json .
COPY yarn.lock .

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        libicu57 \
        libssl1.1 \
        libstdc++6 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*
	
ENV DOTNET_SDK_VERSION 3.0.103

RUN curl -SL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Sdk/$DOTNET_SDK_VERSION/dotnet-sdk-$DOTNET_SDK_VERSION-linux-x64.tar.gz \
    && dotnet_sha512='22acd337c1f837c586b9d0e3581feeba828c7d6dc64e4c6c9b24bdc6159c635eb7019c3fb0534edeb4f84971e9c3584c7e3a4d80854cf5664d2792ee8fde189b' \
    && echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -zxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
	&& ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet
	
RUN yarn install 

COPY . .

RUN yarn build

FROM node:12-alpine

LABEL name=com.xbimz.torrent.bot

ENV NODE_ENV=production
ENV NPM_CONFIG_LOGLEVEL=warn

WORKDIR /app/

COPY package.json .
COPY yarn.lock .

RUN yarn install

COPY --from=builder /app/build .
COPY --from=builder /app/src/js/healthcheck.js .

EXPOSE 3000

CMD ["node", "App.js"]

HEALTHCHECK CMD node healthcheck
