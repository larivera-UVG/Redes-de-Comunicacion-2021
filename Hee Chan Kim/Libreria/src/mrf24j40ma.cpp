/**
 * mrf24j.cpp, Karl Palsson, 2011, karlp@tweak.net.au
 * modified bsd license / apache license
 * modified by Hee Chan Kim.
 */

#include "mrf24j40ma.h"

// aMaxPHYPacketSize = 127, from the 802.15.4-2006 standard.
static uint8_t rx_buf[127];

// essential for obtaining the data frame only
// MAC header (MHR)
// bytes_MHR = 2 Frame control + 1 sequence number + 2 panid + 2 shortAddr Destination + 2 shortAddr Source
static int bytes_MHR = 9;
static int bytes_FCS = 2; // FCS length = 2
static int bytes_nodata = bytes_MHR + bytes_FCS; // no_data bytes in PHY payload,  header length + FCS

static int ignoreBytes = 0; // bytes to ignore, some modules behaviour.

static boolean bufPHY = false; // flag to buffer all bytes in PHY Payload, or not

volatile uint8_t flag_got_rx;
volatile uint8_t flag_got_tx;

static rx_info_t rx_info;
static tx_info_t tx_info;
static pool_t pool;

/**
 * Constructor MRF24J Object.
 * @param pin_reset, @param pin_chip_select, @param pin_interrupt
 */
Mrf24j::Mrf24j(int pin_reset, int pin_chip_select, int pin_interrupt) {
    _pin_reset = pin_reset;
    _pin_cs = pin_chip_select;
    _pin_int = pin_interrupt;

    pinMode(_pin_reset, OUTPUT);
    pinMode(_pin_cs, OUTPUT);
    pinMode(_pin_int, INPUT);

    SPI.setBitOrder(MSBFIRST) ;
    SPI.setDataMode(SPI_MODE0);
    SPI.begin();
}

void Mrf24j::reset(void) {
    digitalWrite(_pin_reset, LOW);
    delay(10);  // just my gut
    digitalWrite(_pin_reset, HIGH);
    delay(20);  // from manual
}

byte Mrf24j::read_short(byte address) {
    digitalWrite(_pin_cs, LOW);
    // 0 top for short addressing, 0 bottom for read
    SPI.transfer(address<<1 & 0b01111110);
    byte ret = SPI.transfer(0x00);
    digitalWrite(_pin_cs, HIGH);
    return ret;
}

byte Mrf24j::read_long(uint16_t address) {
    digitalWrite(_pin_cs, LOW);
    byte ahigh = address >> 3;
    byte alow = address << 5;
    SPI.transfer(0x80 | ahigh);  // high bit for long
    SPI.transfer(alow);
    byte ret = SPI.transfer(0);
    digitalWrite(_pin_cs, HIGH);
    return ret;
}


void Mrf24j::write_short(byte address, byte data) {
    digitalWrite(_pin_cs, LOW);
    // 0 for top short address, 1 bottom for write
    SPI.transfer((address<<1 & 0b01111110) | 0x01);
    SPI.transfer(data);
    digitalWrite(_pin_cs, HIGH);
}

void Mrf24j::write_long(uint16_t address, byte data) {
    digitalWrite(_pin_cs, LOW);
    byte ahigh = address >> 3;
    byte alow = address << 5;
    SPI.transfer(0x80 | ahigh);  // high bit for long
    SPI.transfer(alow | 0x10);  // last bit for write
    SPI.transfer(data);
    digitalWrite(_pin_cs, HIGH);
}

uint16_t Mrf24j::get_pan(void) {
    byte panh = read_short(MRF_PANIDH);
    return panh << 8 | read_short(MRF_PANIDL);
}

void Mrf24j::set_pan(uint16_t panid) {
    write_short(MRF_PANIDH, panid >> 8);
    write_short(MRF_PANIDL, panid & 0xff);
}

void Mrf24j::address16_write(uint16_t address16) {
    write_short(MRF_SADRH, address16 >> 8);
    write_short(MRF_SADRL, address16 & 0xff);
}

uint16_t Mrf24j::address16_read(void) {
    byte a16h = read_short(MRF_SADRH);
    return a16h << 8 | read_short(MRF_SADRL);
}

