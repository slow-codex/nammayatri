module Domain.Action.UI.DriverProfileQuestions where

import qualified API.Types.UI.DriverProfileQuestions
import qualified AWS.S3 as S3
import ChatCompletion.Interface.Types as CIT
import qualified Data.Text as T
import Data.Time.Calendar (diffDays)
import Data.Time.Clock (utctDay)
import qualified Domain.Types.DriverProfileQuestions as DTDPQ
import Domain.Types.LlmPrompt as DTL
import qualified Domain.Types.Merchant as DM
import qualified Domain.Types.MerchantOperatingCity as DMOC
import qualified Domain.Types.MerchantServiceConfig as DOSC
import qualified Domain.Types.Person as SP
import Environment
import EulerHS.Prelude hiding (id)
import qualified IssueManagement.Storage.Queries.MediaFile as QMF
import Kernel.Types.APISuccess (APISuccess (Success))
import Kernel.Types.Error
import Kernel.Types.Id
import Kernel.Utils.Common as KUC
import Storage.Beam.IssueManagement ()
import qualified Storage.Cac.MerchantServiceUsageConfig as QOMC
import Storage.CachedQueries.LLMPrompt.LLMPrompt as SCL
import qualified Storage.CachedQueries.Merchant as CQM
import qualified Storage.Queries.DriverProfileQuestions as DPQ
import qualified Storage.Queries.DriverStats as QDS
import qualified Storage.Queries.Person as QP
import Tools.ChatCompletion as TC
import Tools.Error

data ImageType = JPG | PNG | UNKNOWN deriving (Generic, Show, Eq)

postDriverProfileQues ::
  ( ( Maybe (Id SP.Person),
      Id DM.Merchant,
      Id DMOC.MerchantOperatingCity
    ) ->
    API.Types.UI.DriverProfileQuestions.DriverProfileQuesReq ->
    Flow APISuccess
  )
