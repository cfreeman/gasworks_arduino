/*
 * Copyright (c) Clinton Freeman 2013
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
 * associated documentation files (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge, publish, distribute,
 * sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or
 * substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
 * NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
#ifndef _GASWORKS_ACH_
#define _GASWORKS_ACH_

typedef struct {
  int intensity;        // The LED intensity at the key frame value range: [0,255]
  unsigned long t;      // The time when this intensity is reached.
} KeyFrame;

typedef struct {
  int pin;              // The IO pin that the LED is connected too.
  boolean on;           // Is the LED on?

  KeyFrame start_low;   // When the LED pulse begins.
  KeyFrame start_high;  // When the LED pulse reaches its maxima.
  KeyFrame end_high;    // When the LED pulse departs its maxima.
  KeyFrame end_low;     // When the LED pulse ends.
} LED;

typedef struct {
  char instruction;     // The instruction that came in over the serial connection.
  float argument;       // The argument that was supplied with the instruction.
} Command;

/**
 * The function to use when updating an LED.
 *
 * light is the LED to be updated.
 * current_state is the current state of the neurone.
 * current_time is the time when the LED was updated.
 * command is the current command from the arduino.
 */
typedef struct State_struct (*StateFn)(LED *light, struct State_struct current_state,
                                       unsigned long current_time, Command command);

typedef struct State_struct {
  float energy;             // The current energy level of the neurone/state.
  unsigned long started_at; // The time the current state started.
  StateFn updateLED;        // The current function to use to update state.
} State;

State DisabledMode(LED *light, State current_state, unsigned long current_time, Command command);

State CooldownMode(LED *light, State current_state, unsigned long current_time, Command command);

State InteractiveMode(LED *light, State current_state, unsigned long current_time, Command command);

State PowerupMode(LED *light, State current_state, unsigned long current_time, Command command);

const int DURATION_HE = 250;                  // The duration LEDs will be on for when the neurone is at 'High' energy.
const int DURATION_LE = 4000;                 // The duration LEDs will be on for when the neurone is at 'Low' energy.

const int COOLDOWN_HE = 250;                  // The duration between LED flashes when the neurone is at 'High' Energy.
const int COOLDOWN_LE = 4000;                 // The duration between LED flashes when the neurone is at 'Low' Energy.

const int BRIGHT_LOWER_HE = 105;              // The dimmest the LED will be when the neurone is at 'High' Energy.
const int BRIGHT_LOWER_LE = 5;                // The dimmest the LED will be when the neurone is at 'Low' Energy.

const int BRIGHT_UPPER_HE = 255;              // The brightest the LED will be when the neurone is at 'High' Energy.
const int BRIGHT_UPPER_LE = 20;               // The brightest the LED will be when the neurone is at 'Low' Energy.

const int POWERUP_LENGTH = 3000;              // The length of the power up animation in milliseconds.

const int WARM_UP_LOWER_DURATION_LE = 2500;
const int WARM_UP_UPPER_DURATION_LE = 4000;

const int WARM_UP_COOLDOWN_LE = 4000;
const int WARM_UP_COOLDOWN_HE = 0;

const int WARM_UP_BRIGHT_LE = 255;
const int WARM_UP_BRIGHT_HE = 20;

const int NUM_LIGHTS = 13;
LED lights[] = {{1, false, (KeyFrame){0, 0}, (KeyFrame){0, 1}, (KeyFrame){0, 2}, (KeyFrame){0, 3}},
                {2, false, (KeyFrame){0, 0}, (KeyFrame){0, 1}, (KeyFrame){0, 2}, (KeyFrame){0, 3}},
                {3, false, (KeyFrame){0, 0}, (KeyFrame){0, 1}, (KeyFrame){0, 2}, (KeyFrame){0, 3}},
                {4, false, (KeyFrame){0, 0}, (KeyFrame){0, 1}, (KeyFrame){0, 2}, (KeyFrame){0, 3}},
                {5, false, (KeyFrame){0, 0}, (KeyFrame){0, 1}, (KeyFrame){0, 2}, (KeyFrame){0, 3}},
                {6, false, (KeyFrame){0, 0}, (KeyFrame){0, 1}, (KeyFrame){0, 2}, (KeyFrame){0, 3}},
                {7, false, (KeyFrame){0, 0}, (KeyFrame){0, 1}, (KeyFrame){0, 2}, (KeyFrame){0, 3}},
                {8, false, (KeyFrame){0, 0}, (KeyFrame){0, 1}, (KeyFrame){0, 2}, (KeyFrame){0, 3}},
                {9, false, (KeyFrame){0, 0}, (KeyFrame){0, 1}, (KeyFrame){0, 2}, (KeyFrame){0, 3}},
                {10, false, (KeyFrame){0, 0}, (KeyFrame){0, 1}, (KeyFrame){0, 2}, (KeyFrame){0, 3}},
                {11, false, (KeyFrame){0, 0}, (KeyFrame){0, 1}, (KeyFrame){0, 2}, (KeyFrame){0, 3}},
                {12, false, (KeyFrame){0, 0}, (KeyFrame){0, 1}, (KeyFrame){0, 2}, (KeyFrame){0, 3}},
                {13, false, (KeyFrame){0, 0}, (KeyFrame){0, 2}, (KeyFrame){0, 2}, (KeyFrame){0, 3}}};

#endif
