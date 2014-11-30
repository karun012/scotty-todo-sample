{-# LANGUAGE OverloadedStrings, GeneralizedNewtypeDeriving #-}
module Main where

import Web.Scotty.Trans
import Data.Default
import Data.String

import Control.Concurrent.STM
import Control.Monad.Reader 

import Types
import App

main = do 
    sync <- newTVarIO def
    let runM m = runReaderT (runWebM m) sync
        runActionToIO = runM
    scottyT 3000 runM runActionToIO app
 
