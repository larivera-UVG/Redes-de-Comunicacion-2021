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

// word send to know when to start the timer
const char timerGo[] = "timerGo";

// word send to start the association service
const char join[] = "JOIN";

// word send to notice everyone that the coordinator is here
const char beat[] = "BEAT";

// word send to request a coordinator election service
const char newCooR[] = "NEWCOOR";

// word send to request the vote
const char vote[] = "VOTE";

// word send to let know the PAN a new coordinator is set
const char newMe[] = "NEWME";

// word send for updating the PAN information
const char updateinfo[] = "UPDATE";

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
    PANID = panid;
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
    write_short(MRF_PACON2, 0x98); // ??? Initialize FIFOEN = 1 and TXONTS = 0x6.
    write_short(MRF_TXSTBL, 0x95); // ??? Initialize RFSTBL = 0x9.

    write_long(MRF_RFCON0, 0x03); // ??? Initialize RFOPT = 0x03.
    write_long(MRF_RFCON1, 0x01); // ??? Initialize VCOOPT = 0x02.
    write_long(MRF_RFCON2, 0x80); // ??? Enable PLL (PLLEN = 1).
    write_long(MRF_RFCON6, 0x90); // ??? Initialize TXFIL = 1 and 20MRECVR = 1.
    write_long(MRF_RFCON7, 0x80); // ??? Initialize SLPCLKSEL = 0x2 (100 kHz Internal oscillator).
    write_long(MRF_RFCON8, 0x10); // ??? Initialize RFVCO = 1.
    write_long(MRF_SLPCON1, 0x21); // ??? Initialize CLKOUTEN = 1 and SLPCLKDIV = 0x01.

    //  Configuration for nonbeacon-enabled devices (see Section 3.8 ???Beacon-Enabled and
    //  Nonbeacon-Enabled Networks???):
    write_short(MRF_BBREG2, 0x80); // Set CCA mode to ED
    write_short(MRF_CCAEDTH, 0x60); // ??? Set CCA ED threshold.
    write_short(MRF_BBREG6, 0x40); // ??? Set appended RSSI value to RXFIFO.
    set_interrupts(); // Set the interruption of the rx and tx
    set_channel(25); // Selects the channel 
    set_promiscuous(false); // - for a normal reception mode.
    // max power is by default.. just leave it...
    // Set transmitter power - See ???REGISTER 2-62: RF CONTROL 3 REGISTER (ADDRESS: 0x203)???.
    write_short(MRF_RFCTL, 0x04); //  ??? Reset RF state machine.
    write_short(MRF_RFCTL, 0x00); // part 2
    // The filter is set to zero, so it accepts all type of frames
    write_short(MRF_RXFLUSH, 0x01);
    // Set the TX stabilization period. Recommended 0x95
    write_short(MRF_TXSTBL,0x95); // aMinSIFSPeriod 
    // Refer to IEEE 802.15.4???-2003 Standard, Section 7.5.1.2 ???IFS??? and Table 70: MAC Sublayer Constants.

    // Create all the timers
    setTimer();
    timer_init();

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

        // we identify the pan from the source. Now we can now if it's a broadcast or from our pan
        uint8_t panid = read_long(0x305);
        rx_info.panid = (panid << 8) | read_long(0x304);

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

//Function for masking a register with a short address
uint8_t Mrf24j::mask_short(uint8_t reg, uint8_t mask, uint8_t change){
    uint8_t receive =  read_short(reg);
    uint8_t temp = receive & ~(mask);
    return temp | change;
}

//Function for masking a register with a long address
uint16_t Mrf24j::mask_long(uint16_t reg, uint16_t mask, uint8_t change){
    uint16_t receive =  read_long(reg);
    uint8_t temp = receive & ~(mask);
    return temp | change;
}

//MAC layer. Set the clear channel assessment settings to check if the channel is busy or idle.
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
        default: //Energy above threshold
            write_short(MRF_BBREG2, mask_short(MRF_BBREG2, 0xC0, 0x80));
            write_short(MRF_CCAEDTH, mask_short(MRF_CCAEDTH, 0xFF, 0x96));
            break;
    }
}

