{-
 Copyright 2022-23, Juspay India Pvt Ltd

 This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License

 as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program

 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY

 or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of

 the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}
module IssueManagement.Storage.CachedQueries.Issue.IssueOption where

import IssueManagement.Common
import IssueManagement.Domain.Types.Issue.IssueCategory
import IssueManagement.Domain.Types.Issue.IssueMessage
import IssueManagement.Domain.Types.Issue.IssueOption
import IssueManagement.Domain.Types.Issue.IssueTranslation
import IssueManagement.Storage.BeamFlow
import qualified IssueManagement.Storage.Queries.Issue.IssueOption as Queries
import Kernel.External.Types (Language)
import Kernel.Prelude
import qualified Kernel.Storage.Hedis as Hedis
import Kernel.Types.Id
import Kernel.Utils.Common (CacheFlow)

findAllByCategoryAndLanguage :: BeamFlow m r => Id IssueCategory -> Language -> Identifier -> m [(IssueOption, Maybe IssueTranslation)]
findAllByCategoryAndLanguage issueCategoryId language identifier =
  Hedis.withCrossAppRedis (Hedis.safeGet $ makeIssueOptionByCategoryAndLanguageKey issueCategoryId language identifier) >>= \case
    Just a -> pure a
    Nothing -> cacheAllIssueOptionByCategoryAndLanguage issueCategoryId language identifier /=<< Queries.findAllByCategoryAndLanguage issueCategoryId language

findAllActiveByMessageAndLanguage :: BeamFlow m r => Id IssueMessage -> Language -> Identifier -> m [(IssueOption, Maybe IssueTranslation)]
findAllActiveByMessageAndLanguage issueMessageId language identifier =
  Hedis.withCrossAppRedis (Hedis.safeGet $ makeIssueOptionByMessageAndLanguageKey issueMessageId language identifier) >>= \case
    Just a -> pure a
    Nothing -> cacheAllIssueOptionByMessageAndLanguage issueMessageId language identifier /=<< Queries.findAllActiveByMessageAndLanguage issueMessageId language

findById :: BeamFlow m r => Id IssueOption -> Identifier -> m (Maybe IssueOption)
findById issueOptionId identifier =
  Hedis.withCrossAppRedis (Hedis.safeGet $ makeIssueOptionByIdKey issueOptionId identifier) >>= \case
    Just a -> pure a
    Nothing -> cacheIssueOptionById issueOptionId identifier /=<< Queries.findById issueOptionId

findByIdAndLanguage :: BeamFlow m r => Id IssueOption -> Language -> Identifier -> m (Maybe (IssueOption, Maybe IssueTranslation))
findByIdAndLanguage issueOptionId language identifier =
  Hedis.withCrossAppRedis (Hedis.safeGet $ makeIssueOptionByIdAndLanguageKey issueOptionId language identifier) >>= \case
    Just a -> pure a
    Nothing -> cacheIssueOptionByIdAndLanguage issueOptionId language identifier /=<< Queries.findByIdAndLanguage issueOptionId language

findByIdAndCategoryId :: BeamFlow m r => Id IssueOption -> Id IssueCategory -> Identifier -> m (Maybe IssueOption)
findByIdAndCategoryId issueOptionId issueCategoryId identifier =
  Hedis.withCrossAppRedis (Hedis.safeGet $ makeIssueOptionByIdAndIssueCategoryIdKey issueOptionId issueCategoryId identifier) >>= \case
    Just a -> pure a
    Nothing -> cacheIssueOptionByIdAndIssueCategoryId issueOptionId issueCategoryId identifier /=<< Queries.findByIdAndCategoryId issueOptionId issueCategoryId

--------- Caching logic for issue option by issueCategoryId & language -------------------

clearIssueOptionByCategoryAndLanguageCache :: CacheFlow m r => Id IssueCategory -> Language -> Identifier -> m ()
clearIssueOptionByCategoryAndLanguageCache issueCategoryId language identifier = Hedis.withCrossAppRedis . Hedis.del $ makeIssueOptionByCategoryAndLanguageKey issueCategoryId language identifier

cacheAllIssueOptionByCategoryAndLanguage :: CacheFlow m r => Id IssueCategory -> Language -> Identifier -> [(IssueOption, Maybe IssueTranslation)] -> m ()
cacheAllIssueOptionByCategoryAndLanguage issueCategoryId language identifier issueOptionTranslation = do
  expTime <- fromIntegral <$> asks (.cacheConfig.configsExpTime)
  Hedis.withCrossAppRedis $ Hedis.setExp (makeIssueOptionByCategoryAndLanguageKey issueCategoryId language identifier) issueOptionTranslation expTime

makeIssueOptionByCategoryAndLanguageKey :: Id IssueCategory -> Language -> Identifier -> Text
makeIssueOptionByCategoryAndLanguageKey issueCategoryId language identifier = show identifier <> ":CachedQueries:IssueOption:IssueCategoryId-" <> getId issueCategoryId <> ":Language-" <> show language

--------- Caching logic for issue option by id -------------------

clearIssueOptionByIdCache :: CacheFlow m r => Id IssueOption -> Identifier -> m ()
clearIssueOptionByIdCache issueOptionId identifier = Hedis.withCrossAppRedis . Hedis.del $ makeIssueOptionByIdKey issueOptionId identifier

