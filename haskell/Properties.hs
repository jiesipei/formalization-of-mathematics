module Properties where

import Examples
import Test.QuickCheck
import ToomCook

genK :: Gen Int
genK = choose (2, 10)

genNum :: Gen Integer
genNum = choose (100000000, 999999999)

propToomCookCorrect :: ToomCook -> Property
propToomCookCorrect t = forAll genNum $ \n -> forAll genNum $ \m ->
  toomCook t n m == n * m

propSplitCorrect :: Property
propSplitCorrect = forAll genK $ \k -> forAll genNum $ \n ->
  let b = 10^baseExponent k n n in n == merge b (split k b n)

main :: IO ()
main = do
  quickCheck (propToomCookCorrect test2Settings)
  quickCheck (propToomCookCorrect wikiSettings)
  quickCheck propSplitCorrect