//MAC layer. reads the energy level in the channel
uint8_t Mrf24j::lqi(void){
    write_short(MRF_BBREG6,0x80);
    return read_long(MRF_RSSI); //measures the link quality by the energy detection
}

//MAC layer. Set the transceptor as a no beacon coordinantor
void Mrf24j::NoBeaconInitCoo(void){
    write_short(MRF_RXMCR, mask_short(MRF_RXMCR, 0x08, 0x08));
    write_short(MRF_TXMCR, mask_short(MRF_TXMCR, 0x02, 0x00));
    write_short(MRF_ORDER, 0xFF);
    am_I_the_coordinator = true;
}

//NTW layer. Check if the current transceptor is a coordinator. 1-coordinator 0-no coordinator.
bool Mrf24j::check_coo(void){
    bool check = false;
    byte temp = read_short(MRF_RXMCR);
    if (temp & 0x08)
    check = true;
    return check;
}

//MAC layer. Set the transceptor as a no beacon node.
void Mrf24j::NoBeaconInit(void){
    write_short(MRF_RXMCR, mask_short(MRF_RXMCR, 0x08, 0x00));
    write_short(MRF_TXMCR, mask_short(MRF_TXMCR, 0x02, 0x00));
}

//MAC layer. Set the Unslotted CSMA-CA algorithm in the transceptor. For more info check datasheet section 3.9
void Mrf24j::UnslottedCSMACA(void){        //no beacon
    write_short(MRF_TXMCR, mask_short(MRF_TXMCR, 0x20, 0x00));
    //MACminBE and MACMaxCSMABackoff  are default
    write_short(MRF_TXMCR, mask_short(MRF_TXMCR, 0x18, 0x18));
    write_short(MRF_TXMCR, mask_short(MRF_TXMCR, 0x07, 0x04));
}

 //MAC layer. Set the Slotted CSMA-CA algorithm in the transceptor. For more info check datasheet section 3.9
void Mrf24j::SlottedCSMACA(void){          //with beacon
    write_short(MRF_TXMCR, mask_short(MRF_TXMCR, 0x20, 0x20));
    //MACminBE and MACMaxCSMABackoff are default. Set to the IEEE 802.15.4 Standard
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
    write_long(i++, address & 0xff);  // dest16 low
    write_long(i++, address >> 8); // dest16 high

    word src16 = address16_read();
    write_long(i++, src16 & 0xff); // src16 low
    write_long(i++, src16 >> 8); // src16 high

    // All testing seems to indicate that the next two  bytes are ignored.
    //2 bytes on FCS appended by TXMAC
    i+=ignoreBytes;
    for (int q = 0; q < len; q++) {
        write_long(i++, data[q]);
    }
    // NO ack on, and go!
    write_short(MRF_TXNCON, (0<<MRF_TXNACKREQ | 1<<MRF_TXNTRIG));
}

//MAC layer association response. Modify de the PAN and ip address
void Mrf24j::association_set(uint16_t panid, uint16_t address){
    set_pan(panid);
    address16_write(address);
}

