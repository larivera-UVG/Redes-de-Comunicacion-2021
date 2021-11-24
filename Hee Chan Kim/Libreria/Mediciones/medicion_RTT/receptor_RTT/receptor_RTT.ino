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

//Variables
int i;
bool begin = false;

//RGB
Adafruit_NeoPixel pixels(NUMPIXELS, rgb, NEO_GRB + NEO_KHZ800);

//PAN
const uint16_t pan = 0x1234;
//Dirección
const uint16_t direccion = 0x000C;
//Dirección envio
uint16_t dest = 0x000F;

//mandar código RGB a la red
char led[] = "sd!";
bool member = false;

//buffer serial
const int SIZE = 116;
char buf[SIZE];
char recibido[SIZE];

//MRF24J40
Mrf24j mrf(rst, cs, itr);

void MRFInterruptRoutine() {
  //rutina para la interrupción
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
  //mrf.set_channel(12);

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
  mrf.NoBeaconInit();
  mrf.set_cca(1);
  mrf.UnslottedCSMACA();
}

void loop() {
  mrf.check_flags(&handleRx, &handleTx);
}

//maneja la bandera de recepción
void handleRx(void){  
  /*for (int i = 0; i < mrf.rx_datalength(); i++)
  Serial.write(mrf.get_rxinfo()->rx_data[i]);*/
  
  /*for (int j = 0; j < mrf.rx_datalength(); j++){
    if (mrf.get_rxinfo()->rx_data[j] == 0xAA)
    i++;
    else {
      break;
      Serial.println("fallo");
    }
  }*/
  
  if(mrf.get_rxinfo()->rx_data[0] == 'h' &&
      mrf.get_rxinfo()->rx_data[1] == 'o' &&
      mrf.get_rxinfo()->rx_data[2] == 'l' &&
      mrf.get_rxinfo()->rx_data[3] == 'a'){
        mrf.sendNoAck(dest,"S\n"); 
  } else {
    mrf.sendNoAck(dest,"N\n"); 
  }
  
     
}

//maneja la bandera de envío
void handleTx(void){
  //Serial.println("fue el tx");
}
