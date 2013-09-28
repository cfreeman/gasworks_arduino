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
typedef struct LED {
  int pin;                // The pin that the LED is connected too.
  int brightness;         // The current brightness of the LED.
  int duration;           // The duration that the LED will be illuminated for this flash.
  unsigned long off_at;   // The time the LED was turned off.
  unsigned long on_at;    // The time the LED was turned on.
  boolean on;             // Is the LED on?
};

const int DURATION_HE = 250;      // The duration the LED will be on for when at 'High' energy.
const int DURATION_LE = 3000;     // The duration the LED will be on for when at 'Low' energy.

const int COOLDOWN_HE = 250;      // The duration between LED flashes when at 'High' Energy.
const int COOLDOWN_LE = 3000;     // The duration between LED flashes when at 'Low' Energy.

const int BRIGHT_LOWER_HE = 105;  // The dimmest the LED will be when at 'High' Energy.
const int BRIGHT_LOWER_LE = 5;    // The dimmest the LED will be when at 'Low' Energy.

const int BRIGHT_UPPER_HE = 255;  // The brightest the LED will be when at 'High' Energy.
const int BRIGHT_UPPER_LE = 20;   // The brightest the LED will be when at 'Low' Energy.


// Non-interactive warmup mode constants.

const int WARM_UP_LOWER_DURATION_LE = 2500;
const int WARM_UP_UPPER_DURATION_LE = 3000;

const int WARM_UP_COOLDOWN_LE = 3000;
const int WARM_UP_COOLDOWN_HE = 0;

const int WARM_UP_BRIGHT_LE = 255;
const int WARM_UP_BRIGHT_HE = 20;

const int NUM_LIGHTS = 13;         // The number of lights (LEDs) that are attached. Must have an entry for each in lights.
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

void disabledMode(struct LED *light, float energy) {
  if (light->on) {
    analogWrite(light->pin, 0);
    light-> on = false;
    light->off_at = millis();
  }
}

void nonInteractiveMode(struct LED *light, float energy) {
  unsigned long current_time = millis();
  double delta_t = 0.0;

  if (current_time >= light->on_at && current_time < light->off_at) {
    light->on = true;
    delta_t = ((light->off_at - current_time) / (double) light->duration);
    analogWrite(light->pin, LERPDesc(light->brightness, 0, delta_t));
  } else {
    analogWrite(light->pin, 0);
    light->on = false;
    light->brightness = LERPDesc(WARM_UP_BRIGHT_LE, WARM_UP_BRIGHT_HE, energy);
    light->on_at = current_time + random(WARM_UP_COOLDOWN_LE - LERPDesc(WARM_UP_COOLDOWN_LE, WARM_UP_COOLDOWN_HE, energy));

    light->duration = random(WARM_UP_LOWER_DURATION_LE, WARM_UP_UPPER_DURATION_LE);
    light->off_at = light->on_at + light->duration;
  }
}

void interactiveMode(struct LED *light, float energy) {
  unsigned long current_time = millis();

  // Light has been on - disable and work out next on time.
  if ((light->on_at + light->duration) < current_time) {

    // Turn the LED off.
    analogWrite(light->pin, LOW);
    light->off_at = current_time;
    light->on = false;

    // Determine the brightness to use the next time the LED is switched on.
    light->brightness = random(LERP(BRIGHT_LOWER_LE, BRIGHT_LOWER_HE, energy), 
                               LERP(BRIGHT_UPPER_LE, BRIGHT_UPPER_HE, energy));

    // Determine how long the LED should be on for when turned on.
    light->duration = random(LERP(DURATION_LE, DURATION_HE, energy));
    
    // Determine when the LED should turn on.
    light->on_at = current_time + random(LERP(COOLDOWN_LE, COOLDOWN_HE, energy));
  }

  // Light has been off - enable it.
  if (!light->on && current_time >= light->on_at) {
    analogWrite(light->pin, light->brightness);
    light->on = true;
  }
}

/**
 * Updates the state of one of the attached LEDs.
 *
 * @param index The index of the LED to update.
 * @param energy The energy level to use when updating the state of the LED. Valid energy levels
 * are between 0.0 and 1.0. Where 0.0 represents low energy, 1.0 represents high energy. The 
 * scuplture in a high energy state has a more rapid and brighter sequence.
 */
void updateLED(struct LED *light, float energy) {
  if (energy < -1.0) {
    disabledMode(light, energy);
  } else if (energy >= -1.0 && energy < 0.0) {
    nonInteractiveMode(light, energy);
  } else {
    interactiveMode(light, energy);
  }
}

/**
 * Arduino initalisation.
 */
void setup() {
  Serial.begin(9600);  
  
  // initialize the digital pin as an output.
  for (int i = 0; i < NUM_LIGHTS; i++) {
    pinMode(lights[i].pin, OUTPUT);    
  }
}

// Energy level ranges from -2.0 to 1.0
// An Energy level less than -1.0 disables the sculpture completely.
// An Energy level between -1.0 and 0.0 is a non-interactive sequence.
// An Energy level between 0.0 and 1.0 is for the interactive sequence.
float energy = -2.0f;

/**
 * SerialEvent occurs whenever a new data comes in the
 * hardware serial RX.  This routine is run between each
 * time loop() runs, so using delay inside loop can delay
 * response.  Multiple bytes of data may be available.
 */
void serialEvent() {  
  // Wait till we have enough bytes to decode it as a floating point number.
  if (Serial.available() >= 4) {
    union {
      byte b[4];   
      float f;
    } ufloat;

    // We have enough bytes - decode as a float.  
    ufloat.b[0] = Serial.read();   
    ufloat.b[1] = Serial.read();
    ufloat.b[2] = Serial.read();
    ufloat.b[3] = Serial.read();    

    energy = ufloat.f;
  }  
}

/**
 * Main Arduino loop.
 */
void loop() {
//  if (energy >= 1.0) {
//    energy = -1.0;
//  }
//  energy += 0.0001;

  for (int i = 0; i < NUM_LIGHTS; i++) {
    updateLED(&lights[i], energy);
  }

//  Serial.print(energy);
//  Serial.print('\n');
}



