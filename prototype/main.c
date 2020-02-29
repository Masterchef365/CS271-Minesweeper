#include <stdio.h>
#include <stdlib.h>

#define WIDTH 6
#define HEIGHT 6
#define BOARD_LEN WIDTH *HEIGHT
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

const int FULL_AREA_KERNEL_X[] = {-1, 0, 1, -1, 1, -1, 0, 1};
const int FULL_AREA_KERNEL_Y[] = {-1, -1, -1, 0, 0, 1, 1, 1};
const int FULL_AREA_KERNEL_LEN = 8;

const int ADJACENT_KERNEL_X[] = {-1, 0, 0, 1};
const int ADJACENT_KERNEL_Y[] = {0, -1, 1, 0};
const int ADJACENT_KERNEL_LEN = 4;

// Number of mines in the vicinity, 9 = mine here
unsigned char field[WIDTH * HEIGHT] = {0};
unsigned int n_mines = 0;
unsigned int correctly_flagged_mines = 0;

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
void advance_rng() { rng = (1103515245 * rng + 12345) % 2147483648; }

// Can be optimized to [y * WIDTH + x >= 0 && < WIDTH * HEIGHT
int bounds_check(int x, int y) {
    return x >= 0 && y >= 0 && x < WIDTH && y < HEIGHT;
}

void inc_number_at_xy(int x, int y) {
    for (int i = 0; i < FULL_AREA_KERNEL_LEN; i++) {
        int x_m = x + FULL_AREA_KERNEL_X[i];
        int y_m = y + FULL_AREA_KERNEL_Y[i];
        int position = y_m * WIDTH + x_m;
        if (bounds_check(x_m, y_m) && field[position] != FIELD_MINE) {
            field[position] += 1;
        }
    }
}

void generate_map() {
    // Populate cells with mines
    n_mines = 0;
    for (int y = 0; y < HEIGHT; y++) {
        for (int x = 0; x < WIDTH; x++) {
            advance_rng();
            if (rng % 100 < PERCENT_MINES) {
                field[y * WIDTH + x] = FIELD_MINE;
                n_mines++;
                inc_number_at_xy(x, y);
            }
        }
    }
}

void recursive_clear(int x, int y) {
    interactive[y * WIDTH + x] = INTER_DISCOVERED;

    for (int i = 0; i < ADJACENT_KERNEL_LEN; i++) {
        int x_m = x + ADJACENT_KERNEL_X[i];
        int y_m = y + ADJACENT_KERNEL_Y[i];
        int position = y_m * WIDTH + x_m;
        if (bounds_check(x_m, y_m) && field[position] != FIELD_MINE) {
            if (interactive[position] == INTER_UNDISCOVERED) {
                interactive[position] = INTER_DISCOVERED;
                if (field[position] == FIELD_CLEAR) {
                    recursive_clear(x_m, y_m);
                }
            }
        }
    }
}

// Assumes correct bounds
void toggle_flag(int x, int y) {
    int position = y * WIDTH + x;
    if (interactive[position] == INTER_UNDISCOVERED) {
        interactive[position] = INTER_FLAGGED;
        if (field[position] == FIELD_MINE) {
            correctly_flagged_mines += 1;  
        } else {
            correctly_flagged_mines -= 1;  
        }
    } else {
        interactive[position] = INTER_UNDISCOVERED;
        if (field[position] == FIELD_MINE) {
            correctly_flagged_mines -= 1;  
        } else {
            correctly_flagged_mines += 1;  
        }
    }
}

void clear_mine(int x, int y) {
    int position = y * WIDTH + x;
    if (field[position] == FIELD_MINE) {
        printf("You died!\n");
        exit(-1);
    }

    recursive_clear(x, y);
}

int main() {
    generate_map();
    while (correctly_flagged_mines < n_mines) {
        print_field();

        // Read command
        int command;
        do {
            printf(
                    "What operation would you like to execute?\n"
                    "0 = Clear\n"
                    "1 = Toggle flag\n"
                    "Operation: "
                  );
            scanf("%i", &command);
        } while (command > 1);

        // Read X and Y positions
        int x, y;
        do {
            printf("X position: ");
            scanf("%X", &x);
            printf("Y position: ");
            scanf("%X", &y);
        } while (!bounds_check(x, y));

        // Execute command
        if (command == 1) {
            toggle_flag(x, y);
        } else {
            clear_mine(x, y);
        }
    }
    printf("You won!\n");
}
