/** @brief: Este programa muestra el uso del UART
*/

#include <stdio.h>
#include <stdlib.h>
#include <termios.h>
#include <unistd.h>
#include <fcntl.h>

#include <stdbool.h>

#define N  1024
#define EVER 1
#define SAMPLES_AMOUNT 8

int config_serial ( char *, speed_t );

typedef unsigned char byte;

short avg(const byte *samples, const int n) {
    int sum = 0, i = 0;
    for (i = 0; i < n; ++i) sum += samples[i];
    return sum / n;
}

float to_volt(const unsigned short diginput, const unsigned int vref) { 
    return ((diginput + 1) / 4096) * vref; 
}

int main() {
	register int i;
	int fd_serie;
	short dato;
    short result;
    short high_part, prev = 0;
  
	fd_serie = config_serial( "/dev/ttyUSB1", B115200 ); // B115200
	printf("serial abierto con descriptor: %d\n", fd_serie);

    unsigned int acc = 0;
	// Leemos datos del UART
	for (; EVER;) {
		read ( fd_serie, &dato, 1 );
		// printf("dato: %d\n", (int) dato & 0x3f);
        if (dato & 0x80) { // preguntamos por el bit 7
            high_part = (dato & 0x3F) << 6; // recorremos 6 bits a la izquierda, quitamos el bit que indica parte alta o baja
            // printf("valor recorrido : %d\n", high_part);		
            prev = 1;
        } else { // dato es parte baja
            if (prev) { // la anterior lectura fue parte alta
                result = high_part | (dato & 0x3F); // concatenamos los bits de la lectura anterior con la actual
                prev = 0;
                // printf("%d\t", result);		
                acc += result;
                if (++i == 4) {
                    printf("%d\t", acc >> 2);
                    acc = 0;
                    i = 0;
                }
            }
        }
    }
	close( fd_serie );
	return 0;
}

/** @brief: Esta funcion Configura la interfaz serie
 *  @param: dispositivo_serial, Nombre el dispositivo serial a usar: ttyUSB0, ttyUSB1, etc
 *  @param: baudios, Velocidad de comunicacion. Se usa la constante Bxxxx, donde xxxx  es la
 *          velocidad. Estan definidas en termios.h. Ejemplo: B9600, B19200..
 *  @return: fd, Descriptor del serial
 *******************************************************************************************
 */
int config_serial( char *dispositivo_serial, speed_t baudios )
{
	struct termios newtermios;
  	int fd;
    /*
     * Se abre un descriptor de archivo para manejar la interfaz serie
     * O_RDWR - Se abre el descriptor para lectura y escritura
     * O_NOCTTY - El dispositivo terminal no se convertira en el terminal del proceso
     * ~O_NONBLOCK - Se hace bloqueante la lectura de datos
     */
  	fd = open( dispositivo_serial, (O_RDWR | O_NOCTTY) & ~O_NONBLOCK );
	if( fd == -1 )
	{
		printf("Error al abrir el dispositivo tty \n");
		exit( EXIT_FAILURE );
  	}

    /*
     * cflag - Proporciona los indicadores de modo de control
     *	CBAUD	- Velocidad de transmision en baudios.
     * 	CS8	- Especifica los bits por dato, en este caso 8
     * 	CLOCAL 	- Ignora las lineas de control del modem: CTS y RTS
     * 	CREAD  	- Habilita el receptor del UART
     * iflag - proporciona los indicadores de modo de entrada
     * 	IGNPAR 	- Ingnora errores de paridad, es decir, comunicación sin paridad
     * oflag - Proporciona los indicadores de modo de salida
     * lflag - Proporciona indicadores de modo local
     * 	TCIOFLUSH - Elimina datos recibidos pero no leidos, como los escritos pero no transmitidos
     * 	~ICANON - Establece modo no canonico, en este modo la entrada esta disponible inmediatamente
     * cc[]	 - Arreglo que define caracteres especiales de control
     *	VMIN > 0, VTIME = 0 - Bloquea la lectura hasta que el numero de bytes (1) esta disponible
     */
	newtermios.c_cflag 	= CBAUD | CS8 | CLOCAL | CREAD;
  	newtermios.c_iflag 	= IGNPAR;
  	newtermios.c_oflag	= 0;
  	newtermios.c_lflag 	= TCIOFLUSH | ~ICANON;
  	newtermios.c_cc[VMIN]	= 1;
  	newtermios.c_cc[VTIME]	= 0;

    // Configura la velocidad de salida del UART
  	if( cfsetospeed( &newtermios, baudios ) == -1 )
	{
		printf("Error al establecer velocidad de salida \n");
		exit( EXIT_FAILURE );
  	}

    // Configura la velocidad de entrada del UART
	if( cfsetispeed( &newtermios, baudios ) == -1 )
	{
		printf("Error al establecer velocidad de entrada \n" );
		exit( EXIT_FAILURE );
	}

    // Limpia el buffer de entrada
	if( tcflush( fd, TCIFLUSH ) == -1 )
	{
		printf("Error al limpiar el buffer de entrada \n" );
		exit( EXIT_FAILURE );
	}

    // Limpia el buffer de salida
	if( tcflush( fd, TCOFLUSH ) == -1 )
	{
		printf("Error al limpiar el buffer de salida \n" );
		exit( EXIT_FAILURE );
	}

    /*
     * Se establece los parametros de terminal asociados con el
     * descriptor de archivo fd utilizando la estructura termios
     * TCSANOW - Cambia los valores inmediatamente
     */
	if( tcsetattr( fd, TCSANOW, &newtermios ) == -1 )
	{
		printf("Error al establecer los parametros de la terminal \n" );
		exit( EXIT_FAILURE );
	}

    //Retorna el descriptor de archivo
	return fd;
}