/**
 * Simple send 16, with acks, not much of anything.. assumes src16 and local pan only.
 * @param data
 */
void Mrf24j::send16(uint16_t dest16, char * data) {
    byte len = strlen(data); // get the length of the char* array
    int i = 0;
    write_long(i++, bytes_MHR); // header length
    // +ignoreBytes is because some module seems to ignore 2 bytes after the header?!.
    // default: ignoreBytes = 0;
    write_long(i++, bytes_MHR+ignoreBytes+len);

    // 0 | pan compression | ack | no security | no data pending | data frame[3 bits]
    write_long(i++, 0b01100001); // first byte of Frame Control
    // 16 bit source, 802.15.4 (2003), 16 bit dest,
    write_long(i++, 0b10001000); // second byte of frame control
    write_long(i++, 1);  // sequence number 1

    word panid = get_pan();

    write_long(i++, panid & 0xff);  // dest panid
    write_long(i++, panid >> 8);
    write_long(i++, dest16 & 0xff);  // dest16 low
    write_long(i++, dest16 >> 8); // dest16 high

    word src16 = address16_read();
    write_long(i++, src16 & 0xff); // src16 low
    write_long(i++, src16 >> 8); // src16 high

    // All testing seems to indicate that the next two bytes are ignored.
    //2 bytes on FCS appended by TXMAC
    i+=ignoreBytes;
    for (int q = 0; q < len; q++) {
        write_long(i++, data[q]);
    }
    // ack on, and go!
    write_short(MRF_TXNCON, (1<<MRF_TXNACKREQ | 1<<MRF_TXNTRIG));
}

void Mrf24j::set_interrupts(void) {
    // interrupts for rx and tx normal complete
    write_short(MRF_INTCON, 0b11110110);
}

/** use the 802.15.4 channel numbers..
 */
void Mrf24j::set_channel(byte channel) {
    write_long(MRF_RFCON0, (((channel - 11) << 4) | 0x03));
}

void Mrf24j::init(void) {
    /*
    // Seems a bit ridiculous when I use reset pin anyway
    write_short(MRF_SOFTRST, 0x7); // from manual
    while (read_short(MRF_SOFTRST) & 0x7 != 0) {
        ; // wait for soft reset to finish
    }
    */
    write_short(MRF_PACON2, 0x98); // – Initialize FIFOEN = 1 and TXONTS = 0x6.
    write_short(MRF_TXSTBL, 0x95); // – Initialize RFSTBL = 0x9.

    write_long(MRF_RFCON0, 0x03); // – Initialize RFOPT = 0x03.
    write_long(MRF_RFCON1, 0x01); // – Initialize VCOOPT = 0x02.
    write_long(MRF_RFCON2, 0x80); // – Enable PLL (PLLEN = 1).
    write_long(MRF_RFCON6, 0x90); // – Initialize TXFIL = 1 and 20MRECVR = 1.
    write_long(MRF_RFCON7, 0x80); // – Initialize SLPCLKSEL = 0x2 (100 kHz Internal oscillator).
    write_long(MRF_RFCON8, 0x10); // – Initialize RFVCO = 1.
    write_long(MRF_SLPCON1, 0x21); // – Initialize CLKOUTEN = 1 and SLPCLKDIV = 0x01.

    //  Configuration for nonbeacon-enabled devices (see Section 3.8 “Beacon-Enabled and
    //  Nonbeacon-Enabled Networks”):
    write_short(MRF_BBREG2, 0x80); // Set CCA mode to ED
    write_short(MRF_CCAEDTH, 0x60); // – Set CCA ED threshold.
    write_short(MRF_BBREG6, 0x40); // – Set appended RSSI value to RXFIFO.
    set_interrupts();
    set_channel(12);
    set_promiscuous(false); // - for a normal reception mode.
    // max power is by default.. just leave it...
    // Set transmitter power - See “REGISTER 2-62: RF CONTROL 3 REGISTER (ADDRESS: 0x203)”.
    write_short(MRF_RFCTL, 0x04); //  – Reset RF state machine.
    write_short(MRF_RFCTL, 0x00); // part 2
    // The filter is set to zero, so it accepts all type of frames
    write_short(MRF_RXFLUSH, 0x01);
    delay(1); // delay at least 192usec
}

