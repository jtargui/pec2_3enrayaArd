import processing.serial.*;

// Variables de lectura de arduino
Serial port;  // Crear el objeto Serial
String buffer = ""; // Almacena los datos recibidos hasta encontrar el símbolo de fin de comando
boolean comandoRecibido = false;  //Nos indica que hemos recibido un comando entero de Arduino
boolean enviarComando1 = true;
boolean enviarComando2 = true;
// Variables del juego
char[][] tablero = new char[3][3]; // Matriz de 3x3 para el tablero
boolean turnoJugador1 = true; // True si es el turno del jugador 1, False si es el turno del jugador 2
boolean juegoTerminado = false; // True si el juego ha terminado
char ganador = ' '; // 'X' si ha ganado el jugador 1, 'O' si ha ganado el jugador 2, 'T' si hay empate
int tiempoGanador = 0; // Tiempo en segundos que muestra el mensaje de ganador

// Dimensiones del juego
int anchoTablero = 800; // Ancho del tablero
int altoTablero = 600; // Alto del tablero
int margen = 0; // Margen alrededor del tablero
int anchoCuadrado = anchoTablero/3; // Ancho de cada cuadrado del tablero
int altoCuadrado = altoTablero/3; // Alto de cada cuadrado del tablero
int margenCasilla = 5;  //Margen entre las casillas
// Variables para la pantalla de inicio
boolean inicio = true; // True si se está mostrando la pantalla de inicio
boolean juegoIniciado = false; // True si se ha iniciado el juego
int tiempoInicio = 0; // Tiempo en segundos que muestra la pantalla de inicio

// Configuración inicial
void setup() {
  size(800, 600);
  textAlign(CENTER, CENTER);
  textSize(24);
  printArray(Serial.list());
  
  // Abrir el puerto donde arduino se connecta
  port = new Serial(this, Serial.list()[2], 9600);
  port.bufferUntil('&');  // Espera el símbolo de fin de comando para llamar a la función "serialEvent"
  
  // Reiniciar el juego
  reiniciarJuego();
}

void draw() {
  background(255);
  
  //Comandos de Arduino
  if (comandoRecibido) {
    // Si se ha recibido un comando completo, procesa los datos
    procesarComando(buffer);
    
    // Prepara para recibir un nuevo comando
    buffer = "";
    comandoRecibido = false;
  }
  
  //Juego tres en raya
  if (inicio) {
    if (juegoIniciado) {
      // Si se ha iniciado el juego, saltar a la pantalla del juego
      inicio = false;
    } else {
      // Mostrar la pantalla de inicio
      textAlign(CENTER, CENTER);
      textSize(30);
      fill(0);
      text("Tic Tac Toe", width/2, height/2 - 50);
      textSize(20);
      text("Press 'Start'...", width/2, height/2);     
    }
  } else {
    // Mostrar el tablero
    dibujarTablero();
    
    if (juegoTerminado) {
      
      // Dibujamos una caja para poner el texto
      fill(0,128,0);
      rect(10,height/2-80,width-20, 100);
      // Si el juego ha terminado, mostrar el mensaje de ganador
      textAlign(CENTER, CENTER);
      textSize(70);
      fill(0);
      if (ganador == 'X') {
        text("Player 1 wins", width/2, height/2 - 50);
      } else if (ganador == 'O') {
        text("Player 2 wins", width/2, height/2 - 50);
      } else if (ganador == 'T') {
        text("Tie game", width/2, height/2 - 50);
      }
      
      // Contar el tiempo que se muestra el mensaje de ganador
      if (millis() - tiempoGanador >= 3000) {
        // Reiniciar el juego después de 3 segundos
        reiniciarJuego();
        inicio = true;
      }
    } else {
      // Mostrar el turno del jugador
      textAlign(CENTER, CENTER);
      textSize(20);
      fill(0);
      if (turnoJugador1) {
        text("Player 1's turn", width/2, height - 40);
        if (enviarComando1) {
          enviarComando1=false;
          port.write("|0 PLAYER1_TURN&");
          enviarComando2 = true;
        }
      } else {
        text("Player 2's turn", width/2, height - 40);
        if (enviarComando2) {
          enviarComando2 = false;
          enviarComando1 = true;
          port.write("|0 PLAYER2_TURN&");
        }
      }
    }
  }
}

