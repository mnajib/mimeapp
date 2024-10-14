{-# LANGUAGE OverloadedStrings #-}

-- module MimeManager where
module Main where

import Control.Applicative (liftA2)
import Control.Monad (forM_)
import Data.List (nub, sort)
import Data.Maybe (fromMaybe)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import System.Directory (doesFileExist, listDirectory)
import System.FilePath ((</>))

-- | Path to the user's.local directory
localDir :: FilePath
localDir = "/home/najib/.local"

-- | Path to the mimeapps.list file
mimeAppsListFile :: FilePath
mimeAppsListFile = localDir </> "share/applications/mimeapps.list"

-- | Path to the desktop files directory
desktopFilesDir :: FilePath
desktopFilesDir = localDir </> "share/applications"

-- | List all added match filetypes to applications
listAddedMatchFiletypes :: IO ()
listAddedMatchFiletypes = do
  mimeAppsListContent <- TIO.readFile mimeAppsListFile
  let matches = parseMimeAppsList mimeAppsListContent
  forM_ matches $ \(ftype, app) -> putStrLn $ T.unpack ftype ++ " -> " ++ T.unpack app

-- | List all added match filetypes to applications (short version)
listAddedMatchFiletypesShort :: IO ()
listAddedMatchFiletypesShort = do
  mimeAppsListContent <- TIO.readFile mimeAppsListFile
  let matches = parseMimeAppsList mimeAppsListContent
  mapM_ (putStrLn. T.unpack. fst) matches

-- | Parse the mimeapps.list file and return a list of tuples (filetype, application)
parseMimeAppsList :: T.Text -> [(T.Text, T.Text)]
parseMimeAppsList content = map parseMatch $ T.lines content
  where
    parseMatch line = case T.splitOn "=" line of
      [ftype, app] -> (ftype, app)
      _ -> ("", "")

-- | List all desktop files in the desktop files directory
listDesktopFiles :: IO ()
listDesktopFiles = do
  files <- listDirectory desktopFilesDir
  forM_ files $ putStrLn

main :: IO ()
main = do
  putStrLn "Mime Manager"
  putStrLn "------------"
  putStrLn "1. List added match filetypes to applications"
  putStrLn "2. List added match filetypes to applications (short version)"
  putStrLn "3. List desktop files"
  putStrLn "Choose an option: "
  option <- getLine
  case option of
    "1" -> listAddedMatchFiletypes
    "2" -> listAddedMatchFiletypesShort
    "3" -> listDesktopFiles
    _ -> putStrLn "Invalid option"
