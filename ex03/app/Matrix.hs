module Matrix
  ( Matrix (..),
    ConvolveStrategy (..),
    kernelUniform,
    kernelGaussian,
    matrixNormalize,
    convolve,
    createMatrixWithValue,
    createMatrixWithFunc,
    createMatrix,
  )
where

import Data.Maybe
import Data.Vector.Unboxed qualified as U
import Data.Word (Word8)

data Matrix a = Matrix
  { matrixRows :: Int,
    matrixCols :: Int,
    matrixElements :: !(U.Vector a)
  }

instance (Show a, U.Unbox a) => Show (Matrix a) where
  show (Matrix rows cols elements) =
    "Matrix "
      ++ show rows
      ++ "x"
      ++ show cols
      ++ "\n"
      ++ unlines
        [ show (U.slice start len elements)
          | i <- [0 .. rows - 1],
            let start = i * cols,
            let len = cols
        ]

createMatrixWithValue :: (U.Unbox a) => (Int, Int) -> a -> Matrix a
createMatrixWithValue (rows, cols) val = Matrix rows cols (U.replicate (rows * cols) val)

unflatIndex :: Int -> Int -> (Int, Int)
unflatIndex cols i = (i `div` cols, i `mod` cols)

createMatrix :: (U.Unbox a) => [[a]] -> Matrix a
createMatrix nested_list = Matrix num_rows num_cols (U.fromList $ concat nested_list)
  where
    num_rows = length nested_list
    num_cols = length $ head nested_list

createMatrixWithFunc :: (U.Unbox a) => (Int, Int) -> ((Int, Int) -> a) -> Matrix a
createMatrixWithFunc (rows, cols) func = Matrix rows cols (U.generate size (func . unflatenCurried))
  where
    size = rows * cols
    unflatenCurried = unflatIndex cols

unsafeIndex :: (U.Unbox a) => Matrix a -> (Int, Int) -> a
unsafeIndex (Matrix _ m elements) (r, c) = elements U.! (r * m + c)

index :: (U.Unbox a) => Matrix a -> (Int, Int) -> Maybe a
index matrix@(Matrix rows cols _) (r, c)
  | r < 0 || r >= rows || c < 0 || c >= cols = Nothing
  | otherwise = Just (unsafeIndex matrix (r, c))

clamp :: (Ord a) => a -> a -> a -> a
clamp min_val max_val x
  | x < min_val = min_val
  | x > max_val = max_val
  | otherwise = x

data ConvolveStrategy = Zeroed | Mirrored | Replication | Periodic

convolve :: Matrix Word8 -> Matrix Float -> ConvolveStrategy -> Matrix Word8
convolve
  img@(Matrix rows cols _)
  kernel@(Matrix rows_k cols_k _)
  convolve_strategy =
    createMatrixWithFunc
      (rows, cols)
      ( \(r, c) ->
          clamp
            0
            255
            ( round
                ( sum
                    [ sample (r - center + kr, c - center + kc)
                        * (kernel `unsafeIndex` (kr, kc))
                      | kr <- [0 .. rows_k - 1],
                        kc <- [0 .. cols_k - 1]
                    ]
                )
            )
      )
    where
      center = rows_k `div` 2
      sample :: (Int, Int) -> Float
      sample (r, c) =
        case convolve_strategy of
          Zeroed -> fromIntegral $ fromMaybe 0 (index img (r, c)) :: Float
          Mirrored -> fromIntegral $ unsafeIndex img (mirror1D rows r, mirror1D cols c) :: Float
          Periodic -> fromIntegral $ unsafeIndex img (r `wrap` rows, c `wrap` cols) :: Float
          Replication -> fromIntegral $ unsafeIndex img (clamp 0 (rows - 1) r, clamp 0 (cols - 1) c) :: Float
        where
          mirror1D :: Int -> Int -> Int
          mirror1D max_coord coord
            | coord < 0 = -coord + 1
            | coord >= max_coord = 2 * max_coord - (1 + coord)
            | otherwise = coord
          wrap :: Int -> Int -> Int
          wrap x n
            | x > 0 = x `mod` n
            | otherwise = n - 1 - ((-x) `mod` n)

kernelUniform :: Int -> Matrix Float
kernelUniform n =
  createMatrixWithValue (n, n) val
  where
    val = 1.0 / fromIntegral (n * n)

matrixNormalize :: Matrix Float -> Matrix Float
matrixNormalize m@(Matrix rows cols elements) =
  createMatrixWithFunc
    (rows, cols)
    ( \(i, j) ->
        (m `unsafeIndex` (i, j)) / total_sum
    )
  where
    total_sum = U.sum elements

kernelGaussian :: Int -> Float -> Matrix Float
kernelGaussian n sigma =
  matrixNormalize $
    createMatrixWithFunc
      (n, n)
      ( \(i, j) ->
          let ci = fromIntegral (i - center)
              cj = fromIntegral (j - center)
              r2 = ci * ci + cj * cj
           in exp $ -(r2 / (2 * sigma * sigma))
      )
  where
    center = n `div` 2
