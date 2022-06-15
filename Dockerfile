#Imagen inicial de la que se partimos
FROM nginx:alpine

#Actualiza sourcelist e Instalamos Java 8
RUN apk -U add openjdk8 \
    && rm -rf /var/cache/apk/*;
RUN apk add ttf-dejavu

#Instalamos microservicios java, definimos variables y argumentos
ENV JAVA_OPTS=""
ARG JAR_FILE
ADD ${JAR_FILE} app.jar

#Instalamos la app en el servidor nginx
#Creamos volumen, borramos directorio, copiamos ficheros, app y script
VOLUME /tmp
RUN rm -rf /usr/share/nginx/html/*
COPY nginx.conf /etc/nginx/nginx.conf
COPY dist/billingApp /usr/share/nginx/html
COPY appshell.sh appshell.sh

#Exponemos puerto 8080 para java swagger y puerto 80 para nginx
EXPOSE 80 8080

#Ejecutamos script
ENTRYPOINT [ "sh", "/appshell.sh" ]