//NTW layer association request. Request created by the orphan or node without a PAN set.
bool Mrf24j::association_request(void){  //it needs to have the interruption handler created in MCU
    bool joined = false;
    bool heard = false;
    int timeout = 0;
    byte channel = 11; // starts checking in the channel 11
    Timer_500ms_request = 5*WAIT_100MS;
    Timer_10ms_general = 1*WAIT_10MS;

    while(!joined){

        // Timer for the service. If the timeout reaches MACResponseWaitTime the service ends
        // and returns a 0.
        if(Timer_500ms_request == 0){ //implementation of the "timer.h" library of software timer
            break;
        }

        // When the request gets a ack as response, the sweep between channels and broadcast stops.
        if (!heard){
            if(rx_datalength()==2 && flag_got_rx){
                flag_got_rx = 0;
                if(rx_info.rx_data[0] == 'O' &&
                rx_info.rx_data[1] == 'K'){
                    // if an ACK is received tx_ok will be 1.
                    heard = true;
                }
            } else {
                // the broadcast is made each cycle of 1000 figures sweeping the channel.
                if(Timer_10ms_general==0){
                    Timer_10ms_general = 10*WAIT_10MS;
                    //channel sweep
                    channel++;
                    if(channel==27)
                    channel = 11;
                    //set_channel(channel); 
                    broadcast(join); // the message for association service is "JOIN"
                }
            }
        }

        if (heard){
            // after the ACK sent by the coordinator, it sends the info of the PAN.
            if(flag_got_rx){
                //Serial.println("recibio algo");
                //for (int i = 0; i < rx_datalength(); i++)
                //Serial.write(rx_info.rx_data[i]);
                //Serial.println(" ");
                flag_got_rx = 0;   
                if (rx_datalength()>3) {   
                // 0: PAN HIGH - 1: PAN LOW - 2: ADDRESS UP - 3: ADDRESS LOW 
                    uint16_t panid = rx_info.rx_data[0]; //pan high
                    panid = ((panid << 8)|rx_info.rx_data[1]); //pan low
                    uint16_t address = rx_info.rx_data[2]; //address up
                    address = ((address << 8)|rx_info.rx_data[3]); //address low
                    association_set(panid, address);
                    coord = rx_info.origin; // the coordinantor is the only capable to make the associaton response service
                    joined = true;
                    break;
                }
            }
        }        
    }
    if(joined){
        // if the node successfully joined the PAN. it sends an OK to the coordinator to let it know everything is ok.
        char add[] = "OK";
        sendAck(coord,add);
    }
    Timer_5000ms_heartbeat = 50*WAIT_100MS; // reset the new coordinator timer
    return joined;
}

// Function to call the struct that contain the addresses
pool_t * Mrf24j::get_pool(void) {
    return &pool;
}

// APP layer service for the coordinator when someone tries to associate
// Use by the coordinator
bool Mrf24j::association(void){
    bool member = false;
    //bool coordinator = check_coo();
    if(am_I_the_coordinator){
        // reads the command "JOIN" to starts the association service
        if(rx_datalength() == 4){
            if(rx_info.rx_data[0] == 'J' &&
            rx_info.rx_data[1] == 'O' &&
            rx_info.rx_data[2] == 'I' &&
            rx_info.rx_data[3] == 'N'){
                char add[] = "OK";
                broadcast(add,rx_info.origin);
                Timer_10ms_general = 10*WAIT_10MS;
                while(Timer_10ms_general>0){
                } // waiting timer for sending the message
                member = association_response();
            }
        }
    }
    return(member);
}

//NTW layer association response
bool Mrf24j::association_response(void){
    bool response = false;
    char buffer[4];
    uint16_t panid = PANID; //gets the pan id
    uint16_t address = 0;
    int i, j;
    // calls the pool and extract the address of an unassign address
    // the available addresses are set to 0 in pool.availability
    for (i = 0; i<pool.size; i++){
        if(pool.availability[i]==0){
            address = pool.address[i];
            break;
        }
    }
    
    //Serial.print("direcci??n por asignar: "); Serial.println(address);
    buffer[0] = (panid >> 8 & 0x00FF); // pan id high
    buffer[1] = (panid >> 0 & 0x00FF); // pan id low
    buffer[2] = (address >> 8 & 0x00FF); // address high
    buffer[3] = (address >> 0 & 0x00FF); // address low

    broadcast_byte(buffer, 4, rx_info.origin); // sends the info to the node
    Timer_100ms_response = 1*WAIT_100MS;
    while(!response){
        volatile uint8_t length = rx_datalength();
        // the coordinator expects an "OK" to confirm the info received.
        if(length==2 && flag_got_rx){
            flag_got_rx = 0; // clean the flag of rx
            volatile char palabra[] = {rx_info.rx_data[0],rx_info.rx_data[1]};
            if(palabra[0]== 'O' &&
               palabra[1]== 'K'){
                Serial.println("se unio uno nuevo");
                response = true;
                pool.availability[i] = 1; // sets occupy the selected address
            }
        }

        // if the time out occur the service fail.
        if(Timer_100ms_response==0){
            //Serial.println("se acabo el tiempo");
            break;
        } 
    }
    return response;
}


