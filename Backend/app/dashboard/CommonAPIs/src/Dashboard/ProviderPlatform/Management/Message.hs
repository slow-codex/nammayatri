{-
 Copyright 2022-23, Juspay India Pvt Ltd

 This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License

 as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program

 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY

 or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of

 the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Dashboard.ProviderPlatform.Management.Message
  ( module Reexport,
  )
where

import API.Types.ProviderPlatform.Management.Endpoints.Message
import Dashboard.Common as Reexport
import Data.Text as T
import Kernel.Prelude
import Kernel.ServantMultipart

---
-- Upload File
--

instance FromMultipart Tmp UploadFileRequest where
  fromMultipart form = do
    file <- fmap fdPayload (lookupFile "file" form)
    reqContentType <- fmap fdFileCType (lookupFile "file" form)
    fileType <- fmap (read . T.unpack) (lookupInput "fileType" form)
    pure UploadFileRequest {..}

instance ToMultipart Tmp UploadFileRequest where
  toMultipart uploadFileRequest =
    MultipartData
      [Input "fileType" (show uploadFileRequest.fileType)]
      [FileData "file" (T.pack uploadFileRequest.file) "" (uploadFileRequest.file)]

---
-- Send Message
--

instance FromMultipart Tmp SendMessageRequest where
  fromMultipart form = do
    let inputType = fmap (read . T.unpack) (lookupInput "type" form)
    csvFile <- either (helper inputType) (Right . Just . fdPayload) (lookupFile "csvFile" form)
    _type <- inputType
    messageId <- lookupInput "messageId" form
    pure SendMessageRequest {..}
    where
      helper (Right AllEnabled) _ = Right Nothing
      helper _ x = Left x

instance ToMultipart Tmp SendMessageRequest where
  toMultipart form =
    MultipartData
      [ Input "type" $ show form._type,
        Input "messageId" form.messageId
      ]
      (maybe [] (\file -> [FileData "csvFile" (T.pack file) "text/csv" file]) form.csvFile)
