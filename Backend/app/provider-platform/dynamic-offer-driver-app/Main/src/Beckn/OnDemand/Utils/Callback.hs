{-
 Copyright 2022-23, Juspay India Pvt Ltd

 This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License

 as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program

 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY

 or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of

 the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}

module Beckn.OnDemand.Utils.Callback where

import Data.HashMap.Strict as HMS
import Domain.Types.Merchant as DM
import EulerHS.Prelude hiding ((.~))
import qualified EulerHS.Types as ET
import Kernel.Streaming.Kafka.Producer.Types (KafkaProducerTools)
import Kernel.Tools.Metrics.CoreMetrics
import Kernel.Types.Id
import Kernel.Utils.Common
import Kernel.Utils.Monitoring.Prometheus.Servant
import Kernel.Utils.Servant.SignatureAuth
import Servant.Client
import TransactionLogs.PushLogs
import TransactionLogs.Types

withCallback ::
  ( HasFlowEnv m r '["nwAddress" ::: BaseUrl, "httpClientOptions" ::: HttpClientOptions],
    HasShortDurationRetryCfg r c,
    CacheFlow m r,
    EsqDBFlow m r,
    HasFlowEnv m r '["kafkaProducerTools" ::: KafkaProducerTools],
    HasFlowEnv m r '["ondcTokenHashMap" ::: HMS.HashMap KeyConfig TokenConfig]
  ) =>
  DM.Merchant ->
  WithBecknCallback api callback_success m
withCallback = withCallback' withShortRetry

withCallback' ::
  (HasFlowEnv m r '["kafkaProducerTools" ::: KafkaProducerTools], HasFlowEnv m r '["ondcTokenHashMap" ::: HMS.HashMap KeyConfig TokenConfig]) =>
  (m () -> m ()) ->
  (HasFlowEnv m r '["nwAddress" ::: BaseUrl], EsqDBFlow m r, CacheFlow m r) =>
  DM.Merchant ->
  WithBecknCallback api callback_success m
withCallback' doWithCallback transporter action api cbUrl internalEndPointHashMap fromError f = do
  let bppSubscriberId = getShortId $ transporter.subscriberId
      authKey = getHttpManagerKey bppSubscriberId
  withBecknCallback doWithCallback (Just $ ET.ManagerSelector authKey) transporter.id.getId action api cbUrl internalEndPointHashMap fromError f

type Action = Text

type WithBecknCallback api callback_result m =
  ( MonadFlow m,
    SanitizedUrl api,
    CoreMetrics m,
    HasClient ET.EulerClient api,
    Client ET.EulerClient api
      ~ (callback_result -> ET.EulerClient AckResponse),
    ToJSON callback_result
  ) =>
  Action ->
  Proxy api ->
  BaseUrl ->
  HashMap BaseUrl BaseUrl ->
  (BecknAPIError -> callback_result) ->
  m callback_result ->
  m AckResponse

withBecknCallback ::
  (HasFlowEnv m r '["kafkaProducerTools" ::: KafkaProducerTools], HasFlowEnv m r '["ondcTokenHashMap" ::: HMS.HashMap KeyConfig TokenConfig]) =>
  (m () -> m ()) ->
  Maybe ET.ManagerSelector ->
  Text ->
  WithBecknCallback api callback_result m
withBecknCallback doWithCallback auth transporterId action api cbUrl internalEndPointHashMap fromError cbHandler = do
  forkBecknCallback
    fromError
    doWithResult
    action
    cbHandler
  return Ack
  where
    doWithResult result = do
      fork ("sending " <> show action <> ", pushing ondc logs") do
        void $ pushLogs action (toJSON result) transporterId "MOBILITY"
      doWithCallback . void . callBecknAPI auth Nothing action api cbUrl internalEndPointHashMap $ result

forkBecknCallback ::
  (Forkable m, MonadCatch m, Log m) =>
  (BecknAPIError -> result) ->
  (result -> m ()) ->
  Text ->
  m result ->
  m ()
forkBecknCallback fromError doWithResult actionName action =
  fork actionName $
    try action >>= \case
      Right success -> doWithResult success
      Left err -> do
        logError $ "Error executing callback action " <> actionName <> ": " <> show err
        doWithResult $ fromError (someExceptionToBecknApiError err)
