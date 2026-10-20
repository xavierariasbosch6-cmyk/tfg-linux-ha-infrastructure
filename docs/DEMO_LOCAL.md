# Demo reproducible — HAProxy + 2 Nginx (local, 0 EUR cloud)

**Estado:** codigo publicado; aun no validado mediante ejecucion real de Docker. Esta implementacion nueva es distinta de las tres VM originales del TFG.

## Requisitos

- Docker Engine + Docker Compose V2 (o Docker Desktop con Compose).
- Git.
- Para las pruebas: Bash, curl y awk (Linux, macOS o WSL).
- Puerto 8080 disponible en el equipo que ejecuta Docker.
- No hace falta AWS, Oracle Cloud, VMware ni contratar servicios de pago.

## Arquitectura

~~~text
Cliente local (http://127.0.0.1:8080)
                   |
            HAProxy :8080
             /        \
       node1:80       node2:80
       Nginx          Nginx
             red interna Docker
~~~

Docker Compose crea contenedores y red. HAProxy aplica HTTP round-robin, sondea /health y retira un backend cuando deja de estar sano. Cada pagina HTML permite ver que nodo atiende la peticion. El encabezado X-Backend-Node muestra el backend seleccionado.

**Advertencia:** un balanceador sigue siendo un punto unico de fallo. Esta primera demo verifica la continuidad tras perder un nodo backend, NO la alta disponibilidad completa del sistema.

## Arranque desde GitHub

En una terminal con Docker:

~~~bash
git clone https://github.com/xavierariasbosch6-cmyk/tfg-linux-ha-infrastructure.git
cd tfg-linux-ha-infrastructure
docker compose -f deploy/local/compose.yaml up -d --wait
docker compose -f deploy/local/compose.yaml ps
~~~

Navegar a http://127.0.0.1:8080 **desde la misma maquina donde se ejecuta Docker**.

El puerto se publica solo en la interfaz local, no en todas las interfaces de red. Para comprobar la cabecera:

~~~bash
for i in 1 2 3 4 5 6; do curl -sSI http://127.0.0.1:8080/ | grep -i x-backend-node; done
~~~

## Pruebas de balanceo y fallo

Con Docker y la demo iniciados:

~~~bash
bash scripts/test_local.sh
~~~

El script comprueba que ambos Nginx responden, detiene temporalmente node1, espera 5 segundos a que HAProxy reconozca el fallo, verifica que node2 sigue funcionando y vuelve a arrancar node1 para comprobar su reincorporacion. El script procura restaurar node1 tambien si una comprobacion falla.

La prueba **no mide cero interrupcion** durante esos primeros segundos, ni prueba un fallo del contenedor del balanceador, de Docker, del host, ni de una region cloud.

Prueba manual alternativa:

~~~bash
docker compose -f deploy/local/compose.yaml stop node1
# Despues de unos segundos:
curl -i http://127.0.0.1:8080/
docker compose -f deploy/local/compose.yaml start node1
~~~

## Inspeccionar y detener

~~~bash
docker compose -f deploy/local/compose.yaml logs -f lb
docker compose -f deploy/local/compose.yaml down --remove-orphans
~~~

Estos comandos se aplican solo al proyecto Compose tfg-linux-ha-demo; no apagan los servidores originales del TFG.

## Validacion automatizada

El workflow de GitHub Actions local-demo.yml intenta validar Compose e iniciar los contenedores para ejecutar la misma prueba de integracion. Hasta observar un resultado verde en Actions no afirmaremos que ha superado la prueba real.

## Lo que demuestra

- Configuracion declarativa de contenedores, volumenes y redes Docker.
- Balanceo HTTP con HAProxy y comprobaciones de salud.
- Despliegue reproducible desde GitHub.
- Verificacion de la caida de un backend y posterior recuperacion.
- Diferencia entre la redundancia de los servidores web y la alta disponibilidad global.

Siguientes fases: Keepalived + HAProxy redundante en red L2 compatible, monitorizacion real, Ansible, y opcion OCI Always Free con politica estricta de 0 EUR.
