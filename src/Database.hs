{-# LANGUAGE OverloadedStrings #-}
module Database where

import Data.Aeson ((.:), (.:?), decode, FromJSON(..), Value(..), ToJSON(..), (.=), object)
import Control.Applicative
import qualified Data.ByteString.Lazy.Char8 as B

data Todo = Todo { text :: Maybe String, uid :: Maybe Int } deriving (Show, Eq)

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
