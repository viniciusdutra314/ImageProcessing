.global kinectic_energy,factorial,is_prime
.type factorial,%function
.type kinectic_energy,%function
.type is_prime,%function
.p2align 4

kinectic_energy: //x0=m,x1=v
    mul x2, x1,x1 
    mul x0, x0,x2
    mov x3,#2
    udiv x0, x0, x3
    ret


factorial: 
    cmp x0,#1
    beq done_factorial
    cmp x0,#0 
    beq done_factorial

    mov x1,x0 
loop_factorial: cmp x1,#1
    beq done_factorial
    sub x1,x1,#1
    mul x0,x0,x1
    b loop_factorial
done_factorial:
    ret


is_prime:
    cmp x0,#2
    b.lo notprime
    b.eq prime
    mov x1,#2
divide_loop:
    udiv x2,x0,x1 
    msub x2, x1,x2 ,x0 // p/q <=> p-q*udiv=remainder
    cbz x2,notprime
    add x1,x1,#1
    cmp x1,x0
    b.ne divide_loop
    b.eq prime
prime:
    mov x0,#1
    ret 
notprime:
    mov x0,#0
    ret
