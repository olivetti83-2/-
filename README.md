Esta documentación no está acabada, son sólo apuntes que he ido añadiendo mientras realizaba la práctica.

Arrancar contenedor para probar la app http://localhost docker run -p 80:80 -p 8080:8080 --name facturacionapp oliverp83/facturacionapp:prod

Base de datos adminer y postgres (ejecutar con otro nombre docker-compose -f nombre archivo up -d) docker-compose up -d (Ya se puede entrar en adminer en http://localhost:9090 Cambiar base de datos a postgres y rellenar todos los campos con olivetti (definido en docker-compose.yaml))

4 apps diferentes misma red virtual: angular: frontend app springboot: backend app postgres (motor bbdd) adminer (app para conectarme a la base de datos)

Imagenes desde local: Dentro del repositorio Poner el engine del docker hacia el registro del minikube (sólo en la terminal), para que cuando minikube intente hacer el pull de las imagenes que utilice las imagenes que vamos a crear minikube docker-env (genera) eval $(minikube -p minikube docker-env) (aplica)

generar imagen backend - desde donde esté el jar docker build -t facturacionapp-back --no-cache --build-arg JAR_FILE=./*.jar .

generar imagen frontend - desde la carpeta src/angular docker build -t oliverp83/facturacionapp-front --no-cache .

Subir las imagenes a docker hub

Montar servicio de bbdd

kubectl apply -f ./ (desde la carpeta cd /k8s/db)

K8S
Monto el servicio del motor de datos postgres y un adm web, tengo dos pods que representan las dos app y monto un servicio
que pueda acceder a esos dos pods de tal manera que un usuario pueda acceder a través de la web a la aplicacion para hacer modificaciones
También dejo una opción abierta para que se puedan conectar a la base de datos usando otro cliente que no sea pgadmin, es una parte que podría montarse o no... pero bueno está montada...
El pod de bbdd contiene una imagen de postgress un volume para que mantenga la información y monto otro volumen con un script de iniciación de ese pod de tal manera que cuando se inicie cree una bbdd propia que se necesitará  para la app y para crear usuarios, al final termino con la infraestructura necesaria para trabajar con la bbdd antes de pasar a instalar la app

Primero creo los manifiestos de los pods de las apps, defino los deployment para postgress y pgadmin, utilizan ficheros de configuracion para almacenar usuarios y pass y la definicion de los volumenes que tenemos aquí
Empecé por lo más básico que fueron los ficheros de configuración que van a tener los usuarios para la bbdd y para acceder al pgadmin 
(secret-dev.yaml) - aquí manejamos la contraseña y el usuario y está codificado en base 64
(secret-pg-admin) lo unico que cambia son las variables, que las he sacado de las variables de la imagen oficial de pgadmin
Después definí los volúmenes y las imagenes de cada uno de los pods persistent-volume, el almacenamiento persistente independiente del ciclo de vida de los pods. Digo que se crea manual, le doy 5gb y es de lectura y escritura, el punto de montaje es mnt/data/ que es donde se almacenará la base de datos
El claim tiene la definición que es la parte importante donde digo que la petición va a tomar dos gigas y que va a tener acceso de lectura y escritura desde los pods 

Luego el configmap que lo utilizo para pasar un sh para que se conecte al motor de base de datos y que cree un usuario, la base de datos y que le otorgue privilegios

Luego construyo los pods y lo uno todo con las imagenes que me las bajo de dockerhub y lo meto dentro de un fichero de configuración que es el deployment, creo postgres y luego pgadmin, aquí defino los detalles, sin alta disponibilidad porque se lo daré a la app, defino que para todos los pods asigne el label de postgres, defino el contenedor, la imagen de la que va a partir, defino los puertos que bueno es el que viene por defecto en postgres, hago referencia al secret para que cuando se inicie pues vaya a las variables del secret, utilizo volumenes, postgres utiliza una ruta por defecto, la parte de los volumenes defino dos, uno para los datos de la base de datos y otro para el script que defino en el configmap, el primer volumen va a ser variable y defino el claim que es como el disco duro, definimos que de 5 gigas tiene 2 para asignar al motor de datos postgres

definicion pod postgres (deployment)
le paso el tipo, la metadata y defino los pods que en este caso va a ser uno (replicas), no se crea manual porque lo va a crear el automatico, en los selectores indicamos como manejamos los diferentes pods que se crean para la solución, todos los que coincidan con la palabra postgres y se le asigna una label y los selectores pues son eso para que el cluster sepa como identificarlos de esa app
La definicion del contenedor, nombre e imagen de la que parte, del repositorio de dockerhub, que haga un pull y definimos los puertos el del contenedor o la app de postgres que es el puerto por defecto. Las variables de entorno coge de referencia el secret de postgress.
Los volumenes como la bbdd utiliza una ruta por defecto, lo guardo a parte en un volumen independiente que sea persistente, le indico lo que va a montar en el volumen, en los volumenes hay dos uno almacena los datos de la bbdd y otro el script definido en el configmap que creará otra base de datos, el primer volumen almacenara toda los datos de la base de datos

definicion pod pgadmin (deployment)
le paso el tipo, la metadata, defino el pod como va a ser una replica, el template y la especificacion de la imagen que la descarga de dockerhub y hace referencia a unas variables de entorno que hemos definido en el secret del pgadmin y el puerto que abrimos dentro del contenedor para la conectividad, lo único que varía del anterior son los datos propios.

Los servicios  postgress el primero es postgres, el contenido la metadata le indico que es un service y la especificación le digo que tiene el puerto por defecto interno y que se expone al 30432 al exterior, el tipo de servicio es Nodeport porque solo hay un nodo, para que se pueda acceder a través de la ip del cluster y del puerto 
pgadmin servicio, nombre y mapeo los puertos interno y externo.

Después hice la orquestación de la app expongo dos servicios mas el frontend con nginx y el backend en spring, el frontend va a tener dos pods y el backend tres, el backend necesita conectarse con la base de datos postgres por lo que modifiqué la ip y le asigné una fija para que tenga una manera eficiente de comunicarse independientemente de las veces que cambie el pod
El front está en angular y se traduce a html que se ejecuta en el navegador del usuario, la petición al microservicio se hace desde el navegador del usuario hace la peticion al servicio y el servidor nginx busca y le devuelve el código necesario para ejecutar la llamada, en realidad se hace desde el navegador al backend a traves de la ip de minikube


PGADMIN: 

ip minikube (minikube ip) y puerto 30200  http://192.168.49.2:30200

New server: General Ponemos un nombre: posgresService Connection Ponemos la ip de minikube y el puerto 30200 Nombre DB, Usuario y Password (secret-dev.yaml - codificado en base64 - descodificar: echo "valor" | base64 -d) y 

Creamos otro server, ahora nos vamos a conectar a la base de datos que hemos creado en el configmap-postgres-initbd.yaml General Ponemos un nombre: posgresPod (esta conexión es opcional, es por si alguien no quiere acceder a través de pgAdmin) Connection Usaremos la Ip del servicio y el puerto interno Nombre DB, Usuario y Password (configmap-postgres-initbd.yaml)

jenkins: 
pom.xml - primero se ha creado un pipeline con maven y github para descargar github en jenkins

ngrok - configuramos el webhook y garantizamos el funcionamiento de este proxy porque nuestro repositorio que está en internet a través del puerto configurado nos envía mensajes a nuestra máquina local cada vez que se haga un push . 

Se crea un pipeline para que de manera automática cada vez que hacemos un cambio o hacemos un push (en la rama seleccionada) a nuestro repositorio se envíe un evento y ese evento sea capaz de disparar ese pipeline que tenemos construído. 

Pipeline, que ejecute pruebas automáticas y si va bien se hace el merge

slack: para que nos lleguen notificaciones al canal que queramos

sonarqube
descargar imagen docker pull sonarqube
levantar contenedor docker run -d --name sonarqube -p 9000:9000 sonarqube
creamos una red docker network create jenkins_sonarqube
conectamos contenedor de sonarqube con docker network connect jenkins_sonarqube sonarqube
y lo mismo con el contenedor de jenkins docker network connect jenkins_sonarqube jenkinsblue
para verificarlo docker container inspect sonarqube | grep jenkins_sonarqube y lo mismo con el contenedor de jenkins

ya puedes ir a http://localhost:9000
el usuario y la contraseña por defecto son admin/admin


crear imagen desde jenkins
ip route show default | awk '/default/ {print$3}'
ip a -buscamos docker 0 porque esa es la direccion que vamos a utilizar para que nuestro contenedor de jenkins se pueda comunicar con nuestro host y pueda acceder al docker engine




PROMETHEUS:
aplicamos la autorización(kubectl apply -f authorization-prometheus.yaml), lo veremos en el dashboard que se ha creado el cluster role

configmap-prometheus.yaml - con una de las reglas más comunes, se define una alerta del uso de memoria que tiene que ver con los pods si supera 1 bit, la segunda parte tiene la configuración global, se define un intervalo de 5 segundos, se cargan las reglas y se mandan al alert manager (puerto 9093) y después tenemos la configuración de los trabajos de kubernetes que se encargan de la información para que más tarde podamos usarla.
El primer job se encarga de recuperar toda la información del cluster (cadvisor)
El segundo job nos permite obtener las métricas del apiserver
El tercero se encarga de los nodos, de recopilar la información, métricas, cpu memoria...
El cuarto se encarga de recopilar info de los pods
El quinto se encarga de recuperar la info de los endpoints (configuración estándar)
EL sexto kubernetes state metrics (/kube-state-metrics) definimos un componente de k8s que se encarga de la información del estado de todos los objetos que tenemos

deployment: utilizamos un contenedor con una imagen de dockerhub de prometheus definimos los atributos servicio los puertos, recursos de memoria  en definitiva la instalación como tal. Montamos los volumenes (def en configmap) que serán los que nos permitan mantener la información y la definición del servicio para que sea accesible fuera del cluster
Aplicamos con kubetcl apply -f deployment-prometheus.yaml y seguido hacemos un kubectl get all --namespace monitoring, vemos el servicio que está escuchando en el puerto 30000 y buscamos la ip de minikube con el comando minikube ip y accedemos a la interfaz gráfica de prometheus

En status target vemos todos los jobs
kube-state-metrics saldrá en rojo porque no está creado dentro del cluster

Le damos a buscar container memory rss y le damos a ejecutar, si le damos a graph nos muestra una gráfica más amigable

Podemos ver las reglas en status rules que es la regla definida en el configmap

En alerts vemos la alerta por memoria que tenemos configurada, y el estado que es firing, alerta que se está ejecutando constantemente


Solucionar el problema del target, configuramos el kube-state-metrics,
cluster-rol-ksm.yaml - definimos recursos a los que puede acceder el rol y los permisos para tener la mayor cantidad posible de todos los objetos que tenemos dentro del cluster, sino no podríamos obtener el estado...
lo utilizamos en el archivo de autorización, creamos un serviceaccount especifico para asociarlo al cluster-rol para poder utilizarlo en el nuevo servicio, es sólo autorización a ciertos roles y ciertas cuentas
y el ultimo fichero es la definición como tal del servicio porque necesitamos que se le asigne una ip para que sea accesible por el servicio de prometheus
Entonces procedemos a aplicar los archivos y verificamos que k8-state-metrics cambie de color y ya tendríamos todo listo para trabajar con prometheus

ALERT MANAGER:
Tres archivos configuración, almacenamiento y despliegue, igual que los otros.
El manager es el responsable de manejar todas las alertas, decidir que hace con ellas, se instala partiendo de la imagen alertmanager de prometheus
Almacenamiento: persistent volume claim, montamos el "disco duro"
Configuración: definimos metadata, luego definimos que cree de manera automática el yaml de alert manager que es el que va a tener la configuración,
también definimos el canal de slack...(url utilizando webhooks)
La alerta está definida en configmpa-prometheus que la envía al alert manager y en el configmap del alertmanager definimos como procede cuando le lleguen ese tipo de alertas.
Deployment elegimos partir de la imagen del alertmanager, montamos el archivo como volumen, el puerto 9093, definimos recursos: memoria, cpu y luego el servicio para que se pueda acceder desde fuera del cluster
Aplicamos la configuración. Y podríamos acceder al AlertManager con la ip de minikube y el puerto 31000


GRAFANA:
configuración global de grafana, primero metadata y despues definimos un fichero que se llama prometheus.yaml donde tenemos un datasource, que de momento sólo hay uno, este es el que vamos a incluir y lo definimos ahí, es el del servicio de prometheus lo importante aquí es el endpoing que tiene que coincidir con el de prometheus, el nombre del servicio y el puerto interno dentro del cluster (8280) 
deployment: primero metadata como siempre, definimos la especificación del contenedor, la imagen, pasamos parámetros, definimos recursos y montamos un volumen y despues está la definición del servicio como tal, están los puertos 3000 el que asigna el cluster, el de grafana que es el 3000 y el que asignamos nosotros que en este caso es el 32000

Accedemos con la ip de minikube y el puerto asignado en este caso el 32000, la contraseña es admin/admin

He utilizado un dashboard predefinido en concreto el 6417, lo he añadido en dashboards import y he metido el id y abajo he seleccionado prometheus, le das a importar y se te carga.
Toda esta información viene de los jobs
