## Carpeta de documentos

[![N|Solid](https://cldup.com/dTxpPi9lDf.thumb.png)](https://nodesource.com/products/nsolid)

Esta carpeta contiene los documentos de la parte de simulación del trabajo de tesis. Inicialmente era una copia del repositorio original de RMASE, así que tiene todas las dependencias necesarias para que la aplicación se ejecute sin problemas. Los archivos configurables están en:
Rmase-1.1-share/algorithms/custom_components/antnet/
  Esta carpeta contiene los archivos relevantes que se añadieron a la aplicación para desarrollar la plataforma de simulación de AntNet
Rmase-1.1-share/topologies/
  Esta carpeta se puede utilizar para definir nuevas topologías para realizar pruebas (se puede utilizar test_topo.m como plantilla para crear nuevas)
  
El documento "Manual de uso simulador de AntNet en RMASE.pdf" incluye los detalles para ejecutar las simulaciones correspondientes.

## Acerca de RMASE

RMASE (Routing Modelling Application Simulation Environment) es un entorno de simulación de eventos discretos desarrollado como una aplicación dentro de Prowler. Este a su vez genera las simulaciones del modelo de radio, según la especificación de acceso al medio de TinyOS. Para más información acerca de prowler puede visitarse su sitio oficial: https://www.isis.vanderbilt.edu/projects/nest/prowler/

RMASE permite escribir el código de cada agente del enjambre, para luego simular el algoritmo distribuido. Tiene incluidas muchas funcionalidades como generación de gráficas, estadísticas, animación de los resultados, etc. Se pueden añadir nuevos componentes de ruteo al definir las acciones que cada agente realizará con cada comando y evento. Los comandos, eventos y las capas son los principales componentes de RMASE. Para más información puede verse la documentación oficial dentro de este respositorio en: Rmase-1.1-share/doc/html/Rmase/

## Acerca de AntNet
AntNet es un algoritmo de ruteo basado en ACO que utiliza el round-trip-time como variable de enfoque para hallar rutas óptimas. La ruta óptima es aquella con el menor RTT. Una excelente explicación de ACO junto con el ejemplo explicativo del experimento de la doble rendija está en https://www.youtube.com/watch?v=xpyKmjJuqhk

Las estructuras principales en memoria de cada agente del enjambre son:
- La matriz T: contiene entradas que representan la probabilidad (feromona) de que una hormiga de forward con destino d tome como siguiente salto el vecino v.
- La estructura S: contiene modelos del RTT hacia cada destino que se actualizan en el tiempo y permiten definir funciones para actualizar T.



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
