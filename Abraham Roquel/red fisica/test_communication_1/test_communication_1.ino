/*
  Universidad del Valle de Guatemala
  Diseño e innovación en ingeniería 2
  Protocolos de enrutamiento basados en inteligencia de enjambre

  Implementación de AntNet por medio de MRF24J40MA en Arduino Nano (ATmega328P Old Bootloader)
  La librería mrf24j40ma.h fue escrita por Hee Chan Kim de Universidad del Valle
  Basado en los ejemplos en https://github.com/larivera-UVG/Redes-de-Comunicacion-2021/tree/HeeChanKim/Hee%20Chan%20Kim/Libreria
*/

//Inicialización del módulo
#include <mrf24j40ma.h>
#include <Adafruit_NeoPixel.h>

// pinout
#define CLK 13
#define rst A1//D15
#define wke A2//D16
#define itr 3//D3
#define miso 12 //D12
#define mosi 11 //D11
#define cs 10 //D10
#define rgb 2 //D2
#define NUMPIXELS 1 // How many NeoPixels are attached to the Arduino
#define DELAYVAL 500 // Time (in milliseconds) to pause between pixels
//RGB
Adafruit_NeoPixel pixels(NUMPIXELS, rgb, NEO_GRB + NEO_KHZ800);
// ids de interés para devices
#define dev_id 4
#define source_id 0
#define destination_id 4

// ids de interes para tipos de mensaje
#define id_msg_hello 0
#define id_msg_forward 1
#define id_msg_backward 2

// parámetros globales / constantes
#define n100_ms_forward 2                                // cantidad de slots de 100_ms para mandar hormigas de forward
#define ms_slot_hello 15
#define node_count 5                                    // 5 nodos en la red
#define max_sample_count 10                              // cantidad de variables anteriores de rtt para calcular max
#define max_hops 6                                      // número máximo de saltos
const uint8_t destination_count = node_count - 1;       // cantidad de destinos posibles
const uint8_t time_slot_count = destination_count*2;    // slots de tiempo para esperar al inicio
const uint16_t address_pool[node_count] = {0x1A31, 0x1A32, 0x1A33, 0x1A34, 0x1A35}; // pool de direcciones disponibles
const char color_pool[node_count][3] = {{30,0,0}, {0,30,0}, {0,0,30}, {30,30,0}, {0,30,30}}; // color asignado a cada nodo
const uint16_t my_address = address_pool[dev_id];       // dirección particular para este id
const char *my_color = (char*) color_pool[dev_id];      // color particular para este id
const uint8_t P_t_scaled = 510 / destination_count; // esto es 2*pi/(k*theta) con theta = pi, k = max(k) y escalado a 255
const bool i_am_source = (dev_id == source_id);     // determinar si somos fuente o no
const uint16_t destination_address = address_pool[destination_id]; // guardar la dirección de destino (se usa solo si somos fuente)

// alocar memoria para las estructuras principales
// las columnas deben sumar 1, columnas son destinos, filas son vecinos
float T_matrix[destination_count][destination_count];
// se va a usar la funcion micros() para el tiempo, y por lo tanto para el modelo de media y varianza
unsigned long S_matrix[destination_count][2];
// matriz para guardar los valores históricos del RTT hacia los diferentes destinos (filas son destinos)
unsigned long RTT_matrix[destination_count][max_sample_count]; 
// arreglo que guarda los indices circulares correspondientes a RTT_matrix
uint8_t circular_i[destination_count];
// contador para condición de paro de descubrimiento de vecinos
uint8_t discover_slot_counter = 0;
// contador para los vecinos que se conocen
uint8_t neighbor_count = 0;
// bool para deterimar si se ejecutan las tareas periodicas (p. e. enviar hormigas de forward)
bool periodic_tasks = false;
// contador para enviar hellos a cada cierto tiempo
uint8_t periodic_hello_counter = 0;
// arreglo que tiene las direcciones de los posibles destinos/vecinos
uint16_t peer_address[destination_count];
// arreglo que tiene bools indicando si la dirección en la posición i es vecino
bool known_neighbors[destination_count];
// arreglos que sirven como buffers para la recepción/envío de paqutes
// los primeros 6 son para el tipo de datos, tamaño del paload entero, dos direcciones (source, destination)
// los otros son 6 por cada salto 
uint8_t data_buffer[6 + (6 * (max_hops + 1))];
// arreglo que sirve para almacenar un bool que determina si ese vecino se toma en cuenta o no para elegir el siguiente salto
bool allowed_neighbors[destination_count];
// arreglo que sirve como buffer para guardar las direcciones tomadas en cada salto
uint16_t hops_address[max_hops + 1];
// arreglo que sirve como buffer para guardar los tiempos correspondientes a cada salto
unsigned long hops_times[max_hops + 1];
// variable para guardar el tamaño de la pila sin duplicados
uint8_t real_size;

