import Data.Massiv.Array
import Data.Massiv.Array.IO

imgSize :: Sz2
imgSize = Sz2 512 512

mid :: Int
mid = 512 `div` 2

black :: Pixel (Y D65) Word8
black = PixelY 0

white :: Pixel (Y D65) Word8
white = PixelY 255

checkboard :: Array U Ix2 (Pixel (Y D65) Word8)
checkboard =
  makeArray
    Seq
    imgSize
    ( \(i :. j) ->
        if (i < mid && j < mid) || (i >= mid && j >= mid)
          then black
          else
            white
    )

main :: IO ()
main = do
  writeImage "checkboard.png" checkboard
