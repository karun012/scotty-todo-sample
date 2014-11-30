{-# LANGUAGE OverloadedStrings, GeneralizedNewtypeDeriving #-}
module Types where

import Data.Default
import Control.Concurrent.STM
import Control.Monad.Reader 

import Data.Aeson ((.:), (.:?), decode, FromJSON(..), Value(..), ToJSON(..), (.=), object)
import Control.Applicative
import qualified Data.Map as M

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