//PAN
const uint16_t pan = 0x0040;
const uint16_t broadcast_address = 0xFFFF;

// quita los loops para el valor en la posicón kt, actualiza la variable global real_size
void rloops(uint8_t kt){
  uint16_t focus_value = hops_address[kt];
  uint8_t repetition_index = 0;
  for (uint8_t i = kt; i < (real_size - 1); i++){
     if (focus_value == hops_address[i]){
       repetition_index = i; // esto obtiene el último valor donde se encuentra el foco
     }
  }
  if (repetition_index > kt){ // si se tiene que ajustar
      uint8_t elements_to_shift = real_size - 1 - repetition_index; // cuantos elementos se van a desplazar
      uint8_t shift_count = repetition_index - kt; // cuanto se va a desplazar cada elementos
      uint8_t moving_index = kt + 1;
      for (byte i = 0; i < elements_to_shift; i++){
          hops_address[moving_index] = hops_address[moving_index + shift_count];
          hops_times[moving_index] = hops_times[moving_index + shift_count];
          moving_index++;
      }
      // reducir el tamaño de la lista real
      real_size = real_size - shift_count;
  }
}

// copiar parte de un arreglo a otro arreglo
void copyB(uint8_t * src, uint8_t * dst, uint8_t len) {
    for (uint8_t i = 0; i < len; i++) {
        *dst++ = *src++;
    }
}

// alimenta el arreglo de hops_times
void get_stack_times(uint8_t hop_count, uint8_t * initial_pos){
    for (uint8_t i = 0; i < hop_count; i++) {
        hops_times[i] = *((unsigned long *) initial_pos);
        initial_pos += 6; // examinar 6 bytes luego
    }
}

// alimenta el arreglo de hops_address
void get_stack_address(uint8_t hop_count, uint8_t * initial_pos){
    for (uint8_t i = 0; i < hop_count; i++) {
        hops_address[i] = *((uint16_t *) initial_pos);
        initial_pos += 6; // examinar 6 bytes luego
    }
}

// imprimir la matriz de feromonas (debugging)
void print_T_matrix(void){
  Serial.println("filas (vecinos), columnas (destinos)");
  for (byte i = 0; i < destination_count; i++){
    for (byte j = 0; j < destination_count; j++){
      char num_buffer[10];
      dtostrf(T_matrix[i][j], 5, 3, num_buffer);
      Serial.print(num_buffer);
      Serial.print(" ");
    }
    Serial.println("");
  }  
}

// permite que se evalúen próximos saltos sobre toda la vecindad
void allow_all_neighbors(void){
  for(byte i = 0; i < destination_count; i++){
      allowed_neighbors[i] = true;
  }
}

// buscar el índice de cierta dirección en peer_address, si no lo halla devolver -1
int find_index(uint16_t search_address){
   for(uint8_t i = 0; i < destination_count; i++){
      if (peer_address[i] == search_address){
        return i;  
      }
   }
   return -1;
}

