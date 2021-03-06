/*
 * File:   mrf24jma.h
 * copyright Karl Palsson, karlp@tweak.net.au, 2011
 * modified BSD License / apache license
 * modified by Hee Chan Kim.
 */

#ifndef __MRF24J40MA_H__
#define __MRF24J40MA_H__

#pragma once //because we only want to compile it once.

#if defined(ARDUINO) && ARDUINO >= 100 // Arduino IDE version >= 1.0
    #include "Arduino.h"
#else // older Arduino IDE versions
    #include "WProgram.h"
#endif
#include <SPI.h>
#include <stdio.h>
#include <stdlib.h>    /* for NULL */
#include <stdint.h>    /* uint8_t, etc. */
#include <stdbool.h>   /* bool type, true, false */
#include "timer.h" /* for software timers */


#define MRF_RXMCR 0x00
#define MRF_PANIDL 0x01
#define MRF_PANIDH 0x02
#define MRF_SADRL 0x03
#define MRF_SADRH 0x04
#define MRF_EADR0 0x05
#define MRF_EADR1 0x06
#define MRF_EADR2 0x07
#define MRF_EADR3 0x08
#define MRF_EADR4 0x09
#define MRF_EADR5 0x0A
#define MRF_EADR6 0x0B
#define MRF_EADR7 0x0C
#define MRF_RXFLUSH 0x0D
//#define MRF_Reserved 0x0E
//#define MRF_Reserved 0x0F
#define MRF_ORDER 0x10
#define MRF_TXMCR 0x11
#define MRF_ACKTMOUT 0x12
#define MRF_ESLOTG1 0x13
#define MRF_SYMTICKL 0x14
#define MRF_SYMTICKH 0x15
#define MRF_PACON0 0x16
#define MRF_PACON1 0x17
#define MRF_PACON2 0x18
//#define MRF_Reserved 0x19
#define MRF_TXBCON0 0x1A

// TXNCON: TRANSMIT NORMAL FIFO CONTROL REGISTER (ADDRESS: 0x1B)
#define MRF_TXNCON      0x1B
#define MRF_TXNTRIG     0
#define MRF_TXNSECEN    1
#define MRF_TXNACKREQ   2
#define MRF_INDIRECT    3
#define MRF_FPSTAT      4

#define MRF_TXG1CON 0x1C
#define MRF_TXG2CON 0x1D
#define MRF_ESLOTG23 0x1E
#define MRF_ESLOTG45 0x1F
#define MRF_ESLOTG67 0x20
#define MRF_TXPEND 0x21
#define MRF_WAKECON 0x22
#define MRF_FRMOFFSET 0x23
// TXSTAT: TX MAC STATUS REGISTER (ADDRESS: 0x24)
#define MRF_TXSTAT 0x24
#define TXNRETRY1       7
#define TXNRETRY0       6
#define CCAFAIL         5
#define TXG2FNT         4
#define TXG1FNT         3
#define TXG2STAT        2
#define TXG1STAT        1
#define TXNSTAT         0

#define MRF_TXBCON1 0x25
#define MRF_GATECLK 0x26
#define MRF_TXTIME 0x27
#define MRF_HSYMTMRL 0x28
#define MRF_HSYMTMRH 0x29
#define MRF_SOFTRST 0x2A
//#define MRF_Reserved 0x2B
#define MRF_SECCON0 0x2C
#define MRF_SECCON1 0x2D
#define MRF_TXSTBL 0x2E
//#define MRF_Reserved 0x2F
#define MRF_RXSR 0x30
#define MRF_INTSTAT 0x31
#define MRF_INTCON 0x32
#define MRF_GPIO 0x33
#define MRF_TRISGPIO 0x34
#define MRF_SLPACK 0x35
#define MRF_RFCTL 0x36
#define MRF_SECCR2 0x37
#define MRF_BBREG0 0x38
#define MRF_BBREG1 0x39
#define MRF_BBREG2 0x3A
#define MRF_BBREG3 0x3B
#define MRF_BBREG4 0x3C
//#define MRF_Reserved 0x3D
#define MRF_BBREG6 0x3E
#define MRF_CCAEDTH 0x3F

