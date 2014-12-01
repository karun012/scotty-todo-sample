scotty-todo-sample
==================
Sample Todo App Using Scotty and ReactJS

#How to run it
I recommend using a sandbox so that the dependencies do not mess up your environment. 
```cabal
cabal update
cabal sandbox init
cabal install
.cabal-sandbox/bin/scotty-todo
```
If the install fails with a "Backjump limit reached" error, use
```cabal
cabal install --max-backjumps=9999
```
Access [http://localhost:3000](http://localhost:3000) to get to the index page
