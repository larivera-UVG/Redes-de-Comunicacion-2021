//rojo significa miembro

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
const uint16_t dest = 0x000A;

//buffer serial
const int SIZE = 105;
char buf[SIZE];
char adios[] = "sd!";
char palabra[] = "JOIN\n";
float numero = 1577.345;

//Clase
Mrf24j mrf(rst, cs, itr);

void MRFInterruptRoutine() {
  //rutina para la interrupción
  // Serial.println("interrupcion");
  mrf.interrupt_handler();

}

void setup() {
  Serial.begin(115200);
  pixels.begin(); 

  //reinicio del modulo
  mrf.reset();
  
  //inicialización. Default no beacon
  mrf.init();

  //asigna PAN
  mrf.set_pan(pan);

  //asigna la dirección
  mrf.address16_write(direccion);

  //inicia no beacon
  mrf.NoBeaconInit();
  Serial.print("Coo: "); Serial.println(mrf.check_coo());

  //asigna el canal
  //mrf.set_channel(11);

  //interrupción asociado al pin itr
  attachInterrupt(digitalPinToInterrupt(itr), MRFInterruptRoutine, CHANGE);

  interrupts();
  
}

void loop() {
  pixels.clear(); // Set all pixel colors to 'off'
  pixels.setPixelColor(0, pixels.Color(150, 0, 0)); 
  pixels.show();   // Send the updated pixel colors to the hardware.
  // revisa las banderas para enviar y recibir datos
  mrf.check_flags(&handleRx, &handleTx);

  if (Serial.available() > 0) {
      String data = Serial.readStringUntil('\n');
      if (data == "enviar"){
        Serial.println("enviando...");
        //mrf.broadcast(palabra,dest);
        mrf.sendAck(dest,palabra);
        //mrf.sendNoAck(dest,palabra);     
      }

      if (data == "rgb"){
        Serial.println(adios);
        //mrf.broadcast(adios,dest);
        mrf.sendAck(dest,adios);
        //mrf.sendNoAck(dest,adios);  
      }
      if (data == "float"){
        //mrf.broadcast(numero,dest);
        mrf.sendF(dest,numero);
        //mrf.sendNoAck(dest,numero);  
      }
  }
}

//maneja la bandera de recepción
void handleRx(void){
  for (int i = 0; i < mrf.rx_datalength(); i++)
  Serial.write(mrf.get_rxinfo()->rx_data[i]);
}

//maneja la bandera de envío
void handleTx(void){
  uint8_t hola = mrf.get_txinfo()->tx_ok;
  //Serial.print("enviar ok: "); Serial.println(hola);
}
