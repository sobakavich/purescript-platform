module Platform
  ( Platform(..)
  , PLATFORM
  , Os(..)
  , Prerelease(..)
  , OsRec
  , PlatformRec
  , runOs
  , runPlatform
  , getPlatform
  , parse
  ) where

import Prelude
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Class (class MonadEff, liftEff)
import Control.Monad.Except (runExcept, throwError)

import Data.Either (either, Either(..))
import Data.Foldable as F
import Data.Foreign (readString, Foreign, ForeignError(TypeMismatch), F)
import Data.Foreign.Class (class IsForeign, read, readProp)
import Data.Foreign.Null (unNull)
import Data.Maybe (Maybe(..))
import Data.List.NonEmpty as NEL

foreign import data PLATFORM ∷ !

type OsRec =
  { architecture ∷ Maybe Int
  , family ∷ Maybe String
  , version ∷ Maybe String
  }

newtype Os = Os OsRec
runOs ∷ Os → OsRec
runOs (Os r) = r


instance isForeignOs ∷ IsForeign Os where
  read f =
    map Os $
      { architecture: _
      , family: _
      , version: _
      }
      <$> readMaybeNull "architecture" f
      <*> readMaybeNull "family" f
      <*> readMaybeNull "version" f

instance showOs ∷ Show Os where
  show (Os r) =
    "(Os \n"
      <> "{ architecture = " <> show r.architecture <> ",\n"
      <> "  family = " <> show r.family <> ",\n"
      <> "  version = " <> show r.version <> "})"

instance eqOs :: Eq Os where
  eq (Os r1) (Os r2) =
    F.and
      [ r1.architecture == r2.architecture
      , r1.family == r2.family
      , r1.version == r2.version
      ]

data Prerelease
  = Alpha
  | Beta

derive instance eqPrerelease ∷ Eq Prerelease

instance showPrerelease ∷ Show Prerelease where
  show Alpha = "Alpha"
  show Beta = "Beta"

instance isForeignPrerelease ∷ IsForeign Prerelease where
  read f =
    readString f >>= case _ of
      "alpha" → pure Alpha
      "beta" → pure Beta
      _ → throwError $ NEL.singleton $ TypeMismatch "prerelease" "string"

type PlatformRec =
  { description ∷ Maybe String
  , layout ∷ Maybe String
  , manufacturer ∷ Maybe String
  , name ∷ Maybe String
  , prerelease ∷ Maybe Prerelease
  , product ∷ Maybe String
  , ua ∷ Maybe String
  , version ∷ Maybe String
  , os ∷ Os
  }

newtype Platform = Platform PlatformRec

runPlatform ∷ Platform → PlatformRec
runPlatform (Platform r) = r

instance showPlatform ∷ Show Platform where
  show (Platform r) =
    "(Platform \n"
      <> " {description = " <> show r.description <> ",\n"
      <> "  layout = " <> show r.layout <> ",\n"
      <> "  manufacturer = " <> show r.manufacturer <> ",\n"
      <> "  name = " <> show r.name <> ",\n"
      <> "  prerelease = " <> show r.prerelease <> ",\n"
      <> "  product = " <> show r.product <> ",\n"
      <> "  ua = " <> show r.ua <> ",\n"
      <> "  version = " <> show r.version <> ",\n"
      <> "  os = " <> show r.os <> "})"

instance eqPlatform ∷ Eq Platform where
  eq (Platform r1) (Platform r2) =
    F.and
      [ r1.description == r2.description
      , r1.layout == r2.layout
      , r1.manufacturer == r2.manufacturer
      , r1.name == r2.name
      , r1.prerelease == r2.prerelease
      , r1.product == r2.product
      , r1.ua == r2.ua
      , r1.version == r2.version
      , r1.os == r2.os
      ]

instance isForeignPlatform ∷ IsForeign Platform where
  read f =
    map Platform $
      { description: _
      , layout: _
      , manufacturer: _
      , name: _
      , prerelease: _
      , product: _
      , ua: _
      , version: _
      , os: _
      }
      <$> readMaybeNull "description" f
      <*> readMaybeNull "layout" f
      <*> readMaybeNull "manufacturer" f
      <*> readMaybeNull "name" f
      <*> readMaybeNull "prerelease" f
      <*> readMaybeNull "product" f
      <*> readMaybeNull "ua" f
      <*> readMaybeNull "version" f
      <*> readProp "os" f

readMaybeNull ∷ forall a. (IsForeign a) ⇒ String → Foreign → F (Maybe a)
readMaybeNull key f = map unNull $ readProp key f

foreign import getPlatform_ ∷ forall e. Eff (platform ∷ PLATFORM | e) Foreign

getPlatform
  ∷ forall m e
  . (Monad m, MonadEff (platform ∷ PLATFORM | e) m)
  ⇒ m (Maybe Platform)
getPlatform = do
  f ← liftEff getPlatform_
  pure $ case runExcept $ read f of
    Left _ → Nothing
    Right p → Just p


foreign import parse_ ∷ String → Foreign

parse ∷ String → Maybe Platform
parse str = either (const Nothing) Just $ runExcept $ read $ parse_ str