void mousePressed() {
  if (!inicio && !juegoTerminado) {
    // Si no estamos en la pantalla de inicio y el juego no ha terminado
    int columna = (mouseX - margen) / anchoCuadrado;
    int fila = (mouseY - margen) / altoCuadrado;
    
    if (columna >= 0 && columna < 3 && fila >= 0 && fila < 3 && tablero[fila][columna] == ' ') {
      // Si la casilla seleccionada está vacía
      if (turnoJugador1) {
        tablero[fila][columna] = 'X'; // Marcar la casilla con una X
      } else {
        tablero[fila][columna] = 'O'; // Marcar la casilla con una O
      }
     controlJuego(); 
    }
  }
}

// Comprobar si hay ganador o empate
void controlJuego() {
    ganador = comprobarGanador();
    if (ganador != ' ') {
      juegoTerminado = true;
      tiempoGanador = millis();
    } else if (comprobarEmpate()) {
      juegoTerminado = true;
      ganador = 'T';
      tiempoGanador = millis();
    } else {
      turnoJugador1 = !turnoJugador1; // Cambiar el turno al otro jugador
    }
}

void keyPressed() {
  ejecutarComandoJuego(key);
}

// Control del juego

void ejecutarComandoJuego(char comando) {
  if (comando == 'r') {
    // Reiniciar el juego
    reiniciarJuego();
    inicio = true;
  } else if (comando == 's' && inicio) {
    // Empezar el juego
    juegoIniciado = true;
  }
  int fila=-1;
  int columna=-1;
  if (!inicio && !juegoTerminado) {
    if (comando == '1') {
        fila=0;
        columna=0;
    } else if (comando == '2') {
        fila=0;
        columna=1;           
    } else if (comando == '3') {
        fila=0;
        columna=2;           
    } else if (comando == '4') {
        fila=1;
        columna=0;             
    } else if (comando == '5') {
        fila=1;
        columna=1;           
    } else if (comando == '6') {
        fila=1;
        columna=2;              
    } else if (comando == '7') {
        fila=2;
        columna=0;           
    } else if (comando == '8') {
        fila=2;
        columna=1;           
    } else if (comando == '9') {
        fila=2;
        columna=2;           
    }

    if (fila>-1 && columna>-1 && tablero[fila][columna] == ' ') {
      // Si la casilla seleccionada está vacía
      if (turnoJugador1) {
        tablero[fila][columna] = 'X'; // Marcar la casilla con una X
      } else {
        tablero[fila][columna] = 'O'; // Marcar la casilla con una O
      }
      controlJuego(); 
    }    
  }
}

// Dibujar el tablero
void dibujarTablero() {
  strokeWeight(4);
  stroke(0);
  
  // Dibujar las líneas verticales del tablero
  for (int i = 1; i < 3; i++) {
    line(margen + i*anchoCuadrado, margen, margen + i*anchoCuadrado, margen + altoTablero);
  }
  
  // Dibujar las líneas horizontales del tablero
  for (int i = 1; i < 3; i++) {
    line(margen, margen + i*altoCuadrado, margen + anchoTablero, margen + i*altoCuadrado);
  }
  
  // Dibujar las marcas de los jugadores en el tablero
  for (int fila = 0; fila < 3; fila++) {
    for (int columna = 0; columna < 3; columna++) {
      if (tablero[fila][columna] == 'X') {
        dibujarX(columna, fila);
      } else if (tablero[fila][columna] == 'O') {
        dibujarO(columna, fila);
      }
    }
  }
}

// Dibujar una X en la casilla indicada
void dibujarX(int columna, int fila) {
  strokeWeight(8);
  stroke(0, 150, 0);
  line(margen + columna*anchoCuadrado + margenCasilla, 
       margen + fila*altoCuadrado + margenCasilla, 
       margen + (columna+1)*anchoCuadrado - margenCasilla, 
       margen + (fila+1)*altoCuadrado - margenCasilla);
  line(margen + (columna+1)*anchoCuadrado - margenCasilla, 
       margen + fila*altoCuadrado + margenCasilla, 
       margen + columna*anchoCuadrado + margenCasilla, 
       margen + (fila+1)*altoCuadrado - margenCasilla);
}

