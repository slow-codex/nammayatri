{-
 
  Copyright 2022-23, Juspay India Pvt Ltd
 
  This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License
 
  as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program
 
  is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 
  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of
 
  the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}

module Screens.AboutUsScreen.View where

import Common.Types.App
import Screens.CustomerUtils.AboutUsScreen.ComponentConfig

import Animation as Anim
import Common.Types.App (LazyCheck(..))
import Components.ComplaintsModel as ComplaintsModel
import Components.GenericHeader as GenericHeader
import Data.Maybe (Maybe(..), fromMaybe)
import Effect (Effect)
import Engineering.Helpers.Commons as EHC
import Font.Size as FontSize
import Font.Style as FontStyle
import Helpers.Utils (fetchImage, FetchImageFrom(..), getCityConfig)
import JBridge as JB
import Language.Strings (getString, getVarString)
import Components.MenuButton as MenuButton
import Components.PrimaryButton as PrimaryButton
import RemoteConfig as RemoteConfig
import Language.Types (STR(..))
import Prelude (Unit, bind, const, pure, unit, ($), (<<<), (==), (<>), not, (&&))
import PrestoDOM (Gravity(..), Length(..), Margin(..), Orientation(..), Padding(..), PrestoDOM, Screen, Visibility(..), Accessiblity(..), afterRender, accessibility, background, color, cornerRadius, fontStyle, gravity, height, imageUrl, imageView, imageWithFallback, lineHeight, linearLayout, margin, onBackPressed, onClick, orientation, padding, scrollBarY, scrollView, text, textSize, textView, visibility, weight, width, accessibilityHint)
import Screens.AboutUsScreen.Controller (Action(..), ScreenOutput, eval)
import Screens.CustomerUtils.AboutUsScreen.ComponentConfig (genericHeaderConfig)
import Screens.Types as ST
import Storage (KeyStore(..), getValueToLocalStore)
import Styles.Colors as Color
import Data.Function.Uncurried (runFn3)
import DecodeUtil (getAnyFromWindow)
import Data.String as DS
import Data.Array as DA

screen :: ST.AboutUsScreenState -> Screen Action ST.AboutUsScreenState ScreenOutput
screen initialState =
  { initialState
  , view
  , name : "AboutUsScreen"
  , globalEvents : []
  , eval
  }

view :: forall w . (Action -> Effect Unit) -> ST.AboutUsScreenState -> PrestoDOM (Effect Unit) w
view push state =
  Anim.screenAnimation $
    linearLayout 
    [ height MATCH_PARENT
    , width MATCH_PARENT
    , orientation VERTICAL
    , onBackPressed push (const BackPressed) 
    , background Color.white900
    , padding if EHC.os == "IOS" then (Padding 0 EHC.safeMarginTop 0 EHC.safeMarginBottom) else (Padding 0 0 0 10)
    , gravity CENTER_HORIZONTAL
    , afterRender push (const AfterRender)
    
    ][  GenericHeader.view (push <<< GenericHeaderActionController) (genericHeaderConfig state)
      , if (not state.appConfig.nyBrandingVisibility) then
                  linearLayout
                    [ height $ V 1
                    , width MATCH_PARENT
                    , background Color.greySmoke
                    ]
                    []
                  else
                    linearLayout [] []
      , scrollView
        [ width MATCH_PARENT
        , scrollBarY false
        ][  
          if state.props.demoModePopup then toggleCityView push state else aboutUsView push state
          ]
      ]

toggleCityView :: forall w . (Action -> Effect Unit) -> ST.AboutUsScreenState -> PrestoDOM (Effect Unit) w
toggleCityView push state = 
  linearLayout
    [ height MATCH_PARENT
    , width MATCH_PARENT
    , orientation VERTICAL
    , padding (Padding 16 0 16 0)
    , background Color.white900
    ][ logoView state push
     , menuButtonsView state push
    ] 

aboutUsView :: forall w . (Action -> Effect Unit) -> ST.AboutUsScreenState -> PrestoDOM (Effect Unit) w
aboutUsView push state =
  linearLayout
    [ height WRAP_CONTENT
    , width MATCH_PARENT
    , orientation VERTICAL
    ][ topTextView push state
     , linearLayout
      [ orientation VERTICAL
      , weight 1.0
      ][]
    , bottomLinksView state
    ]