#define MRF_RFCON0 0x200
#define MRF_RFCON1 0x201
#define MRF_RFCON2 0x202
#define MRF_RFCON3 0x203
#define MRF_RFCON5 0x205
#define MRF_RFCON6 0x206
#define MRF_RFCON7 0x207
#define MRF_RFCON8 0x208
#define MRF_SLPCAL0 0x209
#define MRF_SLPCAL1 0x20A
#define MRF_SLPCAL2 0x20B
#define MRF_RSSI 0x210
#define MRF_SLPCON0 0x211
#define MRF_SLPCON1 0x220
#define MRF_WAKETIMEL 0x222
#define MRF_WAKETIMEH 0x223
#define MRF_REMCNTL 0x224
#define MRF_REMCNTH 0x225
#define MRF_MAINCNT0 0x226
#define MRF_MAINCNT1 0x227
#define MRF_MAINCNT2 0x228
#define MRF_MAINCNT3 0x229
#define MRF_TESTMODE 0x22F
#define MRF_ASSOEADR1 0x231
#define MRF_ASSOEADR2 0x232
#define MRF_ASSOEADR3 0x233
#define MRF_ASSOEADR4 0x234
#define MRF_ASSOEADR5 0x235
#define MRF_ASSOEADR6 0x236
#define MRF_ASSOEADR7 0x237
#define MRF_ASSOSADR0 0x238
#define MRF_ASSOSADR1 0x239
#define MRF_UPNONCE0 0x240
#define MRF_UPNONCE1 0x241
#define MRF_UPNONCE2 0x242
#define MRF_UPNONCE3 0x243
#define MRF_UPNONCE4 0x244
#define MRF_UPNONCE5 0x245
#define MRF_UPNONCE6 0x246
#define MRF_UPNONCE7 0x247
#define MRF_UPNONCE8 0x248
#define MRF_UPNONCE9 0x249
#define MRF_UPNONCE10 0x24A
#define MRF_UPNONCE11 0x24B
#define MRF_UPNONCE12 0x24C

#define MRF_I_RXIF  0b00001000
#define MRF_I_TXNIF 0b00000001


#define MACResponseWaitTime 30000
#define MACJoinedWaitTime 50000
#define BROADCAST 0xFFFF
#define N_DECIMAL_POINTS_PRECISION (10000) // n = 4
#define WAIT_10MS 1 // implement in the timer to wait 10 ms
#define WAIT_100MS 1 // implement in the timer to wait 100 ms

typedef struct _rx_info_t{
    uint8_t frame_length;
    uint16_t origin;
    uint16_t panid;
    uint8_t rx_data[116]; //max data length = (127 aMaxPHYPacketSize - 2 Frame control - 1 sequence number - 2 panid - 2 shortAddr Destination - 2 shortAddr Source - 2 FCS)
    uint8_t lqi;
    uint8_t rssi;
} rx_info_t;

/**
 * Based on the TXSTAT register, but "better"
 */
typedef struct _tx_info_t{
    uint8_t tx_ok:1;
    uint8_t retries:2;
    uint8_t channel_busy:1;
} tx_info_t;
/**
 * Pool for getting the addresses. It's better to include it here because anyone can become the coordinator.
 */
typedef struct _pool_t{
    uint8_t size = 10;
    uint16_t address[10] = {0x0001,0x0002,0x0003,0x0004,0x0005,0x0006,0x0007,0x0008,0x0009,0x000A};
    uint8_t availability[10] = {0,0,0,0,0,0,0,0,0,0};  // 0:available 1:occupy
    uint8_t QUORUM = 1; // the amount of nodes that are need to approve the coordinator election service
} pool_t;

class Mrf24j
{
    public:
        Mrf24j(int pin_reset, int pin_chip_select, int pin_interrupt);
        void reset(void);
        void init(void);

        byte read_short(byte address);
        byte read_long(uint16_t address);

        void write_short(byte address, byte data);
        void write_long(uint16_t address, byte data);

        uint16_t get_pan(void);
        void set_pan(uint16_t panid);

        void address16_write(uint16_t address16);
        uint16_t address16_read(void);

        void set_interrupts(void);

        void set_promiscuous(boolean enabled);

        /**
         * Set the channel, using 802.15.4 channel numbers (11..26)
         */
        void set_channel(byte channel);

        void rx_enable(void);
        void rx_disable(void);

        /** If you want to throw away rx data */
        void rx_flush(void);

        rx_info_t * get_rxinfo(void);

        tx_info_t * get_txinfo(void);

        uint8_t * get_rxbuf(void);

        int rx_datalength(void);

        void set_ignoreBytes(int ib);

        /**
         * Set bufPHY flag to buffer all bytes in PHY Payload, or not
         */
        void set_bufferPHY(boolean bp);

