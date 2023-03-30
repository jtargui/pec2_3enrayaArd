#include <Wire.h>
#include "Adafruit_MPR121.h"

#ifndef _BV
#define _BV(bit) (1 << (bit)) 
#endif

// You can have up to 4 on one i2c bus but one is enough for testing!
Adafruit_MPR121 cap = Adafruit_MPR121();

// Keeps track of the last pins touched
// so we know when buttons are 'released'
uint16_t lasttouched = 0;
uint16_t currtouched = 0;

// Config ledPin
int ledPinPlayer1 = 2;  
int ledPinPlayer2 = 4;  
char val;

void setup() {
  pinMode(ledPinPlayer1, OUTPUT);         // Set pin as OUTPUT
  pinMode(ledPinPlayer2, OUTPUT);         // Set pin as OUTPUT

  Serial.begin(9600);

  while (!Serial) { // needed to keep leonardo/micro from starting too fast!
    delay(10);
  }
   
  // Default address is 0x5A, if tied to 3.3V its 0x5B
  // If tied to SDA its 0x5C and if SCL then 0x5D
  if (!cap.begin(0x5A)) {
    Serial.println("|0 CANT_INIT_BOARD&");
    while (1);
  }
  Serial.println("|0 INIT_BOARD&");
  digitalWrite(ledPinPlayer1, LOW);     // Otherwise turn it OFF
  digitalWrite(ledPinPlayer2, LOW);     // Otherwise turn it OFF
}

void loop() {
  // Get the currently touched pads
  currtouched = cap.touched();
  String serialSend = "";
  for (uint8_t i=0; i<12; i++) {
    // it if *is* touched and *wasnt* touched before, alert!
    if ((currtouched & _BV(i)) && !(lasttouched & _BV(i)) ) {
      serialSend = "|"+String(i) + " touched&";
      Serial.println(serialSend);
    }
    // if it *was* touched and now *isnt*, alert!
    if (!(currtouched & _BV(i)) && (lasttouched & _BV(i)) ) {
      serialSend =  "|"+String(i) + " released&";
      Serial.println(serialSend);
    }
  }
  // reset our state
  lasttouched = currtouched;

  // Read command from serial port
  String command = readSerialCommand();
  if (command.length() > 0) {
      int spaceIndex = command.indexOf(' ');
      if (spaceIndex > 0) {
        String valueString = command.substring(0, spaceIndex);
        int value = valueString.toInt();
        String instruction = command.substring(spaceIndex + 1);
        if(instruction.equals("PLAYER1_TURN")) {
          digitalWrite(ledPinPlayer1, HIGH);    // turn the LED on
          digitalWrite(ledPinPlayer2, LOW);    // turn the LED on
        } else if(instruction.equals("PLAYER2_TURN")) {
          digitalWrite(ledPinPlayer2, HIGH);    // turn the LED on
          digitalWrite(ledPinPlayer1, LOW);    // turn the LED on
        } else {
          digitalWrite(ledPinPlayer1, LOW);     // Otherwise turn it OFF
          digitalWrite(ledPinPlayer2, LOW);     // Otherwise turn it OFF
        }
      }
    }
  delay(500);
}

String readSerialCommand() {
  String command = "";
  while (Serial.available() > 0) {
    char c = Serial.read();
    if (c == '|') {
      command = "";
    } else if (c == '&') {
      break;
    } else {
      command += c;
    }
  }
  command.trim();
  return command;
}
