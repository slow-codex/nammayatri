{-
 
  Copyright 2022-23, Juspay India Pvt Ltd
 
  This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License
 
  as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program
 
  is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 
  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of
 
  the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}

module Screens.TripDetailsScreen.Controller where

import Common.Types.App (CategoryListType, ProviderType(..), LazyCheck(..))
import Components.GenericHeader as GenericHeaderController
import Components.PopUpModal as PopUpModalController
import Components.PrimaryButton as PrimaryButtonController
import Components.SourceToDestination as SourceToDestinationController
import Data.Array (null)
import Data.String (length)
import Data.String (trim)
import JBridge (hideKeyboardOnNavigation, copyToClipboard, showDialer, openUrlInApp, openUrlInMailApp)
import Language.Strings (getString)
import Engineering.Helpers.Utils (showToast)
import Language.Types (STR(..))
import Log (trackAppActionClick, trackAppEndScreen, trackAppScreenRender, trackAppBackPress, trackAppScreenEvent, trackAppTextInput)
import Prelude (class Show, pure, unit, not, bind, ($), (>), discard, void, (==), (<>))
import PrestoDOM (Eval, update, continue, continueWithCmd, exit, updateAndExit)
import PrestoDOM.Types.Core (class Loggable)
import Screens (ScreenName(..), getScreen)
import Screens.Types (TripDetailsScreenState, TripDetailsGoBackType)
import MerchantConfig.Utils (Merchant(..), getMerchant)
import ConfigProvider 
import Services.Config (getSupportNumber)
import Resources.Constants (mailToLink)
import Helpers.Utils (emitTerminateApp, isParentView)
import Data.Maybe (Maybe(..))

instance showAction :: Show Action where
    show _ = ""

instance loggableAction :: Loggable Action where
    performLog action appId = case action of
        AfterRender -> trackAppScreenRender appId "screen" (getScreen TRIP_DETAILS_SCREEN)
        BackPressed -> do
            trackAppBackPress appId (getScreen TRIP_DETAILS_SCREEN)
            trackAppEndScreen appId (getScreen TRIP_DETAILS_SCREEN)
        GenericHeaderActionController act -> case act of
            GenericHeaderController.PrefixImgOnClick -> do
                trackAppActionClick appId (getScreen TRIP_DETAILS_SCREEN) "generic_header_action" "back_icon"
                trackAppEndScreen appId (getScreen TRIP_DETAILS_SCREEN)
            GenericHeaderController.SuffixImgOnClick -> trackAppActionClick appId (getScreen TRIP_DETAILS_SCREEN) "generic_header_action" "forward_icon"
        ReportIssue -> trackAppActionClick appId (getScreen TRIP_DETAILS_SCREEN) "in_screen" "report_issue"
        MessageTextChanged str -> trackAppActionClick appId (getScreen TRIP_DETAILS_SCREEN) "in_screen" "message_text_changed"
        ViewInvoice -> trackAppActionClick appId (getScreen TRIP_DETAILS_SCREEN) "in_screen" "view_invoice"
        Copy -> trackAppActionClick appId (getScreen TRIP_DETAILS_SCREEN) "in_screen" "copy"
        ShowPopUp -> trackAppActionClick appId (getScreen TRIP_DETAILS_SCREEN) "in_screen" "show_confirmation_popup"
        PopUpModalAction act -> case act of
            PopUpModalController.OnButton1Click -> trackAppActionClick appId (getScreen TRIP_DETAILS_SCREEN) "popup_modal_action" "contact_driver_decline"
            PopUpModalController.OnButton2Click -> do
                trackAppActionClick appId (getScreen TRIP_DETAILS_SCREEN) "popup_modal_action" "contact_driver_accept"
                trackAppEndScreen appId (getScreen TRIP_DETAILS_SCREEN)
            PopUpModalController.NoAction -> trackAppActionClick appId (getScreen TRIP_DETAILS_SCREEN) "popup_modal_action" "no_action"
            PopUpModalController.OnImageClick -> trackAppActionClick appId (getScreen TRIP_DETAILS_SCREEN) "popup_modal_action" "image"
            PopUpModalController.ETextController act -> trackAppTextInput appId (getScreen TRIP_DETAILS_SCREEN) "popup_modal_action" "primary_edit_text"
            PopUpModalController.CountDown arg1 arg2 arg3 -> trackAppScreenEvent appId (getScreen TRIP_DETAILS_SCREEN) "popup_modal_action" "countdown_updated"
            PopUpModalController.OnSecondaryTextClick -> trackAppScreenEvent appId (getScreen TRIP_DETAILS_SCREEN) "popup_modal_action" "secondary_text_clicked"
            PopUpModalController.OptionWithHtmlClick -> trackAppScreenEvent appId (getScreen TRIP_DETAILS_SCREEN) "popup_modal_action" "option_with_html_clicked"
            PopUpModalController.DismissPopup -> trackAppScreenEvent appId (getScreen TRIP_DETAILS_SCREEN) "popup_modal_action" "popup_dismissed"
            PopUpModalController.YoutubeVideoStatus _ -> trackAppScreenEvent appId (getScreen TRIP_DETAILS_SCREEN) "popup_modal_action" "youtube_video_status"
            _ -> pure unit
        SourceToDestinationActionController _ -> trackAppScreenEvent appId (getScreen TRIP_DETAILS_SCREEN) "in_screen" "source_to_destination"
        NoAction -> trackAppScreenEvent appId (getScreen TRIP_DETAILS_SCREEN) "in_screen" "no_action"
        OpenChat arg1 -> trackAppScreenEvent appId (getScreen TRIP_DETAILS_SCREEN) "in_screen" "open_chat"
        ListExpandAinmationEnd -> trackAppScreenEvent appId (getScreen TRIP_DETAILS_SCREEN) "in_screen" "list_expand_animation_end"
        ContactSupportPopUpAction act -> case act of
            PopUpModalController.OnButton1Click -> trackAppActionClick appId (getScreen TRIP_DETAILS_SCREEN) "popup_modal_action" "contact_driver_decline"
            PopUpModalController.OnButton2Click -> do
                trackAppActionClick appId (getScreen TRIP_DETAILS_SCREEN) "popup_modal_action" "contact_driver_accept"
                trackAppEndScreen appId (getScreen TRIP_DETAILS_SCREEN)
            PopUpModalController.NoAction -> trackAppActionClick appId (getScreen TRIP_DETAILS_SCREEN) "popup_modal_action" "no_action"
            PopUpModalController.OnImageClick -> trackAppActionClick appId (getScreen TRIP_DETAILS_SCREEN) "popup_modal_action" "image"
            PopUpModalController.ETextController act -> trackAppTextInput appId (getScreen TRIP_DETAILS_SCREEN) "popup_modal_action" "primary_edit_text"
            PopUpModalController.CountDown arg1 arg2 arg3 -> trackAppScreenEvent appId (getScreen TRIP_DETAILS_SCREEN) "popup_modal_action" "countdown_updated"
            PopUpModalController.OnSecondaryTextClick -> trackAppScreenEvent appId (getScreen TRIP_DETAILS_SCREEN) "popup_modal_action" "secondary_text_clicked"
            PopUpModalController.OptionWithHtmlClick -> trackAppScreenEvent appId (getScreen TRIP_DETAILS_SCREEN) "popup_modal_action" "option_with_html_clicked"
            PopUpModalController.DismissPopup -> trackAppScreenEvent appId (getScreen TRIP_DETAILS_SCREEN) "popup_modal_action" "popup_dismissed"
            PopUpModalController.YoutubeVideoStatus _ -> trackAppScreenEvent appId (getScreen TRIP_DETAILS_SCREEN) "popup_modal_action" "youtube_video_status"
            _ -> pure unit

