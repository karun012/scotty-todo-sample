{-# LANGUAGE OverloadedStrings, GeneralizedNewtypeDeriving #-}
module Main where

import Web.Scotty.Trans
import Network.Wai.Middleware.Static
import Network.Wai.Middleware.RequestLogger
import Database hiding (text)
import Data.Default
import Data.String
import Data.Text.Lazy (Text, pack)
import qualified Data.ByteString.Lazy.Char8 as B
import Data.Aeson (encode)
import Network.HTTP.Types

import qualified Data.Map as M

import Control.Concurrent.STM
import Control.Monad.Reader 

main = do 
    sync <- newTVarIO def
    let runM m = runReaderT (runWebM m) sync
        runActionToIO = runM
    scottyT 3000 runM runActionToIO app
 
app :: ScottyT WebM ()
app = do
    middleware logStdoutDev
    middleware $ staticPolicy (noDots >-> addBase "static")
    get "/" $ do 
        file "./static/html/index.html"
    get "/todos" $ do
        todoItems <- webM $ gets todos
        json $ M.elems todoItems
    get "/:todoId" $ do 
        todoId <- param "todoId"
        todoItems <- webM $ gets todos
        let todo = M.lookup todoId todoItems
        case todo of
            Nothing -> do 
                    status status404
                    text $ fromString $ "No item found for id " ++ show todoId
            Just t -> json $ todo
    post "/todo" $ do
        requestBody <- body
        let requestBodyAsString = B.unpack requestBody
        let (result, w) = addTodoItem requestBodyAsString
        case result of
            Success -> do
                    webM w
                    status status200
                    identifier <- webM $ gets nextId
                    setHeader "Location" (pack (show identifier))
            Failure errorMessage -> do
                              status status404
                              text $ fromString $ show errorMessage
