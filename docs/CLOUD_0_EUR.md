# Arquitectura con presupuesto cloud estricto de 0 €

**Decisión (octubre de 2026):** el usuario no autoriza gasto cloud. Queda fuera de alcance el aprovisionamiento de cualquier servicio de pago, aunque pudiera estar cubierto temporalmente por créditos promocionales.

## Componentes y coste

| Entorno | Herramientas | Política |
|---|---|---|
| Laboratorio histórico VMware | Ubuntu, HAProxy, Nginx, Docker, Prometheus, Grafana, Bash | Usar equipos existentes; no implica cloud |
| Demo local reproducible | Docker Compose + scripts + pruebas | Se ejecuta localmente con herramientas gratuitas |
| Validación automatizada | Runners estándar de GitHub Actions sobre repositorio público | Dentro de las condiciones gratuitas aplicables a repos públicos |
| Cloud opcional | OCI Always Free, solo recursos marcados elegibles | No provisionar sin verificar elegibilidad, región, disponibilidad y cuotas |

## Perfil local (recomendado primero)

- Importar configuraciones históricas reales, eliminar secretos y documentar el proyecto original.
- Construir un ejemplo autocontenido de HAProxy + dos servicios Nginx en Docker Compose.
- Documentar arranque, comprobaciones HTTP, fallo de un backend y restauración.
- Automatizar estas pruebas en GitHub Actions.
- Posteriormente implementar una pareja de HAProxy con Keepalived y una IP virtual en red L2 compatible.
- Distinguir el failover entre VM del failover físico: un único host Windows sigue siendo un punto único de fallo.

## Perfil OCI Always Free (opcional, después de la demo local)

**Diseño objetivo**, no provisionado:

~~~text
            Internet
               |
     OCI Always Free Load Balancer
         health checks HTTP
              /     \
             /       \
        VM backend A   VM backend B
       Linux + Nginx   Linux + Nginx
             \          /
       métricas + logs + pruebas
~~~

Se utiliza balanceador gestionado en OCI, **no** se asume que Keepalived/VRRP funcione entre zonas o subredes cloud. Si se desea una prueba de disponibilidad entre dominios de fallo, primero debe verificarse que ambos backends realmente se pueden distribuir y que el plano de balanceo cumple el requisito. Una configuración en una sola región no demuestra recuperación ante la caída de una región entera.

### Límites de referencia de la documentación oficial

- Hasta dos VM AMD micro elegibles, con recursos muy limitados.
- Equivalente en el plan gratuito de hasta 2 OCPU y 12 GB de RAM en Ampere A1 (ARM) compartidos entre una o dos instancias, sujeto a disponibilidad de capacidad.
- Almacenamiento Always Free: cupo combinado de 200 GB para volúmenes.
- Un balanceador Flexible Always Free con ancho de banda configurado a 10 Mbps.
- Crear solo en la región de origen donde correspondan los recursos gratuitos. Seleccionar únicamente recursos con etiqueta **Always Free Eligible**.
- Verificar compatibilidad ARM64 de las imágenes de contenedor.
- Nunca actualizar a cuenta de pago, solicitar shapes no elegibles o aceptar la creación de recursos facturables para superar una falta de capacidad.
- Los recursos de cómputo gratuitos inactivos pueden ser recuperados por Oracle, así que no se garantiza disponibilidad permanente.

Documentación oficial: https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm

### Regla de seguridad económica

1. Antes de aplicar Terraform, comprobar la disponibilidad y elegibilidad en OCI Console, los límites del tenancy y las opciones de la región.
2. Si algo exige una modalidad de pago o no es claramente Always Free, **no aprovisionar**.
3. Usar mínimos permisos, SSH por clave, puertos limitados y secretos fuera de Git.
4. Documentar destrucción y limpieza de recursos, aunque sean gratuitos.
5. Si OCI deniega capacidad, mantener la demostración local y las pruebas de GitHub Actions como resultado final.

No se debe presentar este diseño como infraestructura desplegada hasta que la configuración, las pruebas y la evidencia estén realmente disponibles.
