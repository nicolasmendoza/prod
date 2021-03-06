/*
 * Copyright (c) 2016-2018, 2020 Eric B. Decker
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Warning: many of these routines directly touch cpu registers
 * it is assumed that this is initilization code and interrupts are
 * off.
 *
 * @author Eric B. Decker
 */

#include "hardware.h"
#include "cpu_stack.h"

noinit uint32_t stack_size;

module PlatformP {
  provides {
    interface Init;
    interface Platform;
    interface TimeSkew;
    interface StdControl;
  }
  uses {
    interface Init as PlatformPins;
    interface Init as PlatformLeds;
    interface Init as PlatformClock;
    interface Init as PeripheralInit;
    interface LocalTime<TMilli>;
    interface Stack;
  }
}

implementation {
  command error_t Init.init() {
//    call Stack.init();
//    stack_size = call Stack.size();

    call PlatformLeds.init();   // Initializes the Leds
    call PeripheralInit.init();
    return SUCCESS;
  }


  async command uint32_t Platform.localTime()      { return call LocalTime.get(); }


  /*
   * dummy StdControl for PlatformSerial.
   */
  command error_t StdControl.start() {
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    return SUCCESS;
  }


  /* T32 is a count down so negate it */
  async command uint32_t Platform.usecsRaw()       { return -(TIMER32_1->VALUE); }
  async command uint32_t Platform.usecsRawSize()   { return 32; }

  async command uint32_t Platform.usecsExpired(uint32_t t_base, uint32_t limit) {
    uint32_t t_new;

    t_new = call Platform.usecsRaw();
    if (t_new - t_base > limit)
      return t_new;
    return 0;
  }

  async command uint32_t Platform.jiffiesRaw()     { return (TIMER_A0->R); }
  async command uint32_t Platform.jiffiesRawSize() { return 16; }

  async command uint32_t Platform.jiffiesExpired(uint32_t t_base,
                                                 uint32_t limit) {
    uint32_t t_new;

    t_new = call Platform.jiffiesRaw();
    if (t_new - t_base > limit)
      return t_new;
    return 0;
  }

  uint32_t __platform_usecs_raw() @C() @spontaneous() {
    return -(TIMER32_1->VALUE);
  }

  async command bool     Platform.set_unaligned_traps(bool set_on) {
    bool unaligned_on;

    atomic {
      unaligned_on = FALSE;
      if (SCB->CCR & SCB_CCR_UNALIGN_TRP_Msk)
        unaligned_on = TRUE;
      if (set_on)
        SCB->CCR |= SCB_CCR_UNALIGN_TRP_Msk;
      else
        SCB->CCR &= ~(SCB_CCR_UNALIGN_TRP_Msk);
      __ISB();
    }
    return unaligned_on;
  }


  /**
   * Platform.getInterruptPriority
   * Interrupt priority assignment
   *
   * The mm6a/dev6a are based on the ti msp432/cortex-4mf which have 3 bits
   * of interrupt priority.  0 is the highest, 7 the lowest.
   *
   * platform.h defines IRQ_DEFAULT_PRIORITY, the IRQNs, and their priorities.
   */
  async command int Platform.getIntPriority(int irq_number) {
    return IRQ_DEFAULT_PRIORITY;
  }


  /**
   * Platform.node_id
   *
   * return a pointer to a 6 byte random number that we can
   * use as both our serial_number as well as our network node_id.
   *
   * The msp432 provides a 128 bit (we use the first 48 bits, 6 bytes)
   * random number.  This shows up at address 0x0020_1120 but we
   * reference it using the definitions from the processor header.
   */
  async command uint8_t *Platform.node_id(unsigned int *lenp) {
    if (lenp)
      *lenp = PLATFORM_SERIAL_NUM_SIZE;
    return (uint8_t *) &TLV->RANDOM_NUM_1;
  }


  /***************** Defaults ***************/
  default command error_t PeripheralInit.init() {
    return SUCCESS;
  }

  default async event void TimeSkew.skew(int32_t skew) { }
}
