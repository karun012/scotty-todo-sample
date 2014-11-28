module DatabaseSpec where

import Test.Hspec
import Database

main :: IO ()
main = hspec spec

spec = do
    describe "Database" $ do
        it "lets you add a todo item JSON, and returns an error if the string cannot be parsed into a Todo" $ do
            addTodo "{\"do stuff\"}" `shouldBe` Left "Cannot parse JSON to Todo"
        it "lets you add a todo item JSON, and returns a Todo if successful" $ do
            addTodo "{\"text\" : \"do stuff\" }" `shouldBe` (Right $ Todo { uid = Nothing, text = Just "do stuff" })
