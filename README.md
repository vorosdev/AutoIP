# AutoIP

AutoIP es un script de Bash que actualiza automáticamente la dirección IP pública en el servicio de DNS 
dinámico No-IP. Nace como una alternativa a los Dynamic Update Client (DUC) o Dynamic DNS Clients que 
no tienen soporte para sistemas legados o no compatibles.

## Requisitos

- `curl`: Para realizar solicitudes HTTP.
- `bash 4 o superior, incluso con versiones anteriores (ocupa ligeras modificaciones)`
- `cron`: Para automatizar la ejecucion del script

## Instalación

1. Clona este repositorio
2. Entra a la directorio del repositorio
3. Ejecuta ./setup.sh install con permisos de administrador
4. Modifica el archivo de configuracion con tus credenciales `/usr/local/etc/autoip/config.toml`

   ```toml
   noip.hostname = "tu_hostname"
   noip.usuario = "tu_usuario"
   noip.password = "tu_contraseña"
   noip.user_agent = "AutoIP script/debian-12.6 usuario1@test.com"
   ```

## Uso

El script se ejecutara de forma automatica cada 5 minutos usando una tarea cron.

1. Ejecuta el script:

   ```bash
   ./autoip.sh
   ```

2. El script obtendrá la IP pública desde varios servidores y la actualizará en No-IP si ha cambiado.

## Funcionalidades

- **Colores y logs:** Utiliza colores para resaltar los mensajes en la consola y registra eventos en un archivo de log.
- **Validación de IP:** Asegura que la IP obtenida sea válida antes de actualizar en No-IP.
- **Manejo de errores:** Registra diferentes tipos de mensajes (INFO, WARNING, ERROR) según la respuesta del servidor No-IP.

## Contribuciones

Las contribuciones son bienvenidas. Si deseas mejorar el script, siéntete libre de abrir un issue o un pull request.

## Licencia

Este proyecto utiliza la Licencia GPLv3. 
Tambien se incluyen binarios con licencia MIT del proyecto [tomlq](https://github.com/cryptaliagy/tomlq)
