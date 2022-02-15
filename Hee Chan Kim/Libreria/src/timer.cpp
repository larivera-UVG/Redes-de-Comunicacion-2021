#include <stdlib.h>    /* for NULL */
#include <stdint.h>    /* uint8_t, etc. */
#include <stdbool.h>   /* bool type, true, false */

#include "timer.h"

/** Maximum number of 100ms timers that can be registered. */
#define MAX_100MS_TIMERS 10

/** Maximum number of 10ms timers that can be registered. */
#define MAX_10MS_TIMERS  10

/** The polling frequency for the 10ms timers is scaled by this factor to
    service the 100ms timers. */
#define PRESCALE_100MS   10

/* ------------------------------------------------------------------------ */

/** 10ms timer array.  These are pointers to the actual timers elsewhere in
    the application code. */
static volatile uint8_t *timers_10ms [MAX_10MS_TIMERS];

/** 100ms timer array.  These are pointers to the actual timers elsewhere in
    the application code. */
static volatile uint8_t *timers_100ms [MAX_100MS_TIMERS];

#ifdef ARDUINO_time
volatile unsigned int cuenta = 0;

void timer_init(void){
    SREG = (SREG & 0b01111111);      //Esta instrucción deshabilita a las interrupciones globales sin modificar el resto de las interrupciones.
    TCNT2 = 0;     //Limpiar el registro que guarda la cuenta del Timer-2.
    TIMSK2 =TIMSK2|0b00000001;      //Habilitación de la bandera 0 del registro que habilita la interrupción por sobre flujo o desbordamiento del TIMER2.
    TCCR2B = 0b00000010; //ft2 = 1 MHz
    SREG = (SREG & 0b01111111) | 0b10000000; //Habilitar interrupciones
}

void ISR_timer2(int _count){
    cuenta++;
    if(cuenta > _count) {
      timer_poll();
      cuenta=0;
    }
}
#endif

bool timer_register_10ms (volatile uint8_t *t)
{
  uint8_t k;
  
  for (k = 0; k < MAX_10MS_TIMERS; ++k)
  {
    if (NULL == timers_10ms[k])
    {
      /* Success--found an unused slot */
      timers_10ms[k] = t;
      return false;
    }
  }
  
  /* Failure */
  return true;
}

bool timer_register_100ms (volatile uint8_t *t)
{
  uint8_t k;
  
  for (k = 0; k < MAX_100MS_TIMERS; ++k)
  {
    if (NULL == timers_100ms[k])
    {
      /* Success--found an unused slot */
      timers_100ms[k] = t;
      return false;
    }
  }
  
  /* Failure */
  return true;
}

void timer_poll (void)
{
  static uint8_t prescaler = PRESCALE_100MS;
  volatile uint8_t *t;
  uint8_t k;
  
  /* Service the 10ms timers */
  for (k = 0; k < MAX_10MS_TIMERS; ++k)
  {
    t = timers_10ms[k];
    
    /* First NULL entry marks the end of the registered timers */
    if (t == NULL)
    {
      break;
    }
    
    if (*t > 0)
    {
      -- *t;
    }
  }
  
  /* Now divide the frequency by 10 and service the 100ms timers every 10th
     time through. */
  if (--prescaler == 0)
  {
    prescaler = PRESCALE_100MS;

    for (k = 0; k < MAX_100MS_TIMERS; ++k)
    {
      t = timers_100ms[k];
      
      if (t == NULL)
      {
        break;
      }
      
      if (*t > 0)
      {
        -- *t;
      }
    }
  }
}