------------------------------ menuButtonsView ------------------------------
menuButtonsView :: ST.AboutUsScreenState -> (Action -> Effect Unit) -> forall w . PrestoDOM (Effect Unit) w
menuButtonsView state push = 
  let userCities = RemoteConfig.getSwitchCityConfigs FunctionCall
      userCurrCity = getValueToLocalStore CUSTOMER_LOCATION
  in scrollView
      [ width MATCH_PARENT
      , weight 1.0
      ][  linearLayout
          [ height WRAP_CONTENT
          , width MATCH_PARENT
          , orientation VERTICAL
          , margin $ Margin 1 0 1 0
          , background Color.white900
          ][  textView $ 
              [ text "Choose city from the list to toggle configs"
              , color $ Color.black800
              , margin $ MarginTop 16
              ] <> FontStyle.subHeading1 TypoGraphy
          ,  linearLayout
              [   height WRAP_CONTENT
                , width MATCH_PARENT
                , orientation VERTICAL
                , margin $ Margin 1 16 1 0
                , background Color.white900
              ](DA.mapWithIndex
                  (\ index city ->
                  MenuButton.view (push <<< MenuButtonActionController) (menuButtonConfig state city userCurrCity)) userCities.cities
              )
          ]
      ]

--------------------------------------------------- topTextView -----------------------------------------------------
topTextView :: (Action -> Effect Unit)  -> ST.AboutUsScreenState -> forall w . PrestoDOM (Effect Unit) w
topTextView push state =
  let appName = fromMaybe state.appConfig.appData.name $ runFn3 getAnyFromWindow "appName" Nothing Just
  in  linearLayout
      [ height WRAP_CONTENT
      , width MATCH_PARENT
      , orientation VERTICAL
      , padding (Padding 20 0 20 10)
      ][  logoView state push
        , textView $
          [ height WRAP_CONTENT
          , width MATCH_PARENT
          , text $ getVarString ABOUT_APP_DESCRIPTION [appName]
          , color Color.black800
          , gravity LEFT
          , lineHeight "22"
          , margin (Margin 0 40 0 32)
          ] <> FontStyle.body5 LanguageStyle
        , linearLayout
          [ height WRAP_CONTENT
          , width MATCH_PARENT
          , visibility if state.appConfig.showCorporateAddress then VISIBLE else GONE
          ][ ComplaintsModel.view (ComplaintsModel.config{cardData = contactUsData state})]
        , linearLayout
          [ gravity LEFT
          , width WRAP_CONTENT
          , height WRAP_CONTENT
          , orientation VERTICAL
          , visibility if state.appConfig.nyBrandingVisibility then GONE else VISIBLE
          ][  softwareLicenseView state
            , termsAndConditionsView state
            , privacyPolicyView state
            ]
        ]

--------------------------------------------------- logoView -----------------------------------------------------
logoView :: forall w . ST.AboutUsScreenState -> (Action -> Effect Unit) -> PrestoDOM (Effect Unit) w
logoView state push = 
  let 
    cityConfig = getCityConfig state.appConfig.cityConfig $ getValueToLocalStore CUSTOMER_LOCATION
    appLogo = if DS.null cityConfig.appLogo then state.appConfig.merchantLogo else cityConfig.appLogo
  in linearLayout
        [ height WRAP_CONTENT
        , width MATCH_PARENT
        , gravity CENTER
        , margin $ MarginTop 48
        ][  imageView
              [ height $ V 52
              , width $ V 176
              , imageWithFallback appLogo
              , onClick push (const ShowDemoPopUp)
              ]
          ]

--------------------------------------------------- bottomLinksView -----------------------------------------------------
bottomLinksView :: ST.AboutUsScreenState -> forall w. PrestoDOM (Effect Unit) w
bottomLinksView state =
  linearLayout
    [ height WRAP_CONTENT
    , width MATCH_PARENT
    , gravity CENTER
    , orientation VERTICAL
    ]
    [ linearLayout
        [ height WRAP_CONTENT
        , width MATCH_PARENT
        , orientation VERTICAL
        , gravity CENTER
        , visibility if state.appConfig.nyBrandingVisibility then VISIBLE else GONE
        ]
        [ textView
            $ [ height WRAP_CONTENT
              , width WRAP_CONTENT
              , text "Powered by"
              , color Color.black800
              , gravity CENTER_VERTICAL
              , lineHeight "22"
              ]
            <> FontStyle.paragraphText LanguageStyle
        , linearLayout
            [ height $ V 25
            , width MATCH_PARENT
            , orientation HORIZONTAL
            , gravity CENTER
            ]
            [ imageView
                [ height $ V 20
                , width $ V 20
                , imageWithFallback $ fetchImage FF_ASSET "ic_launcher"
                ]
            , textView
                $ [ text $ "namma yatri"
                  , color Color.black
                  , margin $ Margin 3 0 0 2
                  , height WRAP_CONTENT
                  , width WRAP_CONTENT
                  , gravity CENTER
                  ]
                <> FontStyle.h2 LanguageStyle
            ]
        ]
    , textView
        $ [ width WRAP_CONTENT
          , height WRAP_CONTENT
          , accessibility ENABLE
          , accessibilityHint $ "App Version : " <>  (getValueToLocalStore VERSION_NAME) <> " : Bundle Version : " <> (getValueToLocalStore BUNDLE_VERSION)
          , text $ "v" <> (getValueToLocalStore VERSION_NAME) <> " [ " <> (getValueToLocalStore BUNDLE_VERSION) <> " ]"
          , color "#354052"
          , margin (Margin 0 20 0 10)
          , accessibility DISABLE
          ]
        <> FontStyle.body6 LanguageStyle
    ]
  
