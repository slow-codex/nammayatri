{-
  Copyright 2022-23, Juspay India Pvt Ltd

  This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License

  as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program

  is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY

  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of

  the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}
{-# LANGUAGE InstanceSigs #-}

module IssueManagement.Storage.Beam.Issue.IssueTranslation where

import qualified Database.Beam as B
import Database.Beam.MySQL ()
import IssueManagement.Tools.UtilsTH
import Kernel.External.Types (Language)

data IssueTranslationT f = IssueTranslationT
  { id :: B.C f Text,
    sentence :: B.C f Text,
    translation :: B.C f Text,
    language :: B.C f Language,
    merchantId :: B.C f Text,
    createdAt :: B.C f UTCTime,
    updatedAt :: B.C f UTCTime
  }
  deriving (Generic, B.Beamable)

instance B.Table IssueTranslationT where
  data PrimaryKey IssueTranslationT f
    = Id (B.C f Text)
    deriving (Generic, B.Beamable)
  primaryKey = Id . id

type IssueTranslation = IssueTranslationT Identity

$(enableKVPG ''IssueTranslationT ['id] [['language]])

$(mkTableInstancesGenericSchema ''IssueTranslationT "issue_translation")
