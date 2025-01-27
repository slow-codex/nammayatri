{-
 Copyright 2022-23, Juspay India Pvt Ltd

 This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License

 as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program

 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY

 or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of

 the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}

module Domain.Action.Dashboard.Management.Booking
  ( postBookingCancelAllStuck,
    postBookingSyncMultiple,
  )
where

import qualified "dashboard-helper-api" Dashboard.Common.Booking as Common
import Data.Coerce (coerce)
import qualified Data.HashMap.Internal as HashMap
import qualified Domain.Types.Booking as DBooking
import qualified Domain.Types.BookingCancellationReason as DBCR
import qualified Domain.Types.CancellationReason as DCR
import qualified Domain.Types.Merchant as DM
import qualified Domain.Types.MerchantOperatingCity as DMOC
import qualified Domain.Types.Person as DP
import qualified Domain.Types.Ride as DRide
import Environment
import Kernel.Beam.Functions as B
import Kernel.Prelude
import qualified Kernel.Types.Beckn.Context as Context
import Kernel.Types.Error
import Kernel.Types.Id
import Kernel.Utils.Common
import Kernel.Utils.Validation (runRequestValidation)
import SharedLogic.Merchant (findMerchantByShortId)
import qualified SharedLogic.SyncRide as SyncRide
import qualified Storage.CachedQueries.Merchant.MerchantOperatingCity as CQMOC
import qualified Storage.Queries.Booking as QBooking
import qualified Storage.Queries.BookingCancellationReason as QBCR
import qualified Storage.Queries.DriverInformation as QDrInfo
import qualified Storage.Queries.Ride as QRide

---------------------------------------------------------------------

-- cancel all stuck bookings/rides:
--   bookings, when status is NEW for more than 6 hours
--   bookings and rides, when ride status is NEW for more than 6 hours

postBookingCancelAllStuck ::
  ShortId DM.Merchant ->
  Context.City ->
  Common.StuckBookingsCancelReq ->
  Flow Common.StuckBookingsCancelRes
postBookingCancelAllStuck merchantShortId opCity req = do
  merchant <- findMerchantByShortId merchantShortId
  mbMerchantOpCity <- CQMOC.findByMerchantIdAndCity merchant.id opCity
  merchantOpCity <- fromMaybeM (MerchantOperatingCityNotFound $ "merchant-Id-" <> merchant.id.getId <> "-city-" <> show opCity) mbMerchantOpCity
  let reqBookingIds = cast @Common.Booking @DBooking.Booking <$> req.bookingIds
      distanceUnit = merchantOpCity.distanceUnit
  now <- getCurrentTime
  stuckBookingIds <- B.runInReplica $ QBooking.findStuckBookings merchant merchantOpCity reqBookingIds now
  stuckRideItems <- B.runInReplica $ QRide.findStuckRideItems merchant merchantOpCity reqBookingIds now
  let bcReasons = mkBookingCancellationReason merchant.id (DMOC.id <$> mbMerchantOpCity) Common.bookingStuckCode Nothing distanceUnit <$> stuckBookingIds
  let bcReasonsWithRides = (\item -> mkBookingCancellationReason merchant.id (DMOC.id <$> mbMerchantOpCity) Common.rideStuckCode (Just item.rideId) distanceUnit item.bookingId) <$> stuckRideItems
  let allStuckBookingIds = stuckBookingIds <> (stuckRideItems <&> (.bookingId))
  let stuckPersonIds = stuckRideItems <&> (.driverId)
  let stuckDriverIds = cast @DP.Person @DP.Driver <$> stuckPersonIds
  -- drivers going out of ride, update location from redis to db
  QRide.updateStatusByIds (stuckRideItems <&> (.rideId)) DRide.CANCELLED
  QBooking.cancelBookings allStuckBookingIds now
  for_ (bcReasons <> bcReasonsWithRides) QBCR.upsert
  QDrInfo.updateNotOnRideMultiple stuckDriverIds
  logTagInfo "dashboard -> stuckBookingsCancel: " $ show allStuckBookingIds
  pure $ mkStuckBookingsCancelRes stuckBookingIds stuckRideItems

mkBookingCancellationReason :: Id DM.Merchant -> Maybe (Id DMOC.MerchantOperatingCity) -> Common.CancellationReasonCode -> Maybe (Id DRide.Ride) -> DistanceUnit -> Id DBooking.Booking -> DBCR.BookingCancellationReason
mkBookingCancellationReason merchantId mbMerchantOperatingCityId reasonCode mbRideId distanceUnit bookingId = do
  DBCR.BookingCancellationReason
    { bookingId = bookingId,
      rideId = mbRideId,
      merchantId = Just merchantId,
      source = DBCR.ByMerchant,
      reasonCode = Just $ coerce @Common.CancellationReasonCode @DCR.CancellationReasonCode reasonCode,
      driverId = Nothing,
      additionalInfo = Nothing,
      driverCancellationLocation = Nothing,
      driverDistToPickup = Nothing,
      distanceUnit,
      merchantOperatingCityId = mbMerchantOperatingCityId
    }

