{-# OPTIONS_GHC -Wno-unused-imports #-}

module API.Action.Dashboard.IssueManagement
  ( API,
    handler,
  )
where

import qualified API.Action.Dashboard.IssueManagement.Issue
import qualified API.Action.Dashboard.IssueManagement.IssueList
import qualified Domain.Types.Merchant
import qualified Environment
import qualified Kernel.Types.Beckn.Context
import qualified Kernel.Types.Id
import Servant

type API = (API.Action.Dashboard.IssueManagement.Issue.API :<|> API.Action.Dashboard.IssueManagement.IssueList.API)

handler :: (Kernel.Types.Id.ShortId Domain.Types.Merchant.Merchant -> Kernel.Types.Beckn.Context.City -> Environment.FlowServer API)
handler merchantId city = API.Action.Dashboard.IssueManagement.Issue.handler merchantId city :<|> API.Action.Dashboard.IssueManagement.IssueList.handler merchantId city
