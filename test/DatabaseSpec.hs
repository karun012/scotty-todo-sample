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
            currentTodoId <- runM $ gets nextId
            currentTodos <- runM $ gets todos

            currentTodoId `shouldBe` 1
            currentTodos `shouldBe` M.fromList [(1, Todo { text = Just "do stuff", uid = Just 1})]
        it "lets you find todo items by id" $ do
            sync <- newTVarIO def
            let runM m = runReaderT (runWebM m) sync
                (result, w) = addTodoItem "{\"text\" : \"do stuff\" }"
            runM w
            todoItem <- runM $ findTodoById 1
            doesNotExist <- runM $ findTodoById 99
            todoItem `shouldBe` (Just $ Todo { text = Just "do stuff", uid = Just 1})
            doesNotExist `shouldBe` Nothing
        it "get all todos" $ do
            sync <- newTVarIO def
            let runM m = runReaderT (runWebM m) sync
            let (result, w) = addTodoItem "{\"text\" : \"do stuff\" }"

            noTodos <- runM getTodos

            runM w
            todoItems <- runM getTodos

            noTodos `shouldBe` []
            todoItems `shouldBe` [Todo { text = Just "do stuff", uid = Just 1}]
