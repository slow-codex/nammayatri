{-# LANGUAGE ApplicativeDo #-}
{-# OPTIONS_GHC -Wwarn=incomplete-record-updates #-}

module Domain.Types.Extra.MerchantPaymentMethod where

import Data.Aeson.Types
import qualified Data.List as List
import Data.OpenApi
import Kernel.Prelude
import qualified Text.Show
import Tools.Beam.UtilsTH

-- Extra code goes here --
data PaymentType = ON_FULFILLMENT | POSTPAID
  deriving (Generic, FromJSON, ToJSON, Show, Read, Eq, Ord, ToSchema)

data PaymentInstrument = Card CardType | Wallet WalletType | UPI | NetBanking | Cash
  deriving (Generic, Eq, Ord)

instance ToSchema PaymentInstrument where
  declareNamedSchema = genericDeclareNamedSchema $ fromAesonOptions paymentInstrumentOptions

instance ToJSON PaymentInstrument where
  toJSON = genericToJSON paymentInstrumentOptions

instance FromJSON PaymentInstrument where
  parseJSON = genericParseJSON paymentInstrumentOptions

paymentInstrumentOptions :: Options
paymentInstrumentOptions =
  defaultOptions
    { sumEncoding = paymentInstrumentTaggedObject
    }

paymentInstrumentTaggedObject :: SumEncoding
paymentInstrumentTaggedObject =
  defaultTaggedObject
    { tagFieldName = "instrumentType",
      contentsFieldName = "instrumentName"
    }

instance Show PaymentInstrument where
  show (Card p) = "Card_" <> show p
  show (Wallet p) = "Wallet_" <> show p
  show UPI = "UPI"
  show NetBanking = "NetBanking"
  show Cash = "Cash"

instance Read PaymentInstrument where
  readsPrec d' =
    readParen
      (d' > app_prec)
      ( \r ->
          [ (Card v1, r2)
            | r1 <- stripPrefix "Card_" r,
              (v1, r2) <- readsPrec (app_prec + 1) r1
          ]
            ++ [ (Wallet v1, r2)
                 | r1 <- stripPrefix "Wallet_" r,
                   (v1, r2) <- readsPrec (app_prec + 1) r1
               ]
            ++ [ (UPI, r1)
                 | r1 <- stripPrefix "UPI" r
               ]
            ++ [ (NetBanking, r1)
                 | r1 <- stripPrefix "NetBanking" r
               ]
            ++ [ (Cash, r1)
                 | r1 <- stripPrefix "Cash" r
               ]
      )
    where
      app_prec = 10
      stripPrefix pref r = bool [] [List.drop (length pref) r] $ List.isPrefixOf pref r

data CardType = DefaultCardType
  deriving (Generic, Show, Read, Eq, ToSchema, Ord)

-- Generic instances for type with single value will not work
instance FromJSON CardType where
  parseJSON (String "DefaultCardType") = pure DefaultCardType
  parseJSON (String _) = parseFail "Expected \"DefaultCardType\""
  parseJSON e = typeMismatch "String" e

instance ToJSON CardType where
  toJSON = String . show

data WalletType = DefaultWalletType
  deriving (Generic, Show, Read, Eq, ToSchema, Ord)

-- Generic instances for type with single value will not work
instance FromJSON WalletType where
  parseJSON (String "DefaultWalletType") = pure DefaultWalletType
  parseJSON (String _) = parseFail "Expected \"DefaultWalletType\""
  parseJSON e = typeMismatch "String" e

instance ToJSON WalletType where
  toJSON = String . show

data PaymentCollector = BAP | BPP
  deriving (Generic, FromJSON, ToJSON, Show, Read, Eq, ToSchema, Ord)

data PaymentMethodInfo = PaymentMethodInfo
  { paymentType :: PaymentType,
    paymentInstrument :: PaymentInstrument,
    collectedBy :: PaymentCollector
  }
  deriving (Show)

$(mkBeamInstancesForEnum ''PaymentCollector)

$(mkBeamInstancesForEnum ''PaymentType)

$(mkBeamInstancesForEnum ''PaymentInstrument)
