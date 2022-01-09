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
#define SIZE 105

//RGB
Adafruit_NeoPixel pixels(NUMPIXELS, rgb, NEO_GRB + NEO_KHZ800);

//PAN
const uint16_t pan = 0x1234;
//Dirección
const uint16_t direccion = 0x000F;
//Dirección envio
uint16_t dest = 0x0000;

//mandar código RGB a la red
uint8_t led[] = {0,0,0};


char guardado[SIZE];
bool asociado = false;

// **********************************************************
// interrupcion asociada al transceptor
// **********************************************************
//MRF24J40
Mrf24j mrf(rst, cs, itr);

void MRFInterruptRoutine() {
  //rutina para la interrupción
  mrf.interrupt_handler();
}

// **********************************************************
// interrupcion asociada al timer 2
// **********************************************************
//Timers en software
uint8_t my_timer = 10;
uint8_t my_timer2 = 25;

ISR(TIMER2_OVF_vect){
   ISR_timer2();  
}

// **********************************************************
// setup
// **********************************************************
void mrf_setup(){
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

  //inicializa red sin baliza
  mrf.NoBeaconInitCoo();
  //mrf.set_cca(1);
  mrf.UnslottedCSMACA();
}

void isr_setup(void){
  //interrupción asociado al pin itr
  attachInterrupt(digitalPinToInterrupt(itr), MRFInterruptRoutine, CHANGE);

  //interrupción asociada al timer2
  //timer_init();
  //timer_register_100ms(&my_timer);
  //timer_register_10ms(&my_timer2);

  interrupts();
}

void setup() {
  Serial.begin(115200);
  pixels.begin(); 

  mrf_setup();
  isr_setup();


  while(!asociado){
    asociado = mrf.association_request();
  } 

  uint16_t pan_received = mrf.get_pan();
  uint16_t address_received = mrf.address16_read();

  Serial.print("Está conectada a la red: "); Serial.println(pan_received);
  Serial.print("Su dirección es: "); Serial.println(address_received);
}

// **********************************************************
// loop
// **********************************************************
void loop() {
  pixels.clear(); // Set all pixel colors to 'off'
  pixels.setPixelColor(0, pixels.Color(led[0], led[1], led[2])); 
  pixels.setBrightness(10);
  pixels.show();   // Send the updated pixel colors to the hardware.
  
  // revisa las banderas para enviar y recibir datos
  mrf.check_flags(&handleRx, &handleTx);
  mrf.coo_loop(10,true);
  mrf.node_loop();
  mrf.syncSending(mrf.coord,guardado);
}

//maneja la bandera de recepción
void handleRx(void){
  for (int i = 0; i < mrf.rx_datalength(); i++)
  Serial.write(mrf.get_rxinfo()->rx_data[i]);
  Serial.println(" ");
  
  bool fromCoo = mrf.readCoo();
  bool electionCoo = mrf.electionCoo();
  bool member = mrf.association();
  if(member){
        mrf.sendNoAck_byte(mrf.get_rxinfo()->origin,led,3);
        member = false;
  }
  if(mrf.rx_datalength() == 3){
    led[0] = mrf.get_rxinfo()->rx_data[0];
    led[1] = mrf.get_rxinfo()->rx_data[1];
    led[2] = mrf.get_rxinfo()->rx_data[2];
  }
  if(mrf.get_rxinfo()->rx_data[0] == 'S' &&
     mrf.get_rxinfo()->rx_data[1] == 'A' &&
     mrf.get_rxinfo()->rx_data[2] == 'V' &&
     mrf.get_rxinfo()->rx_data[3] == 'E'){
      for (int i = 0; i < SIZE; i++)
      guardado[i] = 0;
      for (int i = 4, j = 0;i < mrf.rx_datalength(); i++, j++)
      guardado[j] = mrf.get_rxinfo()->rx_data[i];
     }
}

//maneja la bandera de envío
void handleTx(void){

}