/**
 * Call this from within an interrupt handler connected to the MRFs output
 * interrupt pin.  It handles reading in any data from the module, and letting it
 * continue working.
 * Only the most recent data is ever kept.
 */
void Mrf24j::interrupt_handler(void) {
    uint8_t last_interrupt = read_short(MRF_INTSTAT);
    if (last_interrupt & MRF_I_RXIF) {
        flag_got_rx++;
        // read out the packet data...
        noInterrupts(); //depende del micro que utilicemos
        rx_disable();
        // read start of rxfifo for, has 2 bytes more added by FCS. frame_length = m + n + 2
        uint8_t frame_length = read_long(0x300);
        // Now it is ok. The rx.datalength() was called before changing the frame length
        rx_info.frame_length = frame_length;

        // now we get the source address. If we need to send a message back, we are able now
        uint8_t origin = read_long(0x309);
        rx_info.origin = (origin << 8) | read_long(0x308);

        // buffer all bytes in PHY Payload
        if(bufPHY){
            int rb_ptr = 0;
            for (int i = 0; i < frame_length; i++) { // from 0x301 to (0x301 + frame_length -1)
                rx_buf[rb_ptr++] = read_long(0x301 + i);
            }
        }

        // buffer data bytes
        int rd_ptr = 0;
        // from (0x301 + bytes_MHR) to (0x301 + frame_length - bytes_nodata - 1)
        for (int i = 0; i < rx_datalength(); i++) {
            rx_info.rx_data[rd_ptr++] = read_long(0x301 + bytes_MHR + i);
        }

        // same as datasheet 0x301 + (m + n + 2) <-- frame_length
        rx_info.lqi = read_long(0x301 + frame_length);
        // same as datasheet 0x301 + (m + n + 3) <-- frame_length + 1
        rx_info.rssi = read_long(0x301 + frame_length + 1);

        rx_enable();
        interrupts();
    }
    if (last_interrupt & MRF_I_TXNIF) {
        flag_got_tx++;
        uint8_t tmp = read_short(MRF_TXSTAT);
        // 1 means it failed, we want 1 to mean it worked.
        tx_info.tx_ok = !(tmp & ~(1 << TXNSTAT));
        tx_info.retries = tmp >> 6;
        tx_info.channel_busy = (tmp & (1 << CCAFAIL));
    }
}


/**
 * Call this function periodically, it will invoke your nominated handlers
 */
void Mrf24j::check_flags(void (*rx_handler)(void), void (*tx_handler)(void)){
    // TODO - we could check whether the flags are > 1 here, indicating data was lost?
    if (flag_got_rx) {
        flag_got_rx = 0;
        rx_handler();
    }
    if (flag_got_tx) {
        flag_got_tx = 0;
        tx_handler();
    }
}

/**
 * Set RX mode to promiscuous, or normal
 */
void Mrf24j::set_promiscuous(boolean enabled) {
    if (enabled) {
        write_short(MRF_RXMCR, mask_short(MRF_RXMCR, 0x01, 0x01)); //promiscuous
    } else {
        write_short(MRF_RXMCR, mask_short(MRF_RXMCR, 0x01, 0x00)); //normal
    }
}

rx_info_t * Mrf24j::get_rxinfo(void) {
    return &rx_info;
}

tx_info_t * Mrf24j::get_txinfo(void) {
    return &tx_info;
}

uint8_t * Mrf24j::get_rxbuf(void) {
    return rx_buf;
}

int Mrf24j::rx_datalength(void) {
    return rx_info.frame_length - bytes_nodata;
}

void Mrf24j::set_ignoreBytes(int ib) {
    // some modules behaviour
    ignoreBytes = ib;
}

/**
 * Set bufPHY flag to buffer all bytes in PHY Payload, or not
 */
void Mrf24j::set_bufferPHY(boolean bp) {
    bufPHY = bp;
}

boolean Mrf24j::get_bufferPHY(void) {
    return bufPHY;
}

/**
 * Set PA/LNA external control
 */
