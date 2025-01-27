{-
  Copyright 2022-23, Juspay India Pvt Ltd

  This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License

  as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program

  is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY

  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of

  the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}

module Lib.Payment.Storage.Beam.PaymentTransaction where

import qualified Database.Beam as B
import Kernel.Beam.Lib.UtilsTH
import qualified Kernel.External.Payment.Interface as Payment
import Kernel.Prelude
import Kernel.Types.Common hiding (Price (..), PriceAPIEntity (..), id)

data PaymentTransactionT f = PaymentTransactionT
  { id :: B.C f Text,
    txnUUID :: B.C f (Maybe Text),
    txnId :: B.C f (Maybe Text),
    paymentMethodType :: B.C f (Maybe Text),
    paymentMethod :: B.C f (Maybe Text),
    respMessage :: B.C f (Maybe Text),
    respCode :: B.C f (Maybe Text),
    gatewayReferenceId :: B.C f (Maybe Text),
    orderId :: B.C f Text,
    merchantId :: B.C f Text,
    amount :: B.C f HighPrecMoney, -- FIXME Kernel.Types.Common.Price
    currency :: B.C f Currency, -- FIXME Kernel.Types.Common.Price
    applicationFeeAmount :: B.C f (Maybe HighPrecMoney),
    retryCount :: B.C f (Maybe Int),
    dateCreated :: B.C f (Maybe UTCTime),
    statusId :: B.C f Int,
    status :: B.C f Payment.TransactionStatus,
    juspayResponse :: B.C f (Maybe Text),
    mandateStatus :: B.C f (Maybe Payment.MandateStatus),
    mandateStartDate :: B.C f (Maybe UTCTime),
    mandateEndDate :: B.C f (Maybe UTCTime),
    mandateId :: B.C f (Maybe Text),
    mandateFrequency :: B.C f (Maybe Payment.MandateFrequency),
    mandateMaxAmount :: B.C f (Maybe HighPrecMoney), -- FIXME Kernel.Types.Common.Price
    bankErrorCode :: B.C f (Maybe Text),
    bankErrorMessage :: B.C f (Maybe Text),
    splitSettlementResponse :: B.C f (Maybe Value),
    createdAt :: B.C f UTCTime,
    updatedAt :: B.C f UTCTime,
    merchantOperatingCityId :: B.C f (Maybe Text)
  }
  deriving (Generic, B.Beamable)

instance B.Table PaymentTransactionT where
  data PrimaryKey PaymentTransactionT f
    = Id (B.C f Text)
    deriving (Generic, B.Beamable)
  primaryKey = Id . id

type PaymentTransaction = PaymentTransactionT Identity

$(enableKVPG ''PaymentTransactionT ['id] [['txnUUID], ['orderId]])

$(mkTableInstancesGenericSchema ''PaymentTransactionT "payment_transaction")
