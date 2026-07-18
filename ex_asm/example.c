#include <stdio.h>

extern float kinectic_energy(float m, float v);

int main() {
  float m = 4.0;
  float v = 7.0;
  printf("m=%f\n", m);
  printf("v=%f\n", v);
  printf("kinetic_energy(m,v)=%f\n", kinectic_energy(m, v));
  printf("expected %f\n", (m * v * v) / 2);
}
