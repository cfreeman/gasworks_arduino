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
#include "Arduino.h"
#include "gasworks.h"

const int DURATION_HE = 250;      // The duration the LED will be on for when at 'High' energy.
const int DURATION_LE = 3000;     // The duration the LED will be on for when at 'Low' energy.

const int COOLDOWN_HE = 250;      // The duration between LED flashes when at 'High' Energy.
const int COOLDOWN_LE = 3000;     // The duration between LED flashes when at 'Low' Energy.

const int BRIGHT_LOWER_HE = 105;  // The dimmest the LED will be when at 'High' Energy.
const int BRIGHT_LOWER_LE = 5;    // The dimmest the LED will be when at 'Low' Energy.

const int BRIGHT_UPPER_HE = 255;  // The brightest the LED will be when at 'High' Energy.
const int BRIGHT_UPPER_LE = 20;   // The brightest the LED will be when at 'Low' Energy.

const int POWERUP_LENGTH = 3000;  // The length of the power up animation in milliseconds.

const int WARM_UP_LOWER_DURATION_LE = 2500;
const int WARM_UP_UPPER_DURATION_LE = 3000;

const int WARM_UP_COOLDOWN_LE = 3000;
const int WARM_UP_COOLDOWN_HE = 0;

const int WARM_UP_BRIGHT_LE = 255;
const int WARM_UP_BRIGHT_HE = 20;


/**
 * Performs a linear interpoloation between left and right based on the ratio.
 *
 * @param left The left value of the interpolation.
 * @param right The right value of the interpolation.
 * @param ratio How far to interpolate between left and right.
 *
 */
int LERP(int left, int right, float ratio) {
  if (left < right) {
    return left + ((right-left)*ratio);
  } else {
    return left - ((left-right)*ratio);
  }
}

int LERPDesc(int left, int right, float ratio) {
  return left - LERP(left, right, abs(ratio));
}

State DisabledMode(LED *light, State current_state, Command command) {
  unsigned long current_time = millis();
  if (light->on) {
    analogWrite(light->pin, 0);
    light->on = false;
    light->off_at = current_time;
  }

  if (command.instruction == 'e') {
    return (State) {command.argument, current_time, &InteractiveMode};
  } else if (command.instruction == 'c') {
    return (State) {command.argument, current_time, &CooldownMode};
  }

  return current_state;
}

State CooldownMode(LED *light, State current_state, Command command) {
  unsigned long current_time = millis();
  double delta_t = 0.0;

  if (current_time >= light->on_at && current_time < light->off_at) {
    light->on = true;
    delta_t = ((light->off_at - current_time) / (double) light->duration);
    analogWrite(light->pin, LERPDesc(light->brightness, 0, delta_t));
  } else {
    analogWrite(light->pin, 0);
    light->on = false;
    light->brightness = LERPDesc(WARM_UP_BRIGHT_LE, WARM_UP_BRIGHT_HE, current_state.energy);
    light->on_at = current_time + random(WARM_UP_COOLDOWN_LE - LERPDesc(WARM_UP_COOLDOWN_LE, WARM_UP_COOLDOWN_HE, current_state.energy));

    light->duration = random(WARM_UP_LOWER_DURATION_LE, WARM_UP_UPPER_DURATION_LE);
    light->off_at = light->on_at + light->duration;
  }

  if (command.instruction == 'a') {
    return (State) {0.0, current_time, &PowerupMode};
  } else if (command.instruction == 'e') {
    return (State) {command.argument, current_time, &InteractiveMode};
  } else if (command.instruction == 'c') {
    return (State) {command.argument, current_state.started_at, &CooldownMode};
  }

  return current_state;
}

State InteractiveMode(LED *light, State current_state, Command command) {
  unsigned long current_time = millis();

  // Light has been on - disable it and work out next on time.
  if ((light->on_at + light->duration) < current_time) {

    // Turn the LED off.
    analogWrite(light->pin, LOW);
    light->off_at = current_time;
    light->on = false;

    // Determine the brightness to use the next time the LED is switched on.
    light->brightness = random(LERP(BRIGHT_LOWER_LE, BRIGHT_LOWER_HE, current_state.energy),
                               LERP(BRIGHT_UPPER_LE, BRIGHT_UPPER_HE, current_state.energy));

    // Determine how long the LED should be on for when turned on.
    light->duration = random(LERP(DURATION_LE, DURATION_HE, current_state.energy));

    // Determine when the LED should turn on.
    light->on_at = current_time + random(LERP(COOLDOWN_LE, COOLDOWN_HE, current_state.energy));
  }

  // Light has been off - enable it.
  if (!light->on && current_time >= light->on_at) {
    analogWrite(light->pin, light->brightness);
    light->on = true;
  }

  if (command.instruction == 'a') {
    return (State) {0.0, current_time, &PowerupMode};
  } else if (command.instruction == 'e') {
    return (State) {command.argument, current_state.started_at, &InteractiveMode};
  } else if (command.instruction == 'c') {
    return (State) {command.argument, current_time, &CooldownMode};
  }

  return current_state;
}

State PowerupMode(LED *light, State current_state, Command command) {
  unsigned long current_time = millis();
  double delta_t = max((current_time - current_state.started_at) / ((double) POWERUP_LENGTH) - 0.3, 0.0);

  if (light->on) {
    analogWrite(light->pin, LERP(light->brightness, 255, delta_t));
  } else {
    analogWrite(light->pin, LERP(0, 255, delta_t));
  }

  // After the powerup animation has completed, return to interactive mode.
  if (current_time >= (current_state.started_at + POWERUP_LENGTH)) {
    return (State) {0.0, current_time, &InteractiveMode};
  }

  return current_state;
}

Command ReadCommand() {
  // Not enough bytes for a command, return an empty command.
  if (Serial.available() < 5) {
    return (Command) {'*', 0.0};
  }

  union {
    char b[4];
    float f;
  } ufloat;

  // Read the command identifier and argument from the serial port.
  char c = Serial.read();
  Serial.readBytes(ufloat.b, 4);
  return (Command) {c, ufloat.f};
}

const int NUM_LIGHTS = 13;
LED lights[] = {{1, 0, 0, 0, 0, false},
                {2, 0, 0, 0, 0, false},
                {3, 0, 0, 0, 0, false},
                {4, 0, 0, 0, 0, false},
                {5, 0, 0, 0, 0, false},
                {6, 0, 0, 0, 0, false},
                {7, 0, 0, 0, 0, false},
                {8, 0, 0, 0, 0, false},
                {9, 0, 0, 0, 0, false},
                {10, 0, 0, 0, 0, false},
                {11, 0, 0, 0, 0, false},
                {12, 0, 0, 0, 0, false},
                {13, 0, 0, 0, 0, false}};
State state;

/**
 * Arduino initalisation.
 */
void setup() {
  Serial.begin(9600);

  for (int i = 0; i < NUM_LIGHTS; i++) {
    pinMode(lights[i].pin, OUTPUT);
  }

  state.energy = 0.0;
  state.started_at = millis();
  state.updateState = &DisabledMode;
}

/**
 * Main Arduino loop.
 */
void loop() {
  Command c = ReadCommand();

  for (int i = 0; i < NUM_LIGHTS; i++) {
    state = state.updateState(&lights[i], state, c);

    // Write to the light state to the arduino pin.
    // if (lights[i].on) {
    //   analogWrite(lights[i].pin, lights[i].brightness);
    // } else {
    //   analogWrite(lights[i].pin, LOW);
    // }
  }
}
