{-# LANGUAGE OverloadedStrings, GeneralizedNewtypeDeriving #-}
module Database where


import Data.Aeson ((.:), (.:?), decode, FromJSON(..), Value(..), ToJSON(..), (.=), object)
import Control.Applicative
import qualified Data.Map as M
import qualified Data.ByteString.Lazy.Char8 as B

import Types

addTodoItem :: String -> (Result, WebM ())
addTodoItem json = let parsed = parseJsonToTodo json
                   in case parsed of
                          Left error -> (Failure error, modify id)
                          Right t -> let newState = modify $ \st -> let nextUid = nextId st + 1
                                                                        todoWithId = Todo (text t) (Just nextUid)
                                                                    in st { nextId = nextUid, todos = M.insert nextUid todoWithId (todos st) }
                                     in (Success, newState)

parseJsonToTodo :: String -> Either String Todo
parseJsonToTodo json  = let parsed = decode (B.pack json) :: Maybe Todo
                        in case parsed of
                               Nothing -> Left "Cannot parse JSON to Todo"
                               Just todo -> Right todo

findTodoById :: Int -> WebM (Maybe Todo)
findTodoById uid = gets (\st -> let todoItems = (todos st) 
                                in M.lookup uid todoItems)

getTodos :: WebM [Todo]
getTodos = gets (\st -> M.elems (todos st))