postDriverProfileQues (mbPersonId, merchantId, merchantOpCityId) req@API.Types.UI.DriverProfileQuestions.DriverProfileQuesReq {..} =
  do
    driverId <- mbPersonId & fromMaybeM (PersonNotFound "No person id passed")
    person <- QP.findById driverId >>= fromMaybeM (PersonNotFound ("No person found with id" <> show driverId))
    driverStats <- QDS.findByPrimaryKey driverId >>= fromMaybeM (PersonNotFound ("No person found with id" <> show driverId))
    now <- getCurrentTime
    fork "generating about_me" $ do
      aboutMe <- generateAboutMe person driverStats now req
      DPQ.upsert
        ( DTDPQ.DriverProfileQuestions
            { updatedAt = now,
              createdAt = now,
              driverId = driverId,
              hometown = hometown,
              merchantOperatingCityId = merchantOpCityId,
              pledges = pledges,
              aspirations = toMaybe aspirations,
              drivingSince = drivingSince,
              imageIds = toMaybe imageIds,
              vehicleTags = toMaybe vehicleTags,
              aboutMe = Just aboutMe
            }
        )
    pure Success
  where
    toMaybe xs = guard (not (null xs)) >> Just xs

    generateAboutMe person driverStats now req' = do
      gptGenProfile <- try $ genAboutMeWithAI person driverStats now req'
      either
        (\(err :: SomeException) -> logError ("Error occurred: " <> show err) *> pure (hometownDetails req'.hometown <> "I have been with Nammayatri for " <> (withNY now person.createdAt) <> " months. " <> writeDriverStats driverStats <> genAspirations req'.aspirations))
        pure
        gptGenProfile

    hometownDetails mHometown = case mHometown of
      Just hometown' -> "Hailing from " <> hometown' <> ", "
      Nothing -> ""

    withNY now createdAt = T.pack $ show $ diffDays (utctDay now) (utctDay createdAt) `div` 30

    writeDriverStats driverStats = ratingStat driverStats <> cancellationStat driverStats

    nonZero Nothing = 1
    nonZero (Just a)
      | a <= 0 = 1
      | otherwise = a

    ratingStat driverStats =
      if driverStats.rating > Just 4.75 && isJust driverStats.rating
        then "I rank among the top 10 percentile in terms of rating "
        else ""

    cancellationStat driverStats =
      let cancRate = div ((fromMaybe 0 driverStats.ridesCancelled) * 100 :: Int) (nonZero driverStats.totalRidesAssigned :: Int)
       in if cancRate < 7
            then "I " <> if (ratingStat driverStats :: Text) == "" then "" else "also " <> "have a very low cancellation rate that ranks among top 10 percentile. "
            else ""

    genAspirations aspirations' = if null aspirations' then "" else "With the earnings from my trips, I aspire to " <> T.toLower (T.intercalate ", " aspirations')

    genAboutMeWithAI person driverStats now req' = do
      orgLLMChatCompletionConfig <- QOMC.findByMerchantOpCityId merchantOpCityId Nothing >>= fromMaybeM (MerchantServiceUsageConfigNotFound merchantOpCityId.getId)
      prompt <-
        SCL.findByMerchantOpCityIdAndServiceNameAndUseCaseAndPromptKey merchantOpCityId (DOSC.LLMChatCompletionService $ (.llmChatCompletion) orgLLMChatCompletionConfig) DTL.DriverProfileGen DTL.AzureOpenAI_DriverProfileGen_1 >>= fromMaybeM (LlmPromptNotFound merchantOpCityId.getId (show (DOSC.LLMChatCompletionService $ (.llmChatCompletion) orgLLMChatCompletionConfig)) (show DTL.DriverProfileGen) (show DTL.AzureOpenAI_DriverProfileGen_1))
          >>= buildPrompt person driverStats now req' . (.promptTemplate)
      gccresp <- TC.getChatCompletion merchantId merchantOpCityId (buildChatCompletionReq prompt)
      logDebug $ "generated - " <> gccresp.genMessage.genContent
      pure $ gccresp.genMessage.genContent

    buildPrompt person driverStats now req' promptTemplate = do
      merchant <- CQM.findById merchantId
      pure $
        T.replace "{#homeTown#}" (hometownDetails req'.hometown)
          . T.replace "{#withNY#}" (withNY now person.createdAt)
          . T.replace "{#rating#}" (show driverStats.rating)
          . T.replace "{#drivingSince#}" (maybe "" show req'.drivingSince)
          . T.replace "{#aspirations#}" (T.intercalate ", " req'.aspirations)
          . T.replace "{#vehicleTags#}" (T.intercalate ", " req'.vehicleTags)
          . T.replace "{#pledge#}" (T.intercalate ", " req'.pledges)
          . T.replace "{#onPlatformSince#}" (show person.createdAt)
          . T.replace "{#merchant#}" (maybe "" (.name) merchant)
          . T.replace "{#driverName#}" ((.firstName) person)
          $ promptTemplate

    buildChatCompletionReq prompt = CIT.GeneralChatCompletionReq {genMessages = [CIT.GeneralChatCompletionMessage {genRole = "user", genContent = prompt}]}

getDriverProfileQues ::
  ( ( Maybe (Id SP.Person),
      Id DM.Merchant,
      Id DMOC.MerchantOperatingCity
    ) ->
    Maybe Bool ->
    Flow API.Types.UI.DriverProfileQuestions.DriverProfileQuesRes
  )
getDriverProfileQues (mbPersonId, _merchantId, _merchantOpCityId) isImages =
  mbPersonId & fromMaybeM (PersonNotFound "No person id passed")
    >>= DPQ.findByPersonId
    >>= \case
      Just res ->
        getImages (maybe [] (Id <$>) res.imageIds)
          >>= \images ->
            pure $
              API.Types.UI.DriverProfileQuestions.DriverProfileQuesRes
                { aspirations = fromMaybe [] res.aspirations,
                  hometown = res.hometown,
                  pledges = res.pledges,
                  drivingSince = res.drivingSince,
                  vehicleTags = fromMaybe [] res.vehicleTags,
                  otherImages = if isImages == Just True then images else [], -- fromMaybe [] res.images
                  profileImage = Nothing,
                  otherImageIds = fromMaybe [] res.imageIds
                }
      Nothing ->
        pure $
          API.Types.UI.DriverProfileQuestions.DriverProfileQuesRes
            { aspirations = [],
              hometown = Nothing,
              pledges = [],
              drivingSince = Nothing,
              vehicleTags = [],
              otherImages = [],
              profileImage = Nothing,
              otherImageIds = []
            }
  where
    getImages imageIds = do
      mapM (QMF.findById) imageIds <&> catMaybes <&> ((.url) <$>)
        >>= mapM (S3.get . T.unpack . extractFilePath)

    extractFilePath url = case T.splitOn "filePath=" url of
      [_before, after] -> after
      _ -> T.empty
