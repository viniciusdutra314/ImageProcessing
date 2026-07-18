.global kinectic_energy
.type kinectic_energy,%function
.p2align 4

kinectic_energy: //s0=m,s1=v
    fmul s2, s1,s1 
    fmul s0, s0,s2
    ret
