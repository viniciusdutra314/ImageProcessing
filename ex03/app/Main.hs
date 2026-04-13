import Control.Monad (forM_)
import Matrix
import PGM
import System.Process (callCommand)
import Text.Printf (printf)

imageMagick_ex02 :: String -> IO ()
imageMagick_ex02 filepath = do
  let command =
        unwords
          [ "magick montage",
            "-label 'Padding : Zeros'",
            "item02/checkboard_zeros_a.pgm",
            "-label 'Padding : Espelhamento'",
            "item02/checkboard_espelhamento_b.pgm",
            "-label 'Padding : Replicação'",
            "item02/checkboard_replicacao_c.pgm",
            "-label 'Padding : Periódico'",
            "item02/checkboard_periodico_d.pgm",
            "-tile 2x2",
            "-geometry +10+10",
            "-background '#1982bf'",
            "-fill '#333333'",
            "-font 'DejaVu-Sans'",
            "-pointsize 32",
            filepath
          ]
  callCommand command

imageMagick_ex03 :: String -> IO ()
imageMagick_ex03 filepath = do
  let command =
        unwords
          [ "magick montage",
            "-label 'Imagem original'",
            "img.pgm",
            "-label 'Suavização Leve (5x5)'",
            "item03/img_blur_5.pgm",
            "-label 'Suavização Média (15x15)'",
            "item03/img_blur_15.pgm",
            "-label 'Suavização Forte (50x50)'",
            "item03/img_blur_49.pgm",
            "-tile 2x2",
            "-geometry +10+10",
            "-background '#1982bf'",
            "-fill white",
            "-font 'DejaVu-Sans'",
            "-pointsize 50",
            filepath
          ]
  callCommand command

imageMagick_ex04 :: String -> IO ()
imageMagick_ex04 outputFile = do
  let kernels = [5, 15, 49] :: [Int]
  let sigmas = [2.0, 20.0, 200.0] :: [Float]
  let files =
        [ printf "item04/img_gauss_%d_%.1f.pgm" n s
          | n <- kernels,
            s <- sigmas
        ]

  let command =
        unwords $
          ["magick montage"]
            ++ files
            ++ [ "-tile 3x3",
                 "-geometry +10+10",
                 "-background '#1982bf'",
                 "-fill white",
                 "-font 'DejaVu-Sans'",
                 "-pointsize 50",
                 "-title 'Filtro Gaussiano: Kernel (Linhas) vs Sigma (Colunas)'",
                 outputFile
               ]

  callCommand command

imageMagick_ex05_sobel :: String -> IO ()
imageMagick_ex05_sobel outputFile = do
  let command =
        unwords
          [ "magick montage",
            "-label 'Sobel X (Original)'",
            "item05/sobel_x.pgm",
            "-label 'Sobel Y (Original)'",
            "item05/sobel_y.pgm",
            "-label 'Sobel X (Pós-Blur)'",
            "item05/sobel_x_blur.pgm",
            "-label 'Sobel Y (Pós-Blur)'",
            "item05/sobel_y_blur.pgm",
            "-tile 2x2",
            "-geometry +10+10",
            "-background '#1982bf'",
            "-fill white",
            "-font 'DejaVu-Sans'",
            "-pointsize 50",
            outputFile
          ]
  callCommand command

main :: IO ()
main = do
  -- Exercício 1)
  let checkboard =
        createMatrixWithFunc
          (size, size)
          ( \(i, j) ->
              if sameSide i j
                then black
                else white
          )
        where
          sameSide i j = (i < mid && j < mid) || (i >= mid && j >= mid)
          white = 255
          black = 0
          size = 512
          mid = size `div` 2
  writeImagePGM "item01/checkboard.pgm" checkboard
  -- Exercício 2)
  writeImagePGM "item02/checkboard_zeros_a.pgm" (convolve checkboard (kernelUniform 15) Zeroed)
  writeImagePGM "item02/checkboard_espelhamento_b.pgm" (convolve checkboard (kernelUniform 15) Mirrored)
  writeImagePGM "item02/checkboard_replicacao_c.pgm" (convolve checkboard (kernelUniform 15) Replication)
  writeImagePGM "item02/checkboard_periodico_d.pgm" (convolve checkboard (kernelUniform 15) Periodic)
  imageMagick_ex02 "item02/item02.ppm"
  -- Exercício 3)
  img <- readImagePGM "img.pgm" >>= either error pure
  forM_ [5, 15, 49] $ \n ->
    writeImagePGM ("item03/img_blur_" ++ show n ++ ".pgm") (convolve img (kernelUniform n) Periodic)
  imageMagick_ex03 "item03/item03.ppm"
  -- Exercício 4)
  forM_ [5, 15, 49] $ \k ->
    forM_ [2.0, 20.0, 200.0] $ \sigma ->
      do
        let kernel_gaussian = kernelGaussian k sigma
            path = "item04/img_gauss_" ++ show k ++ "_" ++ show sigma ++ ".pgm"
        writeImagePGM path (convolve img kernel_gaussian Periodic)
  imageMagick_ex04 "item04/item04.ppm"
  -- Exercício 5)
  let sobel_x =
        createMatrix
          [ [-1.0, 0.0, 1.0],
            [-2.0, 0.0, 2.0],
            [-1.0, 0.0, 1.0]
          ]
  print sobel_x
  let sobel_y =
        createMatrix
          [ [1.0, 2.0, 1.0],
            [0.0, 0.0, 0.0],
            [-1.0, -2.0, -1.0]
          ]
  print sobel_y
  writeImagePGM "item05/sobel_x.pgm" (convolve img sobel_x Periodic)
  writeImagePGM "item05/sobel_y.pgm" (convolve img sobel_y Periodic)
  writeImagePGM "item05/sobel_x_blur.pgm" (convolve (convolve img (kernelUniform 20) Periodic) sobel_x Periodic)
  writeImagePGM "item05/sobel_y_blur.pgm" (convolve (convolve img (kernelUniform 20) Periodic) sobel_y Periodic)
  imageMagick_ex05_sobel "item05/item05.ppm"