        boolean get_bufferPHY(void);

        /**
         * Set PA/LNA external control
         */
        void set_palna(boolean enabled);

        void send16(uint16_t dest16, char * data);

        void interrupt_handler(void);

        void check_flags(void (*rx_handler)(void), void (*tx_handler)(void));

        // ------------------------------- MAC -------------------------------
        /**
         * Evaluation for the channel to determine if it is busy or free (CCA)
         */ 
        void set_cca(uint8_t method = 0);
        uint8_t lqi(void);
        bool channel_occupied(void);
        /*
         * Mask when it's necessary to modify certain bits from register
         */
        uint8_t mask_short(uint8_t reg, uint8_t mask, uint8_t change);
        uint16_t mask_long(uint16_t reg, uint16_t mask, uint8_t change);

        /*
         * Functions for a Non beacon network
         */
        void NoBeaconInitCoo(void);
        bool check_coo(void);
        void NoBeaconInit(void);
        void UnslottedCSMACA(void);
        void SlottedCSMACA(void);

        /*
         * Functions for sending data
         */
        void sendAck(uint16_t dest16, char * data);
        void sendNoAck(uint16_t dest16, char * data);
        void broadcast(char * data, uint16_t address = BROADCAST);
        void sendNoAck_byte(uint16_t dest16, uint8_t * data, uint8_t data_size);
        void broadcast_byte(char * data, uint8_t data_size, uint16_t address = BROADCAST);

        /*
         * To associate to a PAN
         */
        void association_set(uint16_t panid, uint16_t address);
        
        // ------------------------------- NTW -------------------------------
        /*
         * To associate to a PAN
         */
        bool association_response(void);
        bool association_request(void);
        pool_t * get_pool(void);

        // ------------------------------- APP -------------------------------
        /*
         * Sending/Returning a float
         */
        float readF(void); // max 4 numbers after decimal point.
        void sendF(uint16_t address, float value, bool ack = 1);

        /*
         * Time Sync service 
         */
        bool sync(void); // for the Coordinator ONLY
        bool syncSending(uint16_t dest, char * message); // sends the message
        void synchronizedNodes(void); //synchronized the service with the number of nodes 

        /*
         * Algorithm to check coordinator messages 
         */
        bool readCoo(void);

        /*
         * To associate to a PAN
         */
        bool association(void); //for the coordinator ONLY

        /*
         * Check all members are still connected
         */
        byte still(void); // check if the members are still connected.
        void update(void); // send an update to all nodes.
        void updateInfo(void); // update the information of the PAN
        void cooCheck(uint8_t seconds = 2); // calls the still service every "seconds"

        /*
         * Set the software timers
         */
        void setTimer(void);

        /*
         * Coordinator election service
         */
        void cooBeat(void);
        bool heartbeat(void);
        bool electionCoo(void);
        bool votation(void);
        void cooElection(void);
        bool check_IamCoo(void);
        bool am_I_the_coordinator;

        /*
         * The two principal loops: coordinator and node
         */
        int coo_loop(uint8_t seconds = 2, bool synchronize = false);
        int node_loop(void);
        uint16_t coord;

    private:
        int _pin_reset;
        int _pin_cs;
        int _pin_int;
        bool _ACK_FAIL;
        bool _timerGo;
        uint32_t _timer;
        volatile bool previousCooRequest;
        volatile bool newCooRequest;
        bool IamCoo;
        uint16_t newcoord;
        volatile uint8_t quorum;
        volatile uint8_t tries;
        uint16_t PANID;

        // Timers. MAX: 10 of 10ms and 10 of 100ms
        volatile uint8_t Timer_500ms_request; // 100ms_timer
        volatile uint8_t Timer_100ms_response; // 100ms_timer
        volatile uint8_t Timer_200ms_still; // 100ms_timer
        volatile uint8_t Timer_10ms_general; // 10ms_timer
        volatile uint8_t Timer_2500ms_beat; // 10ms_timer
        volatile uint8_t Timer_5000ms_heartbeat; // 100ms_timer
        volatile uint8_t Timer_5000ms_acceptNew; // 100ms_timer
        volatile uint8_t Timer_connected; // 100ms_timer
        volatile uint8_t Timer_sync; // 10ms_timer
        volatile uint8_t Timer_10000ms_lqi; // 100ms_timer
};

#endif  /* __MRF24J40MA_H__ */
