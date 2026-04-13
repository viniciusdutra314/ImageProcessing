module Matrix
  ( Matrix (..),
    ConvolveStrategy (..),
    convolve,
    createMatrixWithValue,
    createMatrixWithFunc,
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
            let start = fromIntegral (i * cols),
            let len = fromIntegral cols
        ]

createMatrixWithValue :: (U.Unbox a) => (Int, Int) -> a -> Matrix a
createMatrixWithValue (rows, cols) val = Matrix rows cols (U.replicate (fromIntegral (rows * cols)) val)

unflatIndex :: Int -> Int -> (Int, Int)
unflatIndex cols i = (fromIntegral (i `div` fromIntegral cols), fromIntegral (i `mod` fromIntegral cols))

createMatrixWithFunc :: (U.Unbox a) => (Int, Int) -> ((Int, Int) -> a) -> Matrix a
createMatrixWithFunc (rows, cols) func = Matrix rows cols (U.generate size (func . unflatenCurried))
  where
    size = fromIntegral (rows * cols)
    unflatenCurried = unflatIndex cols

index :: (U.Unbox a) => Matrix a -> (Int, Int) -> a
index (Matrix _ m elements) (r, c) = elements U.! fromIntegral (r * m + c)

indexMaybe :: (U.Unbox a) => Matrix a -> (Int, Int) -> Maybe a
indexMaybe matrix@(Matrix rows cols _) (r, c)
  | r < 0 || r >= rows || c < 0 || c >= cols = Nothing
  | otherwise = Just (index matrix (r, c))

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
                        * (kernel `index` (kr, kc))
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
          Zeroed -> fromIntegral $ fromMaybe 0 (indexMaybe img (r, c)) :: Float
          Mirrored -> fromIntegral $ index img (mirror1D rows r, mirror1D cols c) :: Float
          Periodic -> fromIntegral $ index img (r `wrap` rows, c `wrap` cols) :: Float
          Replication -> fromIntegral $ index img (clamp 0 (rows - 1) r, clamp 0 (cols - 1) c) :: Float
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
