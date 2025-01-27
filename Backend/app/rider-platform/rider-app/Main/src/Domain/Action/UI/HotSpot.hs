{-
 Copyright 2022-23, Juspay India Pvt Ltd

 This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License

 as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program

 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY

 or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of

 the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}

module Domain.Action.UI.HotSpot where

import Control.Lens
import Data.Default.Class
import qualified Data.Text as Dt
import Domain.Types.HotSpot
import Domain.Types.HotSpotConfig
import Domain.Types.LocationAddress as LA
import Domain.Types.Merchant hiding (updatedAt)
import qualified Environment ()
import Kernel.External.Maps
import Kernel.Prelude
import Kernel.Storage.Hedis
import Kernel.Types.Common hiding (id)
import Kernel.Types.Id
import Kernel.Utils.Common (CacheFlow, isExpired)
import Storage.CachedQueries.HotSpotConfig as QHotSpotConfig
import Storage.CachedQueries.Maps.LocationMapCache

frequencyUpdator ::
  ( CacheFlow m r,
    EsqDBFlow m r,
    HasField "hotSpotExpiry" r Seconds
  ) =>
  Id Merchant ->
  LatLong ->
  Maybe LA.LocationAddress ->
  TypeOfMovement ->
  Maybe HotSpotConfig ->
  m ()
frequencyUpdator merchantId latLong _ movement mbHotSpotConfig = do
  mbHotSpotConfig' <- maybe (QHotSpotConfig.findConfigByMerchantId merchantId) (pure . Just) mbHotSpotConfig
  case mbHotSpotConfig' of
    Just HotSpotConfig {..} -> when shouldTakeHotSpot do
      mbHotSpot <- convertToHotSpot latLong Nothing merchantId mbHotSpotConfig'
      now <- getCurrentTime
      case mbHotSpot of
        Just HotSpot {..} -> do
          mbTargetHotSpot :: Maybe [HotSpot] <- get (makeHotSpotKey $ Dt.take precisionToGetGeohash _geoHash)
          case mbTargetHotSpot of
            Just hotSpots -> do
              let filteredHotSpot = filter (\hotSpot -> Dt.pack (Dt.unpack hotSpot._geoHash) == _geoHash) hotSpots
              if not (null filteredHotSpot)
                then do
                  let updatedHotSpot =
                        map
                          ( \hotSpot ->
                              if Dt.pack (Dt.unpack hotSpot._geoHash) == _geoHash
                                then hotSpot & movementLens movement %~ (+ 1) & updatedAt ?~ now
                                else hotSpot
                          )
                          hotSpots
                  filterAndUpdateHotSpotWithExpiry (Dt.take precisionToGetGeohash _geoHash) updatedHotSpot hotSpotExpiry
                else do
                  expTime <- getSeconds <$> asks (.hotSpotExpiry)
                  let createdGeoHash = createGeoHash HotSpot {..} now
                  setExp (makeHotSpotKey $ Dt.take precisionToGetGeohash _geoHash) (hotSpots ++ [createdGeoHash]) expTime
            Nothing -> do
              expTime <- getSeconds <$> asks (.hotSpotExpiry)
              let createdGeoHash = createGeoHash HotSpot {..} now
              setExp (makeHotSpotKey $ Dt.take precisionToGetGeohash _geoHash) [createdGeoHash] expTime
        Nothing -> return ()
    Nothing -> return ()
  where
    createGeoHash :: HotSpot -> UTCTime -> HotSpot
    createGeoHash HotSpot {..} now =
      def
        & geoHash .~ _geoHash
        & centroidLatLong .~ _centroidLatLong
        & movementLens movement %~ (+ 1)
        & address .~ Nothing
        & updatedAt ?~ now

filterAndUpdateHotSpotWithExpiry ::
  ( CacheFlow m r,
    EsqDBFlow m r,
    HasField "hotSpotExpiry" r Seconds
  ) =>
  Text ->
  [HotSpot] ->
  Int ->
  m ()
filterAndUpdateHotSpotWithExpiry geohash hotSpots hotSpotExpiry = do
  expTime <- getSeconds <$> asks (.hotSpotExpiry)
  filterWithExpiry <-
    filterM
      ( \hotSpot -> case hotSpot._updatedAt of
          Just updatedAt_ -> not <$> isExpired (realToFrac hotSpotExpiry) updatedAt_
          Nothing -> return False
      )
      hotSpots
  setExp (makeHotSpotKey geohash) filterWithExpiry expTime
