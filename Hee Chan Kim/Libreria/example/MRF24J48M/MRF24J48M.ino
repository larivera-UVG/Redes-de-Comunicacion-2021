 /*************************************************************************************************

* Titolo: Mrf24j40ShieldExample01

* Autori: Ingg. Tommaso Giusto e Alessandro Giusto

* Data: 26/06/2014

* Email: tommro@libero.it

*************************************************************************************************/


/*************************************************************************************************

* Inclusione librerie

*************************************************************************************************/



#include <SPI.h>

#include "mrf24j.h"


/*************************************************************************************************

* Definizione pin I/O Arduino

*************************************************************************************************/

// Pin reset modulo radio

const int pinResetMRF = 4;

// Pin chip select modulo radio

const int pinCSMRF = 5;

// Pin interrupt modulo radio

const int pinIntMRF = 2;

// Pin rele MRF shield

const int pinShieldRele = 8;

// Pin input MRF shield

const int pinShieldInput = 10;


// PAN rete wireless

const word PANWireless = 0x1235;


// Indirizzo proprio nodo rete wireless

const word thisNodeAddress = 0x6001;

//const word thisNodeAddress = 0x6002;


// Indirizzo nodo destinazione rete wireless

const word destNodeAddress = 0x6002;

//const word destNodeAddress = 0x6001;


/*************************************************************************************************

* Variabili programma

*************************************************************************************************/


// Oggetto Mrf24j shield

Mrf24j mrfShield(pinResetMRF, pinCSMRF, pinIntMRF);


// Ultimo stato input

int lastStatoInput;


/*************************************************************************************************

* Codice programma

*************************************************************************************************/


// Inizializzazione Scheda

void setup() {

// Inizializzo I/O

pinMode(pinShieldRele, OUTPUT);

pinMode(pinShieldInput, INPUT);

// Disattivo rele

digitalWrite(pinShieldRele, LOW);

// Leggo valore corrente input

lastStatoInput = LOW;


// Avvio porta seriale

Serial.begin(9600);

// Resetto oggetto Mrf24j shield

mrfShield.reset();

// Inizializzo oggetto Mrf24j shield

mrfShield.init();

// Imposto PAN rete wireless

mrfShield.set_pan(PANWireless);

// Imposto indirizzo nodo rete wireless

mrfShield.address16_write(thisNodeAddress);


// uncomment if you want to receive any packet on this channel

//mrfShield.set_promiscuous(true);

// uncomment if you want to enable PA/LNA external control

//mrfShield.set_palna(true);

// uncomment if you want to buffer all PHY Payload

//mrfShield.set_bufferPHY(true);


// Collego la funzione da eseguire quando capita change interrupt del pin MRF interrupt

// 0 -> corrisponde ad Arduino pin 2 (INT0 per Arduino ATmega8/168/328)

attachInterrupt(0, MRFInterruptRoutine, CHANGE);

interrupts();

}


// Funzione esecuzione MRF interrupt

void MRFInterruptRoutine() {

// Passo controllo routine interrupt oggetto Mrf24j shield

mrfShield.interrupt_handler();

}


// Programma Principale

void loop() {

int statoInput;

unsigned long currentMillis;

char serialBuffer[105];

int index;

int flag;


// Richiamo funzione gestione handler ricezione/trasmissione

mrfShield.check_flags(&handleRx, &handleTx);

// Leggo stato input

statoInput = digitalRead(pinShieldInput);

// Se variato stato input

if (statoInput != lastStatoInput) {

// Invio lo stato (protocollo di comunicazione)

if (statoInput == HIGH)

mrfShield.send16(destNodeAddress, "INPUT0");

else

mrfShield.send16(destNodeAddress, "INPUT1");


// Aggiorno variabile ultimo stato

lastStatoInput = statoInput;

}

// Se dati ricevuti sulla porta seriale

if (Serial.available() > 0) {

// Inizializzo il buffer comando

serialBuffer[0] = 'S';

serialBuffer[1] = 'E';

serialBuffer[2] = 'R';

serialBuffer[3] = 'I';

serialBuffer[4] = 'A';

index = 5;

// Memorizzo i caratteri ricevuti

for (;;) {

// Se nuovo carattere disponibile

if (Serial.available() > 0) {

// Accodo il carattere

serialBuffer[index] = (char) (Serial.read());

index++;

// Indico ricevuto carattere

flag = 0;

}

// Se nuovo carattere non disponibile

else {

// Se gia' non ricevuto carattere

if (flag == 1)

// Termino ciclo for memorizzo i caratteri ricevuti

break;


// Indico non ricevuto carattere

flag = 1;

// Attesa ricezione prossimo carattere

delay(5);

}

}

// Aggiungo fine stringa

serialBuffer[index] = (char) ('\0');

// Invio il comando

mrfShield.send16(destNodeAddress, serialBuffer);

}

}


// Handler eseguito alla ricezione di dati dalla radio

void handleRx() {

int i;

// Se ricevuto comando valido

if (mrfShield.rx_datalength() > 5) {

// Se ricevuto comando INPUT

if ((mrfShield.get_rxinfo()->rx_data[0] == 'I') &&

(mrfShield.get_rxinfo()->rx_data[1] == 'N') &&

(mrfShield.get_rxinfo()->rx_data[2] == 'P') &&

(mrfShield.get_rxinfo()->rx_data[3] == 'U') &&

(mrfShield.get_rxinfo()->rx_data[4] == 'T')) {

// Imposto stato rele

if (mrfShield.get_rxinfo()->rx_data[5] == '0')

digitalWrite(pinShieldRele, LOW);

else

digitalWrite(pinShieldRele, HIGH);

}

// Se ricevuto comando SERIA

else if ((mrfShield.get_rxinfo()->rx_data[0] == 'S') &&

(mrfShield.get_rxinfo()->rx_data[1] == 'E') &&

(mrfShield.get_rxinfo()->rx_data[2] == 'R') &&

(mrfShield.get_rxinfo()->rx_data[3] == 'I') &&

(mrfShield.get_rxinfo()->rx_data[4] == 'A')) {

// Invio i dati sulla seriale

for (int i = 5; i < mrfShield.rx_datalength(); i++)

Serial.write(mrfShield.get_rxinfo()->rx_data[i]);

}

}

}


// Handler eseguito per trasmissione di dati sulla radio

void handleTx() {

}