// elegir un vecino como next hop para cierto destino con base en T_matrix y una máscara
uint16_t select_neighbor(uint16_t dest_address){
  // obtener el incide correspondiente a ese destino
  int dest_address_index = find_index(dest_address);
  float w_sum = 0.0;
  // recorrer la matriz de feromona, para la columna apropiada
  for (byte i = 0; i < destination_count; i++){
    // tomar la suma de los pesos, tomando en cuenta el arreglo con la máscara
    w_sum += (T_matrix[i][dest_address_index] * ((float) allowed_neighbors[i]));
  }
  // generar un número aleatorio entre 0 y 1 (sin incluir)
  float rand_number = ((float)random(1, 1000)) / 1000.0;
  // index dentro de la columna
  byte k = 0;
  // evaluar la columna
  float accum_sum = (T_matrix[k][dest_address_index] * ((float) allowed_neighbors[k])) / w_sum;
  while (rand_number > accum_sum){
    k++;
    accum_sum += (T_matrix[k][dest_address_index] * (float) allowed_neighbors[k]) / w_sum;
  }
  return peer_address[k];
}

// obtener el minimo de un arreglo
unsigned long min_val (unsigned long * arreglo, uint8_t arr_size){
    unsigned long found_min_val = arreglo[0];
    for (uint8_t i = 0; i < arr_size; i++){
      found_min_val = min(arreglo[i], found_min_val);
    }
}

// actualizar la matriz de RTTs historicos
void update_rtt_matrix(unsigned long new_rtt, uint16_t destination_address){
   uint8_t dest_index = find_index(destination_address);
   RTT_matrix[dest_index][circular_i[dest_index]] = new_rtt;
   circular_i[dest_index] = ((circular_i[dest_index] + 1) % max_sample_count);
}

// obtener el refuerzo r
float get_reinforcement(unsigned long new_rtt, uint16_t destination_address){
  uint8_t dest_index = find_index(destination_address);
  unsigned long min_val_found = min_val((unsigned long *) RTT_matrix[dest_index], max_sample_count);
  if (min_val_found == 0){
    return 0.5;
  }else{
    return min(0.5, float(min_val_found) / float(new_rtt));
  }
}

// actualizar el arreglo de feromonas
void update_T_matrix(float reinforcement, uint16_t destination_address, uint16_t chosen_neighbor_address){
    uint8_t dest_index = find_index(destination_address);
    uint8_t neighbor_index = find_index(chosen_neighbor_address);
    for (byte i = 0; i < destination_count; i++){
      if (i == neighbor_index){
        T_matrix[i][dest_index] = T_matrix[i][dest_index] + 0.1 * (1 - T_matrix[i][dest_index]);
      } else {
        T_matrix[i][dest_index] = T_matrix[i][dest_index] - 0.1 * T_matrix[i][dest_index];
      }
    }
}

// inicialización de variables
void var_init(void){
  // no hay feromona al inicio
  for(byte i = 0; i < destination_count; i++){
      for(byte j = 0; j < destination_count; j++)
        T_matrix[i][j] = 0.0;
  }

  // condiciones inciales iguales a cero
  for(byte i = 0; i < destination_count; i++){
      for(byte j = 0; j < 2; j++)
        S_matrix[i][j] = 0;
  }

  // inicializar matriz con ceros
  for(byte i = 0; i < destination_count; i++){
      for(byte j = 0; j < max_sample_count; j++)
        RTT_matrix[i][j] = 0;
  }

  // al incio no se conoce a ningún vecino
  for(byte i = 0; i < destination_count; i++){
      known_neighbors[i] = false;
  }

  // inicializar las direcciones posibles como todas aquellas que no sean mi dirección
  uint8_t k = 0;
  for(byte i = 0; i < node_count; i++){
      if (dev_id != i){
        peer_address[k] = address_pool[i];
        k++;
      }
  }

  // incializar la máscara de direcciones que pueden ser el siguiente salto
  allow_all_neighbors();

  // inicializar indices de arreglos circulares
  for (byte i = 0; i < destination_count; i++){
    circular_i[i] = 0;  
  }

  // testing
  //for(byte i = 0; i < destination_count; i++){
  //    char mesanjito[50];
  //    sprintf(mesanjito, "0x%4X, i = %d", peer_address[i], find_index(peer_address[i]));
  //    Serial.println(mesanjito);
  //}

  //print_T_matrix();
}