cacheIssueOptionById :: CacheFlow m r => Id IssueOption -> Identifier -> Maybe IssueOption -> m ()
cacheIssueOptionById issueOptionId identifier issueOption = do
  expTime <- fromIntegral <$> asks (.cacheConfig.configsExpTime)
  Hedis.withCrossAppRedis $ Hedis.setExp (makeIssueOptionByIdKey issueOptionId identifier) issueOption expTime

makeIssueOptionByIdKey :: Id IssueOption -> Identifier -> Text
makeIssueOptionByIdKey id identifier = show identifier <> ":CachedQueries:IssueOption:Id-" <> id.getId

--------- Caching logic for issue option by id and language -------------------

clearAllIssueOptionByIdAndLanguageCache :: CacheFlow m r => Id IssueOption -> Identifier -> m ()
clearAllIssueOptionByIdAndLanguageCache issueOptionId identifier =
  forM_ allLanguages $ \language ->
    clearIssueOptionByIdAndLanguageCache issueOptionId language identifier

clearIssueOptionByIdAndLanguageCache :: CacheFlow m r => Id IssueOption -> Language -> Identifier -> m ()
clearIssueOptionByIdAndLanguageCache issueOptionId language identifier = Hedis.withCrossAppRedis . Hedis.del $ makeIssueOptionByIdAndLanguageKey issueOptionId language identifier

cacheIssueOptionByIdAndLanguage :: CacheFlow m r => Id IssueOption -> Language -> Identifier -> Maybe (IssueOption, Maybe IssueTranslation) -> m ()
cacheIssueOptionByIdAndLanguage issueOptionId language identifier issueOptionTranslation = do
  expTime <- fromIntegral <$> asks (.cacheConfig.configsExpTime)
  Hedis.withCrossAppRedis $ Hedis.setExp (makeIssueOptionByIdAndLanguageKey issueOptionId language identifier) issueOptionTranslation expTime

makeIssueOptionByIdAndLanguageKey :: Id IssueOption -> Language -> Identifier -> Text
makeIssueOptionByIdAndLanguageKey id language identifier = show identifier <> ":CachedQueries:IssueOption:Id-" <> id.getId <> ":Language-" <> show language

--------- Caching logic for issue option by id and issueCategoryId -------------------

clearIssueOptionByIdAndIssueCategoryIdCache :: CacheFlow m r => Id IssueOption -> Id IssueCategory -> Identifier -> m ()
clearIssueOptionByIdAndIssueCategoryIdCache issueOptionId issueCategoryId identifier = Hedis.withCrossAppRedis . Hedis.del $ makeIssueOptionByIdAndIssueCategoryIdKey issueOptionId issueCategoryId identifier

cacheIssueOptionByIdAndIssueCategoryId :: CacheFlow m r => Id IssueOption -> Id IssueCategory -> Identifier -> Maybe IssueOption -> m ()
cacheIssueOptionByIdAndIssueCategoryId issueOptionId issueCategoryId identifier issueOptionTranslation = do
  expTime <- fromIntegral <$> asks (.cacheConfig.configsExpTime)
  Hedis.withCrossAppRedis $ Hedis.setExp (makeIssueOptionByIdAndIssueCategoryIdKey issueOptionId issueCategoryId identifier) issueOptionTranslation expTime

makeIssueOptionByIdAndIssueCategoryIdKey :: Id IssueOption -> Id IssueCategory -> Identifier -> Text
makeIssueOptionByIdAndIssueCategoryIdKey id issueCategoryId identifier = show identifier <> ":CachedQueries:IssueOption:Id-" <> id.getId <> ":IssueCategoryId-" <> show issueCategoryId

--------- Caching logic for issue option by issueMessageId & language -------------------

clearAllIssueOptionByMessageAndLanguageCache :: CacheFlow m r => Id IssueMessage -> Identifier -> m ()
clearAllIssueOptionByMessageAndLanguageCache issueMessageId identifier =
  forM_ allLanguages $ \language ->
    clearIssueOptionByMessageAndLanguageCache issueMessageId language identifier

clearIssueOptionByMessageAndLanguageCache :: CacheFlow m r => Id IssueMessage -> Language -> Identifier -> m ()
clearIssueOptionByMessageAndLanguageCache issueMessageId language identifier = Hedis.withCrossAppRedis . Hedis.del $ makeIssueOptionByMessageAndLanguageKey issueMessageId language identifier

cacheAllIssueOptionByMessageAndLanguage :: CacheFlow m r => Id IssueMessage -> Language -> Identifier -> [(IssueOption, Maybe IssueTranslation)] -> m ()
cacheAllIssueOptionByMessageAndLanguage issueMessageId language identifier issueOption = do
  expTime <- fromIntegral <$> asks (.cacheConfig.configsExpTime)
  Hedis.withCrossAppRedis $ Hedis.setExp (makeIssueOptionByMessageAndLanguageKey issueMessageId language identifier) issueOption expTime

makeIssueOptionByMessageAndLanguageKey :: Id IssueMessage -> Language -> Identifier -> Text
makeIssueOptionByMessageAndLanguageKey issueMessageId language identifier = show identifier <> ":CachedQueries:IssueOption:IssueMessageId-" <> getId issueMessageId <> ":Language-" <> show language
