{-
 Copyright 2022-23, Juspay India Pvt Ltd

 This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License

 as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program

 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY

 or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of

 the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}

module Tools.Error
  ( module Tools.Error,
    module Error,
  )
where

import Data.Aeson (decode)
import Kernel.Prelude
import Kernel.Types.Error as Error hiding (MerchantError)
import Kernel.Types.Error.BaseError.HTTPError.FromResponse
import Kernel.Types.Error.BaseError.HTTPError.HttpCode
import Kernel.Utils.Common hiding (Error)
import Network.HTTP.Types.Status
import Servant.Client

data Error = Error
  { statusCode :: HttpCode,
    contents :: ErrorResponseContents
  }
  deriving (Show, Generic, IsAPIError)

data ErrorResponseContents = ErrorResponseContents
  { errorCode :: Text,
    errorMessage :: Maybe Text
  }
  deriving (Show, Generic, ToJSON, FromJSON, IsAPIError)

instance FromResponse Error where
  fromResponse (Response (Status code _) _ _ body) = Error (codeToHttpCodeWith500Default code) <$> decode body

instance IsHTTPError Error where
  toErrorCode err = err.contents.errorCode
  toHttpCode err = err.statusCode

instance IsBaseError Error where
  toMessage err = err.contents.errorMessage

instance IsBecknAPIError Error where
  toType _ = DOMAIN_ERROR

instanceExceptionWithParent 'HTTPException ''Error

data RoleError
  = RoleNotFound Text
  | RoleDoesNotExist Text
  | RoleNameExists Text
  deriving (Eq, Show, IsBecknAPIError)

instanceExceptionWithParent 'HTTPException ''RoleError

instance IsBaseError RoleError where
  toMessage = \case
    RoleNotFound roleId -> Just $ "Role with roleId \"" <> show roleId <> "\" not found."
    RoleDoesNotExist roleId -> Just $ "No role matches passed data \"" <> show roleId <> "\" not exist."
    RoleNameExists name -> Just $ "Role with name \"" <> show name <> "\" already exists."

instance IsHTTPError RoleError where
  toErrorCode = \case
    RoleNotFound _ -> "ROLE_NOT_FOUND"
    RoleDoesNotExist _ -> "ROLE_DOES_NOT_EXIST"
    RoleNameExists _ -> "ROLE_NAME_ALREADY_EXISTS"
  toHttpCode = \case
    RoleNotFound _ -> E500
    RoleDoesNotExist _ -> E400
    RoleNameExists _ -> E400

instance IsAPIError RoleError

data MerchantError
  = MerchantAlreadyExist Text
  | MerchantAccountLimitExceeded Text
  | UserDisabled
  deriving (Eq, Show, IsBecknAPIError)

instanceExceptionWithParent 'HTTPException ''MerchantError

instance IsBaseError MerchantError where
  toMessage = \case
    MerchantAlreadyExist shortId -> Just $ "Merchant with shortId \"" <> show shortId <> "\" already exist."
    MerchantAccountLimitExceeded shortId -> Just $ "Merchant with shortId \"" <> show shortId <> "\" already exist."
    UserDisabled -> Just "User is disabled. Contact admin"

instance IsHTTPError MerchantError where
  toErrorCode = \case
    MerchantAlreadyExist _ -> "MERCHANT_ALREADY_EXIST"
    MerchantAccountLimitExceeded _ -> "MERCHANT_ACCOUNT_LIMIT_EXCEEDED"
    UserDisabled -> "USER_DISABLED"
  toHttpCode = \case
    MerchantAlreadyExist _ -> E400
    MerchantAccountLimitExceeded _ -> E400
    UserDisabled -> E400

instance IsAPIError MerchantError

------------------ CAC ---------------------
-- This is for temporary implementation of the CAC auth API. This will be depcricated once we have SSO for CAC.
data CacAuthError = CacAuthError | CacInvalidToken
  deriving (Eq, Show, IsBecknAPIError)

instanceExceptionWithParent 'HTTPException ''CacAuthError

instance IsBaseError CacAuthError where
  toMessage = \case
    CacAuthError -> Just "Auth Token Missing !!!!!!!!"
    CacInvalidToken -> Just "Invalid Auth Token !!!!!!!!"

instance IsHTTPError CacAuthError where
  toErrorCode = \case
    CacAuthError -> "CAC_AUTH_ERROR"
    CacInvalidToken -> "CAC_INVALID_TOKEN"
  toHttpCode = \case
    CacAuthError -> E401
    CacInvalidToken -> E401

instance IsAPIError CacAuthError
