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
const uint16_t direccion = 0x0001;
//Dirección envio
const uint16_t dest = 0x1002;

//mandar código RGB a la red
char led[3] = {0,150,0};

//buffer serial
const int SIZE = 105;
char buf[SIZE];

char miembro[] = "miembro 1";

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

  Serial.println("hola");
}

void loop() {
  pixels.clear(); // Set all pixel colors to 'off'
  pixels.setPixelColor(0, pixels.Color(150, 0, 0));
  pixels.show();   // Send the updated pixel colors to the hardware.
  // revisa las banderas para enviar y recibir datos
  mrf.check_flags(&handleRx, &handleTx);

  uint8_t energia = mrf.lqi();
  Serial.println(energia);
  delay(100);
}

//maneja la bandera de recepción
void handleRx(void){
  
}

//maneja la bandera de envío
void handleTx(void){
  
}
