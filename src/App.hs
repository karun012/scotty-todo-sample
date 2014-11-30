{-# LANGUAGE OverloadedStrings, GeneralizedNewtypeDeriving #-}
module App where

import Web.Scotty.Trans
import Network.Wai.Middleware.Static
import Network.Wai.Middleware.RequestLogger
import Data.Default
import Data.String
import Data.Text.Lazy (Text, pack)
import qualified Data.ByteString.Lazy.Char8 as B
import Data.Aeson (encode)
import Network.HTTP.Types

import Database
import Types hiding (text)

app :: ScottyT WebM ()
app = do
    middleware logStdoutDev
    middleware $ staticPolicy (noDots >-> addBase "static")
    get "/" $ do 
        file "./static/html/index.html"
    get "/todos" $ do
        todoItems <- webM getTodos
        json todoItems
    get "/:todoId" $ do 
        todoId <- param "todoId"
        todo <- webM $ findTodoById todoId
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
