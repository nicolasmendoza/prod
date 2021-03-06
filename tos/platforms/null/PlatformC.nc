/*
 * Copyright (c) 2005-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA,
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Dummy implementation to support the null platform.
 */

module PlatformC {
  provides interface Init;
  provides interface Platform;
}
implementation {
  command error_t Init.init() {
    return SUCCESS;
  }

  async command uint32_t Platform.localTime()      { return 0; }
  async command uint32_t Platform.usecsRaw()       { return 0; }
  async command uint32_t Platform.usecsRawSize()   { return 0; }
  async command uint32_t Platform.usecsExpired(uint32_t t_base, uint32_t limit) {
    return (uint32_t) -1;
  }
  async command uint32_t Platform.jiffiesRaw()     { return 0; }
  async command uint32_t Platform.jiffiesRawSize() { return 0; }
  async command uint32_t Platform.jiffiesExpired(uint32_t t_base, uint32_t limit) {
    return (uint32_t) -1;
  }
  async command bool     Platform.set_unaligned_traps(bool on_off) {
    return FALSE;
  }
  async command int      Platform.getIntPriority(int irq_number) {
    return 0;
  }
  async command uint8_t *Platform.node_id(unsigned int *lenp) {
    return NULL;
  }
}
