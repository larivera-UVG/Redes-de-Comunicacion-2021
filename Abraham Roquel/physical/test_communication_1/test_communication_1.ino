/*
  Universidad del Valle de Guatemala
  Diseño e innovación en ingeniería 2
  Protocolos de enrutamiento basados en inteligencia de enjambre

  test_communication_1: el propósito es comunicar 2 unidades de arduino nano 33 IoT vía los módulos WiFi.
*/

#include <SPI.h>
#include <WiFiNINA.h>

#define device_id 1

// class B private address range: 172.16.0.0 to 172.31.255.255

#if device_id == 1
  #define device_ip "172.21.0.1"
#else
  #define device_ip "172.21.0.2"
#endif

//void printMacAddress(byte mac[]) {
//  for (int i = 5; i >= 0; i--) {
//    if (mac[i] < 16) {
//      Serial.print("0");
//    }
//    Serial.print(mac[i], HEX);
//    if (i > 0) {
//      Serial.print(":");
//    }
//  }
//  Serial.println();
//}

void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }

  char buff_message[50];
  sprintf(buff_message, "I'm device no. %d, with ip %s\n", device_id, device_ip);
  Serial.print(buff_message);

//  byte mac[6];
//  WiFi.macAddress(mac);
//  Serial.print("MAC: ");
//  printMacAddress(mac);
}

void loop() {
  // put your main code here, to run repeatedly:

}
