# MRF24J40MA
Esta librería es para el manejo del transceptor MRF24J40MA junto con cuatro servicios necesarios para tener una red funcional en aplicaciones de robótica de enjambre. La librería fue probada con éxito junto con un Arduino Nano. Para utilizar esta librería es necesario cambiar la configuración del SPI acorde al microcontrolador utilizado y  conocer cómo configurar un timer y la interrupción de un GPIO.

# Índice

 - **Protocolo**
 - **Servicios**
 - **Configuración**
 - **Estructuras, métodos y funciones**

# Protocolo
El transceptor tiene la capacidad de utilizar el protocolo de Zigbee para comunicarse. Sin embargo, la librería para este transceptor no es de código abierto ya que también cuenta con su propio protocolo para comunicación, que el proveedor espera que se utilice. Por lo tanto, esta librería esta construida para que MRF24J40MA utilice Zigbee.

Zigbee es un estándar que define un protocolo de comunicación para baja velocidad y una red de corto alcance, pero es de bajo consumo de potencia. Los dispositivos basados en ZigBee operan en las frecuencias de 868 MHz, 915 MHz y 2.4 GHz. Puede llegar a transmitir hasta 250 Kbps. Esta tecnología esta enfocada hacia aplicaciones que requieran costo bajo, baja transmisión de datos y el mayor tiempo de vida posible usando baterías.

En este estandar se definen dos tipos de dispositivos: Dispositivos de funcionalidad reducida (RFD) y Dispositivo de funcionalidad completa (FFD). Para esta librería se definen todos los dispositivos como FFD para que todos los nodos puedan funcionar en todos los servicios desarrollados. Adicionalmente, Un nodo se debe de configurar como coordinador y todos los demás como nodos.

# Servicios

## Servición de asociación
Este servicio permite a cada nodo asociarse a una PAN existente. Primero se necesita que exista un coordinador y luego cada nodos puede ejecutar el servicio de asociación.

