module Matrix
  ( Matrix,
    Matrix (..),
    convolve,
    createMatrixWithValue,
    createMatrixWithFunc,
  )
where

import Data.Maybe
import Data.Vector.Unboxed qualified as U
import Data.Word (Word, Word8)

data Matrix a = Matrix
  { matrixRows :: !Word,
    matrixCols :: !Word,
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

createMatrixWithValue :: (U.Unbox a) => (Word, Word) -> a -> Matrix a
createMatrixWithValue (rows, cols) val = Matrix rows cols (U.replicate (fromIntegral (rows * cols)) val)

unflatIndex :: Word -> Int -> (Word, Word)
unflatIndex cols index = (fromIntegral (index `div` fromIntegral (cols)), fromIntegral (index `mod` fromIntegral (cols)))

createMatrixWithFunc :: (U.Unbox a) => (Word, Word) -> ((Word, Word) -> a) -> Matrix a
createMatrixWithFunc (rows, cols) func = Matrix rows cols (U.generate size (\index -> func (unflatenCurried index)))
  where
    size = fromIntegral (rows * cols)
    unflatenCurried = unflatIndex cols

index :: (U.Unbox a) => Matrix a -> (Word, Word) -> a
index (Matrix _ m elements) (r, c) = elements U.! fromIntegral (r * m + c)

indexMaybe :: (U.Unbox a) => Matrix a -> (Word, Word) -> Maybe a
indexMaybe matrix (r, c)
  | r >= rows || c >= cols = Nothing
  | otherwise = Just (index matrix (r, c))
  where
    (Matrix rows cols _) = matrix

clamp :: Float -> Word8
clamp x = fromIntegral (round x)

convolve :: Matrix Word8 -> Matrix Float -> Matrix Word8
convolve img kernel =
  createMatrixWithFunc
    (rows, cols)
    ( \(r, c) ->
        clamp
          ( sum
              [ (sample (r - center + kr, c - center + kc)) * (index kernel (kr, kc))
                | kr <- [0 .. rows_k - 1],
                  kc <- [0 .. cols_k - 1]
              ]
          )
    )
  where
    (Matrix rows cols _) = img
    (Matrix rows_k cols_k _) = kernel
    center = rows_k `div` 2
    sample (r, c) = fromIntegral (fromMaybe 0 (indexMaybe img (r, c))) :: Float