//APP layer convert the chart array to a float variable. MAX 4 digits after decimal point
float Mrf24j::readF(void){ //read the value as a float
    return atof(rx_info.rx_data);
}

//APP layer send a float number with a maximum of 4 digits after the decimal point
void Mrf24j::sendF(uint16_t address, float value, bool ack){
    char sz[116] = {' '} ;
    int val_int, val_fra;
    float temp = value;
    val_int = (int) temp;   // compute the integer part of the float
    float val_float = (temp - val_int);
    val_fra = ((int)(val_float*N_DECIMAL_POINTS_PRECISION)%N_DECIMAL_POINTS_PRECISION); //compute the fraction
    snprintf(sz, 116, "%d.%d", val_int, val_fra); // convert the float number into char array
    if(ack)
    sendAck(address, sz);
    else
    sendNoAck(address,sz);
    return;
}

// APP layer algorithm to check if the message came from the coordinator
// Here we put all  the commads that the coordinator can send
bool Mrf24j::readCoo(void){
    bool received = false;

    if(rx_info.origin == coord){
        // reset the timer of the coordinator election service
        Timer_5000ms_heartbeat = 50*WAIT_100MS;

        // command for sync the messages in the PAN
        if(rx_info.rx_data[0] == 't' &&
        rx_info.rx_data[1] == 'i' &&
        rx_info.rx_data[2] == 'm' &&
        rx_info.rx_data[3] == 'e' &&
        rx_info.rx_data[4] == 'r' &&
        rx_info.rx_data[5] == 'G' &&
        rx_info.rx_data[6] == 'o'){
            _timerGo = true; // activate the sync 
            _timer = 0; // set the timer
            received = true;
            Timer_sync = (address16_read())*10*WAIT_10MS;
        }
        
        // command to update PAN info
        if(rx_info.rx_data[0] == 'U' &&
        rx_info.rx_data[1] == 'P' &&
        rx_info.rx_data[2] == 'D' &&
        rx_info.rx_data[3] == 'A' &&
        rx_info.rx_data[4] == 'T' &&
        rx_info.rx_data[5] == 'E'){
            updateInfo();
            Serial.println("actualizado");
        }
    }

    return(received);
}

// APP layer for the COORDINATOR ONLY starts the sync timer for the PAN
bool Mrf24j::sync(void){
    int timeout = 0;
    bool done = false; 
    if(am_I_the_coordinator){
        sendNoAck(BROADCAST,timerGo);
        done = true;
    }

    return(done);
}

// APP layer constantly updating the counter for sending a message.
// must be in main loop to function correctly
bool Mrf24j::syncSending(uint16_t dest, char * message){
    bool done = false;
    if(_timerGo && Timer_sync == 0){ // if sync is activated
        _timerGo = false; // deactivate the sync
        done = true;
        sendAck(dest, message);
        Timer_sync = (address16_read())*WAIT_10MS;
    }

    return(done);
}

// APP layer fo the coordinator
// have the service synchronized with the number of nodes
void Mrf24j::synchronizedNodes(void){
    int last = 0;
    if(Timer_sync != 0)
    return;
    for(int i = 0; i < pool.size; i++){
        if(pool.availability[i] == 1)
        last += 1;
    }
    if(last != 0)
    sync();
    Timer_sync = (last)*50*WAIT_10MS;
    return;
}

