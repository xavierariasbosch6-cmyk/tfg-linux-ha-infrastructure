# Recuperar el TFG original: paso a paso

**Estado: pendiente de exportar.** Este documento es un procedimiento para recuperar archivos reales de las tres máquinas Ubuntu de VMware Workstation. Los archivos históricos todavía **no se han publicado** en este repositorio.

## 1. Comenzar por el balanceador

| VM | IP original de laboratorio | Rol |
| --- | --- | --- |
| lb | 192.168.19.130 | HAProxy |
| node1 | 192.168.19.128 | Nginx y Docker |
| node2 | 192.168.19.129 | Nginx y Docker |

Inicia la máquina virtual **lb** en VMware Workstation e inicia sesión en Ubuntu.

Ejecuta:

~~~bash
hostname
ip -br -4 addr
sudo systemctl status haproxy --no-pager
~~~

Con esto identificamos la VM y comprobamos el balanceador original sin modificarlo.

## 2. Obtener el recolector de archivos

Si la VM tiene acceso a Internet y Git instalado:

~~~bash
git clone https://github.com/xavierariasbosch6-cmyk/tfg-linux-ha-infrastructure.git
cd tfg-linux-ha-infrastructure
bash scripts/export_original_tfg.sh lb
~~~

El script solicitará la contraseña local de sudo y guardará un archivo privado en tu carpeta personal con un nombre como:

~~~text
/home/TU_USUARIO/tfg-private-lb-XXXXXXXX.tar.gz
~~~

**El script no realiza envíos por red, ni ejecuta git push, ni instala paquetes.** Trabaja en una carpeta local protegida.

Si falta Git o no tienes Internet en Ubuntu, consulta primero con el asistente antes de instalar o cambiar la red; podemos acceder a las configuraciones directamente.

## 3. Qué recoge el script

- La configuración de HAProxy en /etc/haproxy/haproxy.cfg.
- Los archivos Netplan en /etc/netplan.
- Inventario local de servicios y contenedores.
- Entradas cron del usuario y de root.
- Una lista de posibles archivos Compose, Prometheus y Bash hallados en la carpeta personal.

Para node1 y node2 se utilizará exactamente el mismo script con el argumento correspondiente, y recogerá los ficheros habituales de Nginx en lugar de HAProxy.

El código Bash/Compose/Prometheus de usuario **no se copia automáticamente** porque antes debemos localizar qué archivos pertenecen realmente al TFG.

## 4. Importante: revisar antes de publicar

El exportador puede incluir datos confidenciales dentro de Netplan, HAProxy, Nginx o crontab. Por eso crea un archivo privado y nunca lo añade al repositorio.

- No subas directamente el archivo tar.gz a GitHub.
- No publiques claves privadas SSH, contraseñas, tokens, archivos .env ni certificados con claves privadas.
- No copies el contenido íntegro de un archivo de configuración al chat sin revisarlo.
- Eliminar un secreto de la versión actual de GitHub **no garantiza** que desaparezca del historial. Si se expone uno, habrá que revocarlo o rotarlo.

Para consultar los nombres de los archivos contenidos en el paquete sin mostrar sus contenidos:

~~~bash
tar -tzf /home/TU_USUARIO/tfg-private-lb-XXXXXXXX.tar.gz
~~~

Sustituye la ruta por la que haya mostrado el script.

Para leer la configuración original de HAProxy **dentro de Ubuntu** y revisarla antes de compartirla:

~~~bash
sudo less /etc/haproxy/haproxy.cfg
~~~

## 5. Transferencia al PC Windows (más adelante)

Si SSH está activo en Ubuntu y hay conectividad desde Windows, podremos utilizar scp en PowerShell para copiar **el archivo privado** a una carpeta de tu ordenador. Antes comprobaremos usuario, IP y ruta real. Si SSH no está activo, usaremos otro método; no es necesario modificar la VM todavía.

Después revisaremos los archivos, generaremos copias saneadas y los incorporaremos a las carpetas públicas correspondientes. Preservaremos la diferencia entre:
1. Originales del TFG realizado en junio de 2026.
2. Ampliaciones nuevas: laboratorio Docker, alta disponibilidad Keepalived, automatización e infraestructura cloud gratuita.

## 6. Siguiente ejecución

Repetir con node1 y node2:

~~~bash
bash scripts/export_original_tfg.sh node1
bash scripts/export_original_tfg.sh node2
~~~

Cada comando se ejecuta **dentro de la VM que corresponda**, no desde el Windows anfitrión. Los archivos extraídos deben revisarse antes de copiarlos a GitHub.
