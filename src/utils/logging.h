
#include <stdarg.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <sys/timeb.h>

#include <string.h>
#include <time.h>
#include <stdlib.h>

#ifndef LOGGING_H
#define LOGGING_H


#define LOG_ERROR 1
#define LOG_WARNING 2
#define LOG_INFO 3
#define LOG_DEBUG 4

// ---------------------------------------------------------------------------------
// Error handling interface.
// ---------------------------------------------------------------------------------
void get_timestamp(	char buf_36chars[]);
int fatal_handler(	char* message, ...);
int warning_handler( char* message, ... );
int info_handler(		char* message, ... );
int debug_handler(	char* message, ... );


/** If we return 0 either the log level is less than LOG_ERROR  
  * or we could not open the log file
  */
int log_init( int log_level, char* log_file );
void log_free(); 

#endif