{-
 
  Copyright 2022-23, Juspay India Pvt Ltd
 
  This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License
 
  as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program
 
  is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 
  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of
 
  the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}

module Screens.HotspotScreen.ScreenData where

import ConfigProvider
import Engineering.Helpers.Commons as EHC
import Foreign.Object (empty)
import Services.API (LatLong(..))
import Screens.Types (HotspotScreenState(..))

initData :: HotspotScreenState
initData =
  { data:
      { pointsWithWeight : []
      , dataExpiryAt : ""
      , currentDriverLat : 0.0
      , currentDriverLon : 0.0
      , config : getAppConfig appConfig
      , logField : empty
      }
  , props:
      { lastUpdatedTime : ""
      , showNavigationSheet : false
      , refreshAnimation : false
      , selectedCircleColor : ""
      , selectedCircleLatLng : LatLong { lat : 0.0, lon : 0.0}
      , isAnyCircleSelected : false
      , mapCorners : {
          leftPoint : ""
        , topPoint : ""
        , rightPoint : ""
        , bottomPoint : ""
        }
      }
  }