--------------------------------------------------- softwareLicenseView -----------------------------------------------------
softwareLicenseView :: forall w . ST.AboutUsScreenState -> PrestoDOM (Effect Unit) w
softwareLicenseView state = 
  linearLayout
    [ height WRAP_CONTENT
    , orientation VERTICAL
    , width WRAP_CONTENT
    ][  linearLayout
        [ height WRAP_CONTENT
        , orientation VERTICAL
        , width WRAP_CONTENT
        , visibility GONE
        ][  textView $
            [ width WRAP_CONTENT
            , height WRAP_CONTENT
            , text (getString SOFTWARE_LICENSE)
            , color Color.blue900
            , margin (Margin 0 0 0 0)
            ] <> FontStyle.paragraphText LanguageStyle
          , linearLayout
            [ width MATCH_PARENT
            , height (V 1)
            , background Color.blue900
            ][]
          ]
        ]
      
--------------------------------------------------- termsAndConditionsView -----------------------------------------------------      
termsAndConditionsView :: ST.AboutUsScreenState -> forall w . PrestoDOM (Effect Unit) w
termsAndConditionsView state =
  linearLayout
    [ height WRAP_CONTENT
    , width WRAP_CONTENT
    , orientation VERTICAL
    ][  textView $
        [ width WRAP_CONTENT
        , height WRAP_CONTENT
        , text (getString TERMS_AND_CONDITIONS)
        , accessibilityHint "Terms and Conditions : Button"
        , accessibility ENABLE
        , color Color.blue900
        , onClick (\action -> do
            _ <- pure action
            _ <- JB.openUrlInApp $ state.appConfig.termsLink
            pure unit
          ) (const TermsAndConditions)
        , margin (Margin 0 20 0 0)
        ] <> FontStyle.paragraphText LanguageStyle
      , linearLayout
              [ width MATCH_PARENT
              , height (V 1)
              , background Color.blue900
              ][]
        ]

--------------------------------------------------- privacyPolicyView -----------------------------------------------------
privacyPolicyView :: forall w .ST.AboutUsScreenState -> PrestoDOM (Effect Unit) w
privacyPolicyView state =
  linearLayout
    [ height WRAP_CONTENT
    , orientation VERTICAL
    , width WRAP_CONTENT
    ][  textView $
        [ width WRAP_CONTENT
        , height WRAP_CONTENT
        , text (getString PRIVACY_POLICY)
        , accessibilityHint "Privacy Policy : Button"
        , accessibility ENABLE
        , color Color.blue900
        , margin (Margin 0 20 0 0)
        , onClick (\action -> do
            _ <- pure action
            _ <- JB.openUrlInApp $ state.appConfig.privacyLink
            pure unit
          ) (const PrivacyPolicy)
        ] <> FontStyle.paragraphText LanguageStyle
      , linearLayout
        [ width MATCH_PARENT
        , height (V 1)
        , background Color.blue900
        ][]
      ]

contactUsData :: ST.AboutUsScreenState -> Array ComplaintsModel.CardData
contactUsData state = [
  { title : (getString CORPORATE_ADDRESS)
  , subTitle : (getString $ CORPORATE_ADDRESS_DESCRIPTION "CORPORATE_ADDRESS_DESCRIPTION")
  , addtionalData : Just (getString $ CORPORATE_ADDRESS_DESCRIPTION_ADDITIONAL "CORPORATE_ADDRESS_DESCRIPTION_ADDITIONAL")
  }
, { title : (getString REGISTERED_ADDRESS)
  , subTitle : (getString $ REGISTERED_ADDRESS_DESCRIPTION "REGISTERED_ADDRESS_DESCRIPTION")
  , addtionalData : Just (getString $ REGISTERED_ADDRESS_DESCRIPTION_ADDITIONAL "REGISTERED_ADDRESS_DESCRIPTION_ADDITIONAL")
  }
]


primaryButtonConfig :: ST.AboutUsScreenState -> PrimaryButton.Config
primaryButtonConfig state = let 
    config = PrimaryButton.config
    primaryButtonConfig' = config 
      {   textConfig
         { text = (getString UPDATE)
         } 
        , margin = (Margin 0 0 0 0)
        , id = "UpdateLanguageButton"
      }
  in primaryButtonConfig'

menuButtonConfig :: ST.AboutUsScreenState -> RemoteConfig.UserCity -> String -> MenuButton.Config
menuButtonConfig state userCity currCity = MenuButton.config {
      titleConfig{
          text = userCity.name
        , selectedTextStyle = FontStyle.ParagraphText
        , unselectedTextStyle = FontStyle.ParagraphText
       }
      ,subTitleConfig
      {
        text = userCity.title
      }
      , id = userCity.value
      , isSelected = (userCity.value == currCity)
    }