// Dibujar una O en la casilla indicada
void dibujarO(int columna, int fila) {
  strokeWeight(8);
  stroke(150, 0, 0);
  noFill();
  ellipseMode(CORNER);
  ellipse(margen + columna*anchoCuadrado + margenCasilla, 
          margen + fila*altoCuadrado + margenCasilla, 
          anchoCuadrado - 2*margenCasilla, altoCuadrado - 2*margenCasilla);
}

// Comprobar si hay un ganador
char comprobarGanador() {
  char ganador = ' ';
  
  // Comprobar las filas
  for (int fila = 0; fila < 3; fila++) {
    if (tablero[fila][0] == tablero[fila][1] && tablero[fila][1] == tablero[fila][2]) {
      ganador = tablero[fila][0];
    }
  }
  
  // Comprobar las columnas
  for (int columna = 0; columna < 3; columna++) {
    if (tablero[0][columna] == tablero[1][columna] && tablero[1][columna] == tablero[2][columna]) {
      ganador = tablero[0][columna];
    }
  }
  
  // Comprobar las diagonales
  if (tablero[0][0] == tablero[1][1] && tablero[1][1] == tablero[2][2]) {
    ganador = tablero[0][0];
  } else if (tablero[0][2] == tablero[1][1] && tablero[1][1] == tablero[2][0]) {
    ganador = tablero[0][2];
  }
  
  return ganador;
}

// Comprobar si hay empate
boolean comprobarEmpate() {
  boolean empate = true;
  for (int fila = 0; fila < 3; fila++) {
    for (int columna = 0; columna < 3; columna++) {
      if (tablero[fila][columna] == ' ') {
        empate = false;
      }
    }
  }
  return empate;
}

// Reiniciar el juego
void reiniciarJuego() {
  for (int fila = 0; fila < 3; fila++) {
    for (int columna = 0; columna < 3; columna++) {
      tablero[fila][columna] = ' ';
    }
  }
  inicio = true;
  juegoIniciado = false;
  turnoJugador1 = true;
  juegoTerminado = false;
  enviarComando1 = true;
  enviarComando2 = true;
  port.write("|0 PLAYER_RESET&");
  ganador = ' ';
}

/** CÓDIGO REFERENTE A ARDUINO*/
void serialEvent(Serial myPort) {
  // Se llama a esta función cuando llega un nuevo byte al puerto serie
  // La función "bufferUntil" configura el objeto Serial para llamar a esta función cuando llega el símbolo de fin de comando "&"
  
  // Lee los datos recibidos
  String datos = myPort.readStringUntil('&');
  
  if (datos != null) {
    // Si se han recibido datos, agrégalos al buffer
    buffer += datos;
    
    // Si el buffer contiene el símbolo de inicio de comando, marca que se ha recibido un comando completo
    if (buffer.indexOf('|') != -1) {
      comandoRecibido = true;
    }
  }
}

void procesarComando(String comando) {
  // Esta función procesa los datos recibidos en un comando completo
  // Separa el valor numérico y la instrucción usando el espacio como separador
  
  // Busca el índice del primer espacio en el comando
  int indiceEspacio = comando.indexOf(' ');
  
  if (indiceEspacio != -1) {
    // Si hay un espacio, extrae el valor numérico y la instrucción
    float valorNumerico = float(comando.substring(comando.indexOf('|') + 1, indiceEspacio));
    String instruccion = comando.substring(indiceEspacio + 1);
    
    // Imprime los datos procesados en la consola
    println("Serial: " + comando);
    println("Valor numérico: " + valorNumerico);
    println("Instrucción: " + instruccion);
    
    //Ejecutar comando del juego
    ejecutarComandoJuego(transformarComando(valorNumerico, instruccion));
  }
}

char transformarComando(float valorNumerico, String instruccion) {
  char valor = '.';
  if (instruccion.equals("touched&")) {
    if (valorNumerico >=0 && valorNumerico <=8) {
      valor = (char)((((int)Math.floor(valorNumerico)+1))+'0');
    } else if (valorNumerico == 9.0) {
      return 'r';
    } else if (valorNumerico == 10.0) {
      return 's';
    }
  }
  
  return valor;
}