// APP layer for the coordinador
// checks if the members are still in the network
byte Mrf24j::still(void){
    bool answer = false;
    bool send = true;
    byte change = 0;
    char there[] = "still?";
    bool coordinator = check_coo();
    uint16_t coord = address16_read();
    if(coordinator){ // check if it's the coordinator

        for(int i = 0; i < pool.size; i++){
            // Serial.println(i);
            if(pool.availability[i] && pool.address[i] != coord){
                answer = false; //restart the algorithm
                send = true;
                Timer_200ms_still = 2*WAIT_100MS;
                while(!answer){

                    // if the time out occur the node didn't answer and is remove from the PAN.
                    if(Timer_200ms_still==0){
                        break;
                    }

                    // sends the message to every occupy address
                    if(send){
                        //Serial.println(pool.address[i]);
                        sendAck(pool.address[i],there);
                        send = false;
                    }
                    
                    // if the message wasn't receive after the wait time in MAC, send it again.
                    // the ack recieve
                    if(flag_got_tx){
                        flag_got_tx = 0;
                        if(!tx_info.tx_ok){
                            //Serial.println("send");
                            send = true; // send the message again
                        } else {
                            //Serial.println("answer");
                            answer = true; // great! the node still is connected
                            break;
                        }
                    }
                }

                //Serial.println("se sali??");
                // if it answers, the for loop continues, but no answer means remove
                if(!answer){
                    pool.availability[i] = 0; // 0 means free to assign
                    change++; // counter for the nodes that disappeared
                } 
            }
        }

        for(int i = 0; i < pool.size; i++){
            if(coord == pool.address[i]){
                pool.availability[i] = 1;
                break;
            }
        }
    }
    update();
    return(change);
}

// NTW layer
// method ONLY for the coordinator. sends the update PAN information to everyone
void Mrf24j::update(void){
    char mensaje[16] = "";
    strcat(mensaje,updateinfo);
    int i, j;

    for (i = 6, j = 0; i<6 + pool.size; i++, j++){
        if (pool.availability[j] == 1)
        mensaje[i] = 0xAA; // for a reason i can't have a 0 before a 1 or "empty" before something
        else if (pool.availability[j] == 0)
        mensaje[i] = 0xBB;
    }

    sendNoAck(BROADCAST,mensaje);
}

// NTW layer
// update the information
void Mrf24j::updateInfo(void){
    int i, j;
    uint16_t my_address = address16_read();
    for(i=6,j=0; i<16; i++,j++){
        if (rx_info.rx_data[i] == 0xAA)
        pool.availability[j] = 1;
        else if (rx_info.rx_data[i] == 0xBB)
        pool.availability[j] = 0;
        if (pool.address[j] == my_address && pool.availability[j] == 0) // aparentemente no estoy en la red
        association_request();
        Serial.println(pool.availability[j]);

    }
}

// APP layer ONLY for the coordinator
// It's use to call the still service in a "seconds" period
void Mrf24j::cooCheck(uint8_t seconds){
    if(Timer_connected==0){
        still();
        Timer_connected = seconds*10*WAIT_100MS;
    }
}

// APP creates the handlers of the software timers. It needs only 1 timer of the MCU
void Mrf24j::setTimer(void){ // current 1 timers of 10ms in use and 6 timer of 100ms in use
    timer_register_100ms(&Timer_500ms_request);
    timer_register_100ms(&Timer_100ms_response);
    timer_register_100ms(&Timer_200ms_still);
    timer_register_10ms(&Timer_10ms_general);
    timer_register_10ms(&Timer_2500ms_beat);
    timer_register_100ms(&Timer_5000ms_heartbeat);
    timer_register_100ms(&Timer_5000ms_acceptNew);
    timer_register_100ms(&Timer_connected);
    timer_register_10ms(&Timer_sync);
    timer_register_100ms(&Timer_10000ms_lqi);
}


// APP layer ONLY for the coordinator
// It's use to constantly report the PAN that the coordinador still is working fine.
void Mrf24j::cooBeat(void){
    if(Timer_2500ms_beat==0){
        sendNoAck(BROADCAST,"BEAT");
        Timer_2500ms_beat = 250*WAIT_100MS;
    }
}

/*
 * Coordinator election service
 * This service is base in 'Raft' a consensus algorithm alternative.
 * Each function has a role that is implemented in the last function.
 */

