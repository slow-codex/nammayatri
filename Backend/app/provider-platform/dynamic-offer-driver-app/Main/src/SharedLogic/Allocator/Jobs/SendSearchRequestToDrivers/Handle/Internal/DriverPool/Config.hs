{-
 Copyright 2022-23, Juspay India Pvt Ltd

 This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License

 as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program

 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY

 or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of

 the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}

module SharedLogic.Allocator.Jobs.SendSearchRequestToDrivers.Handle.Internal.DriverPool.Config
  ( DriverPoolBatchesConfig (..),
    BatchSplitByPickupDistance (..),
    HasDriverPoolBatchesConfig,
    PoolSortingType (..),
    OnRideRadiusConfig (..),
    BatchSplitByPickupDistanceOnRide (..),
  )
where

import Database.Beam.Backend
import Kernel.Prelude
import Kernel.Utils.Common
import Kernel.Utils.Dhall (FromDhall)
import Tools.Beam.UtilsTH (mkBeamInstancesForEnum, mkBeamInstancesForList)

data BatchSplitByPickupDistance = BatchSplitByPickupDistance
  { batchSplitSize :: Int,
    batchSplitDelay :: Seconds
  }
  deriving stock (Show, Eq, Read, Ord, Generic)
  deriving anyclass (FromJSON, ToJSON, ToSchema)

data BatchSplitByPickupDistanceOnRide = BatchSplitByPickupDistanceOnRide
  { batchSplitSize :: Int,
    batchSplitDelay :: Seconds
  }
  deriving stock (Show, Eq, Read, Ord, Generic)
  deriving anyclass (ToJSON, FromJSON, ToSchema)

data OnRideRadiusConfig = OnRideRadiusConfig
  { onRideRadius :: Meters,
    batchNumber :: Int
  }
  deriving stock (Show, Eq, Read, Ord, Generic)
  deriving anyclass (ToJSON, FromJSON, ToSchema)

$(mkBeamInstancesForList ''BatchSplitByPickupDistance)
$(mkBeamInstancesForList ''BatchSplitByPickupDistanceOnRide)
$(mkBeamInstancesForList ''OnRideRadiusConfig)

data DriverPoolBatchesConfig = DriverPoolBatchesConfig
  { driverBatchSize :: Int,
    maxNumberOfBatches :: Int,
    poolSortingType :: PoolSortingType
  }
  deriving (Generic, FromDhall)

type HasDriverPoolBatchesConfig r =
  ( HasField "driverPoolBatchesCfg" r DriverPoolBatchesConfig
  )

data PoolSortingType = Intelligent | Random | Tagged
  deriving stock (Show, Eq, Read, Ord, Generic)
  deriving anyclass (FromJSON, ToJSON, FromDhall, ToSchema)

instance HasSqlValueSyntax be String => HasSqlValueSyntax be BatchSplitByPickupDistance where
  sqlValueSyntax = autoSqlValueSyntax

instance HasSqlValueSyntax be String => HasSqlValueSyntax be BatchSplitByPickupDistanceOnRide where
  sqlValueSyntax = autoSqlValueSyntax

instance HasSqlValueSyntax be String => HasSqlValueSyntax be OnRideRadiusConfig where
  sqlValueSyntax = autoSqlValueSyntax

$(mkBeamInstancesForEnum ''PoolSortingType)