[![](https://mermaid.ink/img/eyJjb2RlIjoic2VxdWVuY2VEaWFncmFtXG5Db29yZGluYWRvci0tPiBOb2RvOiBcbk5vZG8tPj4gQ29vcmRpbmFkb3I6IFF1aWVybyB1bmlybWVcbkNvb3JkaW5hZG9yLT4-IE5vZG86IENvbmZpcm1hY2nDs25cbk5vdGUgcmlnaHQgb2YgTm9kbzogRXNwZXJhIGxhIGluZm9ybWFjacOzbiBkZSBsYSByZWRcbkNvb3JkaW5hZG9yLT4-IE5vZG86IEluZm9ybWFjacOzbiBkZSBsYSBQQU5cbk5vZG8tPj4gQ29vcmRpbmFkb3I6IENvbmZpcm1hY2nDs25cbiIsIm1lcm1haWQiOnsidGhlbWUiOiJkZWZhdWx0In0sInVwZGF0ZUVkaXRvciI6ZmFsc2UsImF1dG9TeW5jIjp0cnVlLCJ1cGRhdGVEaWFncmFtIjpmYWxzZX0)](https://mermaid-js.github.io/mermaid-live-editor/edit#eyJjb2RlIjoic2VxdWVuY2VEaWFncmFtXG5Db29yZGluYWRvci0tPiBOb2RvOiBcbk5vZG8tPj4gQ29vcmRpbmFkb3I6IFF1aWVybyB1bmlybWVcbkNvb3JkaW5hZG9yLT4-IE5vZG86IENvbmZpcm1hY2nDs25cbk5vdGUgcmlnaHQgb2YgTm9kbzogRXNwZXJhIGxhIGluZm9ybWFjacOzbiBkZSBsYSByZWRcbkNvb3JkaW5hZG9yLT4-IE5vZG86IEluZm9ybWFjacOzbiBkZSBsYSBQQU5cbk5vZG8tPj4gQ29vcmRpbmFkb3I6IENvbmZpcm1hY2nDs25cbiIsIm1lcm1haWQiOiJ7XG4gIFwidGhlbWVcIjogXCJkZWZhdWx0XCJcbn0iLCJ1cGRhdGVFZGl0b3IiOmZhbHNlLCJhdXRvU3luYyI6dHJ1ZSwidXBkYXRlRGlhZ3JhbSI6ZmFsc2V9)

## Servicio de sincronización
Este servicio sincroniza los mensajes de todos los nodos en la red. El coordinador informa a cada nodo cuando enviar su mensaje.

[![](https://mermaid.ink/img/eyJjb2RlIjoic2VxdWVuY2VEaWFncmFtXG5Db29yZGluYWRvci0tPiBOb2RvIDE6IFxuQ29vcmRpbmFkb3ItLT4gTm9kbyAyOiBcbkNvb3JkaW5hZG9yLS0-IE5vZG8gMzogXG5Db29yZGluYWRvci0tPiBOb2RvIDQ6IFxuQ29vcmRpbmFkb3ItPiBOb2RvIDQ6IFNpbmNyb25pemFyIFxuTm9kbyAxLT4-IE5vZG8gMjogbWVuc2FqZVxuTm9kbyAyLT4-IE5vZG8gMzogbWVuc2FqZVxuTm9kbyAzLT4-IE5vZG8gNDogbWVuc2FqZVxuTm9kbyA0LT4-IENvb3JkaW5hZG9yOiBtZW5zYWplIiwibWVybWFpZCI6eyJ0aGVtZSI6ImRlZmF1bHQifSwidXBkYXRlRWRpdG9yIjpmYWxzZSwiYXV0b1N5bmMiOnRydWUsInVwZGF0ZURpYWdyYW0iOmZhbHNlfQ)](https://mermaid-js.github.io/mermaid-live-editor/edit#eyJjb2RlIjoic2VxdWVuY2VEaWFncmFtXG5Db29yZGluYWRvci0tPiBOb2RvIDE6IFxuQ29vcmRpbmFkb3ItLT4gTm9kbyAyOiBcbkNvb3JkaW5hZG9yLS0-IE5vZG8gMzogXG5Db29yZGluYWRvci0tPiBOb2RvIDQ6IFxuQ29vcmRpbmFkb3ItPiBOb2RvIDQ6IFNpbmNyb25pemFyIFxuTm9kbyAxLT4-IE5vZG8gMjogbWVuc2FqZVxuTm9kbyAyLT4-IE5vZG8gMzogbWVuc2FqZVxuTm9kbyAzLT4-IE5vZG8gNDogbWVuc2FqZVxuTm9kbyA0LT4-IENvb3JkaW5hZG9yOiBtZW5zYWplIiwibWVybWFpZCI6IntcbiAgXCJ0aGVtZVwiOiBcImRlZmF1bHRcIlxufSIsInVwZGF0ZUVkaXRvciI6ZmFsc2UsImF1dG9TeW5jIjp0cnVlLCJ1cGRhdGVEaWFncmFtIjpmYWxzZX0)

## Revisar la conexión de los nodos
El coordinador revisa si todos los nodos de la red siguen conectados y manda la actualización a todos. Si en dado caso un nodo se desconectó el coordinador libera la dirección de ese nodo y manda la actualización a todos.

[![](https://mermaid.ink/img/eyJjb2RlIjoic2VxdWVuY2VEaWFncmFtXG5Db29yZGluYWRvci0-PiBOb2RvIDE6IFNpZ3VlIGNvbmVjdGFkbz9cbk5vZG8gMS0-PiBDb29yZGluYWRvcjogU2lcbkNvb3JkaW5hZG9yLT4-IE5vZG8gMjogU2lndWUgY29uZWN0YWRvP1xuTm9kbyAyLT4-IENvb3JkaW5hZG9yOiBTaVxuQ29vcmRpbmFkb3ItPj4gTm9kbyAzOiBTaWd1ZSBjb25lY3RhZG8_XG5Ob2RvIDMtPj4gQ29vcmRpbmFkb3I6IFNpXG5Db29yZGluYWRvci0-PiBOb2RvIDQ6IFNpZ3VlIGNvbmVjdGFkbz9cbk5vZG8gNC0teCBDb29yZGluYWRvcjogTm8gaHVibyByZXNwdWVzdGFcbk5vdGUgbGVmdCBvZiBDb29yZGluYWRvcjogw5puaWNhbWVudGUgcmVzcG9uZGllcm9uPGJyLz4gMyBub2RvcywgbGliZXJhIGxhPGJyLz4gZGlyZWNjacOzbiBkZWwgbm9kbyA0LlxuQ29vcmRpbmFkb3ItPiBOb2RvIDM6IEFjdHVhbGl6YSBsYSBpbmZvcm1hY2nDs24gZGUgbGEgcmVkIiwibWVybWFpZCI6eyJ0aGVtZSI6ImRlZmF1bHQifSwidXBkYXRlRWRpdG9yIjpmYWxzZSwiYXV0b1N5bmMiOnRydWUsInVwZGF0ZURpYWdyYW0iOmZhbHNlfQ)](https://mermaid-js.github.io/mermaid-live-editor/edit#eyJjb2RlIjoic2VxdWVuY2VEaWFncmFtXG5Db29yZGluYWRvci0-PiBOb2RvIDE6IFNpZ3VlIGNvbmVjdGFkbz9cbk5vZG8gMS0-PiBDb29yZGluYWRvcjogU2lcbkNvb3JkaW5hZG9yLT4-IE5vZG8gMjogU2lndWUgY29uZWN0YWRvP1xuTm9kbyAyLT4-IENvb3JkaW5hZG9yOiBTaVxuQ29vcmRpbmFkb3ItPj4gTm9kbyAzOiBTaWd1ZSBjb25lY3RhZG8_XG5Ob2RvIDMtPj4gQ29vcmRpbmFkb3I6IFNpXG5Db29yZGluYWRvci0-PiBOb2RvIDQ6IFNpZ3VlIGNvbmVjdGFkbz9cbk5vZG8gNC0teCBDb29yZGluYWRvcjogTm8gaHVibyByZXNwdWVzdGFcbk5vdGUgbGVmdCBvZiBDb29yZGluYWRvcjogw5puaWNhbWVudGUgcmVzcG9uZGllcm9uPGJyLz4gMyBub2RvcywgbGliZXJhIGxhPGJyLz4gZGlyZWNjacOzbiBkZWwgbm9kbyA0LlxuQ29vcmRpbmFkb3ItPiBOb2RvIDM6IEFjdHVhbGl6YSBsYSBpbmZvcm1hY2nDs24gZGUgbGEgcmVkIiwibWVybWFpZCI6IntcbiAgXCJ0aGVtZVwiOiBcImRlZmF1bHRcIlxufSIsInVwZGF0ZUVkaXRvciI6ZmFsc2UsImF1dG9TeW5jIjp0cnVlLCJ1cGRhdGVEaWFncmFtIjpmYWxzZX0)

## Servicio de elección de nuevo coordinador
Este servicio resuelve un problema de falla de punto único que sería el caso de una topología centralizada. Basado en el algoritmo *Raft* este servicio inicia cuando un nodo se postula como candidato cuando el coordinador previo falla y los demás nodos votan por el nuevo candidato. Este servicio mantiene la red operando a pesar de la falla del coordinador.

[![](https://mermaid.ink/img/eyJjb2RlIjoic2VxdWVuY2VEaWFncmFtXG5Db29yZGluYWRvci0teCBOb2RvIDE6IEZhbGxvXG5Db29yZGluYWRvci0teCBOb2RvIDI6IEZhbGxvXG5Db29yZGluYWRvci0teCBOb2RvIDM6IEZhbGxvXG5Db29yZGluYWRvci0teCBOb2RvIDQ6IEZhbGxvXG5Ob2RvIDEtPiBOb2RvIDQ6IE51ZXZvIGNhbmRpZGF0b1xuTm9kbyAyLT4-IE5vZG8gMTogVm90b1xuTm9kbyAzLT4-IE5vZG8gMTogVm90b1xuTm9kbyA0LT4-IE5vZG8gMTogVm90b1xuTm90ZSBsZWZ0IG9mIE5vZG8gMTogU2Ugb2J0dXZpZXJvbiBsb3M8YnIvPiB2b3RvcyBuZWNlc2FyaW9zPGJyLz4gcGFyYSBjYW1iaWFyIGRlPGJyLz4gY29vcmRpbmFkb3IuXG5Ob2RvIDEtPiBOb2RvIDQ6IENvbmZpcm1hY2nDs24gZGUgbnVldm8gY29vcmRpbmFkb3IiLCJtZXJtYWlkIjp7InRoZW1lIjoiZGVmYXVsdCJ9LCJ1cGRhdGVFZGl0b3IiOmZhbHNlLCJhdXRvU3luYyI6dHJ1ZSwidXBkYXRlRGlhZ3JhbSI6ZmFsc2V9)](https://mermaid-js.github.io/mermaid-live-editor/edit#eyJjb2RlIjoic2VxdWVuY2VEaWFncmFtXG5Db29yZGluYWRvci0teCBOb2RvIDE6IEZhbGxvXG5Db29yZGluYWRvci0teCBOb2RvIDI6IEZhbGxvXG5Db29yZGluYWRvci0teCBOb2RvIDM6IEZhbGxvXG5Db29yZGluYWRvci0teCBOb2RvIDQ6IEZhbGxvXG5Ob2RvIDEtPiBOb2RvIDQ6IE51ZXZvIGNhbmRpZGF0b1xuTm9kbyAyLT4-IE5vZG8gMTogVm90b1xuTm9kbyAzLT4-IE5vZG8gMTogVm90b1xuTm9kbyA0LT4-IE5vZG8gMTogVm90b1xuTm90ZSBsZWZ0IG9mIE5vZG8gMTogU2Ugb2J0dXZpZXJvbiBsb3M8YnIvPiB2b3RvcyBuZWNlc2FyaW9zPGJyLz4gcGFyYSBjYW1iaWFyIGRlPGJyLz4gY29vcmRpbmFkb3IuXG5Ob2RvIDEtPiBOb2RvIDQ6IENvbmZpcm1hY2nDs24gZGUgbnVldm8gY29vcmRpbmFkb3IiLCJtZXJtYWlkIjoie1xuICBcInRoZW1lXCI6IFwiZGVmYXVsdFwiXG59IiwidXBkYXRlRWRpdG9yIjpmYWxzZSwiYXV0b1N5bmMiOnRydWUsInVwZGF0ZURpYWdyYW0iOmZhbHNlfQ)

# Configuración
El usuario debe de incluir en el `main.c` únicamente el encabezado `mrf24j40ma.h`, pero agregar al folder donde este el `main.c` la librería de mrf24j40ma y timer. 

## Inicialización

Para el correcto funcionamiento de la librería es necesario configurar los siguientes puntos:

 - Objeto `MRF24J`: de la libreria es necesario crear un objeto `MRJ24J` para dotarlo de todas las variables y metodos necesario para el manejo del transceptor.
 - Timer: a partir de este timer se crean más timers en software que se utilizan dentro de la librería.  Es necesario configurar la interrupción de un timer para que ocurra cada 10*ms* y llamar la función `ISR_timer()`.
 - Interrupción de un GPIO: esta interrupción periférica esta sujeta al pin de interrupción del transceptor y su función es informar cuando hay nueva información en transceptor que es necesario leerla. Esta información puede ser el mensaje que recibió de otro transceptor y *ack*. En la interrupción es necesario llamar la función `mrf.interrupt_handler()` de la clase `Mrf24j`
 - Setup: el setup para el transceptor incluye seleccionar un canal de los 16 disponibles de la frecuencia de 2.4 Ghz, asignar una dirección PAN, asignar una dirección al transceptor y llamar la función `mrf.init()`.
 - Coordinador: se debe configurar únicamente un nodo como coordinador para administrar la red. La función que se debe de llamar es `mrf.NoBeaconInitCoo()`. Para todos los demás nodos en la red se llama `mrf.NoBeaconInit()`.

Un ejemplo de inicialización en Arduino IDLE para Arduino Nano:

	#include "mrf24j40ma.h"
	
	#define CLK 13
	#define rst A1//D15
	#define wke A2//D16
	#define itr 3//D3
	#define miso 12 //D12
	#define mosi 11 //D11
	#define cs 10 //D10

    //MRF24J40
    Mrf24j mrf(rst, cs, itr);
    
    void MRFInterruptRoutine() {
      mrf.interrupt_handler();
    }
    
    ISR(TIMER2_OVF_vect){
       ISR_timer2();  
    }
    
    void mrf_setup(){      
      //inicialización
      mrf.init();
    
      //asigna PAN
      mrf.set_pan(pan);
    
      //asigna canal
      //mrf.set_channel(12);
    
      //asigna la dirección
      mrf.address16_write(direccion);
    
      //inicializa red sin baliza
      mrf.NoBeaconInitCoo(); // Para coordinador
      //mrf.NoBeaconInit(); // Para un nodo
      mrf.UnslottedCSMACA(); // Algoritmo para evitar colision

	  //interrupción asociado al pin itr
      attachInterrupt(digitalPinToInterrupt(itr), MRFInterruptRoutine, CHANGE);    
      interrupts();
    }
    
    void setup() {
      Serial.begin(115200);
    
      mrf_setup();
	}

 
## Ciclo principal

En el ciclo principal también es necesario llamar algunos métodos de la clase para el correcto funcionamiento del transceptor. 

 ### `mrf.check_flags(void (*handlerRx)(void), void (*handlerTx)(void))` 
 Este método se debe colocar en el ciclo principal. La información que recibe el microcontrolador del transceptor puede estar asociada al Tx o Rx del transceptor. Entonces, este método indica si la información que recibió el MCU del transceptor es del Tx o Rx y a través de los punteros realiza el ciclo `handlerRx` o el ciclo `handlerTx`.

 - `handlerRx` en este handler es necesario incluir los siguientes métodos: `mrf.readCoo()`, `mrf.electionCoo()` y `mrf.association()`.

### `mrf.coo_loop(uint8_t  seconds, bool  synchronize)` 
Este método lo utiliza el coordinador, pero debe de estar en todos los nodos. La primera variable define cuanto tiempo debe transcurrir cada vez que se revisa la conexión de los nodos. La segunda variable decide si se sincronizan la transmisión de los nodos.

### `mrf.node_loop(void)`
Este método lo utilizan todos los nodos a excepción del coordinador. Ejecuta los algoritmos necesarios para cada uno de los servicios.

Un ejemplo en Arduino IDLE para el Arduino Nano

    void loop() {
      // revisa las banderas para enviar y recibir datos
      mrf.check_flags(&handleRx, &handleTx);
      mrf.coo_loop(10,true);
      mrf.node_loop();
    }
    
    //maneja la bandera de recepción
    void handleRx(void){
      bool fromCoo = mrf.readCoo();
      bool electionCoo = mrf.electionCoo();
      bool member = mrf.association();
    }
    
    //maneja la bandera de envío
    void handleTx(void){
    
    }

# Estructuras y métodos
## Estructuras

### `rx_info_t`
| Tipo 	   | Variable 		| Descripción |
|----------|----------------|---------------------------------------------------------------|
| uint8_t  | frame_length 	| Indica el tamaño del mensaje con un valor máximo de 127 bytes. Se actualiza en `mrf.interrupt_handler()`.|
| uint16_t | origin 		| Contiene la dirección del emisor del mensaje recibido. Se 			actualiza en `mrf.interrupt_handler()`.|
| uint16_t | panid			| Contiene la PAN del emisor del mensaje recibido para saber si el mensaje vino de nuestra PAN o es un BROADCAST. Se actualiza en `mrf.interrupt_handler()`.|
| uint8_t  | rx_data[116] 	| buffer del mensaje recibido. Se actualiza en `mrf.interrupt_handler()`.|
| uint8_t  | lqi 			| Indica la calidad del mensaje recibido donde 255 es alto y 0 es bajo. Se actualiza en `mrf.interrupt_handler()`.|
| uint8_t  | rssi		 	| Es la potencia del mensaje recibido donde -100 dBm hasta 0 dBm está mapeado de 0 a 255. Se actualiza en `mrf.interrupt_handler()`.|


### `tx_info_t`
| Tipo 	   | Variable 		| Descripción |
|----------|----------------|---------------------------------------------------------------|
| uint8_t  | tx_ok| Un 1 significa que recibió un ack y 0 que no lo recibió. Se actualiza en `mrf.interrupt_handler()`.|
| uint8_t | retries | Indica el número de intentos realizados. Se actualiza en `mrf.interrupt_handler()`.|
| uint8_t | channel_busy | Indica que el mensaje no se envió porque el canal está ocupado. Se actualiza en `mrf.interrupt_handler()`.|


### `pool_t`
| Tipo 	   | Variable 		| Descripción |
|----------|----------------|---------------------------------------------------------------|
| uint8_t  | size| Es el tamaño de direcciones disponibles en la red|
| uint16_t | address[] 	| Contiene todas las direcciones disponibles en la red. Las asigna cuando se ejecuta el servicio de asociación.|
| uint8_t | availability| Indica si cada una de las direcciones está ocupada o disponible. Se actualiza cuando ocurre una asociación.|
| uint8_t | QUORUM| El número de votos necesarios para que un candidato se vuelva el coordinador.|

## Métodos de MRF24J40MA

| Funcion        |Descripción                                                  	|
|----------------|--------------------------------------------------------------|
|`Mrf24j(int  pin_reset, int  pin_chip_select, int  pin_interrupt)`|Crea el objeto Mrf24j. Los parámetros son los tres pines asignados para reset, cs del SPI y el pin de interrupción.             								|
|`void  reset(void)`|Reinicia el transceptor utilizando el pin de reset|
|`void  init(void)`|Inicializa el transceptor, selecciona el canal de default: 12,inicia las interrupciones, inicia el timer 2 del Arduino Nano para crear los timers digitales.| 
|`byte  read_short(byte  address)`|Devuelve el byte del registro del parámetro address.|
|`byte  read_long(uint16_t  address)`|Devuelve el byte del registro del parámetro address. Aqui es para leer los registros con dirección de 12 bits.|
| `void  write_short(byte  address, byte  data)`|Escribe en el registro del parámetro address el parámetro data.|
| `void  write_long(uint16_t  address, byte  data)`|Escribe en el registro del parámetro address el parámetro data. Aqui es para escribir en los registros con dirección de 12 bits.|
|`uint16_t  get_pan(void)`|Devuelve la PAN a la que el transceptor está conectada.|
|`void  set_pan(uint16_t  panid)`|Asigna la PAN al transceptor.|
|`void  address16_write(uint16_t  address16)`|Asigna la dirección de 16 bits al transceptor.|
|`uint16_t  address16_read(void)`|Lee la dirección de 16 bits del transceptor.|
|`void  set_interrupts(void)`|Activa las interrupciones del transceptor.|
|`void  set_promiscuous(boolean  enabled)` |Con el parámetro enable se habilita o deshabilita que se pueda recibir cualquier tipo de trama, aun si no cumple con los requerimientos de recepción de Zigbee.|
|`void  set_channel(byte  channel)`|Asigna un canal de la frecuencia 2.4 GHz al transceptor.|
|`void  rx_enable(void)`|Habilita la recepción. De default ya está habilitada.|
|`void  rx_disable(void)`|Deshabilita la recepción.|
|`void  rx_flush(void)`|Limpia el buffer de recepción del transceptor.|
|`rx_info_t  *  get_rxinfo(void)`|Es el puntero a la estructura asociada a la recepción de datos.|
|`tx_info_t  *  get_txinfo(void)`|Es el puntero a la estructura asociada a la transmisión de datos.|
|`uint8_t  *  get_rxbuf(void)`|Si se habilita el buffer adicional para el payload en este puntero se almacena el payload.|
|`int  rx_datalength(void)`|Devuelve el tamaño del mensaje recibido.
|`void  set_ignoreBytes(int  ib)`|Le dice al transceptor cuantos bytes ignorar del payload.|
|`void  set_bufferPHY(boolean  bp)`|Habilita el buffer adicional para el payload.|
|`boolean  get_bufferPHY(void)`|Devuelve un booleano. Si es true significa que existe el buffer adicional.|
|`void  set_palna(boolean  enabled)`|La máquina de estados finitos RF del MRF24J40 puede utilizarse junto con una antena externa.|
|`void  send16(uint16_t  dest16, char  *  data)`|Envía el mensaje dado por el parámetro data a la dirección del parámetro dest16 esperando un ack como respuesta.|
|`void  interrupt_handler(void)`|Esta función es esencial para el correcto funcionamiento del transceptor. Se debe de llamar en la interrupción creada por el transceptor. Actualiza la información asociada a Tx y Rx.|
|`void  check_flags(void (*rx_handler)(void), void (*tx_handler)(void))`| Esta función es esencial para el correcto funcionamiento del transceptor. El primer parámetro rx_hander corresponde a un loop creado por el usuario para la interrupción ocasionada por el Rx y el segundo parámetro tx_handler corresponde a un loop creado por el usuario para la interrupción ocasionada por el Tx.|
|`void  set_cca(uint8_t  method)`|Es un indicador de la capa MAC para conocer si el medio está disponible o ocupado. El parámetro método selecciona entre las 3 opciones disponibles: [0]si la energía en el canal supera el umbral (ED), [1]si el mensaje corresponde a la modulación correcta para el protocolo o [2]la combinación de ambos. De default está la opción [0].|
|`uint8_t  lqi(void)`|Devuelve la potencia medida en el medio mapeado en un valor entre 0 y 255.|
|`bool  channel_occupied(void)`|Indica si el canal está ocupado.|
|`uint8_t  mask_short(uint8_t  reg, uint8_t  mask, uint8_t  change)`|Aplica una mascara a un registro para modificar un único pin. El parámetro reg es la el registro, el parámetro mask debe ser un byte lleno de 1 a excepción del bit a modificar y el parámetro change es el valor del bit que se quiere modificar.|
|`uint16_t  mask_long(uint16_t  reg, uint16_t  mask, uint8_t  change)`|Aplica una mascara a un registro de dirección de 12 bits para modificar un único pin. El parámetro reg es la el registro, el parámetro mask debe ser un byte lleno de 1 a excepción del bit a modificar y el parámetro change es el valor del bit que se quiere modificar.|
|`void  NoBeaconInitCoo(void)`|Inicializa un coordinador en una red sin baliza.|
|`bool  check_coo(void)`|Revisa si el transceptor está configurado como coordinador.|
|`void  NoBeaconInit(void)`|Inicializa en una red sin baliza.|
|`void  UnslottedCSMACA(void)`|Habilita el algoritmo CSMA-CA sin baliza.|
|`void  SlottedCSMACA(void)`|Habilita el algoritmo CSMA-CA con baliza.|
|`void  sendAck(uint16_t  dest16, char  *  data)`|Envía el parámetro data a la dirección del parámetro dest16 esperando un ack como respuesta.
|`void  sendNoAck(uint16_t  dest16, char  *  data)`|Envía el parámetro data a la dirección del parámetro dest16 sin esperar un ack como respuesta.
|`void  broadcast(char  *  data, uint16_t  address = BROADCAST)`| Envía el parámetro data como broadcast sin esperar un ack como respuesta. Si se modifica el parámetro address el mensaje sera a la PAN correspondiente a broadcast, pero la dirección corresponde al parámetro definido.|
|`void  association_set(uint16_t  panid, uint16_t  address)`|Modifica la PAN y la dirección asociadas al transceptor.|
|`bool  association_response(void)`|Respuesta del coordinador para asociar un nuevo nodo a la red. Modifica la variable availability de la estructura pool_t cuando una asociación tiene éxito. Devuelve 1 si la asociación fue exitosa.|
|`bool  association_request(void)`|Solicitud de un para asociarse a una red. Se modificará la PAN y la dirección si la asociación fue exitosa.|
|`pool_t  *  get_pool(void)`| Es el puntero a la estructura asociada a la información de la red.|
|`float  readF(void)`|Lee el mensaje recibido como un float de hasta 4 números despues del punto decimal.|
|`void  sendF(uint16_t  address, float  value, bool  ack = 1)`|Envía el float del parámetro value a la dirección del parámetro address y el último parámetro indica si espera un ack como respuesta.|
|`bool  sync(void)`|El coordinador informa a la red que debe sincronizar sus mensajes. Debe de llamarse luego de cada vuelta.|
|`bool  syncSending(uint16_t  dest, char  *  message)`|El método correspondiente a enviar un mensaje sincronizado.|
|`void  synchronizedNodes(void)`|Hace la sincronización automática. Si se desea que los mensajes siempre esten sincronizados se llama esta función.|
|`bool  readCoo(void)`|Se implementa en el loop que corresponde al `rx_handler` de `check_flags(void (*rx_handler)(void), void (*tx_handler)(void))` de cada nodo. Revisa si el mensaje recibido vino del coordinador y si el mensaje corresponde a un servicio.|
|`bool  association(void)`|Se implementa en el loop que corresponde al `rx_handler` de `check_flags(void (*rx_handler)(void), void (*tx_handler)(void))` del coordinador. Revisa si el mensaje recibido corresponde a una solicitu de asociación.|
|`byte  still(void)`|Servicio ejecutado por el coordinador y revisa si los nodos siguen conectados a la red. Devuelve el número de nodos desconectados. Si devuelve un 0 ninguno se desconectó. Además, actualiza la información de la red.|
|`void  update(void)`|Envía la información de la red actualizada a todos los nodos por medio de un broadcast.|
|`void  updateInfo(void)`|Si el mensaje recibido corresponde a una actualización que proviene del coordinador, procesa el mensaje para actualizar la información de la red.|
|`void  cooCheck(uint8_t  seconds = 2)`|El coordinador lo implementa para hacer un chequeo de si los nodos siguen conectados cada cierto tiempo determinado por el parámetro seconds.|
|`void  setTimer(void)`|Configura los timers de software asociados al transceptor.|
|`void  cooBeat(void)`|El coordinador lo utiliza para enviar un PING cada cierto tiempo para informar a la red que sigue presente.|
|`bool  heartbeat(void)`|Los nodos lo utilizan para revisar los temporizadores asociados al servicio de nuevo coordinador. En el caso que el coordinador deja de enviar el PING, en esta función se inicializa el servicio de nuevo coordinador.|
|`bool  electionCoo(void)`|Se implementa en el loop que corresponde al `rx_handler` de `check_flags(void (*rx_handler)(void), void (*tx_handler)(void))` de cada nodo. Revisa el mensaje que se recibió para determinar si existe un nuevo coordinador, si debo votar o si votaron por mi.
|`bool  votation(void)`|Cuando se cuentan con los votos suficientes el nuevo candidato procede a actulizar su configuración para ser el nuevo coordinador.|
|`void  cooElection(void)`|Este metodo hace el algoritmo de `heartbeat(void)` y `votation(void)` para una implementación más sencilla.|
|`bool  check_IamCoo(void)`|Revisa si el transceptor comenzó el servicio de asociación.|
|`int  coo_loop(uint8_t  seconds = 2, bool  synchronize = false)`|Es el algoritmo para el coordinador en el que se envía el PING, se implementan los servicios de sincronización, y revisar si siguen conectados los nodos para una implementación más sencilla.|
|`int  node_loop(void)`|Es el algoritmo para el nodo en el que se implementa el servicio de nuevo coordinador y asociación si el nodo queda huerfano.|

Para mayor información sobre el transceptor, este es el [datasheet](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&cad=rja&uact=8&ved=2ahUKEwj0ivDC26_0AhVzVTABHSk7CCMQFnoECAkQAQ&url=https%3A%2F%2Fww1.microchip.com%2Fdownloads%2Fen%2FDeviceDoc%2F39776C.pdf&usg=AOvVaw2GQOCNb3f8nTI0CDw6_MDW)

