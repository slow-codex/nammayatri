{-
 
  Copyright 2022-23, Juspay India Pvt Ltd
 
  This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License
 
  as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program
 
  is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 
  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of
 
  the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}

module Screens.TicketBookingFlow.MetroMyTickets.Handler where

import Engineering.Helpers.BackTrack 
import Prelude 
import Screens.TicketBookingFlow.MetroMyTickets.Controller 
import Control.Monad.Except.Trans 
import Control.Transformers.Back.Trans as App
import PrestoDOM.Core.Types.Language.Flow
import ModifyScreenState 
import Screens.TicketBookingFlow.MetroMyTickets.View as MetroMyTickets
import Types.App 
import Screens.Types as ST


metroMyTicketsScreen :: FlowBT String METRO_MY_TICKETS_SCREEN_OUTPUT
metroMyTicketsScreen = do
  (GlobalState state) <- getState
  action <- lift $ lift $ runScreen $ MetroMyTickets.screen state.metroMyTicketsScreen{ props{ showShimmer = true } }
  case action of
    GoToMetroTicketDetailsFlow bookingId -> do 
      App.BackT $ App.BackPoint <$> (pure $ GO_TO_METRO_TICKET_DETAILS_FLOW bookingId)
    GoToMetroTicketStatusFlow bookingStatusApiResp -> do 
      App.BackT $ App.BackPoint <$> (pure $ GO_TO_METRO_TICKET_STAUS_FLOW bookingStatusApiResp)
    GoToHomeScreen ->  App.BackT $ App.BackPoint <$> (pure $ GO_HOME_FROM_METRO_MY_TICKETS ) 
    GoToMetroBooking -> App.BackT $ App.BackPoint <$> (pure $ GO_METRO_BOOKING_FROM_METRO_MY_TICKETS)
    GoToBusBookingScreen -> App.BackT $ App.BackPoint <$> (pure $ GO_BUS_BOOKING_FROM_METRO_MY_TICKETS)
    _  -> App.BackT $ App.NoBack <$> (pure $ METRO_MY_TICKETS_SCREEN_OUTPUT_NO_OUTPUT)
