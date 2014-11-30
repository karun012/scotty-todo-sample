module DatabaseSpec where

import Test.Hspec
import Database

import Data.Default
import Control.Concurrent.STM
import Control.Monad.Reader
import qualified Data.Map as M

import System.IO.Silently

main :: IO ()
main = hspec spec

spec = do
    describe "Database" $ do
        it "returns a Failure with an error message if the json cannot be parsed to a Todo" $ do
            let (result, w) = addTodoItem "{\"do stuff\"}"
            result `shouldBe` (Failure "Cannot parse JSON to Todo")
        it "adds new todos to AppState" $ do
            sync <- newTVarIO def
            let runM m = runReaderT (runWebM m) sync
                (result, w) = addTodoItem "{\"text\" : \"do stuff\" }"
            runM w
            nextTodoId <- runM $ gets nextId
            currentTodos <- runM $ gets todos
            nextTodoId `shouldBe` 1
            currentTodos `shouldBe` M.fromList [(1, Todo { text = Just "do stuff", uid = Just 1})]

