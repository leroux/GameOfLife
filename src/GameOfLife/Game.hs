{-# LANGUAGE OverlappingInstances, FlexibleInstances #-}

module Game where

import           Data.List (delete, transpose, nub, intersperse)
import           Data.List.Split (chunksOf)
import qualified Data.Map as M
import           Data.Maybe (catMaybes)

----
-- Cell
----
data Cell = Dead | Alive deriving Eq
type Position = (Int, Int)
type Structure = [Position]

instance Show Cell where
  show Dead  = " "
  show Alive = "*"


----
-- Grid
----
type Grid = M.Map Position Cell

instance Show Grid where
  show = unlines . map (intersperse ' ' . map (head . show)) . gridToList

gridToList :: Grid -> [[Cell]]
gridToList g = (transpose . chunksOf 50 . map snd . M.toAscList) g
  where width = (fst . fst . M.findMax) g

-- Create grid of size (m * n) and populate with Cell c.
-- 0-indexed grid!
initGrid :: Cell -> Int -> Int -> Grid
initGrid c m n = insertStructureWith c [ (x, y) | x <- [0..m - 1], y <- [0..n - 1] ] M.empty

-- Completely dead grid.
deadGrid :: Int -> Int -> Grid
deadGrid = initGrid Dead

-- Fully alive grid.
aliveGrid :: Int -> Int -> Grid
aliveGrid = initGrid Alive

isDead :: Grid -> Bool
isDead = M.null . M.filter (== Alive)

isAlive :: Grid -> Bool
isAlive = not . isDead


----
-- Grid/Structure
----
-- Translate structure from base origin.
translateStructure :: Structure -> Position -> Structure
translateStructure s (x, y) = map (\(a, b) -> (x + a, y + b)) s

-- Insert cell structure into grid.
insertStructureWith :: Cell -> Structure -> Grid -> Grid
insertStructureWith c s g = foldr (\k -> M.insert k c) g s
 
-- Insert alive cells structure into grid.
insertStructureAt :: Position -> Structure -> Grid -> Grid
insertStructureAt p s = insertStructureWith Alive $ translateStructure s p


----
-- Cell Interactions
----
-- Number of alive neighbors of a position.
neighborsAlive :: Position -> Grid -> Int
neighborsAlive p g = length $ filter (== Alive) $ getNeighbors p g

getNeighbors :: Position -> Grid -> [Cell]
getNeighbors p g = catMaybes [M.lookup n g | n <- unbound (surrounding p) g]

unbound :: Structure -> Grid -> Structure
unbound s g = map around s
  where around (x, y) = (x `mod` mx, y `mod` my)
        (mx, my) = fst $ M.findMax g

-- Surrounding positions of some position.
-- Should returns a list of 8 Positions.
surrounding :: Position -> [Position]
surrounding (x, y) = nub $ delete (x, y) [ (m, n) | m <- near x, n <- near y] where
  near x' = [x' - 1, x', x' + 1]

-- Next state of a cell based on its environment.
step :: Position -> Cell -> Grid -> Cell
step p c g = let neighbors = neighborsAlive p g in
    case c of
      Alive -> stepAlive neighbors
      _     -> stepDead neighbors
  where
  stepAlive n
    | n `elem` [2, 3] = Alive
    | otherwise       = Dead
  stepDead n
    | n == 3    = Alive
    | otherwise = Dead 


-- Next generation.
tick :: Grid -> Grid
tick g = M.mapWithKey (\k v -> step k v g) g
