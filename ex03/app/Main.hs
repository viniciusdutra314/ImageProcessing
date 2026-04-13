import Control.Monad (forM_)
import Matrix
import PGM
import System.Process (callCommand)

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
            "item03/img_blur_50.pgm",
            "-tile 4x1",
            "-geometry +10+10",
            "-background '#1982bf'",
            "-fill white",
            "-font 'DejaVu-Sans'",
            "-pointsize 50",
            filepath
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
  let ex03_kernel_sizes = [5, 15, 50]
  forM_ ex03_kernel_sizes $ \n ->
    writeImagePGM ("item03/img_blur_" ++ show n ++ ".pgm") (convolve img (kernelUniform n) Periodic)
  imageMagick_ex03 "item03/item03.ppm"
