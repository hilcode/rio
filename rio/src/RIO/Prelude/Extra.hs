{-# LANGUAGE BangPatterns #-}
module RIO.Prelude.Extra
  ( mapLeft
  , fromFirst
  , mapMaybeA
  , mapMaybeM
  , forMaybeA
  , forMaybeM
  , foldMapM
  , nubOrd
  , whenM
  , unlessM
  , asIO
  ) where

import qualified Data.Set as Set
import Data.Monoid (First (..))
import Data.Foldable (foldlM)
import RIO.Prelude.Reexports

-- | Apply a function to a 'Left' constructor
mapLeft :: (a1 -> a2) -> Either a1 b -> Either a2 b
mapLeft f (Left a1) = Left (f a1)
mapLeft _ (Right b) = Right b

-- | Get a 'First' value with a default fallback
fromFirst :: a -> First a -> a
fromFirst x = fromMaybe x . getFirst

-- | Applicative 'mapMaybe'.
mapMaybeA :: Applicative f => (a -> f (Maybe b)) -> [a] -> f [b]
mapMaybeA f = fmap catMaybes . traverse f

-- | @'forMaybeA' '==' 'flip' 'mapMaybeA'@
forMaybeA :: Applicative f => [a] -> (a -> f (Maybe b)) -> f [b]
forMaybeA = flip mapMaybeA

-- | Monadic 'mapMaybe'.
mapMaybeM :: Monad m => (a -> m (Maybe b)) -> [a] -> m [b]
mapMaybeM f = liftM catMaybes . mapM f

-- | @'forMaybeM' '==' 'flip' 'mapMaybeM'@
forMaybeM :: Monad m => [a] -> (a -> m (Maybe b)) -> m [b]
forMaybeM = flip mapMaybeM

-- | Extend 'foldMap' to allow side effects.
--
-- Internally, this is implemented using a strict left fold. This is used for
-- performance reasons. It also necessitates that this function has a @Monad@
-- constraint and not just an @Applicative@ constraint. For more information,
-- see
-- <https://github.com/commercialhaskell/rio/pull/99#issuecomment-394179757>.
--
-- @since 0.1.3.0
foldMapM
  :: (Monad m, Monoid w, Foldable t)
  => (a -> m w)
  -> t a
  -> m w
foldMapM f = foldlM
  (\acc a -> do
    w <- f a
    return $! mappend acc w)
  mempty

-- | Strip out duplicates
nubOrd :: Ord a => [a] -> [a]
nubOrd =
  loop mempty
  where
    loop _ [] = []
    loop !s (a:as)
      | a `Set.member` s = loop s as
      | otherwise = a : loop (Set.insert a s) as

-- | Run the second value if the first value returns 'True'
whenM :: Monad m => m Bool -> m () -> m ()
whenM boolM action = do
  x <- boolM
  if x then action else return ()

-- | Run the second value if the first value returns 'False'
unlessM :: Monad m => m Bool -> m () -> m ()
unlessM boolM action = do
  x <- boolM
  if x then return () else action

-- | Helper function to force an action to run in 'IO'. Especially
-- useful for overly general contexts, like hspec tests.
--
-- @since 0.1.3.0
asIO :: IO a -> IO a
asIO = id
