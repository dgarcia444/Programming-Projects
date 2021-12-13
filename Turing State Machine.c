#include <stdio.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define EOL '\n'

typedef struct Tape {
    struct Tape *next; // moves right
    struct Tape *prev; // moves left
    char data; // the contents of the cell
} Tape;


struct Rules {
    char writeVal;
    char moveDirection;
    char newState;
};


//add to beginning of the list
void prepend(struct Tape **headPointer, char newData) {
    // Allocate for new cell
    struct Tape *newCell = malloc(sizeof(struct Tape));
    // Put the data inside the cell
    newCell->data = newData;
    // Make this new cell point to the head
    // Also make the previous point to null
    newCell->next = (*headPointer);
    newCell->prev = NULL;
    // Make the head's prev point to the new cell
    // Check if the current head's prev doesn't point to anything
    if ((*headPointer) != NULL)
        (*headPointer)->prev = newCell;
    // Move the head pointer to the new cell
    (*headPointer) = newCell;
}



//add to the end of the list
void append(struct Tape **headPointer, char newData) {
    //this prints put a blank in the beginning
    struct Tape *newCell = malloc(sizeof(struct Tape));

    newCell->prev = NULL;
    newCell->next = NULL;

    struct Tape *tail = *headPointer;// to be used later

    // Fill in the contents of the cell
    newCell->data = newData;

    // Check if linked list is empty
    // If it is empty, make the new cell the head
    if (*headPointer == NULL) {
        newCell->prev = NULL;
        *headPointer = newCell;
        return;
    }

    // if the list is not empty, move through the tape until you reach the last cell
    while (tail->next != NULL) { // This gives a segmentation fault for some reason
        tail = tail->next;
    }

    // Make the current tail of the list point to the new cell
    tail->next = newCell;
    
    //Make the new cell's previous pointer point to the tail
    newCell->prev = tail;
}

void printTape(struct Tape *cell) {
    printf("\nPrinting the tape... \n");
    // if the current cell isn't null, move along the tape and print out it'c contents
    while (cell != NULL) {
        printf("%c ", cell->data);
        cell = cell->next;
    }
}




int main() {

    FILE *file;
    char input[60];
    char a,b,c,d,e,f,g,h,ch;
    char start = 'A';
    int startState,totalStates,endState = 0;
    //int totalStates = 0;
    //int endState = 0;

    printf("%s", "What file do you wanna load?");
    //gets(input);
    scanf("%s", input);
    file = fopen(input, "r");
    if (file == NULL) {
        perror("This file couldn't be read.");
        exit(EXIT_FAILURE);
    }

    //set size
    int size = ftell(file) - 2;
    //allocate memory for linked list
    struct Tape *tail = malloc(size * sizeof(struct Tape));
    fseek(file, 0, SEEK_SET);
    //trying to insert A at the beginning of the linked list
    prepend(&tail, start);
    //get the next character until the end of the line
    while ((ch = getc(file)) != EOL) {
        //add to the end of the linked list
        append(&tail, ch);
    }

    printTape(tail);
    printf("\n");
    printf("\n");


    while ((f = getc(file)) != EOL) {
        totalStates = f - 48;

    }
    printf("%d\n", totalStates);

    while ((g = getc(file)) != EOL) {
        startState = g - 48;

    }
    printf("%d\n", startState);

    while ((h = getc(file)) != EOL) {
        endState = h - 48;

    }
    printf("%d\n", endState);

    printf("\n");

    //adding instructions to 2-D array
    
    //allocating memory for array
    struct Rules **instructions = malloc(totalStates * sizeof(struct Rules*));
    for (int i = 0; i < totalStates; i++) {
        instructions[i] = malloc(256 * sizeof(struct Rules));
    }

    while ((ch = fscanf(file, "(%c,%c)->(%c,%c,%c)\n", &a, &b, &c, &d, &e)) != EOF) {
        //printf("Read: %d\t%c\t%c\t%c\t%d\n", a, b, c, d, e);
        instructions[a-48][b].writeVal = c;
        instructions[a-48][b].moveDirection = d;
        instructions[a-48][b].newState = e - 48;
        printf("%d\t%c\t%c\t%c\t%d\n", a-48, b, instructions[a-48][b].writeVal, instructions[a-48][b].moveDirection,
               instructions[a-48][b].newState);
    }

    
    
    //executing turing machine
    
    //this will be our pointer to read/write
    struct Tape *temp = tail;
    while (startState < endState) {
        printTape(tail);
        //Read from the tape! Store in b.
            b = temp->data;
        //print out the instructions
        printf("\n\nInstructions:\n%d\t%c\t%c\t%c\t%d\n", startState, b, instructions[startState][b].writeVal, instructions[startState][b].moveDirection,
               instructions[startState][b].newState);
        printf("\nWe're currently in state: %d ", startState);
        printf("\nReading a: %c ", b);
        temp->data = instructions[startState][b].writeVal;
        printf("\nWriting a: %c ", temp->data);
        if (instructions[startState][b].moveDirection == 'R') {
            // if there is no node to move right to
            if (temp->next == NULL) {
                printf("\nMoving: %c ", instructions[startState][b].moveDirection);
                // build the node on the fly
                append(&tail, 'B');
                temp = temp->next;
                //print the tape
                printTape(tail);
            } else {
                printf("\nMoving: %c ", instructions[startState][b].moveDirection);
                temp = temp->next;
                printTape(tail);
            }
        } else if (instructions[startState][b].moveDirection == 'L') {
            if (temp->prev == NULL) {
                printf("\nMoving: %c ", instructions[startState][b].moveDirection);
                prepend(&tail, 'B');
                temp = temp->prev;
                printTape(tail);
            } else {
                printf("\nMoving: %c ", instructions[startState][b].moveDirection);
                temp = temp->prev;
                printTape(tail);
            }
        }
        startState = instructions[startState][b].newState;
        printf("\nWe are now in state: %d\n ", startState);
    }
    printTape(tail);
}