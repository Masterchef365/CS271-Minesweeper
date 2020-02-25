#include <stdio.h>
#include <unistd.h>

#define WIDTH 16
#define HEIGHT 16
#define BOARD_LEN WIDTH * HEIGHT
const unsigned char INTER_UNDISCOVERED = 0;
const unsigned char INTER_DISCOVERED = 1;
const unsigned char INTER_FLAGGED = 2;

const unsigned char FIELD_CLEAR = 0;
const unsigned char FIELD_MINE = 9;

const char UNDISCOVERED_CHAR = '-';
const char FLAG_CHAR = 'F';
const char CLEAR_CHAR = ' ';
const char MINE_CHAR = '*';

const int PERCENT_MINES = 8;

// Number of mines in the vicinity, 9 = mine here
unsigned char field[WIDTH * HEIGHT] = {0}; 

// 0 = undiscovered, 1 = cleared, 2 = flagged
unsigned char interactive[WIDTH * HEIGHT] = {0}; 

unsigned int rng = 15; // Is also the seed

void print_field() {
    printf("---------------------------------------------\n");

    printf("  ");
    for (int x = 0; x < WIDTH; x++) {
        printf(" %X", x);
    }
    putchar('\n');

    for (int y = 0; y < HEIGHT; y++) {
        printf("%2X", y);
        for (int x = 0; x < WIDTH; x++) {
            unsigned char field_val = field[y * WIDTH + x];
            unsigned char inter_val = interactive[y * WIDTH + x];

            putchar(' ');

            if (inter_val == INTER_UNDISCOVERED) {
                putchar(UNDISCOVERED_CHAR);
                continue;
            } else if (inter_val == INTER_FLAGGED) {
                putchar(FLAG_CHAR);
                continue;
            }

            if (field_val == FIELD_CLEAR) {
                putchar(CLEAR_CHAR);
            } else if (field_val > FIELD_CLEAR && field_val < FIELD_MINE) {
                printf("%i", field_val);
            } else {
                putchar(MINE_CHAR);
            }

        }
        putchar('\n');
    }
}

// https://stackoverflow.com/questions/3062746/special-simple-random-number-generator#3062783
void advance_rng() {
    rng = (1103515245 * rng + 12345) % 2147483648;
}

// Can be optimized to [y * WIDTH + x >= 0 && < WIDTH * HEIGHT
int bounds_check(int x, int y) {
    return x >= 0 && y >= 0 && x < WIDTH && y < HEIGHT;
}

void inc_number_at_xy(int x, int y) {
    for (int x_offset = -1; x_offset <= 1; x_offset++) {
        for (int y_offset = -1; y_offset <= 1; y_offset++) {
            if (!(x_offset == 0 && y_offset == 0)) {
                int x_m = x + x_offset;
                int y_m = y + y_offset;
                int position = y_m * WIDTH + x_m;
                if (bounds_check(x_m, y_m) && field[position] != FIELD_MINE) {
                    field[position] += 1;
                }
            }
        }
    }
}

void generate_map() {
    // Populate cells with mines
    for (int y = 0; y < HEIGHT; y++) {
        for (int x = 0; x < WIDTH; x++) {
            advance_rng();
            if (rng % 100 < PERCENT_MINES) {
                field[y * WIDTH + x] = FIELD_MINE;
                inc_number_at_xy(x, y);
            }
        }
    }
}

void recursive_clear(int x, int y) {
    interactive[y * WIDTH + x] = INTER_DISCOVERED;

    int x_offsets[] = {-1, 0, 0, 1};
    int y_offsets[] = {0, -1, 1, 0};
    for (int i = 0; i < 4; i++) {
        int x_m = x + x_offsets[i];
        int y_m = y + y_offsets[i];
        int position = y_m * WIDTH + x_m;
        if (bounds_check(x_m, y_m) && field[position] != FIELD_MINE) {
            if (interactive[position] == INTER_UNDISCOVERED) {
                interactive[position] = INTER_FLAGGED;
                print_field();
                usleep(1000 * 10);
                interactive[position] = INTER_DISCOVERED;
                if (field[position] == FIELD_CLEAR) {
                    recursive_clear(x_m, y_m);
                }
                //} else {
                //}
            }
        }
    }
}

int main () {
    print_field();
    generate_map();
    //for (int i = 0; i < WIDTH * HEIGHT; i++)
    //interactive[i] = INTER_DISCOVERED;

    recursive_clear(1, 1);
    print_field();
}
