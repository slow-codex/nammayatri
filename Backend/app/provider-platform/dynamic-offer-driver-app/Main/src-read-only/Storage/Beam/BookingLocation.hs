{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -Wno-unused-imports #-}

module Storage.Beam.BookingLocation where

import qualified Database.Beam as B
import Kernel.External.Encryption
import Kernel.Prelude
import qualified Kernel.Prelude
import Tools.Beam.UtilsTH

data BookingLocationT f = BookingLocationT
  { area :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.Text),
    areaCode :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.Text),
    building :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.Text),
    city :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.Text),
    country :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.Text),
    door :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.Text),
    state :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.Text),
    street :: B.C f (Kernel.Prelude.Maybe Kernel.Prelude.Text),
    createdAt :: B.C f Kernel.Prelude.UTCTime,
    id :: B.C f Kernel.Prelude.Text,
    lat :: B.C f Kernel.Prelude.Double,
    lon :: B.C f Kernel.Prelude.Double,
    updatedAt :: B.C f Kernel.Prelude.UTCTime
  }
  deriving (Generic, B.Beamable)

instance B.Table BookingLocationT where
  data PrimaryKey BookingLocationT f = BookingLocationId (B.C f Kernel.Prelude.Text) deriving (Generic, B.Beamable)
  primaryKey = BookingLocationId . id

type BookingLocation = BookingLocationT Identity

$(enableKVPG ''BookingLocationT ['id] [])

$(mkTableInstances ''BookingLocationT "booking_location")