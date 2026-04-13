{-# LANGUAGE LambdaCase #-}

import Data.Word
import Matrix
import PGM

checkboard :: Matrix Word8
checkboard =
  createMatrixWithFunc
    (size, size)
    ( \case
        (i, j)
          | sameSide i j -> black
          | otherwise -> white
    )
  where
    sameSide i j = (i < mid && j < mid) || (i >= mid && j >= mid)
    white = 255
    black = 0
    size = 512
    mid = size `div` 2

main :: IO ()
main = do
  let kernel = createMatrixWithValue (15, 15) (1.0 / (15.0 * 15.0))
  writeImagePGM "checkboard_zeros_a.pgm" (convolve checkboard kernel Zeroed)
  writeImagePGM "checkboard_espelhamento_b.pgm" (convolve checkboard kernel Mirrored)
  writeImagePGM "checkboard_replicacao_c.pgm" (convolve checkboard kernel Replication)
  writeImagePGM "checkboard_periodico_d.pgm" (convolve checkboard kernel Periodic)