data Action = GenericHeaderActionController GenericHeaderController.Action
            | SourceToDestinationActionController SourceToDestinationController.Action 
            | BackPressed
            | ReportIssue 
            | MessageTextChanged String
            | ViewInvoice
            | AfterRender
            | NoAction
            | Copy
            | ShowPopUp
            | PopUpModalAction PopUpModalController.Action
            | OpenChat CategoryListType
            | ListExpandAinmationEnd
            | ContactSupportPopUpAction PopUpModalController.Action

data ScreenOutput = GoBack TripDetailsGoBackType TripDetailsScreenState | GoToInvoice TripDetailsScreenState | GoHome TripDetailsScreenState | ConnectWithDriver TripDetailsScreenState | GetCategorieList TripDetailsScreenState | GoToIssueChatScreen TripDetailsScreenState CategoryListType

eval :: Action -> TripDetailsScreenState -> Eval Action ScreenOutput TripDetailsScreenState

eval BackPressed state = 
    if isParentView FunctionCall
        then do
            void $ pure $ emitTerminateApp Nothing true
            continue state
        else
            exit $ GoBack state.props.fromMyRides state

eval ShowPopUp state = continue state{props{showConfirmationPopUp = true}}


eval (PopUpModalAction (PopUpModalController.OnButton1Click)) state = continue state{props{showConfirmationPopUp = false}}

eval (PopUpModalAction (PopUpModalController.OnButton2Click)) state = exit $ ConnectWithDriver state{props{showConfirmationPopUp = false}}

eval (ContactSupportPopUpAction (PopUpModalController.DismissPopup)) state = continue state{props{isContactSupportPopUp = false}}

eval (ContactSupportPopUpAction (PopUpModalController.OnSecondaryTextClick)) state =   
    continueWithCmd state{props{isContactSupportPopUp = false}} [do
        void $ openUrlInMailApp $ mailToLink <> (getAppConfig appConfig).appData.supportMail
        pure NoAction
    ]

eval (ContactSupportPopUpAction (PopUpModalController.OnButton1Click)) state = do
    void $ pure $ showDialer (getSupportNumber "") false
    continue state{props{isContactSupportPopUp = false}}

eval (ContactSupportPopUpAction (PopUpModalController.OnButton2Click)) state = continueWithCmd state [pure $ ContactSupportPopUpAction PopUpModalController.DismissPopup]

eval ViewInvoice state = do
    let onUsRide  = state.data.selectedItem.providerType == ONUS
    if onUsRide then exit $ GoToInvoice state
        else do 
            void $ pure $ showToast $ getString OTHER_PROVIDER_NO_RECEIPT
            continue state

eval ReportIssue state =  do
    if state.data.config.feature.enableHelpAndSupport
        then do 
            let updatedState = state { props { reportIssue = not state.props.reportIssue, showIssueOptions = true } }
            if  null state.data.categories then exit $ GetCategorieList updatedState else continue updatedState
        else continue state {props{isContactSupportPopUp = true}}

eval (MessageTextChanged a) state = continue state { data { message = trim(a) }, props{activateSubmit = if (length (trim(a)) > 1) then true else false}}

eval (GenericHeaderActionController (GenericHeaderController.PrefixImgOnClick )) state = continueWithCmd state [do pure BackPressed]

eval Copy state = continueWithCmd state [ do 
    _ <- pure $ copyToClipboard state.data.tripId
    _ <- pure $ showToast (getString COPIED)
    pure NoAction
  ]

eval (OpenChat item) state = exit $ GoToIssueChatScreen state item

eval AfterRender state = continue state {props {triggerUIUpdate = not state.props.triggerUIUpdate}}

eval ListExpandAinmationEnd state = continue state {props {showIssueOptions = false }}

eval _ state = update state