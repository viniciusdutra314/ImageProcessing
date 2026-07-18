#include <assert.h>
extern int kinectic_energy(int m, int v);
extern int is_prime(int x);
extern int factorial(int x);

int main() {
  assert(!is_prime(0));
  assert(!is_prime(1));
  assert(is_prime(2));
  assert(is_prime(3));
  assert(!is_prime(4));
  assert(is_prime(5));
  assert(!is_prime(6));
  assert(is_prime(7));
}