// marca el arreglo de allowed_neighbors para que no se visiten repetidos (asumen que el arreglo de hops ya está actualizado)
uint8_t mark_visited_neighbors(uint8_t hop_count){
    // al inicio asumir que tenemos todos disponibles
    uint8_t available_neighbors = neighbor_count;
    // al inicio todos los elementos podrían ser visitados
    allow_all_neighbors();
    // marcar los que ya fueron visitados, y decrementar los vecinos disponibles
    for (byte i = 0; i < hop_count; i++){
      int internal_id = find_index(hops_address[i]);
      if (known_neighbors[internal_id]){ // ver si es vecino nuestro
          available_neighbors -= (uint8_t) allowed_neighbors[internal_id];
          allowed_neighbors[internal_id] = false; // marcar para para que ya no se visite
      }        
    }
    return available_neighbors;
}

// función que maneja los mensaje de hello
void test_new_neighbor(uint16_t incoming_address){
   int address_index = find_index(incoming_address); // hallar indice del nuevo vecino
   if (!known_neighbors[address_index]){
      // vecino nuevo
      Serial.println("new neighbor");
      neighbor_count++;                      // actualizar contador de vecinos conocidos
      known_neighbors[address_index] = true; // actualizar campo, ya lo conocemos como vecino
      // como es nuevo vecino, hay que actualizar toda la matriz
      if (neighbor_count == 1){
          // caso especial, llenar toda la fila de 1's (solo se conce un vecino)
          // ciclo for para recorrer las columnas
          for (byte i = 0; i < destination_count; i++){
             T_matrix[address_index][i] = 1.0;
          }
      } else {
          // repatir la probabilidad
          float new_prob = 1.0 / ((float) (neighbor_count)); // probabilidad que queremos asignar al nuevo miembro
          float remaining_prob = 1.0 - new_prob; // probabilidad restante que tienen los otros miembros
          float scale_per_column[destination_count]; // factores de escala para cada columna
          for (byte i = 0; i < destination_count; i++){
              scale_per_column[i] = 0.0;
              for (byte j = 0; j < destination_count; j++){
                  scale_per_column[i] += T_matrix[j][i]; // sumar cada columna
              }
              scale_per_column[i] = remaining_prob / scale_per_column[i]; // escalar por lo que resta
          }
          // actualizar los valores de toda la matriz
          for (byte i = 0; i < destination_count; i++){
              for (byte j = 0; j < destination_count; j++){
                if (i == address_index) // ver si estamos en la fila del nuevo vecino
                {
                    T_matrix[i][j] = new_prob; // asignar lo que se había planificado
                } else {
                    T_matrix[i][j] = T_matrix[i][j] * scale_per_column[j]; // escalar los demás valores
                }
              }
          }
      }

      //print_T_matrix();
   }
}

//Clase
Mrf24j mrf(rst, cs, itr);
void MRFInterruptRoutine() {
  //rutina para la interrupción
  mrf.interrupt_handler();
}
ISR(TIMER2_OVF_vect){
   ISR_timer2();  
}

//Timers en software
uint8_t my_timer = 1;

void isr_setup(void){
  // interrupción asociado al pin itr
  attachInterrupt(digitalPinToInterrupt(itr), MRFInterruptRoutine, CHANGE);
  // interrupción periódica
  timer_register_100ms(&my_timer);
  interrupts();
}

void send_hello_packet(void){
  // enviar paquete de hello, broadcast y con el msg id apropiado
  uint8_t val_hello[1] = {id_msg_hello};
  mrf.sendNoAck_byte(broadcast_address, val_hello, 1);
  //Serial.println("hello sent");
}

