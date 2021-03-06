//verde significa recibir

//Inicialización del módulo

#include <mrf24j40ma.h>
#include <SPI.h>
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
char led[3] = {150,150,150};

//PAN
const uint16_t pan = 0x1234;
//Dirección
const uint16_t direccion = 0x0000;
//Dirección envio
const uint16_t dest = 0x000F;

//buffer serial
char serialBuffer[105];

//Clase
Mrf24j mrf(rst, cs, itr);

void MRFInterruptRoutine() {
  //rutina para la interrupción
  //Serial.println("interrupción");
  mrf.interrupt_handler();

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

  //asigna la dirección
  mrf.address16_write(direccion);

  //inicia no beacon
  mrf.NoBeaconInitCoo();

  //interrupción asociado al pin itr
  attachInterrupt(digitalPinToInterrupt(itr), MRFInterruptRoutine, CHANGE);

  interrupts();
}

void loop() {
  pixels.clear(); // Set all pixel colors to 'off'
  pixels.setPixelColor(0, pixels.Color(led[0], led[1], led[2])); 
  pixels.show();   // Send the updated pixel colors to the hardware.
  // revisa las banderas para enviar y recibir datos
  mrf.check_flags(&handleRx, &handleTx);
}

//maneja la bandera de recepción
void handleRx(void){
  
  /*if(mrf.rx_datalength() > 3){    
    if(mrf.get_rxinfo()->rx_data[0] == 'J' &&
       mrf.get_rxinfo()->rx_data[1] == 'O' &&
       mrf.get_rxinfo()->rx_data[2] == 'I' &&
       mrf.get_rxinfo()->rx_data[3] == 'N'){
        Serial.println("asociando... ");
        //mrf.association_response();
     }
   }*/
  /*Serial.println(mrf.rx_datalength());
  if(mrf.rx_datalength() == 3){
    led[0] = mrf.get_rxinfo()->rx_data[0];
    led[1] = mrf.get_rxinfo()->rx_data[1];
    led[2] = mrf.get_rxinfo()->rx_data[2];
  }*/
  for (int i = 0; i < mrf.rx_datalength(); i++)
  Serial.write(mrf.get_rxinfo()->rx_data[i]);
}

//maneja la bandera de envío
void handleTx(void){
  
}
