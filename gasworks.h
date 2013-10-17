#ifndef _GASWORKS_ACH_
#define _GASWORKS_ACH_

typedef struct {
  int pin;                // The IO pin that the LED is connected too.

  int brightness;         // The current brightness of the LED.
  int duration;           // The duration that the LED will be illuminated for this flash.
  unsigned long off_at;   // The time the LED was turned off.
  unsigned long on_at;    // The time the LED was turned on.
  boolean on;             // Is the LED on?

  // int start_brightness;		// The start brightness of this LED pulse.
  // unsigned long start_time;	// The time when the start brightness occurs.

  // int mid_brightness;		// The middle brightness of this LED pulse.
  // unsigned long mid_time;	// The time when the middle brightness occurs.

  // int end_brightness;		// The ending brightness of this LED pulse.
  // unsigned long end_time;	// The time when the end brightness occurs.
} LED;

typedef struct {
  char instruction;			// The instruction that came in over the serial connection.
  float argument;			// The argument that was supplied with the instruction.
} Command;

/**
 * The function to use when updating the current state of a LED.
 *
 * light is the current state of the LED.
 * energy is the current energy level to use with the lighting strategy.
 * started_at is when the current strategy for updating the state of the led began.
 */
typedef struct State_struct (*StateFn)(LED *light, struct State_struct current_state, Command command);

typedef struct State_struct {
  float energy;					// The current energy level of the neurone/state.
  unsigned long started_at;		// The time the current state started.
  StateFn updateState;			// The current function to use to update state.
} State;

State DisabledMode(LED *light, State current_state, Command command);

State CooldownMode(LED *light, State current_state, Command command);

State InteractiveMode(LED *light, State current_state, Command command);

State PowerupMode(LED *light, State current_state, Command command);

#endif