// APP layer for all the nodes
// Each node expects a heartbeat from the coordinator
bool Mrf24j::heartbeat(void){
    // the time was reached and the coordinador didn't send his beat and no one has
    // sent the request
    if(Timer_5000ms_heartbeat == 0 && !newCooRequest && !previousCooRequest){
        sendNoAck(BROADCAST,newCooR);
        Timer_5000ms_acceptNew = 50*WAIT_100MS;
        newCooRequest = true;
        IamCoo = true;
        quorum = 1;
        tries += 1;
        Serial.print("intentos "); Serial.println(tries);
    }

    // the time was reached and a previous request was made. So the node send its approval
    // of the request.
    if(Timer_5000ms_heartbeat == 0 && previousCooRequest && !newCooRequest){
        newCooRequest = true;
        Timer_5000ms_acceptNew = 50*WAIT_100MS; // the time the service has to complete the election.
        Serial.println("voy a votar");
        Timer_sync = (address16_read())*10*WAIT_10MS;
        while(Timer_sync > 0){};
        sendAck(newcoord,vote);
    }

    // The request was denied because quorum wasn't reached or
    // the request didn't follow through so the service is reset
    if(Timer_5000ms_acceptNew == 0 && newCooRequest){
        newCooRequest = false;
        previousCooRequest = false;
        IamCoo = false;
        Timer_5000ms_heartbeat = 50*WAIT_100MS;
        quorum = 0;
    }

    return IamCoo;
}

// APP layer for all the nodes
// call this function to check if a request for new coordinator was received.
// must be implemented when the rx flag is high.
bool Mrf24j::electionCoo(void){
    volatile bool request_made = false;

    if(!am_I_the_coordinator){
        if(previousCooRequest && (Timer_5000ms_heartbeat==0)){
            if(rx_info.rx_data[0] == 'N' &&
                rx_info.rx_data[1] == 'E' &&
                rx_info.rx_data[2] == 'W' &&
                rx_info.rx_data[3] == 'M' &&
                rx_info.rx_data[4] == 'E'){
                    coord = newcoord;
                    newCooRequest = false;
                    request_made = false;
                    previousCooRequest = false;
                    IamCoo = false;
                    Timer_5000ms_heartbeat = 50*WAIT_100MS;
                    quorum = 0;
                    //Serial.print("coordinador "); Serial.println(coord);
                }
        }

        if(rx_datalength() == 7){
            if(rx_info.rx_data[0] == 'N' &&
                rx_info.rx_data[1] == 'E' &&
                rx_info.rx_data[2] == 'W' &&
                rx_info.rx_data[3] == 'C' &&
                rx_info.rx_data[4] == 'O' &&
                rx_info.rx_data[5] == 'O' &&
                rx_info.rx_data[6] == 'R'){
                    previousCooRequest = true;
                    request_made = true;
                    newcoord = rx_info.origin;
                }
        }

        // APP layer for all the nodes
        // when the node that started the service receives an approval.
        if(rx_datalength() == 4 && IamCoo){
            if(rx_info.rx_data[0] == 'V' &&
                rx_info.rx_data[1] == 'O' &&
                rx_info.rx_data[2] == 'T' &&
                rx_info.rx_data[3] == 'E'){
                    quorum++;
            }
        }
    }


    return request_made;
}


// APP layer for all the nodes
// when the node that started the service checks if quorum was reach.
bool Mrf24j::votation(void){
    // if the amount of votes aren't enough to reach quorum
    pool.QUORUM = 0;
    for(int i = 0; i<pool.size; i++){
        pool.QUORUM += pool.availability[i];
    }
    pool.QUORUM -= 1;

    if((quorum < pool.QUORUM))
    return false;
    else{
        coord = address16_read();
        NoBeaconInitCoo();
        uint16_t address = address16_read();
        tries = 0;

        for(int i = 0; i < pool.size; i++){
                if(pool.availability[i]&&(pool.address[i])!=address){
                    //Serial.print("direcci??n "); Serial.println(pool.address[i]);
                    bool answer = false; //restart the algorithm
                    bool send = true;
                    Timer_200ms_still = 2*WAIT_100MS;
                    while(!answer){

                        // if the time out occurs the node didn't answer and is remove from the PAN.
                        if(Timer_200ms_still==0){
                            break;
                        }

                        // sends the message to every occupy address
                        if(send){
                            sendAck(pool.address[i],newMe);
                            send = false;
                        }
                        
                        // if the message wasn't receive after the wait time in MAC, send it again.
                        // the ack recieve
                        if(flag_got_tx){
                            flag_got_tx = 0;
                            if(!tx_info.tx_ok){
                                //Serial.println("send");
                                send = true; // send the message again
                            } else {
                                //Serial.println("answer");
                                answer = true; // great! the node still is connected
                                break;
                            }
                        }
                    }
                }
        }

        IamCoo = false; // ends the service
        newCooRequest = false;
        previousCooRequest = false;
        Timer_5000ms_heartbeat = 50*WAIT_100MS;
        quorum = 0;
        am_I_the_coordinator = true;
        return true;
    }
}

