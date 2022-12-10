# STCR - CS152 Compiler

## Language Name
STCR (It's pronounced sticker!)

## Extension
.stcR (eg helloWorld.stcR)

## Compiler Name
STCR-C  

## Instructions
Following are the instructions for compiling the source code to build the compiler
- Run "make"
- Next run "cat [nameOfFile].stcr | ./mini_l >> [designatedFile].mil"  
Example: cat helloWorld.stcr | ./mini_l >> helloWorld.mil
- Lastly run "./mil_run [designatedFile].mil"  
Example: ./mil_run helloWorld.mil  
- The program should now be executed using mil_run

## Demo
[Here](https://drive.google.com/file/d/1ak7Fn0jx-iRHjgh5GIwmUEKFHVa2j0VR/view?usp=share_link) is a demo video featuring successful and error test cases.
[Here](https://drive.google.com/file/d/1D2HupRz-teZ9yl88xjk4XMGm1thjFL7v/view?usp=share_link) are additional test cases for the fibonacci application test.

## Features
>Following is the high-level programming language and some code examples for it. 

### Integer Scalar Vars
#### Syntax:
 integer *name*; <br>

#### Examples: 
integer x; integer y;

### One dimensional array of ints
#### Syntax: 
integer array *name* [*size*]; <br>

#### Examples: 
integer array num[0];<br>
integer array num[5];<br>
num[2] := 25;<br>

### Assignment Statement
#### Syntax: 
:=

#### Examples: 
x := 7;<br>
y := 4;<br>

### Arithmetic Operators
#### Syntax:
  +, -, *, /<br>
 
#### Examples:
 x = x + 3;<br>
y = y * x;<br>
q = a - 4 / 2; <br>
x = q * (y - z);<br>

### Relational Operator 
#### Syntax:
 <, >, ==, !=, <=, >= <br>
#### Examples:
 (x > 7)<br>
(2 <= var)<br>
(2 == 2)

### While or Do-While Loops
#### Syntax:  <br>
while (condition) beginbody<br>
  statements<br>
endbody;

#### Examples: 
while (x < 7) beginbody<br>
  x := x + 1;<br>
endbody;<br>
<br>
while (x > 0) beginbody<br>
  y := y + 2;<br>
  x := x - 1;
endbody;


### Break Statement
#### While this was originally planned, this functionality was not implemented due to it not being required on the spec

> Syntax: disrupt<br>
**Examples**:<br>
while (x > 8) beginbody<br>
  x = x minus 1;<br>
  disrupt;<br>
endbody<br>
if (x > y) then<br>
  x = y - 2;<br>
  disrupt;<br>
else<br>
  q = 1;<br>
endif

### If-then-else statements
#### Syntax: <br>
if (condition) beginbody<br>
  statements <br>
endif;<br>
<br>
if (condition) beginbody <br>
  statements<br>
else <br>
  statements<br>
endif;

#### Examples: 
<br>
If (x < y) beginbody <br>
  y := y + 2;<br>
  x := y;<br>
endif<br>
<br>
If (x < y) beginbody<br>
	  x := y;<br>
else <br>
  y := x;<br>
endif

### Read and write statements
Syntax:<br>
read: variable1;<br>
write: variable2;<br>
#### Examples: <br>
read: x;<br>
write: y;<br>

### Comments
#### While this was originally planned, this functionality was not implemented due to it not being required on the spec
> Syntax:<br>
note: for one line
notes: for multiple lines endNotes<br>

>**Examples**:<br>
note: delete this line<br>
notes:<br>
multiple<br>
lines<br>
of code<br>
endNotes

### Functions 
#### Syntax: <br>
function *functionName* beginparams *parameter1, parameter 2*,... endparams <br>
beginlocals *stuff* endlocals <br>
beginbody  *"statments"* endbody <br>
<br>
#### Examples:<br>
function addThreeNumbers beginparams num1, num2, num3 endparams<br>
beginlocals<br>
integer var1;<br>
integer var2;<br>
integer var3;<br>
endlocals<br>
beginbody
...
endbody;
<br>
