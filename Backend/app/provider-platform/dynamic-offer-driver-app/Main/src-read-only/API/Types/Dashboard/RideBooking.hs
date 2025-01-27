{-# LANGUAGE StandaloneKindSignatures #-}
{-# OPTIONS_GHC -Wno-unused-imports #-}

module API.Types.Dashboard.RideBooking where

import qualified API.Types.Dashboard.RideBooking.Driver
import qualified API.Types.Dashboard.RideBooking.DriverRegistration
import qualified API.Types.Dashboard.RideBooking.Maps
import qualified API.Types.Dashboard.RideBooking.Ride
import qualified API.Types.Dashboard.RideBooking.Volunteer
import qualified Data.List
import Data.OpenApi (ToSchema)
import qualified Data.Singletons.TH
import EulerHS.Prelude
import qualified Text.Read
import qualified Text.Show

data RideBookingUserActionType
  = DRIVER API.Types.Dashboard.RideBooking.Driver.DriverUserActionType
  | DRIVER_REGISTRATION API.Types.Dashboard.RideBooking.DriverRegistration.DriverRegistrationUserActionType
  | MAPS API.Types.Dashboard.RideBooking.Maps.MapsUserActionType
  | RIDE API.Types.Dashboard.RideBooking.Ride.RideUserActionType
  | VOLUNTEER API.Types.Dashboard.RideBooking.Volunteer.VolunteerUserActionType
  deriving stock (Generic, Eq, Ord)
  deriving anyclass (ToJSON, FromJSON, ToSchema)

instance Text.Show.Show RideBookingUserActionType where
  show = \case
    DRIVER e -> "DRIVER/" <> show e
    DRIVER_REGISTRATION e -> "DRIVER_REGISTRATION/" <> show e
    MAPS e -> "MAPS/" <> show e
    RIDE e -> "RIDE/" <> show e
    VOLUNTEER e -> "VOLUNTEER/" <> show e

instance Text.Read.Read RideBookingUserActionType where
  readsPrec d' =
    Text.Read.readParen
      (d' > app_prec)
      ( \r ->
          [(DRIVER v1, r2) | r1 <- stripPrefix "DRIVER/" r, (v1, r2) <- Text.Read.readsPrec (app_prec + 1) r1]
            ++ [ ( DRIVER_REGISTRATION v1,
                   r2
                 )
                 | r1 <- stripPrefix "DRIVER_REGISTRATION/" r,
                   (v1, r2) <- Text.Read.readsPrec (app_prec + 1) r1
               ]
            ++ [ ( MAPS v1,
                   r2
                 )
                 | r1 <- stripPrefix "MAPS/" r,
                   ( v1,
                     r2
                     ) <-
                     Text.Read.readsPrec (app_prec + 1) r1
               ]
            ++ [ ( RIDE v1,
                   r2
                 )
                 | r1 <- stripPrefix "RIDE/" r,
                   ( v1,
                     r2
                     ) <-
                     Text.Read.readsPrec (app_prec + 1) r1
               ]
            ++ [ ( VOLUNTEER v1,
                   r2
                 )
                 | r1 <- stripPrefix "VOLUNTEER/" r,
                   ( v1,
                     r2
                     ) <-
                     Text.Read.readsPrec (app_prec + 1) r1
               ]
      )
    where
      app_prec = 10
      stripPrefix pref r = bool [] [Data.List.drop (length pref) r] $ Data.List.isPrefixOf pref r

$(Data.Singletons.TH.genSingletons [''RideBookingUserActionType])
