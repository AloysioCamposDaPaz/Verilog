/*
 * student_code.c
 *
 *  Created on: Apr 01, 2021
 *      Author: Aloysio Campos Da Paz, Rodrigo Barbosa
 */

#include <system.h>
#include <io.h>
#include "sys/alt_irq.h"
#include "student_code.h"
#include "altera_avalon_pio_regs.h"

#define TUNING_1HZ 	0x056	// Tuning word corresponsing to 1Hz = 86
#define TUNING_5HZ 	0x1AE	// Tuning word corresponding to 5Hz = 430

volatile int lfsr_val;
volatile int dds_tuning_word;

#ifdef ALT_ENHANCED_INTERRUPT_API_PRESENT
void handle_lfsr_interrupts(void* context)
#else
void handle_lfsr_interrupts(void* context, alt_u32 id)
#endif
{
	#ifdef LFSR_VAL_BASE
	#ifdef LFSR_CLK_INTERRUPT_GEN_BASE
	#ifdef DDS_INCREMENT_BASE
	
	// Read and store LFSR value with a mask
	lfsr_val = (IORD_ALTERA_AVALON_PIO_DATA(LFSR_VAL_BASE) & 0x01);
	
	// Switches DDS to either 5Hz or 1Hz depending on the value of LFSR bit 0
	if (lfsr_val==0x01) {
		dds_tuning_word = TUNING_5HZ;
	}
	else {
		dds_tuning_word = TUNING_1HZ;
	}

	// Write tuning word to DDS PIO register
	IOWR_ALTERA_AVALON_PIO_DATA(DDS_INCREMENT_BASE, dds_tuning_word);

	// Reset edge capture register
	IOWR_ALTERA_AVALON_PIO_EDGE_CAP(LFSR_CLK_INTERRUPT_GEN_BASE, 0x0);

	#endif
	#endif
	#endif
}

/* Initialize the button_pio. */

void init_lfsr_interrupt()
{
	#ifdef LFSR_VAL_BASE
	#ifdef LFSR_CLK_INTERRUPT_GEN_BASE
	#ifdef DDS_INCREMENT_BASE
	
	/* Enable interrupts */
	IOWR_ALTERA_AVALON_PIO_IRQ_MASK(LFSR_CLK_INTERRUPT_GEN_BASE, 0x1);
	/* Reset the edge capture register. */
	IOWR_ALTERA_AVALON_PIO_EDGE_CAP(LFSR_CLK_INTERRUPT_GEN_BASE, 0x0);
	/* Register the interrupt handler. */
#ifdef ALT_ENHANCED_INTERRUPT_API_PRESENT
	alt_ic_isr_register(LFSR_CLK_INTERRUPT_GEN_IRQ_INTERRUPT_CONTROLLER_ID, LFSR_CLK_INTERRUPT_GEN_IRQ, handle_lfsr_interrupts, 0x0, 0x0);
#else
	alt_irq_register( LFSR_CLK_INTERRUPT_GEN_IRQ, NULL,	handle_button_interrupts);
#endif
	
	#endif
	#endif
	#endif
}

