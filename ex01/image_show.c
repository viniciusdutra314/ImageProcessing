#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct ImagePGM {
  uint16_t *buffer;
  uint16_t max_gray;
  int width;
  int height;
} ImagePGM;

void ImagePGM_close(ImagePGM *img) {
  free(img->buffer);
  img->max_gray = 0;
  img->height = 0;
  img->width = 0;
}

void skip_pgm_comments(FILE *fp) {
  int ch;
  while ((ch = fgetc(fp)) != EOF) {
    if (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r') {
      continue;
    }
    if (ch == '#') {
      while ((ch = fgetc(fp)) != EOF && ch != '\n')
        ;
    } else {
      ungetc(ch, fp);
      break;
    }
  }
}


int read_pgm_file(char const *filepath, ImagePGM *img) {
  FILE *pgm_file = NULL;
  img->buffer = NULL;
  pgm_file = fopen(filepath, "r");
  if (!pgm_file) {
    perror("Erro ao abrir o arquivo");
    goto clean;
  }
  char magic_number[3];
  if (fscanf(pgm_file, "%2s", magic_number) != 1) {
    fprintf(stderr, "Erro ao ler o número mágico\n");
    goto clean;
  }
  skip_pgm_comments(pgm_file);
  if (strcmp(magic_number, "P2") != 0) {
    fprintf(stderr, "Erro: O arquivo não é um PGM do tipo P2 (ASCII)\n");
    goto clean;
  }
  skip_pgm_comments(pgm_file);
  if (fscanf(pgm_file, "%d %d", &(img->width), &(img->height)) != 2) {
    fprintf(stderr, "Erro: Dimensões da imagem inválidas ou ausentes\n");
    goto clean;
  }
  skip_pgm_comments(pgm_file);
  if (fscanf(pgm_file, "%hu", &(img->max_gray)) != 1) {
    fprintf(stderr, "Erro: Valor máximo de cinza inválido ou ausente\n");
    goto clean;
  }

  img->buffer = malloc(sizeof(uint16_t) * (size_t)(img->height * img->width));
  if (!img->buffer) {
    perror("Erro de alocação de memória (imagem muito grande)");
    goto clean;
  }

  for (int i = 0; i < img->height; i++) {
    for (int j = 0; j < img->width; j++) {
      if (fscanf(pgm_file, "%hu", &(img->buffer[i * img->width + j])) != 1) {
        fprintf(stderr, "Erro ao ler pixel na posição %d, %d\n", i, j);
        goto clean;
      }
    }
  }

  fclose(pgm_file);
  return 0;

clean:
  if (pgm_file) {
    fclose(pgm_file);
  }
  if (img->buffer) {
    free(img->buffer);
    img->buffer = NULL;
  }
  return 1;
}

int main(int argc, char **argv) {
  if (argc != 2) {
    printf("Especifique uma imagem .pgm de entrada\n");
    return 1;
  }
  ImagePGM img = {0};
  if (read_pgm_file(argv[1], &img)) {
    fprintf(stderr, "Erro na leitura da imagem %s\n", argv[1]);
    return 1;
  }
  printf("Imagem com %d colunas e %d linhas \n", img.width, img.height);
  ImagePGM_close(&img);
}