// APP layer for all the nodes
// The full service
void Mrf24j::cooElection(void){
    heartbeat();
    if(IamCoo){
        votation();
    }

}


// Check if i started the new coordinator service
bool Mrf24j::check_IamCoo(void){
    return IamCoo;
}

// Loop for the coordinator for an easy implementation of all the services. Call it in the main loop
int Mrf24j::coo_loop(uint8_t seconds, bool synchronize){
    if(!am_I_the_coordinator)
    return 0;

    cooBeat();
    cooCheck(seconds);
    if(synchronize)
    synchronizedNodes();
    return 0;
}

// Loop for the node for an easy implementation of all the services. Call it in the main loop
int Mrf24j::node_loop(){
    if(am_I_the_coordinator)
    return 0;    

    if(tries>3){
        association_request();
        tries = 0;
    }
    // The implementation of the new coordinator service
    heartbeat();
    if(IamCoo)
    votation();

    return 0;
}

bool Mrf24j::channel_occupied(void){
    Timer_10000ms_lqi = 100*WAIT_100MS;
    bool occupy = false;
    while(Timer_10000ms_lqi != 0){
        uint8_t energy = lqi();
        if(energy>0){
            occupy = true;
            break;
        }
    }
    return occupy;
}

// modificado de sendNoAck
void Mrf24j::sendNoAck_byte(uint16_t dest16, uint8_t * data, uint8_t data_size){
    int i = 0;
    write_long(i++, bytes_MHR); // header length
    // +ignoreBytes is because some module seems to ignore 2 bytes after the header?!.
    // default: ignoreBytes = 0;
    write_long(i++, bytes_MHR+ignoreBytes+data_size);

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
    for (int q = 0; q < data_size; q++) {
        write_long(i++, data[q]);
    }
    // no ack on, and go!
    write_short(MRF_TXNCON, (0<<MRF_TXNACKREQ | 1<<MRF_TXNTRIG));
}

//MAC layer (modified from send16())
void Mrf24j::broadcast_byte(char * data, uint8_t data_size, uint16_t address){
    int i = 0;
    write_long(i++, bytes_MHR); // header length
    // +ignoreBytes is because some module seems to ignore 2 bytes after the header?!.
    // default: ignoreBytes = 0;
    write_long(i++, bytes_MHR+ignoreBytes+data_size);

    // 0 | pan compression | ack | no security | no data pending | data frame[3 bits]
    write_long(i++, 0b01100001); // first byte of Frame Control
    // 16 bit source, 802.15.4 (2003), 16 bit dest,
    write_long(i++, 0b10001000); // second byte of frame control
    write_long(i++, 1);  // sequence number 1

    write_long(i++, BROADCAST);  // dest panid high
    write_long(i++, BROADCAST);  // dest panid low
    write_long(i++, address & 0xff);  // dest16 low
    write_long(i++, address >> 8); // dest16 high

    word src16 = address16_read();
    write_long(i++, src16 & 0xff); // src16 low
    write_long(i++, src16 >> 8); // src16 high

    // All testing seems to indicate that the next two  bytes are ignored.
    //2 bytes on FCS appended by TXMAC
    i+=ignoreBytes;
    for (int q = 0; q < data_size; q++) {
        write_long(i++, data[q]);
    }
    // NO ack on, and go!
    write_short(MRF_TXNCON, (0<<MRF_TXNACKREQ | 1<<MRF_TXNTRIG));
}