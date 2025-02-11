{-
 
  Copyright 2022-23, Juspay India Pvt Ltd
 
  This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License
 
  as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program
 
  is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 
  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of
 
  the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}
module ConfigProvider (
  module ConfigProvider,
  module ReExport) where

import Prelude
import Constants as ReExport
import Data.Function.Uncurried (Fn1)
import Effect (Effect)
import Effect.Uncurried (EffectFn1, EffectFn2, mkEffectFn1, mkEffectFn2, runEffectFn1, runEffectFn2)
import Data.Function.Uncurried (Fn1)
import Foreign (Foreign, unsafeToForeign)
import Foreign.Generic (encode)
import MerchantConfig.DefaultConfig as DefaultConfig
import MerchantConfig.Types (AppConfig(..))
import Data.Function.Uncurried (Fn2, Fn3, runFn2, runFn3)
import Presto.Core.Types.Language.Flow (Flow)
import Common.Types.App (FlowBT)
import Engineering.Helpers.Commons (liftFlow)
import Control.Monad.Except.Trans (lift)
import Data.Maybe
import Log
import DecodeUtil

foreign import mergeforegin :: Array Foreign -> Foreign

foreign import evalJSString :: String -> String

foreign import isDebugBuild :: Unit -> Boolean

foreign import loadInWindow :: forall a. Fn2 String a Unit

foreign import loadFileInDUI :: String -> String

foreign import getAppConfigFromWindow :: Fn3 String (Maybe AppConfig) (AppConfig -> (Maybe AppConfig)) (Maybe AppConfig) 

loadAppConfig :: String -> AppConfig
loadAppConfig _ =
  let defaultConfig = encode DefaultConfig.config
      merchantConfig = getConfigFromFile ReExport.configuration_file
      
      mergedConfig = mergeObjects $ [ defaultConfig] <> merchantConfig
      decodeAppConfig = decodeForeignObject mergedConfig DefaultConfig.config
      _ = runFn2 loadInWindow ReExport.appConfig mergedConfig
      _ = runFn2 (loadInWindow :: Fn2 String AppConfig Unit) ReExport.decodeAppConfig decodeAppConfig
  in decodeAppConfig

getConfigFromFile :: String -> Array Foreign
getConfigFromFile fileName = do
  let config = loadFileInDUI $ fileName <> ReExport.dotJSA
  if isFilePresent config 
    then 
      [encode $ evalJSString config]
    else do
      let jsConfig = getConfigFromJS fileName
      if isFilePresent jsConfig 
        then do
          [encode $ evalJSString jsConfig]
        else 
          let _ = printLog "File Not found" $ fileName <> " is not present"
          in []

-- First element is base object and priority increses with increase in descendants. Keys in high priority elements will be overrided in base object.
mergeObjects :: Array Foreign -> Foreign
mergeObjects = mergeforegin

getConfigFromJS :: String -> String
getConfigFromJS fileName = loadFileInDUI $ fileName <> ReExport.dotJS

isFilePresent :: String -> Boolean
isFilePresent file = file /= "" && file /= "undefined"

-- Decode AppConfig Decode Utils
getAppConfigFlowBT :: forall st. String -> FlowBT String st AppConfig
getAppConfigFlowBT = lift <<< lift <<< getAppConfigFlow

getAppConfigFlow :: forall st. String -> Flow st AppConfig
getAppConfigFlow = liftFlow <<< runEffectFn1 getAppConfigEff

getAppConfigEff :: EffectFn1 String AppConfig
getAppConfigEff = mkEffectFn1 \key -> pure $ getAppConfig key

getAppConfig :: String -> AppConfig
getAppConfig _ = do 
  let
    mBconfig = runFn3 getAppConfigFromWindow ReExport.decodeAppConfig Nothing Just
  case mBconfig of
      Nothing -> loadAppConfig ""
      Just config -> config

getCurrency :: String -> String
getCurrency key = (getAppConfig key).currency