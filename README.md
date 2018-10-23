# Hyperledger Burrow Workshop

![Meetup-vii-BlockchainDevelopers-HyperledgerBurrow](docs/assets/meetup-vii.jpg)
		
El pasado 17 de octubre comenzó la nueva temporada del [MeetUp Blockchain Developers](https://www.meetup.com/es-ES/Blockchain-for-developers/), realizando el séptimo encuentro en la sala de [Telefónica Flagship Store](http://flagshipstore.telefonica.es/Blockchain-Developers), titulado [“Monax & Hyperledger Burrow Workshop”](https://www.meetup.com/es-ES/Blockchain-for-developers/events/255052672/). En el evento, Miguel Martínez (yo mismo), miembro del equipo de [Blocknitive](https://blocknitive.com/), realizó una presentación sobre la plataforma Hyperledger Burrow desde un punto de vista técnico. También contamos con la presencia de una de las empresas impulsoras del proyecto, [Monax Industries](https://monax.io/). Chenxiao Hu Wu, Producer Experience Success, expuso la plataforma que lanzaron en abril de 2018, llamada [Agreements Network](https://agreements.network/). Para aquellos que no pudieron asistir, hemos subido [el video](https://www.youtube.com/watch?v=4hiiDi3mVno) a nuestro [canal de Youtube](https://www.youtube.com/blocknitive).

                     
Este post va dirigido a aquellos que quieran refrescar la segunda y última parte del workshop sobre Hyperledger Burrow. En esta parte nos pusimos manos a la obra y explicamos los primeros pasos a seguir para trabajar con esta plataforma. Estos mismos pasos se van a detallar a continuación, e incluyen las siguientes tareas:

1. Descarga e instalación de la última versión de Burrow
2. Permisionado de cuentas, configuración y lanzamiento del nodo Burrow
3. Ejecución de una transacción entre cuentas
4. Despliegue de un contrato inteligente escrito en Solidity
5. Interacción con el contrato utilizando JavaScript

¡Comencemos!


## 1. Descarga e instalación de Burrow

Hyperledger Burrow aún está en estado de incubación, pero todo el código se encuentra disponible en su [repositorio de GitHub](https://github.com/hyperledger/burrow) por lo que podemos descargarle y empezar a probarle. Para instalar Burrow en nuestra máquina, tenemos dos opciones: descargar el repositorio completo y construir un binario a partir de éste utilizando un compilador Go, o descargarnos directamente el binario correspondiente a nuestra arquitectura.

Vamos a seguir la segunda opción. Para ello nos dirigimos a la opción de [Releases](ttps://github.com/hyperledger/burrow/releases) del repositorio y descargamos el binario de su última versión (actualmente, la 0.22) para Linux x86_64. La arquitectura de mi equipo es de 64 bits, vosotros podréis comprobar la vuestra ejecutando el comando ```uname -a```. Este workshop se ha realizado con el sistema operativo *Ubuntu 16.04 LTS*. A continuación podeis encontrar los requisitos que necesitáis, y un enlace para descargarlos.

- [npm](https://www.npmjs.com/get-npm)
- [node](https://nodejs.org/es/)
- [Solidity Compiler (solc)](https://solidity.readthedocs.io/en/v0.4.25/installing-solidity.html#binary-packages)

Antes de nada, procedemos a descargar este repositorio.
```
cd $HOME
git clone https://github.com/blocknitive/workshop_hyperledger_burrow.git
cd $HOME/workshop_hyperledger_burrow
```
Nos movemos a una nueva carpeta, descargamos el binario 0.22 y descomprimimos el archivo:
```
mkdir $HOME/burrowchain && cd $HOME/burrowchain
wget https://github.com/hyperledger/burrow/releases/download/v0.22.0/burrow_0.22.0_Linux_x86_64.tar.gz
tar xvf burrow_0.22.0_Linux_x86_64.tar.gz
cp burrow /bin/burrow
PATH=$PATH:/bin/burrow
```

> Nota: Si quieres mantener esta instalación de forma indefinida debes introducir la última instrucción en archivos como ~/.profile o ~/.bash_profile.

Para comprobar que el cliente del nodo Burrow está instalado correctamente, ejecutamos:
```
burrow --version
```

## 2. Permisionado de cuentas, configuración y lanzamiento de Burrow
De forma análoga a *Ethereum*, para especificar las cuentas existentes se debe construir un archivo de configuración. Para ello, nos servimos de una de las opciones que nos provee el comando.
```
burrow spec -f 1 -p 3 > genesis-spec.json
```

Con ese comando hemos creado una cuenta con todos los permisos (incluido el de validar bloques), y tres cuentas participantes. Vamos a redefinir los permisos que tiene asignados cada cuenta, tomando como referencia lo indicado en la siguiente tabla. Para ello, modificamos el fichero que se ha creado, ```genesis-spec.json```.

| **Nombre**    |    **Permisos** |
| :---          |     :---:      |
| Full          |   *[ all ]*                                           |
| Operator      |   *[ send, call, createContract, name, hasRole ]*     |
| Writer        |   *[ call, name, hasRole ]*     |
| RgReader      |   *[ name, hasRole ]*     |

De esta manera, las cuentas creadas podrán realizar determinadas acciones de acuerdo con los permisos indicados:
- Full: cuenta con todos los permisos de la plataforma, incluido el permiso del que deben disponer las cuentas validadoras (*bond*). Como nuestra red solo tendrá 1 nodo, y éste debe ser validador, sólo podrá haber una cuenta validadora. Además, podrá realizar cualquier operación.
- Operator: dispone de los permisos necesarios para leer y ejecutar transacciones. Podrá desplegar smart contracts y llamar a sus funciones de lectura y escritura.
- Writer: podrá realizar las mismas acciones que la cuenta anterior, excepto la de desplegar contratos.
- RgReader: solo podrá tener acceso al registro de Burrow. No puede realizar transacciones ni llamar a código de smart contracts.

Una vez, realizada la especificación de las cuentas, pasamos a configurar el nodo Burrow. Utilizamos la opción ```burrow configure``` para crear el archivo de configuración *.toml* que después modificaremos a nuestro gusto.
```
burrow configure -s genesis-spec.json -n “BlockchainDevelopersChain” > burrow.toml
```

El archivo de configuración creado está dividido en varias partes:
- *GenesisDoc*: sobre las cuentas y sus permisos. Se listan en primer lugar todas las cuentas, y después por separado las cuentas validadoras. Las variables *Perms* y *SetBit* de *GlobalPermisions.Base* sirven para establecer los permisos que tendrán todas las cuentas por defecto. Establecemos dichas variables a 0 para que la configuración realizada anteriormente tenga efecto.
- *Tendermint*: sobre la red de nodos Burrow.
- *RPC*: sobre los puertos que expone en el nodo Burrow para interactuar con él. Se puede habilitar o deshabilitar cada uno de ellos. Habilitamos todos para poder probarles.
- *Logging*: sobre el histórico log que se crea durante la ejecución del cliente.

El aspecto de este archivo de configuración debe ser parecido a [*burrow.toml.old*](https://github.com/blocknitive/workshop_hyperledger_burrow/blob/master/burrow.toml.old).

¡Está todo listo para lanzar nuestra blockchain Burrow y empezar a jugar con ella! Para arrancar el nodo debemos seleccionar que cuenta validadora usar. En este caso usaremos la primera cuenta (y la única) de la lista de cuentas validadoras.
```
burrow start -v 0 2>burrow.log &
```

Para comprobar que Burrow esta funcionando correctamente debemos verificar que se están agregando bloques a la cadena, y que por lo tanto, se va incrementando la altura.
```
tail -10 burrow.log | grep height
```

Asimismo, podemos acceder a dos de los endpoints que provee Burrow desde el navegador. Si no hemos cambiado las direcciones por defecto de la configuración de RPC, en la dirección ```localhost:26658``` se puede ver información general de la cadena de bloques, y en ```localhost:9102\metrics``` métricas del nodo en tiempo real.

## 3. Ejecución de una transacción entre cuentas

Vamos a enviar una transacción de 5 unidades desde la cuenta *Full* a *Operator*. De forma que la primera cuenta tendrá 5 unidades menos que antes y, la segunda, 5 unidades más. Primero, debemos saber las claves públicas de ambas cuentas. Ejecutamos el siguiente comando para saber las claves las cuáles dispone nuestro nodo.
```
burrow keys list
```

Nos vemos a la carpeta ```workspace1``` y modificamos el fichero ```sendTransaction.yaml``` para cambiar la dirección destino por la clave pública de *Operator*. En ese archivo *-yaml* se pueden indicar los trabajos que queremos que se realicen. En este caso, el único trabajo que se ejecutará será el envío de la transacción.

Para ejecutarlo, debemos seleccionar el fichero que contiene los trabajos que se quieren lanzar y la clave privada de la cuenta origen. La ejecución del trabajo produce un *output* que indica el hash de la transacción que se ha realizado.

Con nuestro navegador podemos dirigirnos a la dirección ```localhost:26658/accounts``` y comprobar el cambio de “Amount” en ambas cuentas. ¡Acabamos de realizar nuestra primera transacción con Hyperledger Burrow!

Hasta aquí la primera parte del workshop. Dentro de poco publicaremos la segunda parte, dónde explicaremos como desplegar un contrato en Solidity y conectar con él desde un cliente Node.js.

### Stay tuned BlockchainDevelopers!

