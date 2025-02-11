{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module ExternalBPP.ExternalAPI.Metro.CMRL.PassengerViewStatus where

import Data.Aeson
import qualified Data.Text as T
import Domain.Types.IntegratedBPPConfig
import EulerHS.Types as ET
import ExternalBPP.ExternalAPI.Metro.CMRL.Auth
import Kernel.Prelude
import Kernel.Tools.Metrics.CoreMetrics (CoreMetrics)
import Kernel.Types.App
import Kernel.Utils.Common
import Servant
import Tools.Error

data PassengerViewStatusReq = PassengerViewStatusReq
  { mobileNumber :: T.Text
  }
  deriving (Generic, Show, ToJSON, FromJSON)

data TicketDetails = TicketDetails
  { sourceStationCode :: T.Text,
    destinationStationCode :: T.Text,
    sourceStationName :: T.Text,
    destinationStationName :: T.Text,
    sourceStationTamilName :: Maybe T.Text,
    destinationStationTamilName :: Maybe T.Text,
    transactionTypeId :: T.Text,
    ticketReferenceNo :: T.Text,
    ticketStatus :: T.Text,
    originalValue :: Int,
    tranValue :: Int,
    txnRefNo :: T.Text,
    bankTxnRefNo :: T.Text,
    transactionTs :: T.Text,
    createdTs :: T.Text
  }
  deriving (Generic, Show, ToJSON, FromJSON)

data PassengerViewStatusRes = PassengerViewStatusRes
  { statusCode :: Int,
    message :: T.Text,
    result :: [TicketDetails]
  }
  deriving (Generic, Show, ToJSON, FromJSON)

type PassengerViewStatusAPI =
  "cumta" :> "passengerviewstatus"
    :> Header "Authorization" T.Text
    :> ReqBody '[JSON] PassengerViewStatusReq
    :> Get '[JSON] PassengerViewStatusRes

passengerViewStatusAPI :: Proxy PassengerViewStatusAPI
passengerViewStatusAPI = Proxy

getPassengerViewStatus :: (CoreMetrics m, MonadFlow m, CacheFlow m r, EncFlow m r) => CMRLConfig -> PassengerViewStatusReq -> m [TicketDetails]
getPassengerViewStatus config req = do
  accessToken <- getAuthToken config
  response <-
    callAPI config.networkHostUrl (ET.client passengerViewStatusAPI (Just $ "Bearer " <> accessToken) req) "getPassengerViewStatus" passengerViewStatusAPI
      >>= fromEitherM (ExternalAPICallError (Just "CMRL_PASSENGER_VIEW_STATUS_API") config.networkHostUrl)
  return response.result
