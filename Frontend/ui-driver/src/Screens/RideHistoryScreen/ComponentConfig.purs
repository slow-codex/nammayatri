{-
 
  Copyright 2022-23, Juspay India Pvt Ltd
 
  This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License
 
  as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program
 
  is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 
  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of
 
  the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}

module Screens.RideHistoryScreen.ComponentConfig where


import Common.Types.App (LazyCheck(..))
import Components.DatePickerModel as DatePickerModel
import Components.ErrorModal as ErrorModal
import Components.GenericHeader as GenericHeader
import Font.Size as FontSize
import Font.Style as FontStyle
import Helpers.Utils (fetchImage, FetchImageFrom(..), getPastDays)
import Language.Strings (getString)
import Language.Types (STR(..))
import Prelude ((<>), (/=), ($), (==))
import PrestoDOM (Length(..), Margin(..), Padding(..), Visibility(..))
import Resource.Constants (tripDatesCount)
import Screens.Types as ST
import Styles.Colors as Color
import Storage (getValueToLocalStore, KeyStore(..))
import Debug(spy)

vehicleImageurl :: String -> String
vehicleImageurl vehicleVariant = case vehicleVariant of 
                                      "AUTO_RICKSHAW" -> fetchImage FF_ASSET "ny_ic_no_past_rides_auto"
                                      "AMBULANCE" -> fetchImage FF_ASSET "ny_ic_no_rides_history_ambulance"
                                      _ -> fetchImage FF_COMMON_ASSET "ny_ic_no_past_rides"

errorModalConfig :: ST.RideHistoryScreenState -> ErrorModal.Config 
errorModalConfig state = let 
  config = ErrorModal.config 
  errorModalConfig' = config 
    { imageConfig {
        imageUrl = vehicleImageurl (getValueToLocalStore VEHICLE_VARIANT)
      , height = V 110
      , width = V 124
      , margin = (MarginBottom 61)
      }
    , errorConfig {
        text = (getString EMPTY_RIDES)
      , margin = (MarginBottom 7)  
      , color = Color.black900
      }
    , errorDescriptionConfig {
        text = (getString YOU_HAVE_NOT_TAKEN_A_TRIP_YET)
      , color = Color.black700
      }
    , buttonConfig {
        text = (getString BOOK_NOW)
      , margin = (Margin 16 0 16 24)
      , background = Color.black900
      , color = Color.yellow900
      , visibility  = GONE
      }
    , background = Color.transparent
    }
  in errorModalConfig' 

datePickerConfig :: ST.RideHistoryScreenState -> DatePickerModel.Config
datePickerConfig state = let
  config = DatePickerModel.config
  datePickerConfig' = config
    { activeIndex = state.datePickerState.activeIndex
    , dates = getPastDays tripDatesCount
    , id = "DatePickerScrollView"
    }
  in datePickerConfig'
