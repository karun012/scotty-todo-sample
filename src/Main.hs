{-# LANGUAGE OverloadedStrings, GeneralizedNewtypeDeriving #-}
module Main where

import Web.Scotty.Trans
import Network.Wai.Middleware.Static
import Network.Wai.Middleware.RequestLogger
import qualified Database as D
import Data.Default
import Data.String
import Data.Text.Lazy (Text)
import qualified Data.ByteString.Lazy.Char8 as B
import qualified Data.Map as M
import Data.Aeson (encode)
import Network.HTTP.Types

import Control.Concurrent.STM
import Control.Monad.Reader 

data AppState = AppState { 
    nextId :: Int, 
    todos :: M.Map Int D.Todo 
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
        let todo = D.addTodo requestBodyAsString
        case todo of 
          Left error -> do
                    status status404
                    text $ fromString $ show error
          Right t -> do
                    webM $ modify $ \st -> let nextUid = nextId st + 1
                                               todoWithId = D.Todo (D.text t) (Just nextUid)
                                           in st { nextId = nextUid, todos = M.insert nextUid todoWithId (todos st) }
                    identifier <- webM $ gets nextId
                    todoItems <- webM $ gets todos
                    let todo = M.lookup identifier todoItems
                    json todo
