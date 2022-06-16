FROM nginx:alpine
 # USAR VOLUMEN
VOLUME /tmp
RUN rm -rf /usr/share/nginx/html/*
COPY nginx.conf /etc/nginx/nginx.conf
COPY billingApp /usr/share/nginx/html
# EXPONER PUERTO PARA NGINX
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

