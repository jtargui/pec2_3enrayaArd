#include <Wire.h>
#include "Adafruit_MPR121.h"

#ifndef _BV
#define _BV(bit) (1 << (bit)) 
#endif

Adafruit_MPR121 cap = Adafruit_MPR121();  // Crear el objeto Adafruit_MPR121
uint16_t lasttouched = 0;                 //Último pin pulsado
uint16_t currtouched = 0;                 //pin actual pulsado
int ledPinPlayer1 = 2;                    //pin asociado al led del jugador 1
int ledPinPlayer2 = 4;                    //pin asociado al led del jugador 2    
char val;                                 //valor leído por el puerto serie

void setup() {
  pinMode(ledPinPlayer1, OUTPUT);         // pin -> OUTPUT
  pinMode(ledPinPlayer2, OUTPUT);         // pin -> OUTPUT
  Serial.begin(9600);                     // Iniciamos el puerto serie
  while (!Serial) {                       // Arduino mega es demasiado rápido para arrancar! (He hecho pruebas con este tambien)
    delay(10);
  }
   
  // Nos conectamos a MPR121
  if (!cap.begin(0x5A)) {
    Serial.println("|0 CANT_INIT_BOARD&");
    while (1);
  }
  Serial.println("|0 INIT_BOARD&");     // Nos hemos podido conectar OK
  digitalWrite(ledPinPlayer1, LOW);     // El led del jugador 1 debe estar apagado
  digitalWrite(ledPinPlayer2, LOW);     // El led del jugador 2 debe estar apagado
}

void loop() {
  // Procedemos a leer el controlador MPR121
  currtouched = cap.touched();
  String serialSend = "";
  for (uint8_t i=0; i<12; i++) {
    // Si hemos tocado una entrada capactativa y es diferente a la anterior, alertamos que tocamos!!.
    if ((currtouched & _BV(i)) && !(lasttouched & _BV(i)) ) {
      // Montamos el mensaje y lo enviamos al puerto serie
      serialSend = "|"+String(i) + " touched&";
      Serial.println(serialSend);
    }
    // Si hemos tocado una entrada capacitativa y ahora no, alertamos que hemos dejado de tocar.
    if (!(currtouched & _BV(i)) && (lasttouched & _BV(i)) ) {
      // Montamos el mensaje y lo enviamos al puerto serie
      serialSend =  "|"+String(i) + " released&";
      Serial.println(serialSend);
    }
  }
  // Actualizar la última entrada capacitativa tocada.
  lasttouched = currtouched;

  // Leemos el puerto serie
  String command = readSerialCommand();
  // Si tenemos un comando entero, procedemos a evaluar el comando y realizar alguna acción
  if (command.length() > 0) {
      //Separamos el comando por un espacio para optener un valor numerico y un comando.
      int spaceIndex = command.indexOf(' ');
      if (spaceIndex > 0) {
        String valueString = command.substring(0, spaceIndex);
        int value = valueString.toInt();
        String instruction = command.substring(spaceIndex + 1);
        // Evaluamos el comando para determinar que LED debemos encender según el turno del jugador.
        if(instruction.equals("PLAYER1_TURN")) {
          digitalWrite(ledPinPlayer1, HIGH);
          digitalWrite(ledPinPlayer2, LOW);
        } else if(instruction.equals("PLAYER2_TURN")) {
          digitalWrite(ledPinPlayer2, HIGH);
          digitalWrite(ledPinPlayer1, LOW);
        } else {
          digitalWrite(ledPinPlayer1, LOW);
          digitalWrite(ledPinPlayer2, LOW);
        }
      }
    }
  delay(500); // Nos esperamos 500ms a repetir el bucle. Si no lo ponemos leemos la información demasiado rápida.
}

// Función para obtener un comando entero leido por puerto serie.
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
