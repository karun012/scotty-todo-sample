{-# LANGUAGE OverloadedStrings, GeneralizedNewtypeDeriving #-}
module Main where

import Web.Scotty.Trans
import Data.Default
import Data.String

import Control.Concurrent.STM
import Control.Monad.Reader 
import System.Environment

import Types
import App

main :: IO ()
main = do 
    env <- getEnvironment
    sync <- newTVarIO def
    let runM m = runReaderT (runWebM m) sync
        runActionToIO = runM
    let port = maybe 8080 read $ lookup "PORT" env

    scottyT port runM runActionToIO app
