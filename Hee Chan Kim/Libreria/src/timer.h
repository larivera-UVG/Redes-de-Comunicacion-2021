/**
 * @file
 * Software timer facility.
 *
 * This module implements an unlimited number of 8-bit down-counting 10ms and 
 * 100ms timers.  Timers are actually held in various places by the application
 * code and are registered with this module for service from the system's 
 * timekeeping interrupt.
 *
 * A down-counting timer starts out set to a time interval and is
 * automatically decremented via the system's periodic interrupt.  Check for a
 * zero value to know when the timer has expired:
 *
 * <pre>uint8_t my_timer = 10;
 * timer_register_100ms(&my_timer);
 *
 * for (;;)
 * {
 *   if (my_timer == 0)
 *   {
 *     do_something();
 *     my_timer = 10;
 *   }
 * }</pre>
 *
 * Down-counting timers are restricted to 8 bits so that they can be
 * atomically manipulated outside interrupt code on 8-bit architectures
 * without resorting to disable interrupts.
 *
 * @warning All variables used as timers must be declared
 *          <code>volatile</code>, because they are modified from an interrupt
 *          context that may not be understood by the compiler.  GCC in
 *          particular is known to optimize away timer variables that aren't
 *          declared <code>volatile</code>.
 *
 * <h2>Configuration</h2>
 * The number of available 10ms and 100ms timer slots is set using
 * {@link MAX_100MS_TIMERS} and {@link MAX_10MS_TIMERS}.
 * 
 * The use of a timer interrupt in arduino
 * ISR(TIMER2_OVF_vect){
 *  
 *  //Instrucciones AQUI
 *  
 * }
 */

#ifndef _TIMER_H_
#define _TIMER_H_

/**
 * @file
 */

#include <stdbool.h>
#include <stdlib.h>

#define ARDUINO_time //for initialize a timer in arduino

#ifdef ARDUINO_time
#include <Arduino.h>
/**
 * Initialize the timer2 in any arduino.
 * It's a 8 bit timer
 */
void timer_init(void);

void ISR_timer2(int _count = 38);
#endif

/**
 * Registers a 10-millisecond timer for service.
 *
 * @param[in]  t  pointer to the variable used for timing
 *
 * @retval     true   if registration failed
 * @retval     false  if registration succeeded (normal return)
 */
bool timer_register_10ms (volatile uint8_t *t);

/**
 * Registers a 100-millisecond timer for service.
 *
 * @param[in]  t  pointer to the variable used for timing
 *
 * @retval     true   if registration failed
 * @retval     false  if registration succeeded (normal return)
 */
bool timer_register_100ms (volatile uint8_t *t);

/**
 * Maintains all registered timers.
 *
 * This function should be called from a stable 10-millisecond time base,
 * preferably from an interrupt.
 */
void timer_poll (void);

#endif /* TIMER_H */