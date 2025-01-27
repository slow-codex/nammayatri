{-
 Copyright 2022-23, Juspay India Pvt Ltd

 This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License

 as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program

 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY

 or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of

 the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}
{-# LANGUAGE DerivingVia #-}

module Tools.Payment
  ( module Reexport,
    createOrder,
    orderStatus,
    refundOrder,
    PaymentServiceType (..),
    createCustomer,
    createEphemeralKeys,
    getCardList,
    createPaymentIntent,
    updatePaymentMethodInIntent,
    capturePaymentIntent,
    updateAmountInPaymentIntent,
    createSetupIntent,
    deleteCard,
    getPaymentIntent,
    cancelPaymentIntent,
    verifyVpa,
  )
where

import Control.Applicative ((<|>))
import Data.Aeson
import qualified Domain.Types.Merchant as DM
import qualified Domain.Types.MerchantOperatingCity as DMOC
import qualified Domain.Types.MerchantServiceConfig as DMSC
import qualified Domain.Types.MerchantServiceUsageConfig as DMSUC
import Domain.Types.TicketPlace
import Kernel.External.Payment.Interface as Reexport hiding
  ( autoRefunds,
    cancelPaymentIntent,
    capturePaymentIntent,
    createCustomer,
    createEphemeralKeys,
    createOrder,
    createPaymentIntent,
    createSetupIntent,
    deleteCard,
    getCardList,
    getPaymentIntent,
    orderStatus,
    updateAmountInPaymentIntent,
    updatePaymentMethodInIntent,
  )
import qualified Kernel.External.Payment.Interface as Payment
import Kernel.External.Types (ServiceFlow)
import Kernel.Prelude
import Kernel.Types.Error
import Kernel.Types.Id
import Kernel.Utils.Common
import Kernel.Utils.TH (mkHttpInstancesForEnum)
import qualified Storage.CachedQueries.Merchant.MerchantServiceConfig as CQMSC
import qualified Storage.CachedQueries.Merchant.MerchantServiceUsageConfig as CQMSUC
import qualified Storage.CachedQueries.PlaceBasedServiceConfig as CQPBSC

createOrder :: ServiceFlow m r => Id DM.Merchant -> Id DMOC.MerchantOperatingCity -> Maybe (Id TicketPlace) -> PaymentServiceType -> Payment.CreateOrderReq -> m Payment.CreateOrderResp
createOrder = runWithServiceConfigAndServiceName Payment.createOrder

orderStatus :: ServiceFlow m r => Id DM.Merchant -> Id DMOC.MerchantOperatingCity -> Maybe (Id TicketPlace) -> PaymentServiceType -> Payment.OrderStatusReq -> m Payment.OrderStatusResp
orderStatus = runWithServiceConfigAndServiceName Payment.orderStatus

refundOrder :: ServiceFlow m r => Id DM.Merchant -> Id DMOC.MerchantOperatingCity -> Maybe (Id TicketPlace) -> PaymentServiceType -> Payment.AutoRefundReq -> m Payment.AutoRefundResp
refundOrder = runWithServiceConfigAndServiceName Payment.autoRefunds

verifyVpa :: ServiceFlow m r => Id DM.Merchant -> Id DMOC.MerchantOperatingCity -> Maybe (Id TicketPlace) -> PaymentServiceType -> Payment.VerifyVPAReq -> m Payment.VerifyVPAResp
verifyVpa = runWithServiceConfigAndServiceName Payment.verifyVPA

---- Ride Payment Related Functions (mostly stripe) ---
createCustomer :: ServiceFlow m r => Id DM.Merchant -> Id DMOC.MerchantOperatingCity -> CreateCustomerReq -> m CreateCustomerResp
createCustomer = runWithServiceConfig1 Payment.createCustomer (.createPaymentCustomer)

createEphemeralKeys :: ServiceFlow m r => Id DM.Merchant -> Id DMOC.MerchantOperatingCity -> CustomerId -> m Text
createEphemeralKeys = runWithServiceConfig1 Payment.createEphemeralKeys (.createEphemeralKeys)

getCardList :: ServiceFlow m r => Id DM.Merchant -> Id DMOC.MerchantOperatingCity -> CustomerId -> m CustomerCardListResp
getCardList = runWithServiceConfig1 Payment.getCardList (.getCardList)

createPaymentIntent :: ServiceFlow m r => Id DM.Merchant -> Id DMOC.MerchantOperatingCity -> CreatePaymentIntentReq -> m CreatePaymentIntentResp
createPaymentIntent = runWithServiceConfig1 Payment.createPaymentIntent (.createPaymentIntent)

cancelPaymentIntent :: ServiceFlow m r => Id DM.Merchant -> Id DMOC.MerchantOperatingCity -> PaymentIntentId -> m CreatePaymentIntentResp
cancelPaymentIntent = runWithServiceConfig1 Payment.cancelPaymentIntent (.cancelPaymentIntent)

getPaymentIntent :: ServiceFlow m r => Id DM.Merchant -> Id DMOC.MerchantOperatingCity -> PaymentIntentId -> m CreatePaymentIntentResp
getPaymentIntent = runWithServiceConfig1 Payment.getPaymentIntent (.createPaymentIntent)

updatePaymentMethodInIntent :: ServiceFlow m r => Id DM.Merchant -> Id DMOC.MerchantOperatingCity -> PaymentIntentId -> PaymentMethodId -> m ()
updatePaymentMethodInIntent = runWithServiceConfig2 Payment.updatePaymentMethodInIntent (.updatePaymentMethodInIntent)

capturePaymentIntent :: ServiceFlow m r => Id DM.Merchant -> Id DMOC.MerchantOperatingCity -> PaymentIntentId -> HighPrecMoney -> HighPrecMoney -> m ()
capturePaymentIntent = runWithServiceConfig3 Payment.capturePaymentIntent (.capturePaymentIntent)

updateAmountInPaymentIntent :: ServiceFlow m r => Id DM.Merchant -> Id DMOC.MerchantOperatingCity -> PaymentIntentId -> HighPrecMoney -> HighPrecMoney -> m ()
updateAmountInPaymentIntent = runWithServiceConfig3 Payment.updateAmountInPaymentIntent (.updateAmountInPaymentIntent)

createSetupIntent :: ServiceFlow m r => Id DM.Merchant -> Id DMOC.MerchantOperatingCity -> CustomerId -> m CreateSetupIntentResp
createSetupIntent = runWithServiceConfig1 Payment.createSetupIntent (.createSetupIntent)

deleteCard :: ServiceFlow m r => Id DM.Merchant -> Id DMOC.MerchantOperatingCity -> PaymentMethodId -> m ()
deleteCard = runWithServiceConfig1 Payment.deleteCard (.deleteCard)

runWithServiceConfigAndServiceName ::
  ServiceFlow m r =>
  (Payment.PaymentServiceConfig -> req -> m resp) ->
  Id DM.Merchant ->
  Id DMOC.MerchantOperatingCity ->
  Maybe (Id TicketPlace) ->
  PaymentServiceType ->
  req ->
  m resp
runWithServiceConfigAndServiceName func merchantId merchantOperatingCityId mbPlaceId paymentServiceType req = do
  placeBasedConfig <- case mbPlaceId of
    Just id -> CQPBSC.findByPlaceIdAndServiceName id (DMSC.PaymentService Payment.Juspay)
    Nothing -> return Nothing
  merchantServiceConfig <-
    CQMSC.findByMerchantOpCityIdAndService merchantId merchantOperatingCityId (getPaymentServiceByType paymentServiceType)
      >>= fromMaybeM (MerchantServiceConfigNotFound merchantId.getId "Payment" (show Payment.Juspay))
  case (placeBasedConfig <&> (.serviceConfig)) <|> Just merchantServiceConfig.serviceConfig of
    Just (DMSC.PaymentServiceConfig vsc) -> func vsc req
    Just (DMSC.MetroPaymentServiceConfig vsc) -> func vsc req
    Just (DMSC.BusPaymentServiceConfig vsc) -> func vsc req
    Just (DMSC.BbpsPaymentServiceConfig vsc) -> func vsc req
    Just (DMSC.MultiModalPaymentServiceConfig vsc) -> func vsc req
    _ -> throwError $ InternalError "Unknown Service Config"
  where
    getPaymentServiceByType = \case
      Normal -> DMSC.PaymentService Payment.Juspay
      BBPS -> DMSC.BbpsPaymentService Payment.Juspay
      FRFSBooking -> DMSC.MetroPaymentService Payment.Juspay
      FRFSBusBooking -> DMSC.BusPaymentService Payment.Juspay
      FRFSMultiModalBooking -> DMSC.MultiModalPaymentService Payment.Juspay

runWithServiceConfig1 ::
  ServiceFlow m r =>
  (Payment.PaymentServiceConfig -> req -> m resp) ->
  (DMSUC.MerchantServiceUsageConfig -> PaymentService) ->
  Id DM.Merchant ->
  Id DMOC.MerchantOperatingCity ->
  req ->
  m resp
runWithServiceConfig1 func getCfg merchantId merchantOperatingCityId req = do
  merchantConfig <- CQMSUC.findByMerchantOperatingCityId merchantOperatingCityId >>= fromMaybeM (MerchantServiceUsageConfigNotFound merchantOperatingCityId.getId)
  merchantPaymentServiceConfig <-
    CQMSC.findByMerchantOpCityIdAndService merchantId merchantOperatingCityId (DMSC.PaymentService $ getCfg merchantConfig)
      >>= fromMaybeM (MerchantServiceConfigNotFound merchantId.getId "Payment" (show $ getCfg merchantConfig))
  case merchantPaymentServiceConfig.serviceConfig of
    DMSC.PaymentServiceConfig msc -> func msc req
    _ -> throwError $ InternalError "Unknown Service Config"

runWithServiceConfig2 ::
  ServiceFlow m r =>
  (Payment.PaymentServiceConfig -> req1 -> req2 -> m resp) ->
  (DMSUC.MerchantServiceUsageConfig -> PaymentService) ->
  Id DM.Merchant ->
  Id DMOC.MerchantOperatingCity ->
  req1 ->
  req2 ->
  m resp
runWithServiceConfig2 func getCfg merchantId merchantOperatingCityId req1 req2 = do
  merchantConfig <- CQMSUC.findByMerchantOperatingCityId merchantOperatingCityId >>= fromMaybeM (MerchantServiceUsageConfigNotFound merchantOperatingCityId.getId)
  merchantPaymentServiceConfig <-
    CQMSC.findByMerchantOpCityIdAndService merchantId merchantOperatingCityId (DMSC.PaymentService $ getCfg merchantConfig)
      >>= fromMaybeM (MerchantServiceConfigNotFound merchantId.getId "Payment" (show $ getCfg merchantConfig))
  case merchantPaymentServiceConfig.serviceConfig of
    DMSC.PaymentServiceConfig msc -> func msc req1 req2
    _ -> throwError $ InternalError "Unknown Service Config"

runWithServiceConfig3 ::
  ServiceFlow m r =>
  (Payment.PaymentServiceConfig -> req1 -> req2 -> req3 -> m resp) ->
  (DMSUC.MerchantServiceUsageConfig -> PaymentService) ->
  Id DM.Merchant ->
  Id DMOC.MerchantOperatingCity ->
  req1 ->
  req2 ->
  req3 ->
  m resp
runWithServiceConfig3 func getCfg merchantId merchantOperatingCityId req1 req2 req3 = do
  merchantConfig <- CQMSUC.findByMerchantOperatingCityId merchantOperatingCityId >>= fromMaybeM (MerchantServiceUsageConfigNotFound merchantOperatingCityId.getId)
  merchantPaymentServiceConfig <-
    CQMSC.findByMerchantOpCityIdAndService merchantId merchantOperatingCityId (DMSC.PaymentService $ getCfg merchantConfig)
      >>= fromMaybeM (MerchantServiceConfigNotFound merchantId.getId "Payment" (show $ getCfg merchantConfig))
  case merchantPaymentServiceConfig.serviceConfig of
    DMSC.PaymentServiceConfig msc -> func msc req1 req2 req3
    _ -> throwError $ InternalError "Unknown Service Config"

data PaymentServiceType = Normal | FRFSBooking | FRFSBusBooking | BBPS | FRFSMultiModalBooking
  deriving (Generic, FromJSON, ToJSON, Show, ToSchema, ToParamSchema)

$(mkHttpInstancesForEnum ''PaymentServiceType)
