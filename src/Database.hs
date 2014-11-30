{-# LANGUAGE OverloadedStrings, GeneralizedNewtypeDeriving #-}
module Database where

import Data.Default

import Data.Aeson ((.:), (.:?), decode, FromJSON(..), Value(..), ToJSON(..), (.=), object)
import Control.Applicative
import qualified Data.Map as M
import qualified Data.ByteString.Lazy.Char8 as B

import Control.Concurrent.STM
import Control.Monad.Reader 

data AppState = AppState { 
    nextId :: Int, 
    todos :: M.Map Int Todo 
}

instance Default AppState where
    def = AppState 0 M.empty

newtype WebM a = WebM { runWebM :: ReaderT (TVar AppState) IO a }
    deriving (Monad, MonadIO, MonadReader (TVar AppState))

webM :: MonadTrans t => WebM a -> t WebM a
webM = lift

gets :: (AppState -> b) -> WebM b
gets f = ask >>= liftIO . readTVarIO >>= return . f

modify :: (AppState -> AppState) -> WebM ()
modify f = ask >>= liftIO . atomically . flip modifyTVar' f

data Todo = Todo { text :: Maybe String, uid :: Maybe Int } deriving (Show, Eq)
data Result = Success | Failure String deriving (Show, Eq)

instance FromJSON Todo where
    parseJSON (Object v) = 
        Todo <$> 
        (v .:? "text") <*>
        (v .:? "uid")

instance ToJSON Todo where
    toJSON (Todo text uid) = object ["text" .= text, "uid" .= uid]

addTodo :: String -> Either String Todo
addTodo json = let parsed = decode (B.pack json) :: Maybe Todo
               in case parsed of
                      Nothing -> Left "Cannot parse JSON to Todo"
                      Just todo -> Right todo

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
