{-
 
  Copyright 2022-23, Juspay India Pvt Ltd
 
  This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License
 
  as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program
 
  is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 
  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of
 
  the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}

module Screens.AboutUsScreen.Handler where

import Prelude (Unit, bind, pure, discard, ($), (<$>))
import Engineering.Helpers.BackTrack (getState)
import Screens.AboutUsScreen.Controller (ScreenOutput(..))
import Control.Monad.Except.Trans (lift)
import Control.Transformers.Back.Trans as App
import PrestoDOM.Core.Types.Language.Flow (runScreen)
import Screens.AboutUsScreen.View as AboutUsScreen
import ModifyScreenState (modifyScreenState)
import Types.App (FlowBT, GlobalState(..), ABOUT_US_SCREEN_OUTPUT(..), ScreenType(..))


aboutUsScreen :: FlowBT String ABOUT_US_SCREEN_OUTPUT
aboutUsScreen = do
  (GlobalState state) <- getState
  action <- lift $ lift $ runScreen $ AboutUsScreen.screen state.aboutUsScreen
  case action of
    GoToHomeScreen state -> do
      modifyScreenState $ AboutUsScreenStateType (\_ → state)
      App.BackT $ App.BackPoint <$> (pure $ GO_TO_HOME_FROM_ABOUT)
