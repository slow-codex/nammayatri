{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Lib.Yudhishthira.Types
  ( module Reexport,
    YudhishthiraDecideReq (..),
    YudhishthiraDecideResp (..),
    ChakraQueriesAPIEntity (..),
    Source (..),
    SourceData,
    CreateNammaTagRequest (..),
    CreateNammaTagResponse (..),
    CreateNammaApplicationTagResponse (..),
    CreateTagResp (..),
    VerifyNammaTagRequest (..),
    VerifyNammaTagResponse (..),
    LogicDomain (..),
    AppDynamicLogicReq (..),
    UpdateKaalBasedTagsJobReq (..),
    AppDynamicLogicResp (..),
    RunLogicResp (..),
    RunKaalChakraJobReq (..),
    KaalChakraAction (..),
    KaalChakraJobData (..),
    ChakraBatchState (..),
    mkKaalChakraJobData,
    mkKaalChakraJobDataFromUpdateTagData,
    UpdateKaalBasedTagsData (..),
    mkUpdateTagDataFromKaalChakraJobData,
    RunKaalChakraJobRes (..),
    RunKaalChakraJobResForUser (..),
    TagAPIEntity (..),
    UsersSet (..),
    QueryResult (..),
    QueryResultDefault (..),
    UpdateNammaTagRequest (..),
    GetLogicsResp (..),
    LogicRolloutObject (..),
    RolloutVersion (..),
    CreateTimeBoundRequest (..),
    LogicRolloutReq,
    TimeBoundResp,
    ConfigType (..),
    allValues,
    AppDynamicLogicVersionResp,
    AppDynamicLogicVersion (..),
    AppDynamicLogicDomainResp,
    ChakraQueryResp,
    UpdateTagReq (..),
    TagNameValue (..),
  )
where

import Control.Lens.Operators hiding ((.=))
import Data.Aeson
import Data.OpenApi as OpenApi hiding (description, name, tags, version)
import qualified Data.Text as T
import Kernel.Beam.Lib.UtilsTH
import Kernel.Prelude
import Kernel.Types.HideSecrets
import Kernel.Types.Id
import Kernel.Types.TimeBound
import Kernel.Utils.Common
import Kernel.Utils.TH (mkHttpInstancesForEnum)
import Lib.Scheduler.Types (AnyJob)
import Lib.Yudhishthira.Types.Application as Reexport
import Lib.Yudhishthira.Types.Common as Reexport
import Lib.Yudhishthira.Types.KaalChakra as Reexport
import Lib.Yudhishthira.Types.Manual as Reexport
import Lib.Yudhishthira.Types.Tag as Reexport
import qualified Text.Show (show)

class Enumerable a where
  allValues :: [a]

data ConfigType
  = DriverPoolConfig
  | TransporterConfig
  deriving (Eq, Ord, Show, Read, Generic, ToJSON, FromJSON, ToSchema, Enum, Bounded)

data Source
  = Application ApplicationEvent
  | KaalChakra Chakra
  deriving (Eq, Ord, Show, Read, Generic, ToJSON, FromJSON, ToSchema)

type SourceData = Value -- json to be decoded in the respective tag

data CreateNammaTagRequest
  = ApplicationTag NammaTagApplication
  | KaalChakraTag NammaTagChakra
  | ManualTag NammaTagManual
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

instance HideSecrets CreateNammaTagRequest where
  hideSecrets = identity

data UpdateNammaTagRequest = UpdateNammaTagRequest
  { tagCategory :: Maybe Text,
    tagName :: Text,
    description :: Maybe Text,
    tagPossibleValues :: Maybe TagValues,
    tagChakra :: Maybe Chakra,
    tagValidity :: Maybe Hours,
    tagStage :: Maybe ApplicationEvent,
    tagRule :: Maybe TagRule,
    actionEngine :: Maybe Value
  }
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

instance HideSecrets UpdateNammaTagRequest where
  hideSecrets = identity

data ChakraQueriesAPIEntity = ChakraQueriesAPIEntity
  { chakra :: Chakra,
    queryName :: Text,
    queryResults :: [QueryResult],
    queryText :: Text
  }
  deriving (Generic, Show, ToJSON, FromJSON, ToSchema)

data QueryResult = QueryResult
  { resultName :: Text,
    resultDefault :: QueryResultDefault
  }
  deriving (Generic, Show, Eq, Ord, Read, ToJSON, FromJSON, ToSchema)

data QueryResultDefault = BOOL Bool | INT Int | DOUBLE Double | TEXT Text
  deriving (Generic, Show, Eq, Ord, Read, ToJSON, FromJSON, ToSchema)

$(mkBeamInstancesForEnumAndList ''QueryResult)

instance HideSecrets ChakraQueriesAPIEntity where
  hideSecrets = identity

data YudhishthiraDecideReq = YudhishthiraDecideReq
  { source :: Source,
    sourceData :: SourceData
  }
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

newtype YudhishthiraDecideResp = YudhishthiraDecideResp
  { tags :: [NammaTagResponse]
  }
  deriving stock (Show, Read, Generic)
  deriving anyclass (ToJSON, FromJSON, ToSchema)

data LogicDomain
  = POOLING
  | FARE_POLICY
  | DYNAMIC_PRICING_UNIFIED
  | FRFS_DISCOUNTS
  | CONFIG ConfigType
  deriving (Eq, Ord, Generic, ToJSON, FromJSON, ToSchema)

instance Enumerable LogicDomain where
  allValues =
    [ POOLING,
      FARE_POLICY,
      DYNAMIC_PRICING_UNIFIED,
      FRFS_DISCOUNTS
    ]
      ++ map CONFIG [minBound .. maxBound]

generateLogicDomainShowInstances :: [String]
generateLogicDomainShowInstances =
  [show POOLING]
    ++ [show FARE_POLICY]
    ++ [show DYNAMIC_PRICING_UNIFIED]
    ++ [show FRFS_DISCOUNTS]
    ++ [show (CONFIG configType) | configType <- configTypes]
  where
    configTypes = [minBound .. maxBound]

instance ToParamSchema LogicDomain where
  toParamSchema _ =
    mempty
      & title ?~ "LogicDomain"
      & type_ ?~ OpenApiString
      & enum_
        ?~ map (String . T.pack) generateLogicDomainShowInstances

instance Show LogicDomain where
  show POOLING = "POOLING"
  show FARE_POLICY = "FARE-POLICY"
  show DYNAMIC_PRICING_UNIFIED = "DYNAMIC-PRICING-UNIFIED"
  show FRFS_DISCOUNTS = "FRFS-DISCOUNTS"
  show (CONFIG configType) = "CONFIG_" ++ show configType

instance Read LogicDomain where
  readsPrec _ s =
    let (prefx, rest) = break (== '_') s
     in case prefx of
          "POOLING" ->
            [(POOLING, drop 1 rest)]
          "FARE-POLICY" ->
            [(FARE_POLICY, drop 1 rest)]
          "DYNAMIC-PRICING-UNIFIED" ->
            [(DYNAMIC_PRICING_UNIFIED, drop 1 rest)]
          "FRFS-DISCOUNTS" ->
            [(FRFS_DISCOUNTS, drop 1 rest)]
          "CONFIG" ->
            let (configType', rest1) = break (== '_') (drop 1 rest)
             in case readMaybe configType' of
                  Just configType -> [(CONFIG configType, rest1)]
                  Nothing -> []
          _ -> []

$(mkBeamInstancesForEnumAndList ''LogicDomain)
$(mkHttpInstancesForEnum ''LogicDomain)

data AppDynamicLogicReq = AppDynamicLogicReq
  { rules :: [Value],
    inputData :: [Value],
    description :: Maybe Text,
    shouldUpdateRule :: Maybe Bool,
    updatePassword :: Maybe Text,
    verifyOutput :: Maybe Bool,
    domain :: LogicDomain
  }
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

data AppDynamicLogicResp = AppDynamicLogicResp
  { result :: Value,
    isRuleUpdated :: Bool,
    domain :: LogicDomain,
    version :: Maybe Int,
    errors :: [String]
  }
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

data GetLogicsResp = GetLogicsResp
  { domain :: LogicDomain,
    version :: Int,
    description :: Maybe Text,
    logics :: [Value]
  }
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

type TimeBoundResp = [CreateTimeBoundRequest]

instance HideSecrets TimeBoundResp where
  hideSecrets = identity

data CreateTimeBoundRequest = CreateTimeBoundRequest
  { timeBoundDomain :: LogicDomain,
    name :: Text,
    timeBounds :: TimeBound
  }
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

instance HideSecrets CreateTimeBoundRequest where
  hideSecrets = identity

data RunLogicResp = RunLogicResp
  { result :: Value,
    errors :: [String]
  }
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

type LogicRolloutReq = [LogicRolloutObject]

data CreateTagResp = ApplicationTagRes CreateNammaApplicationTagResponse | Success deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

instance HideSecrets CreateTagResp where
  hideSecrets = identity

data CreateNammaTagResponse = CreateNammaTagResponse
  { result :: CreateTagResp
  }
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

instance HideSecrets CreateNammaTagResponse where
  hideSecrets = identity

data CreateNammaApplicationTagResponse = CreateNammaApplicationTagResponse
  { executionResultOnDefaultData :: RunLogicResp,
    defaultDataUsed :: Value
  }
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

instance HideSecrets CreateNammaApplicationTagResponse where
  hideSecrets = identity

data VerifyNammaTagRequest = VerifyNammaTagRequest
  { logic :: Value,
    logicData :: Maybe Value,
    source :: Source,
    useDefaultData :: Bool
  }
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

instance HideSecrets VerifyNammaTagRequest where
  hideSecrets = identity

data VerifyNammaTagResponse = VerifyNammaTagResponse
  { executionResult :: RunLogicResp,
    dataUsed :: Value
  }
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

instance HideSecrets VerifyNammaTagResponse where
  hideSecrets = identity

instance HideSecrets LogicRolloutReq where
  hideSecrets = identity

data LogicRolloutObject = LogicRolloutObject
  { domain :: LogicDomain,
    timeBounds :: Text,
    rollout :: [RolloutVersion]
  }
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

instance HideSecrets LogicRolloutObject where
  hideSecrets = identity

data RolloutVersion = RolloutVersion
  { version :: Int,
    rolloutPercentage :: Int,
    versionDescription :: Maybe Text
  }
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

instance HideSecrets RolloutVersion where
  hideSecrets = identity

type AppDynamicLogicVersionResp = [AppDynamicLogicVersion]

data AppDynamicLogicVersion = AppDynamicLogicVersion
  { version :: Int,
    description :: Maybe Text
  }
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

type AppDynamicLogicDomainResp = [LogicDomain]

type ChakraQueryResp = [ChakraQueriesAPIEntity]

instance HideSecrets AppDynamicLogicReq where
  hideSecrets = identity

data UpdateKaalBasedTagsJobReq = UpdateKaalBasedTagsJobReq
  { eventId :: Id Event,
    updateUserTags :: Bool,
    usersInBatch :: Int,
    maxBatches :: Int,
    batchDelayInSec :: Int,
    usersSet :: UsersSet,
    chakra :: Chakra
  }
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

data UpdateKaalBasedTagsData = UpdateKaalBasedTagsData
  { eventId :: Id Event,
    updateUserTags :: Bool,
    usersInBatch :: Int,
    maxBatches :: Int,
    batchDelayInSec :: Int
  }
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

mkKaalChakraJobDataFromUpdateTagData :: UpdateKaalBasedTagsJobReq -> Bool -> KaalChakraJobData
mkKaalChakraJobDataFromUpdateTagData UpdateKaalBasedTagsJobReq {..} parseQueryResults = KaalChakraJobData {..}

data RunKaalChakraJobReq = RunKaalChakraJobReq
  { chakra :: Chakra,
    action :: KaalChakraAction,
    updateUserTags :: Bool,
    parseQueryResults :: Bool,
    usersSet :: UsersSet,
    usersInBatch :: Int,
    maxBatches :: Int, -- we need to avoid endless loops in case of any query is wrong
    batchDelayInSec :: Int,
    completeOldJob :: Maybe (Id AnyJob)
  }
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

data UpdateTagReq = UpdateTagReq
  { tag :: Text,
    isAddingTag :: Bool
  }
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

instance HideSecrets UpdateTagReq where
  hideSecrets = identity

data KaalChakraJobData = KaalChakraJobData
  { updateUserTags :: Bool,
    parseQueryResults :: Bool,
    usersInBatch :: Int,
    maxBatches :: Int,
    batchDelayInSec :: Int
  }
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

mkKaalChakraJobData :: RunKaalChakraJobReq -> KaalChakraJobData
mkKaalChakraJobData RunKaalChakraJobReq {..} = KaalChakraJobData {..}

mkUpdateTagDataFromKaalChakraJobData :: RunKaalChakraJobReq -> Id Event -> UpdateKaalBasedTagsData
mkUpdateTagDataFromKaalChakraJobData RunKaalChakraJobReq {..} eventId = UpdateKaalBasedTagsData {..}

data KaalChakraAction = RUN | SCHEDULE UTCTime
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

data UsersSet = SINGLE_USER (Id User) | LIST_USERS [Id User] | ALL_USERS
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

data ChakraBatchState = Continue Int | Completed | Failed
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

data RunKaalChakraJobRes = RunKaalChakraJobRes
  { eventId :: Maybe (Id Event),
    tags :: Maybe [TagAPIEntity],
    users :: Maybe [RunKaalChakraJobResForUser],
    chakraBatchState :: ChakraBatchState
  }
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

data TagAPIEntity = TagAPIEntity
  { name :: Text,
    possibleValues :: TagValues,
    rule :: TagRule,
    createdAt :: UTCTime,
    updatedAt :: UTCTime
  }
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

data RunKaalChakraJobResForUser = RunKaalChakraJobResForUser
  { userId :: Id User,
    userDataValue :: Value, -- final result with default values
    userOldTags :: Maybe [TagNameValue], -- tagName#TAG_VALUE format
    userUpdatedTags :: Maybe [TagNameValue] -- tagName#TAG_VALUE format
  }
  deriving (Show, Read, Generic, ToJSON, FromJSON, ToSchema)

newtype TagNameValue = TagNameValue {getTagNameValue :: Text} -- tagName#tagValue format
  deriving newtype (Show, Read, Eq, ToJSON, FromJSON, ToSchema)

instance HideSecrets RunKaalChakraJobReq where
  hideSecrets = identity

instance HideSecrets RunKaalChakraJobRes where
  hideSecrets = identity
