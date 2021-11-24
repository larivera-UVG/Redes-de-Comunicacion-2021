# Diseño e Implementación de un Sistema de Comunicación Inalámbrica para Aplicaciones de Robótica de Enjambre - Fase II
## _Hee Chan Kim_

[![N|Solid](https://cldup.com/dTxpPi9lDf.thumb.png)](https://nodesource.com/products/nsolid)

[![Build Status](https://travis-ci.org/joemccann/dillinger.svg?branch=master)](https://travis-ci.org/joemccann/dillinger)

Se utilizó el transceptor MRF24J40MA para fabricar la placa de desarrollo y construir la librería asociada.

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

# Placa de desarrollo
La placa de desarrollo esta disponible en la UVG y los gerbers y los archivos de Altium necesarios para su fabricación están en este carpeta. La placa está desarrollada entorno al transceptor MRF24J40MA y se utilizó exitosamente el Arduino Nano.

# Librería
En la carpeta de librería se encuentra la librería del transceptor, un código ejemplo y los códigos correspondientes a las 4 pruebas realizadas.

# Documentación
En la carpeta de documentación se encuentra toda la información referente a Zigbee, el datasheet del transceptor, los diagramas de flujo de los servicios, imágenes de las pruebas realizadas y el documento de la tesis.

[//]: # (These are reference links used in the body of this note and get stripped out when the markdown processor does its job. There is no need to format nicely because it shouldn't be seen. Thanks SO - http://stackoverflow.com/questions/4823468/store-comments-in-markdown-syntax)

   [dill]: <https://github.com/joemccann/dillinger>
   [git-repo-url]: <https://github.com/joemccann/dillinger.git>
   [john gruber]: <http://daringfireball.net>
   [df1]: <http://daringfireball.net/projects/markdown/>
   [markdown-it]: <https://github.com/markdown-it/markdown-it>
   [Ace Editor]: <http://ace.ajax.org>
   [node.js]: <http://nodejs.org>
   [Twitter Bootstrap]: <http://twitter.github.com/bootstrap/>
   [jQuery]: <http://jquery.com>
   [@tjholowaychuk]: <http://twitter.com/tjholowaychuk>
   [express]: <http://expressjs.com>
   [AngularJS]: <http://angularjs.org>
   [Gulp]: <http://gulpjs.com>

   [PlDb]: <https://github.com/joemccann/dillinger/tree/master/plugins/dropbox/README.md>
   [PlGh]: <https://github.com/joemccann/dillinger/tree/master/plugins/github/README.md>
   [PlGd]: <https://github.com/joemccann/dillinger/tree/master/plugins/googledrive/README.md>
   [PlOd]: <https://github.com/joemccann/dillinger/tree/master/plugins/onedrive/README.md>
   [PlMe]: <https://github.com/joemccann/dillinger/tree/master/plugins/medium/README.md>
   [PlGa]: <https://github.com/RahulHP/dillinger/blob/master/plugins/googleanalytics/README.md>