mkStuckBookingsCancelRes :: [Id DBooking.Booking] -> [QRide.StuckRideItem] -> Common.StuckBookingsCancelRes
mkStuckBookingsCancelRes stuckBookingIds stuckRideItems = do
  let bookingItems = (stuckBookingIds <&>) $ \bookingId -> do
        Common.StuckBookingItem
          { rideId = Nothing,
            bookingId = cast @DBooking.Booking @Common.Booking bookingId
          }
  let rideItems = (stuckRideItems <&>) $ \QRide.StuckRideItem {..} -> do
        Common.StuckBookingItem
          { rideId = Just $ cast @DRide.Ride @Common.Ride rideId,
            bookingId = cast @DBooking.Booking @Common.Booking bookingId
          }
  Common.StuckBookingsCancelRes
    { cancelledBookings = rideItems <> bookingItems
    }

---------------------------------------------------------------------
postBookingSyncMultiple ::
  ShortId DM.Merchant ->
  Context.City ->
  Common.MultipleBookingSyncReq ->
  Flow Common.MultipleBookingSyncResp
postBookingSyncMultiple merchantShortId opCity req = do
  runRequestValidation Common.validateMultipleBookingSyncReq req
  merchant <- findMerchantByShortId merchantShortId
  merchantOpCity <- CQMOC.findByMerchantIdAndCity merchant.id opCity >>= fromMaybeM (MerchantOperatingCityNotFound $ "merchant-Id-" <> merchant.id.getId <> "-city-" <> show opCity)
  let reqBookingIds = cast @Common.Booking @DBooking.Booking . (.bookingId) <$> req.bookings
      distanceUnit = merchantOpCity.distanceUnit
  rideBookingsMap <- B.runInReplica $ QRide.findRideBookingsById merchant merchantOpCity reqBookingIds
  respItems <- forM req.bookings $ \reqItem -> do
    info <- handle Common.listItemErrHandler $ do
      let bookingId = cast @Common.Booking @DBooking.Booking reqItem.bookingId
      let mbRideBooking = HashMap.lookup (getId bookingId) rideBookingsMap
      case mbRideBooking of
        Nothing -> throwError (BookingDoesNotExist bookingId.getId)
        Just (booking, mbRide) -> do
          case mbRide of
            Just ride -> do
              let bookingNewStatus = case ride.status of
                    DRide.UPCOMING -> DBooking.TRIP_ASSIGNED
                    DRide.NEW -> DBooking.TRIP_ASSIGNED
                    DRide.INPROGRESS -> DBooking.TRIP_ASSIGNED
                    DRide.COMPLETED -> DBooking.COMPLETED
                    DRide.CANCELLED -> DBooking.CANCELLED
              let mbCancellationReason =
                    if bookingNewStatus == DBooking.CANCELLED && booking.status /= DBooking.CANCELLED
                      then Just $ mkBookingCancellationReason merchant.id (Just merchantOpCity.id) Common.syncBookingCode (Just ride.id) distanceUnit bookingId
                      else Nothing
              unless (bookingNewStatus == booking.status) $ do
                QBooking.updateStatus bookingId bookingNewStatus
                whenJust mbCancellationReason QBCR.upsert
              let updBooking = booking{status = bookingNewStatus}
              void $ SyncRide.rideSync (mbCancellationReason <&> (.source)) (Just ride) updBooking merchant
            Nothing -> do
              let mbCancellationReason =
                    if booking.status /= DBooking.CANCELLED
                      then Just $ mkBookingCancellationReason merchant.id (Just merchantOpCity.id) Common.syncBookingCodeWithNoRide Nothing distanceUnit bookingId
                      else Nothing
              when (booking.status /= DBooking.CANCELLED) $ do
                QBooking.updateStatus bookingId DBooking.CANCELLED
                whenJust mbCancellationReason QBCR.upsert
              let updBooking = booking{status = DBooking.CANCELLED}
              void $ SyncRide.rideSync (mbCancellationReason <&> (.source)) Nothing updBooking merchant
          pure Common.SuccessItem
    pure $ Common.MultipleBookingSyncRespItem {bookingId = reqItem.bookingId, info}
  logTagInfo "dashboard -> multipleBookingSync: " $ show reqBookingIds
  pure $ Common.MultipleBookingSyncResp {list = respItems}
