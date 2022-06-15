
Arrancar contenedor para probar la app http://localhost
    docker run -p 80:80 -p 8080:8080 --name facturacionapp oliverp83/facturacionapp:prod

Base de datos adminer y postgres (ejecutar con otro nombre docker-compose -f nombre archivo up -d)
    docker-compose up -d
    (Ya se puede entrar en adminer en http://localhost:9090 Cambiar base de datos a postgres y rellenar todos los campos con olivetti (definido en docker-compose.yaml))

4 apps diferentes misma red virtual:
    angular: frontend app
    springboot: backend app
    postgres (motor bbdd)
    adminer (app para conectarme a la base de datos)

Imagenes desde local:
Dentro del repositorio
Poner el engine del docker hacia el registro del minikube (sólo en la terminal), para que cuando minikube intente hacer el pull de las imagenes que utilice las imagenes que vamos a crear
minikube docker-env (genera)
eval $(minikube -p minikube docker-env) (aplica)

generar imagen backend - desde donde esté el jar
docker build -t facturacionapp-back --no-cache --build-arg JAR_FILE=./*.jar .

generar imagen frontend - desde donde esté el jar
docker build -t oliverp83/facturacionapp-front --no-cache .

Subir las imagenes a docker hub

Montar servicio de bbdd

pgAdmin:
ip minikube (minikube ip) y puerto 30200
New server:
    General
        Ponemos un nombre: posgresService
    Connection
        Ponemos la ip de minikube y el puerto 30200
        Nombre DB, Usuario y Password (secret-dev.yaml - codificado en base64 - descodificar: echo "valor" | base64 -d)
Creamos otro server, ahora nos vamos a conectar a la base de datos que hemos creado en el configmap-postgres-initbd.yaml
    General
        Ponemos un nombre: posgresPod (esta conexión es opcional, es por si alguien no quiere acceder a través de pgAdmin)
    Connection
        Usaremos la Ip del servicio y el puerto interno 
        Nombre DB, Usuario y Password (configmap-postgres-initbd.yaml) 