// enviar una hormiga de forward hacia el destino indicado
void send_forward_ant(uint16_t dest_address){
   // indicar el tipo de dato
   data_buffer[0] = id_msg_forward;
   // tamaño del payload
   data_buffer[1] = 12;
   // copiar la dirección fuente
   copyB(((uint8_t * ) & my_address), ((uint8_t * ) & data_buffer[2]), 2);
   // copiar la dirección destino
   copyB(((uint8_t * ) & dest_address), ((uint8_t * ) & data_buffer[4]), 2);
   // obtener el siguiente salto como un vecino aleatorio dentro de la columna de ese destino
   allow_all_neighbors();
   uint16_t next_hop_chosen = select_neighbor(dest_address);
   // obtener el tiempo actual
   unsigned long actual_time = micros();
   // copia la primera dirección del stack, y el tiempo correspondiente
   copyB(((uint8_t * ) & my_address), ((uint8_t * ) & data_buffer[6]), 2);
   copyB(((uint8_t * ) & actual_time), ((uint8_t * ) & data_buffer[8]), 4);
   mrf.sendNoAck_byte(next_hop_chosen, data_buffer, 12);
   //Serial.println(actual_time);
   //char msg_buffer [50];
   //sprintf(msg_buffer, "-> 0x%4X", next_hop_chosen);
   //Serial.println(msg_buffer);
}

void receive_forward_ant(void){
   // espacio para la dirección de destino
   uint16_t packet_destination_address;
   copyB(((uint8_t * ) & data_buffer[4]), ((uint8_t * ) & packet_destination_address), 2);

   // evaluar tamaño de la data entrante
   uint8_t packet_size;
   copyB(((uint8_t * ) & data_buffer[1]), ((uint8_t * ) & packet_size), 1);
   
   // determinar cuántos saltos vienen
   uint8_t hops_in_packet = (packet_size - 6) / 6;

   // las direcciones, rtts empiezan en la posición 6; alimentar arreglo con direcciones
   get_stack_address(hops_in_packet, (uint8_t * ) & data_buffer[6]);

   // ver si somos el destino
   if (packet_destination_address == my_address){
       // enviar hormiga de backward
       // llenar arreglo de tiempos en cada salto, rtts empiezan en posición 8
       get_stack_times(hops_in_packet, (uint8_t * ) & data_buffer[8]);
       real_size = hops_in_packet; // asumir que todos los saltos son válidos al inicio
       uint8_t kt = 0; // apunta a la posición donde se quieren evaluar los loops
       while (kt < (real_size - 1)){
           rloops(kt); // trabajar esa posición y actualiza real_size
           kt++; // aumentar la posición
       }
       // traer la dirección de fuente
       uint16_t packet_source_address;
       copyB(((uint8_t * ) & data_buffer[2]), ((uint8_t * ) & packet_source_address), 2);
       // campos del paquete
       data_buffer[0] = id_msg_backward;
       // actualizar tamaño
       data_buffer[1] = 6 + (6 * (real_size + 1));
       // actualizar direccion de fuente
       copyB(((uint8_t * ) & my_address), ((uint8_t * ) & data_buffer[2]), 2);
       // actualizar dirección de destino
       copyB(((uint8_t * ) & packet_source_address), ((uint8_t * ) & data_buffer[4]), 2);
       // llenar las otra posiciones
       uint8_t moving_index_packet = 6;
       for (byte i = 0; i < real_size; i++){
          copyB(((uint8_t * ) & hops_address[i]), ((uint8_t * ) & data_buffer[moving_index_packet]), 2);
          copyB(((uint8_t * ) & hops_times[i]), ((uint8_t * ) & data_buffer[moving_index_packet + 2]), 4);
          moving_index_packet += 6;
       }
       // poner como dummy al final nuestra direccion y un tiempo cualquiera
       copyB(((uint8_t * ) & my_address), ((uint8_t * ) & data_buffer[moving_index_packet]), 2);
       copyB(((uint8_t * ) & hops_times[0]), ((uint8_t * ) & data_buffer[moving_index_packet + 2]), 4);
       // enviar el paquete
       mrf.sendNoAck_byte(hops_address[real_size - 1], data_buffer, data_buffer[1]);
      //Serial.println(hops_in_packet);
      //char msg_buffer[50];
      //for (byte i = 0; i < hops_in_packet; i++){
      //    sprintf(msg_buffer, "0x%4X, %lu", hops_address[i], hops_times[i]);
      //    Serial.println(msg_buffer);
      //}
   } else if (hops_in_packet < max_hops){ // si no somos el destino evaluar el número de saltos
       // redireccionar hormiga de forward
       // teniendo ya el arreglo de direcciones atravesadas, quitar los vecinos ya visitados de los candidatos
       uint8_t unvisited_neighbors = mark_visited_neighbors(hops_in_packet);
       if (unvisited_neighbors == 0){
          // si no hay vecinos que falte visitar, evaluar sobre toda la vecindad el próximo salto
          allow_all_neighbors();
       }
       // ya está listo el arreglo de allowed_neighbors, calcular el siguiente salto
       uint16_t next_hop_chosen = select_neighbor(packet_destination_address);
       // obtener el tiempo actual
       unsigned long actual_time = micros();       
       // añadir nuestra dirección y tiempo a la pila
       copyB(((uint8_t * ) & my_address), ((uint8_t * ) & data_buffer[packet_size]), 2);
       copyB(((uint8_t * ) & actual_time), ((uint8_t * ) & data_buffer[packet_size + 2]), 4);
       // actualizar tamaño de la data
       data_buffer[1] = packet_size + 6;
       // enviar
       mrf.sendNoAck_byte(next_hop_chosen, data_buffer, data_buffer[1]);
       //Serial.println(actual_time);
   }
   
   
   // copiar la dirección fuente
   //copyB(((uint8_t * ) & data_buffer[2]), ((uint8_t * ) & packet_source_address), 2);
   // copiar la dirección destino

   //Serial.println(hops_in_packet);
   //char msg_buffer[10];
   //for (byte i = 0; i < hops_in_packet; i++){
   //    sprintf(msg_buffer, "0x%4X", hops_address[i]);
   //    Serial.println(msg_buffer);
   //}
   
   // copiar el tiempo recibido
   //copyB(((uint8_t * ) & data_buffer[8]), ((uint8_t * ) & received_time), 4);
   // mostrar los resultados
   //char msg_buffer[50];
   //Serial.println(received_time);
   //sprintf(msg_buffer, "source: 0x%4X, destination: 0x%4X", packet_source_address, packet_destination_address);
   //Serial.println(msg_buffer);
}

