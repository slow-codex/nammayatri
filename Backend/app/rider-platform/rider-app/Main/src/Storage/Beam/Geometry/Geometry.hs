{-
  Copyright 2022-23, Juspay India Pvt Ltd

  This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License

  as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program

  is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY

  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of

  the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}

module Storage.Beam.Geometry.Geometry where

import qualified Database.Beam as B
import Kernel.Prelude
import Kernel.Types.Beckn.Context (City, IndianState)
import Tools.Beam.UtilsTH

data GeometryT f = GeometryT
  { id :: B.C f Text,
    region :: B.C f Text,
    state :: B.C f IndianState,
    city :: B.C f City
  }
  deriving (Generic, B.Beamable)

instance B.Table GeometryT where
  data PrimaryKey GeometryT f
    = Id (B.C f Text)
    deriving (Generic, B.Beamable)
  primaryKey = Id . id

type Geometry = GeometryT Identity

$(enableKVPG ''GeometryT ['id] [])

$(mkTableInstances ''GeometryT "geometry")