void Mrf24j::set_palna(boolean enabled) {
    if (enabled) {
        write_long(MRF_TESTMODE, 0x07); // Enable PA/LNA on MRF24J40MB module.
    }else{
        write_long(MRF_TESTMODE, 0x00); // Disable PA/LNA on MRF24J40MB module.
    }
}

void Mrf24j::rx_flush(void) {
    write_short(MRF_RXFLUSH, 0x01);
}

void Mrf24j::rx_disable(void) {
    write_short(MRF_BBREG1, 0x04);  // RXDECINV - disable receiver
}

void Mrf24j::rx_enable(void) {
    write_short(MRF_BBREG1, 0x00);  // RXDECINV - enable receiver
}

//Useful function
uint8_t Mrf24j::mask_short(uint8_t reg, uint8_t mask, uint8_t change){
    uint8_t receive =  read_short(reg);
    uint8_t temp = receive & ~(mask);
    return temp | change;
}

//Useful function
uint16_t Mrf24j::mask_long(uint16_t reg, uint16_t mask, uint8_t change){
    uint16_t receive =  read_long(reg);
    uint8_t temp = receive & ~(mask);
    return temp | change;
}

//MAC layer
void Mrf24j::set_cca(uint8_t method){
    switch(method){
        case 1: //Energy above threshold
            write_short(MRF_BBREG2, mask_short(MRF_BBREG2, 0xC0, 0x80));
            write_short(MRF_CCAEDTH, mask_short(MRF_CCAEDTH, 0xFF, 0x96));  //the threshold is according to RSSI value and in ZigBee the standard says 40dB
            break;
        case 2: //Carrier sense only (CS)
            write_short(MRF_BBREG2, mask_short(MRF_BBREG2, 0xC0, 0x40));   //PREGUNTAR POR EL CS
            break;
        case 3: //Carrier sense and energy
            write_short(MRF_BBREG2, mask_short(MRF_BBREG2, 0xC0, 0xC0));   //PREGUNTAR POR EL CS
            write_short(MRF_CCAEDTH, mask_short(MRF_CCAEDTH, 0xFF, 0x96));
            break;
        default:
            write_short(MRF_BBREG2, mask_short(MRF_BBREG2, 0xC0, 0x80));
            write_short(MRF_CCAEDTH, mask_short(MRF_CCAEDTH, 0xFF, 0x96));
            break;
    }
}

//MAC layer
uint8_t Mrf24j::lqi(void){
    write_short(MRF_BBREG6,0x80);
    while((MRF_BBREG6 & 0x01) != 0x01);
    return MRF_RSSI; //measures the link quality by the energy detection
}

//MAC layer
void Mrf24j::BeaconInitCoo(void){
    //preguntar
}

//MAC layer
void Mrf24j::BeaconInit(void){

}

//MAC layer
void Mrf24j::NoBeaconInitCoo(void){
    write_short(MRF_RXMCR, mask_short(MRF_RXMCR, 0x08, 0x08));
    write_short(MRF_TXMCR, mask_short(MRF_TXMCR, 0x02, 0x00));
    write_short(MRF_ORDER, 0xFF);
}

//NTW layer
bool Mrf24j::check_coo(void){
    bool check = false;
    byte temp = read_short(MRF_RXMCR);
    if (temp & 0x08)
    check = true;
    return check;
}

//MAC layer
void Mrf24j::NoBeaconInit(void){
    write_short(MRF_RXMCR, mask_short(MRF_RXMCR, 0x08, 0x00));
    write_short(MRF_TXMCR, mask_short(MRF_TXMCR, 0x02, 0x00));
}

//MAC layer
 void Mrf24j::UnslottedCSMACA(void){        //no beacon
    write_short(MRF_TXMCR, mask_short(MRF_TXMCR, 0x20, 0x00));
    //MACminBE and MACMaxCSMABackoff  are default
    write_short(MRF_TXMCR, mask_short(MRF_TXMCR, 0x18, 0x18));
    write_short(MRF_TXMCR, mask_short(MRF_TXMCR, 0x07, 0x04));
 }

 //MAC layer
 void Mrf24j::SlottedCSMACA(void){          //with beacon
    write_short(MRF_TXMCR, mask_short(MRF_TXMCR, 0x20, 0x20));
    //MACminBE and MACMaxCSMABackoff  are default
    write_short(MRF_TXMCR, mask_short(MRF_TXMCR, 0x18, 0x18));
    write_short(MRF_TXMCR, mask_short(MRF_TXMCR, 0x07, 0x04));
 }