void receive_backward_ant(void){
   // espacio para la dirección de fuente y destino
   uint16_t packet_source_address;
   uint16_t packet_destination_address;
   // llenar los valores
   copyB(((uint8_t * ) & data_buffer[2]), ((uint8_t * ) & packet_source_address), 2);
   copyB(((uint8_t * ) & data_buffer[4]), ((uint8_t * ) & packet_destination_address), 2);

   // índice para ir a buscar la dirección del vecino elegido
   uint8_t chosen_neighbor_index = data_buffer[1] - 6;
   uint8_t my_time_index = chosen_neighbor_index - 4;
   // apartar espacio para los valores de interés
   uint16_t chosen_neighbor;
   unsigned long my_time;
   // llenar los valores deseados
   copyB(((uint8_t * ) & data_buffer[chosen_neighbor_index]), ((uint8_t * ) & chosen_neighbor), 2);
   copyB(((uint8_t * ) & data_buffer[my_time_index]), ((uint8_t * ) & my_time), 4);
   // calcular RTT
   unsigned long my_rtt = micros() - my_time;
   //Serial.println(my_rtt);
   // obtener el refuerzo
   float r = get_reinforcement(my_rtt, packet_source_address);
   // actualizar retardos históricos
   update_rtt_matrix(my_rtt, packet_source_address);
   // actualizar matriz de feromona
   update_T_matrix(r, packet_source_address, chosen_neighbor);
   if (packet_destination_address != my_address){
      // hacer forward al paquete
      // actualizar tamaño del paquete
      data_buffer[1] = data_buffer[1] - 6;
      // posición del próximo salto
      uint8_t next_hop_in_stack_index = data_buffer[1] - 12;
      uint16_t next_hop_in_stack;
      copyB(((uint8_t * ) & data_buffer[next_hop_in_stack_index]), ((uint8_t * ) & next_hop_in_stack), 2);
      mrf.sendNoAck_byte(next_hop_in_stack, data_buffer, data_buffer[1]);
   } else {
      char num_buffer[10];
      for (byte i = 0; i < destination_count; i++){
          dtostrf(T_matrix[i][find_index(packet_source_address)], 5, 3, num_buffer);
          Serial.print(num_buffer);
          Serial.print("\t");  
      }
      float rtt_ms = float(my_rtt) / 1000.0;
      dtostrf(rtt_ms, 5, 3, num_buffer);
      Serial.print(num_buffer);
      Serial.print("\t");
      Serial.print(find_index(chosen_neighbor));
      Serial.println("");
   }
   //Serial.println(my_time);
   //Serial.println(my_rtt);
}

