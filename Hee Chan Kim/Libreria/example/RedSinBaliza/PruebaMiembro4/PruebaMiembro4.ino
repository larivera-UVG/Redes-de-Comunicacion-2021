//led blanca: sin red asociada

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

bool asociado = false;
int contador = 0;



//RGB
Adafruit_NeoPixel pixels(NUMPIXELS, rgb, NEO_GRB + NEO_KHZ800);

//PAN
const uint16_t pan = 0x0040;
//Dirección
const uint16_t direccion = 0x1A32;
//Dirección envio
const uint16_t dest = 0x1001;

//mandar código RGB a la red
char led[3] = {0,150,0};

//buffer serial
const int SIZE = 105;
char buf[SIZE];

char miembro[] = "miembro 4";

//Clase
Mrf24j mrf(rst, cs, itr);

void MRFInterruptRoutine() {
  //rutina para la interrupción
  //Serial.println("interrupcion");
  mrf.interrupt_handler();
}

ISR(TIMER2_OVF_vect){
   ISR_timer2();  
}

void setup() {
  Serial.begin(115200);
  pixels.begin(); 

  //reinicio del modulo
  mrf.reset();
  
  //inicialización. Default sin beacon
  mrf.init();

  //asigna PAN
  mrf.set_pan(pan);

  //asigna la dirección
  mrf.address16_write(direccion);

  //interrupción asociado al pin itr
  attachInterrupt(digitalPinToInterrupt(itr), MRFInterruptRoutine, CHANGE);

  interrupts();

  //inicializa red sin baliza
  mrf.NoBeaconInit();
  mrf.set_cca(1);
  mrf.UnslottedCSMACA();

  //RGB
  pixels.clear(); // Set all pixel colors to 'off'
  pixels.setPixelColor(0, pixels.Color(led[0], led[1], led[2])); 
  pixels.show();   // Send the updated pixel colors to the hardware.

  while(!asociado){
    //contador++;
    asociado = mrf.association_request();
    //if(contador>3){
    //  resetFunc(); //call reset
    //}
  } 
  
  
  uint16_t pan_received = mrf.get_pan();
  uint16_t address_received = mrf.address16_read();
  uint16_t origin = mrf.get_rxinfo()->origin;
}

void loop() {
  pixels.clear(); // Set all pixel colors to 'off'
  pixels.setPixelColor(0, pixels.Color(led[0], led[1], led[2])); 
  pixels.show();   // Send the updated pixel colors to the hardware.
  // revisa las banderas para enviar y recibir datos
  mrf.check_flags(&handleRx, &handleTx);  
  mrf.coo_loop(10,true);
  mrf.node_loop();
  mrf.syncSending(dest,miembro);
}

//maneja la bandera de recepción
void handleRx(void){
  for (int i = 0; i < mrf.rx_datalength(); i++)
  Serial.write(mrf.get_rxinfo()->rx_data[i]);
  Serial.println(" ");

  bool fromCoo = mrf.readCoo();
  bool electionCoo = mrf.electionCoo();

  if(mrf.rx_datalength() == 3){
    led[0] = mrf.get_rxinfo()->rx_data[0];
    led[1] = mrf.get_rxinfo()->rx_data[1];
    led[2] = mrf.get_rxinfo()->rx_data[2];
  }

  bool member = mrf.association();
  if(member){
        mrf.sendAck(mrf.get_rxinfo()->origin, led);
        member = false;
  }
  
}

//maneja la bandera de envío
void handleTx(void){
}
