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
    return left + ((right - left) * ratio);
  } else {
    return left - ((left - right) * ratio);
  }
}

/**
 * Based off a starting keyframe, ending keyframe and the current time, work out the current
 * brightness (interpolated between the brightness specified in the starting and ending
 * keyframes.)
 */
int AnimatePulse(KeyFrame start, KeyFrame end, unsigned long current_time) {
  // Normalise dt.
  double delta_t = (current_time - start.t) / (double) (end.t - start.t);

  // Determine current brightness.
  return LERP(start.intensity, end.intensity, delta_t);
}

int LERPDesc(int left, int right, float ratio) {
  return left - LERP(left, right, abs(ratio));
}

State DisabledMode(LED *light, State current_state, unsigned long current_time, Command command) {
  if (light->on) {
    light->on = false;
    light->end_low.intensity = 0;
    light->end_low.t = current_time;
  }

  // Determine the next state of the neurone.
  switch (command.instruction) {
    case 'e':
    return (State) {command.argument, current_time, &InteractiveMode};

    case 'c':
    return (State) {command.argument, current_time, &CooldownMode};

    default:
    return current_state;
  }
}

State CooldownMode(LED *light, State current_state, unsigned long current_time, Command command) {
  // Determine the the next pulse
  if (current_time > light->end_low.t) {
    light->start_low.intensity = 0;
    light->start_low.t = current_time + random(WARM_UP_COOLDOWN_LE - LERPDesc(WARM_UP_COOLDOWN_LE, WARM_UP_COOLDOWN_HE, current_state.energy));

    light->start_high.intensity = LERPDesc(WARM_UP_BRIGHT_LE, WARM_UP_BRIGHT_HE, current_state.energy);
    light->start_high.t = light->start_low.t + 1;

    light->end_high.intensity = light->start_high.intensity;
    light->end_high.t = light->start_high.t + 1;

    light->end_low.intensity = 0;
    light->end_low.t = light->end_high.t + random(WARM_UP_LOWER_DURATION_LE, WARM_UP_UPPER_DURATION_LE);
  }

  // Determine the next state of the neurone.
  switch (command.instruction) {
    case 'a':
    return (State) {0.0, current_time, &PowerupMode};

    case 'e':
    return (State) {command.argument, current_time, &InteractiveMode};

    case 'c':
    return (State) {command.argument, current_state.started_at, &CooldownMode};

    default:
    return current_state;
  }
}

State InteractiveMode(LED *light, State current_state, unsigned long current_time, Command command) {
  if (current_time > light->end_low.t) {
    light->start_low.intensity = 0;
    light->start_low.t = current_time + random(LERP(COOLDOWN_LE, COOLDOWN_HE, current_state.energy));

    light->start_high.intensity = random(LERP(BRIGHT_LOWER_LE, BRIGHT_LOWER_HE, current_state.energy),
                                         LERP(BRIGHT_UPPER_LE, BRIGHT_UPPER_HE, current_state.energy));
    light->start_high.t = light->start_low.t + 1;

    light->end_high.intensity = light->start_high.intensity;
    light->end_high.t = light->start_high.t + random(LERP(DURATION_LE, DURATION_HE, current_state.energy));

    light->end_low.intensity = 0;
    light->end_low.t = light->end_high.t + 1;
  }

  // Determine the next state of the neurone.
  switch (command.instruction) {
    case 'a':
    return (State) {0.0, current_time, &PowerupMode};

    case 'e':
    return (State) {command.argument, current_state.started_at, &InteractiveMode};

    case 'c':
    return (State) {command.argument, current_time, &CooldownMode};

    default:
    return current_state;
  }
}

State PowerupMode(LED *light, State current_state, unsigned long current_time, Command command) {
  light->end_high.intensity = 255;
  light->end_high.t = (current_state.started_at + POWERUP_LENGTH);

  light->end_low.intensity = 0;
  light->end_low.t = light->end_high.t + 1;

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


// The current state of the neurone that the arduino is rendering as a lighting sequence.
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
  state.updateLED = &DisabledMode;
}

/**
 * Main Arduino loop.
 */
void loop() {
  Command c = ReadCommand();

  int i = 5;
  for (int i = 0; i < NUM_LIGHTS; i++) {
    unsigned long t = millis();
    state = state.updateLED(&lights[i], state, t, c);

    // Determine the current brightness of the LED.
    int b = 0;
    if (t > lights[i].start_low.t && t <= lights[i].start_high.t) {
      b = AnimatePulse(lights[i].start_low, lights[i].start_high, t);

    } else if (t > lights[i].start_high.t && t <= lights[i].end_high.t) {
      b = AnimatePulse(lights[i].start_high, lights[i].end_high, t);

    } else if (t > lights[i].end_high.t && t <= lights[i].end_low.t) {
      b = AnimatePulse(lights[i].end_high, lights[i].end_low, t);

    } else if (t > lights[i].end_low.t) {
      b = lights[i].end_low.intensity;

    }

    // Write to the light state to the arduino pin.
    analogWrite(lights[i].pin, b);
  }
}
