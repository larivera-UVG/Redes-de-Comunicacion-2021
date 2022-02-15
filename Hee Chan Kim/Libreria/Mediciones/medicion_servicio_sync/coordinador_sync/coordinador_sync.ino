//defina el color de la red: azul

//Inicialización del módulo

#include <mrf24j40ma.h>
#include <Adafruit_NeoPixel.h>

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

//PAN
const uint16_t pan = 0x1234;
//Dirección
const uint16_t direccion = 0x000F;
//Dirección envio
uint16_t dest = 0x0000;

//mandar código RGB a la red
char led[] = "sd!";
//led[0] = 0;
//led[1] = 0;
//led[2] = 150;
bool member = false;

//buffer serial
const int SIZE = 105;
char buf[SIZE];
char recibido[SIZE];
int success = 0;
bool sincronizacion = false;
bool primero, segundo;
int iter = 0;

//MRF24J40
Mrf24j mrf(rst, cs, itr);

void MRFInterruptRoutine() {
  //rutina para la interrupción
  //Serial.println("interrupcion");
  mrf.interrupt_handler();
}

//Timers en software
uint8_t my_timer = 10;
uint8_t my_timer2 = 25;

ISR(TIMER2_OVF_vect){
   ISR_timer2();  
}

void setup() {
  Serial.begin(115200);
  pixels.begin(); 

  //reinicio del modulo
  mrf.reset();
  
  //inicialización
  mrf.init();

  //asigna PAN
  mrf.set_pan(pan);

  //asigna canal
  mrf.set_channel(25);

  //asigna la dirección
  mrf.address16_write(direccion);

  //interrupción asociado al pin itr
  attachInterrupt(digitalPinToInterrupt(itr), MRFInterruptRoutine, CHANGE);

  //interrupción asociada al timer2
  //timer_init();
  timer_register_100ms(&my_timer);
  timer_register_10ms(&my_timer2);

  interrupts();

  //inicializa red sin baliza
  mrf.NoBeaconInitCoo();
  mrf.set_cca(1);
  mrf.UnslottedCSMACA();

  uint16_t pan_received = mrf.get_pan();
  uint16_t address_received = mrf.address16_read();

  Serial.print("Está conectada a la red: "); Serial.println(pan_received);
  Serial.print("Su dirección es: "); Serial.println(address_received);
}

void loop() {
  pixels.clear(); // Set all pixel colors to 'off'
  pixels.setPixelColor(0, pixels.Color(led[0], led[1], led[2])); 
  pixels.show();   // Send the updated pixel colors to the hardware.
  // revisa las banderas para enviar y recibir datos
  mrf.check_flags(&handleRx, &handleTx);
  /*if (my_timer2 == 0){
    mrf.sendNoAck(0xFFFF,"BEAT");
    my_timer2 = 25;
  }*/
  
  int i = 0;
  if (Serial.available() > 0) {
      String data = Serial.readStringUntil('\n');

      if (data == "exitos"){
        Serial.print("Se realizaron 2000 pruebas y se tuvo exito en "); Serial.println(success);
      } else if (data == "sync"){
        sincronizacion = true;
        mrf.sync();
      }
  }

  if (primero && segundo && sincronizacion){
    success += 1;
    iter += 1;
    mrf.sync();
    my_timer = 10;
    Serial.print("iteración "); Serial.print(iter);
    Serial.print(" exitos "); Serial.println(success);
    primero = false;
    segundo = false;
  }

  if (my_timer == 0 && sincronizacion){
    //Serial.println("1 segundo");
    my_timer = 10;
    iter += 1;
    primero = true;
    segundo = true;
  }

  if (iter >= 2000)
  sincronizacion = false;
}

//maneja la bandera de recepción
void handleRx(void){  
  //Serial.print("Vino de "); Serial.println(mrf.get_rxinfo()->origin);
  for (int i = 0; i < mrf.rx_datalength(); i++)
  Serial.write(mrf.get_rxinfo()->rx_data[i]);
  Serial.println(" ");

  member = mrf.association();
   if(member){
        mrf.sendAck(mrf.get_rxinfo()->origin, led);
        member = false;
  }

  if(mrf.get_rxinfo()->rx_data[0] == 'm' &&
  mrf.get_rxinfo()->rx_data[1] == 'i' &&
  mrf.get_rxinfo()->rx_data[2] == 'e' &&
  mrf.get_rxinfo()->rx_data[3] == 'm' &&
  mrf.get_rxinfo()->rx_data[4] == 'b' &&
  mrf.get_rxinfo()->rx_data[5] == 'r' &&
  mrf.get_rxinfo()->rx_data[6] == 'o' &&
  mrf.get_rxinfo()->rx_data[7] == ' ' &&
  mrf.get_rxinfo()->rx_data[8] == '1'){
    primero = true;
  }
  if(mrf.get_rxinfo()->rx_data[0] == 'm' &&
  mrf.get_rxinfo()->rx_data[1] == 'i' &&
  mrf.get_rxinfo()->rx_data[2] == 'e' &&
  mrf.get_rxinfo()->rx_data[3] == 'm' &&
  mrf.get_rxinfo()->rx_data[4] == 'b' &&
  mrf.get_rxinfo()->rx_data[5] == 'r' &&
  mrf.get_rxinfo()->rx_data[6] == 'o' &&
  mrf.get_rxinfo()->rx_data[7] == ' ' &&
  mrf.get_rxinfo()->rx_data[8] == '2'){
    segundo = true;
  }
}

//maneja la bandera de envío
void handleTx(void){
  //Serial.println("fue el tx");
  //Serial.print("ACK "); Serial.println(mrf.get_txinfo()->tx_ok);
}