//MAC layer (modified from send16())
void Mrf24j::sendAck(uint16_t dest16, char * data) {
    byte len = strlen(data); // get the length of the char* array
    int i = 0;
    write_long(i++, bytes_MHR); // header length
    // +ignoreBytes is because some module seems to ignore 2 bytes after the header?!.
    // default: ignoreBytes = 0;
    write_long(i++, bytes_MHR+ignoreBytes+len);

    // 0 | pan compression | ack | no security | no data pending | data frame[3 bits]
    write_long(i++, 0b01100001); // first byte of Frame Control
    // 16 bit source, 802.15.4 (2003), 16 bit dest,
    write_long(i++, 0b10001000); // second byte of frame control
    write_long(i++, 1);  // sequence number 1

    word panid = get_pan();

    write_long(i++, panid & 0xff);  // dest panid
    write_long(i++, panid >> 8);
    write_long(i++, dest16 & 0xff);  // dest16 low
    write_long(i++, dest16 >> 8); // dest16 high

    word src16 = address16_read();
    write_long(i++, src16 & 0xff); // src16 low
    write_long(i++, src16 >> 8); // src16 high

    // All testing seems to indicate that the next two  bytes are ignored.
    //2 bytes on FCS appended by TXMAC
    i+=ignoreBytes;
    for (int q = 0; q < len; q++) {
        write_long(i++, data[q]);
    }
    // ack on, and go!
    write_short(MRF_TXNCON, (1<<MRF_TXNACKREQ | 1<<MRF_TXNTRIG));
    // the amount of waiting time for the ack can be programmed by the 
    // MAWD (ACKTMOUT 0x12<6:0>) bits.
    // the recipient via hardware will respond after "aTurnaroundTime" (12) symbols,
    // it can be programmed by the TURNTIME (TXTIME 0x27<7:4>) and RFSTBL 
    // (TXSTBL 0x2E<7:4>) bits where "aTurnaroundTime" = TURNTIME + RFSTBL
}

//MAC layer (modified from send16())
void Mrf24j::sendNoAck(uint16_t dest16, char * data) {
    byte len = strlen(data); // get the length of the char* array
    int i = 0;
    write_long(i++, bytes_MHR); // header length
    // +ignoreBytes is because some module seems to ignore 2 bytes after the header?!.
    // default: ignoreBytes = 0;
    write_long(i++, bytes_MHR+ignoreBytes+len);

    // 0 | pan compression | no ack | no security | no data pending | data frame[3 bits]
    write_long(i++, 0b01000001); // first byte of Frame Control
    // 16 bit source, 802.15.4 (2003), 16 bit dest,
    write_long(i++, 0b10001000); // second byte of frame control
    write_long(i++, 1);  // sequence number 1

    word panid = get_pan();

    write_long(i++, panid & 0xff);  // dest panid
    write_long(i++, panid >> 8);
    write_long(i++, dest16 & 0xff);  // dest16 low
    write_long(i++, dest16 >> 8); // dest16 high

    word src16 = address16_read();
    write_long(i++, src16 & 0xff); // src16 low
    write_long(i++, src16 >> 8); // src16 high

    // All testing seems to indicate that the next two  bytes are ignored.
    //2 bytes on FCS appended by TXMAC
    i+=ignoreBytes;
    for (int q = 0; q < len; q++) {
        write_long(i++, data[q]);
    }
    // no ack on, and go!
    write_short(MRF_TXNCON, (0<<MRF_TXNACKREQ | 1<<MRF_TXNTRIG));
}