void setup() {
  Serial.begin(115200);
  var_init();
  randomSeed(analogRead(A0));
 
  // poner el color correspondiente al ID
  pixels.begin(); 
  pixels.clear(); // Set all pixel colors to 'off'
  pixels.setPixelColor(0, pixels.Color(my_color[0], my_color[1], my_color[2]));
  pixels.show();  
  
  //reinicio del modulo
  mrf.reset();
  //inicialización. Default sin beacon
  mrf.init();
  //asigna PAN
  mrf.set_pan(pan);
  //asigna la dirección
  mrf.address16_write(my_address);
  //inicializa red sin baliza
  mrf.NoBeaconInitCoo();
  // método 1 de csma: nivel de potencia sobre umbral
  mrf.set_cca(1); 
  // se utiliza CSMACA ya que no se tiene envio periodico de Beacons
  mrf.UnslottedCSMACA();
  // interrupciones
  isr_setup();
  // mensajes inciales seriales para debugging
  uint16_t address_received = mrf.address16_read();
  char serial_buffer [150];
  sprintf(serial_buffer, "DEV ID: %d, DEV Address: 0x%4X", dev_id, address_received);
  Serial.println(serial_buffer);
}

void loop() {
  // revisa las banderas para enviar y recibir datos
  mrf.check_flags(&handleRx, &handleTx);
  // revisar tareas periódicas 
  if (my_timer == 0){
    // temporizador para 100 ms
    my_timer = 1;

    if (discover_slot_counter < time_slot_count){
        discover_slot_counter += 1;
        // enviar un paquete de hello con probabilidad P_t_scaled
        if (random(0, 256) < P_t_scaled){
            send_hello_packet();
         }
        // si ya se terminó de enviar la ráfaga inicial, ir al siguiente estado
        if (discover_slot_counter == time_slot_count){
          periodic_tasks = true;
        }
    } else if (periodic_tasks){
        // ejecutar periodicas que se prolongan durante toda la ejecución del programa
        // cada 1.5 segundos, enviar hello con probabilidad Pt
        if ((periodic_hello_counter % ms_slot_hello) == 0){
          if (random(0, 256) < P_t_scaled){
            send_hello_packet();
         }
        } else if (i_am_source && (neighbor_count > 0) && ((periodic_hello_counter % n100_ms_forward) == 0)){
          // enviar hormiga de forward si somos fuente y ya tenemos vecinos
          send_forward_ant(destination_address);
        }
        periodic_hello_counter++;
    }
  }
}

//maneja la bandera de recepción
void handleRx(void){
  // imprimir dirección de donde se recibió
  //char direccion_in [7];
  //sprintf(direccion_in, "0x%4X", mrf.get_rxinfo()->origin);
  //Serial.println(direccion_in);
  // ver qué tipo de paquete es
  uint8_t tipo = (mrf.get_rxinfo()->rx_data)[0];
  if (tipo == id_msg_hello){
    // se recibió mensaje de hello
    //Serial.println("Hello received");
    test_new_neighbor((uint16_t) mrf.get_rxinfo()->origin);
  } else if ((tipo == id_msg_forward) && (neighbor_count > 0)){
    // se recibió una hormiga de forward
    //Serial.println("Forward ant received");
    copyB(mrf.get_rxinfo()->rx_data, data_buffer, (mrf.get_rxinfo()->rx_data)[1]); 
    receive_forward_ant();
  } else if (tipo == id_msg_backward){
    // se recibió una hormiga de backward
    //Serial.println("Backward ant received");
    copyB(mrf.get_rxinfo()->rx_data, data_buffer, (mrf.get_rxinfo()->rx_data)[1]); 
    receive_backward_ant();
  }
}

//maneja la bandera de envío
void handleTx(void){
  //Serial.println("sent");
}
