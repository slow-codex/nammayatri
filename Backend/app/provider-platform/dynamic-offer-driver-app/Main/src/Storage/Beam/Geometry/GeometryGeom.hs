{-
  Copyright 2022-23, Juspay India Pvt Ltd

  This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License

  as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program

  is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY

  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of

  the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}

module Storage.Beam.Geometry.GeometryGeom where

import qualified Database.Beam as B
import Kernel.Prelude
import qualified Kernel.Types.Beckn.Context as Context
import Tools.Beam.UtilsTH

data GeometryGeomT f = GeometryGeomT
  { id :: B.C f Text,
    city :: B.C f Context.City,
    state :: B.C f Context.IndianState,
    region :: B.C f Text,
    geom :: B.C f (Maybe Text)
  }
  deriving (Generic, B.Beamable)

instance B.Table GeometryGeomT where
  data PrimaryKey GeometryGeomT f
    = Id (B.C f Text)
    deriving (Generic, B.Beamable)
  primaryKey = Id . id

type GeometryGeom = GeometryGeomT Identity

$(enableKVPG ''GeometryGeomT ['id] [])

$(mkTableInstances ''GeometryGeomT "geometry")