//MAC layer (modified from send16())
void Mrf24j::broadcast(char * data, uint16_t address){
    byte len = strlen(data); // get the length of the char* array
    int i = 0;
    write_long(i++, bytes_MHR); // header length
    // +ignoreBytes is because some module seems to ignore 2 bytes after the header?!.
    // default: ignoreBytes = 0;
    write_long(i++, bytes_MHR+ignoreBytes+len);

    // 0 | pan compression | ack | no security | no data pending | data frame[3 bits]
    write_long(i++, 0b01100001); // first byte of Frame Control
    // 16 bit source, 802.15.4 (2003), 16 bit dest,
    write_long(i++, 0b10001000); // second byte of frame control
    write_long(i++, 1);  // sequence number 1

    write_long(i++, BROADCAST);  // dest panid high
    write_long(i++, BROADCAST);  // dest panid low
    write_long(i++, BROADCAST);  // dest16 low
    write_long(i++, BROADCAST); // dest16 high

    word src16 = address16_read();
    write_long(i++, src16 & 0xff); // src16 low
    write_long(i++, src16 >> 8); // src16 high

    // All testing seems to indicate that the next two  bytes are ignored.
    //2 bytes on FCS appended by TXMAC
    i+=ignoreBytes;
    for (int q = 0; q < len; q++) {
        write_long(i++, data[q]);
    }
    // ack on, and go!
    write_short(MRF_TXNCON, (1<<MRF_TXNACKREQ | 1<<MRF_TXNTRIG));
}

//MAC layer association response
void Mrf24j::association_set(uint16_t panid, uint16_t address){
    set_pan(panid);
    address16_write(address);
}

//NTW layer association request
bool Mrf24j::association_request(void){  //it needs to have the interruption handler created in MCU
    char join[] = "JOIN";
    bool joined = false;
    bool heard = false;
    int timeout = 0;
    byte channel = 11;
    tx_info.tx_ok = 0;
    int i = 0;

    while(!joined){

        timeout++;
        if(timeout>MACResponseWaitTime){
            break;
        }
        
        if (!heard){
            if (tx_info.tx_ok){
                flag_got_tx = 0;
                //address16_write(0x0000);
                heard = true;
            } else {
                if(i>1000){
                    //channel sweep
                    channel++;
                    if(channel==27)
                    channel = 11;
                    //set_channel(channel); 
                    broadcast(join);
                    i = 0;
                }
                i++;
            }
        }

        if (rx_datalength()>0) { //if the ack was received then wait and read   
            // 1: PAN HIGH - 2: PAN LOW - 3: ADDRESS UP - 4: ADDRESS LOW 
            if (rx_datalength() > 3) {
                uint16_t panid = rx_info.rx_data[0];
                panid = ((panid << 8)|rx_info.rx_data[1]);
                uint16_t address = rx_info.rx_data[2];
                address = ((address << 8)|rx_info.rx_data[3]);
                association_set(panid, address);
                joined = true;
                break;
            }
        }        
    }
    if(!joined){
        //Serial.println("ocurrió un break");
    } else {
        //Serial.println("lo recibió");
        char add[] = "OK";
        sendAck(rx_info.origin,add);
    }
    return joined;
}

// Useful function
pool_t * Mrf24j::get_pool(void) {
    return &pool;
}

//NTW layer association response
bool Mrf24j::association_response(void){
    bool response = false;
    char buffer[4];
    uint16_t panid = get_pan();
    uint16_t address = 0;
    int i;
    for (i = 0; i<pool.size; i++){
        if(pool.availability[i]==0){
            address = pool.address[i];
            Serial.print("dirección por asignar: "); Serial.println(address);
            break;
        }
    }
    
    buffer[0] = (panid >> 8 & 0x00FF);
    buffer[1] = (panid >> 0 & 0x00FF);
    buffer[2] = (address >> 8 & 0x00FF);
    buffer[3] = (address >> 0 & 0x00FF);
    
    broadcast(buffer, rx_info.origin);
    int timeout = 0;
    while(!response){
        timeout++;
        if(timeout>MACJoinedWaitTime){
            break;
        }
        
        if(rx_datalength() > 1){
            if(rx_info.rx_data[0] == 'O' &&
               rx_info.rx_data[1] == 'K'){

                Serial.println("se unio uno nuevo");
                response = true;
                pool.availability[i] = 1;
                break;
            }
        } else {
            //broadcast(buffer, NewMember);
        }
    }
    if(!response)
    Serial.println("no se unio nadie...");
    return response;
}
