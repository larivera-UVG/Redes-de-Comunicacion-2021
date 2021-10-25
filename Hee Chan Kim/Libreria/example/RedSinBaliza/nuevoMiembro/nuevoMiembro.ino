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
const uint16_t direccion = 0x1A31;
//Dirección envio
const uint16_t dest = 0x000F;

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

//función para reiniciar el microcontrolador
void(* resetFunc) (void) = 0;  // declare reset fuction at address 0


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
    contador++;
    asociado = mrf.association_request();
    if(contador>3){
      resetFunc(); //call reset
    }
  } 
  uint16_t pan_received = mrf.get_pan();
  uint16_t address_received = mrf.address16_read();
  uint16_t origin = mrf.get_rxinfo()->origin;
  
  Serial.print("Está conectada a la red: "); Serial.println(pan_received);
  Serial.print("Su dirección es: "); Serial.println(address_received);
  Serial.print("Vino de: "); Serial.println(origin);
}

void loop() {
  pixels.clear(); // Set all pixel colors to 'off'
  pixels.setPixelColor(0, pixels.Color(led[0], led[1], led[2])); 
  pixels.show();   // Send the updated pixel colors to the hardware.
  // revisa las banderas para enviar y recibir datos
  mrf.check_flags(&handleRx, &handleTx);
  mrf.cooElection();
  if(mrf.am_I_the_coordinator)
  mrf.cooBeat();
  
  
  int i = 0;
  if (Serial.available() > 0) {
      //String data = Serial.readStringUntil('\n');
      int hola = Serial.readBytesUntil('\n',buf,SIZE);
      hola++;
      buf[hola] = '\n';
      if (hola){
        Serial.println("enviando...");
        //mrf.broadcast(hola);
        mrf.sendAck(dest,buf);
        //mrf.sendNoAck(dest,buf);
        for(int i;i< hola; i++){
          buf[i] = {};
        }     
      }
  }
  if(mrf.syncSending())
  mrf.sendAck(dest,miembro);
}

//maneja la bandera de recepción
void handleRx(void){
  for (int i = 0; i < mrf.rx_datalength(); i++)
  Serial.write(mrf.get_rxinfo()->rx_data[i]);
  Serial.println(" ");

  mrf.electionCoo();
  
  bool fromCoo = mrf.readCoo();
  if(mrf.rx_datalength() == 3){
    led[0] = mrf.get_rxinfo()->rx_data[0];
    led[1] = mrf.get_rxinfo()->rx_data[1];
    led[2] = mrf.get_rxinfo()->rx_data[2];
  }

}

//maneja la bandera de envío
void handleTx(void){
  //Serial.println("fue el tx");
}
