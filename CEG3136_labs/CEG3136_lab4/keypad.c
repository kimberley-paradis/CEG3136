#include <stdtypes.h>
#include "mc9s12dg256.h"
#include "keyPad.h"
#include "delay.h"


typedef struct {
    unsigned char keycode;
    unsigned char value;
} keycode_key_pair_t;

#define NUM_KEYS 16
keycode_key_pair_t convertTbl[NUM_KEYS] = {
    { 0b11101110,'1' },
    { 0b11101101,'2' },
    { 0b11101011,'3' },
    { 0b11100111,'a' },
    { 0b11011110,'4' },
    { 0b11011101,'5' },
    { 0b11011011,'6' },
    { 0b11010111,'b' },
    { 0b10111110,'7' },
    { 0b10111101,'8' },
    { 0b10111011,'9' },
    { 0b10110111,'c' },
    { 0b01111110,'*' },
    { 0b01111101,'0' },
    { 0b01111011,'#' },
    { 0b01110111,'d' }
};

static char key_debounced = 0;
static char key_release_debounced = 0;

static char key_wait_release = 0;

static char volatile key_pressed;

static char volatile key_pressed_temp;

#define DEBOUNCE_TIME (ONETENTH_MS * 10)

void initKeyPad(void)
{
    DDRA = 0b11110000; // Data Direction Register
    PORTA  = 0x00; // initialize PORTA
	  PUCR |= 0b00000001; // Enable pullups

    TIOS_IOS2 = 1; // set to output-compare
	  TC2 = TCNT + DEBOUNCE_TIME; //Set for every 10 ms
    TIE_C2I = 1; // enable interrupt channel
}

void interrupt VectorNumber_Vtimch2 timer2_isr(void) 
{
    int keyPressed;
    int x;
    volatile int temp_1;
    PORTA = 0x0F;
    keyPressed = PORTA != 0x0F;

    if(keyPressed) {
        if(!key_debounced) { //Wait for 1 cycle to debounce key
            key_debounced = 1;
        } else if (key_pressed_temp == NOKEY) {
            key_wait_release = 1;
            for(x = 0; x < NUM_KEYS; x++) {
                PORTA = convertTbl[x].keycode;

                //it means that key is pressed
                temp_1 = PORTA;
                if(PORTA == convertTbl[x].keycode) {
                    key_pressed_temp = convertTbl[x].value;
                    break;
                }
            }
        }
        key_release_debounced = 0;
    } else {
        //Key not pressed
        if(key_wait_release && key_release_debounced) {
            key_wait_release = 0;
            key_pressed = key_pressed_temp;
            key_pressed_temp = NOKEY;
        } else {
            key_release_debounced = 1;
        }
        key_debounced = 0;
    }

    TC2 = TCNT + DEBOUNCE_TIME; //Update interrupt time
}

char pollReadKey(void) 
{
    if(key_pressed != NOKEY) {
        char temp = key_pressed;
        key_pressed = NOKEY;
        return temp;
    }
    return NOKEY;
}

char readKey(void) 
{
    char temp;
    while(key_pressed == NOKEY); //Wait

    temp = key_pressed;
    key_pressed = NOKEY;
    return temp;
}
