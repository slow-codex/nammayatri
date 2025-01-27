module Screens.TicketBookingFlow.TicketStatus.View where

import Common.Types.App
import Screens.TicketBookingFlow.TicketStatus.ComponentConfig

import Animation as Anim
import Animation.Config (translateYAnimConfig, translateYAnimMapConfig, removeYAnimFromTopConfig)
import Domain.Payments as PP
import Components.GenericHeader as GenericHeader
import Components.PrimaryButton as PrimaryButton
import Data.Array as DA
import Data.Array (length, uncons, cons, take, drop, find, elem, mapWithIndex, filter, null)
import Data.Foldable (or)
import Data.String (Pattern(..), Replacement(..), replace)
import Data.String as DS
import Data.String.Common (joinWith)
import Effect (Effect)
import Engineering.Helpers.Commons (getCurrentUTC, screenWidth, flowRunner)
import Data.Foldable (foldl, foldMap)
import Font.Size as FontSize
import Font.Style as FontStyle
import Helpers.Utils (incrOrDecrTimeFrom, getCurrentDatev2, getMinutesBetweenTwoUTChhmmss, fetchImage, FetchImageFrom(..), decodeError, convertUTCToISTAnd12HourFormat, fetchAndUpdateCurrentLocation, getAssetsBaseUrl, getCurrentLocationMarker, getLocationName, getNewTrackingId, getSearchType, parseFloat, storeCallBackCustomer)
import JBridge as JB
import Prelude (not, Unit, discard, void, bind, const, pure, unit, ($), (&&), (/=), (&&), (<<<), (+), (<>), (==), map, show, (||), show, (-), (>), (>>=), mod, negate, (<=), (>=), (<))
import PrestoDOM (FlexWrap(..), Gravity(..), Length(..), Margin(..), Orientation(..), Padding(..), PrestoDOM, Prop, Screen, Visibility(..), shimmerFrameLayout, afterRender, alignParentBottom, background, color, cornerRadius, fontStyle, gravity, height, imageUrl, imageView, imageWithFallback, layoutGravity, linearLayout, margin, onBackPressed, onClick, orientation, padding, relativeLayout, scrollView, stroke, text, textFromHtml, textSize, textView, visibility, weight, width, clickable, id, imageUrl, maxLines, ellipsize, lineHeight, fillViewport)
import PrestoDOM.Animation as PrestoAnim
import Screens.TicketBookingFlow.TicketStatus.Controller (Action(..), ScreenOutput, eval)
import Screens.Types as ST
import Styles.Colors as Color
import Screens.TicketBookingFlow.TicketStatus.ComponentConfig 
import Resources.Constants -- TODO:: Replace these constants with API response
import Engineering.Helpers.Commons (screenWidth, convertUTCtoISC, getNewIDWithTag, convertUTCTimeToISTTimeinHHMMSS)
import Services.API (BookingStatus(..), TicketPlaceResponse(..), TicketPlaceResp(..), TicketServiceResp(..), PlaceType(..), BusinessHoursResp(..), PeopleCategoriesResp(..), TicketCategoriesResp(..), TicketServicesResponse(..), SpecialDayType(..))
import Animation (fadeInWithDelay, translateInXBackwardAnim, translateInXBackwardFadeAnimWithDelay, translateInXForwardAnim, translateInXForwardFadeAnimWithDelay)
import Halogen.VDom.DOM.Prop (Prop)
import Data.Array (catMaybes, head, (..), any)
import Data.Maybe (fromMaybe, isJust, Maybe(..), maybe)
import Debug
import Effect.Aff (launchAff)
import Types.App (defaultGlobalState)
import Control.Monad.Except.Trans (runExceptT , lift)
import Control.Transformers.Back.Trans (runBackT)
import Services.Backend as Remote
import Data.Either (Either(..))
import Presto.Core.Types.Language.Flow (doAff, Flow)
import Helpers.Pooling(delay)
import Effect.Class (liftEffect)
import Types.App (GlobalState, defaultGlobalState)
import Data.Time.Duration (Milliseconds(..))
import Services.API as API
import Storage (KeyStore(..), setValueToLocalStore, getValueToLocalStore)
import Effect.Uncurried  (runEffectFn1)
import PaymentPage (consumeBP)
import Engineering.Helpers.Commons as EHC
import Data.Ord (comparing)
import Data.Function.Uncurried (runFn3)
import Mobility.Prelude (groupAdjacent, boolToVisibility)
import Language.Strings (getString)
import Language.Types (STR(..))
import Domain.Payments as PP

screen :: ST.TicketBookingScreenState -> Screen Action ST.TicketBookingScreenState ScreenOutput
screen initialState =
  { initialState
  , view
  , name : "TicketBookingScreen"
  , globalEvents : [getPlaceDataEvent]
  , eval :
    \action state -> do
        let _ = spy "ZooTicketBookingFlow TicketStatus action " action
        let _ = spy "ZooTicketBookingFlow TicketStatus state " state
        eval action state
  }
  where
  getPlaceDataEvent push = do
    void $ runEffectFn1 consumeBP unit
    void $ launchAff $ flowRunner defaultGlobalState $ paymentStatusPooling initialState.data.shortOrderId  5 3000.0 initialState push PaymentStatusAction
    pure $ pure unit
--------------------------------------------------------------------------------------------

paymentStatusPooling :: forall action. String -> Int -> Number -> ST.TicketBookingScreenState -> (action -> Effect Unit) -> (String -> action) -> Flow GlobalState Unit
paymentStatusPooling shortOrderId count delayDuration state push action = 
  if (getValueToLocalStore PAYMENT_STATUS_POOLING) == "true" && state.props.currentStage == ST.BookingConfirmationStage  && count > 0 && shortOrderId /= "" then do
    ticketStatus <- Remote.getTicketStatus shortOrderId
    _ <- pure $ spy "ticketStatus" ticketStatus
    case ticketStatus of
      Right (API.GetTicketStatusResp resp) -> do
        if (DA.any (_ == resp) ["Booked", "Failed"]) then do
            _ <- pure $ setValueToLocalStore PAYMENT_STATUS_POOLING "false"
            doAff do liftEffect $ push $ action resp
        else do
            void $ delay $ Milliseconds delayDuration
            paymentStatusPooling shortOrderId (count - 1) delayDuration state push action
      Left _ -> pure unit
    else pure unit
    

view :: forall w . (Action -> Effect Unit) -> ST.TicketBookingScreenState -> PrestoDOM (Effect Unit) w
view push state =
    PrestoAnim.animationSet [Anim.fadeIn true]  $ relativeLayout
    [ height MATCH_PARENT
    , width MATCH_PARENT
    , background Color.white900
    , onBackPressed push $ const BackPressed
    ]
    [ 
     shimmerView state,
     linearLayout 
        [ height MATCH_PARENT
        , width MATCH_PARENT
        , background Color.white900
        , orientation VERTICAL
        , visibility if (state.props.currentStage == ST.DescriptionStage && state.props.showShimmer) then GONE else VISIBLE
        , margin $ MarginBottom if state.props.currentStage == ST.BookingConfirmationStage then 0 else 84
        ]
        [ separatorView Color.greySmoke
        , linearLayout
          [ height MATCH_PARENT
          , width MATCH_PARENT
          , background Color.white900
          ][  linearLayout
              [ height MATCH_PARENT
              , width MATCH_PARENT
              , gravity CENTER
              , background Color.purple
              , orientation VERTICAL
              ][ bookingStatusView state push state.props.paymentStatus ]
            ]
          ]
    , bookingConfirmationActions state push state.props.paymentStatus
    ]

shimmerView :: forall w . ST.TicketBookingScreenState -> PrestoDOM (Effect Unit) w
shimmerView state =
  shimmerFrameLayout
    [ width MATCH_PARENT
    , height MATCH_PARENT
    , orientation VERTICAL
    , background Color.white900
    , visibility if state.props.showShimmer then VISIBLE else GONE
    ]
    [ linearLayout
        [ width MATCH_PARENT
        , height (V 235)
        , margin (Margin 16 15 16 0)
        , background Color.greyDark
        , cornerRadius 16.0
        ] []
    , linearLayout
        [ width MATCH_PARENT
        , height WRAP_CONTENT
        , orientation VERTICAL
        , margin (MarginTop 258)
        ] (DA.mapWithIndex 
            (\index item ->
                linearLayout
                  [ width MATCH_PARENT
                  , height (V 60)
                  , margin (Margin 16 16 16 0)
                  , cornerRadius 12.0
                  , background Color.greyDark
                  ][]
            ) (1 .. 7)
          )
    ]

termsAndConditionsView :: forall w . Array String -> Boolean -> PrestoDOM (Effect Unit) w
termsAndConditionsView termsAndConditions isMarginTop =
  linearLayout
  [ width MATCH_PARENT
  , height WRAP_CONTENT
  , orientation VERTICAL
  , margin $ if isMarginTop then MarginTop 10 else MarginTop 0
  ] (mapWithIndex (\index item ->
      linearLayout
      [ width MATCH_PARENT
      , height WRAP_CONTENT
      , orientation HORIZONTAL
      ][ textView $
         [ textFromHtml $ " •  " <> item
         , color Color.black700
         ] <> FontStyle.tags TypoGraphy
      ]
  ) termsAndConditions )

separatorView :: forall w. String -> PrestoDOM (Effect Unit) w
separatorView color =
  linearLayout
  [ height $ V 1
  , width MATCH_PARENT
  , background color
  ][]

getShareButtonIcon :: String -> String
getShareButtonIcon ticketServiceName = case ticketServiceName of
  "Entrance Fee" -> "ny_ic_share_unfilled_white"
  _ -> "ny_ic_share_unfilled_black"

getShareButtonColor :: String -> String
getShareButtonColor ticketServiceName = case ticketServiceName of
  "Entrance Fee" -> Color.white900
  _ -> Color.black900

getPlaceColor :: String -> String
getPlaceColor ticketServiceName = case ticketServiceName of
  "Entrance Fee" -> Color.white900
  "Videography Fee" -> Color.black800
  "Aquarium Fee" -> Color.black800
  _ -> Color.black800

getInfoColor :: String -> String
getInfoColor ticketServiceName = case ticketServiceName of
  "Entrance Fee" -> Color.white900
  "Videography Fee" -> Color.black900
  "Aquarium Fee" -> Color.black900
  _ -> Color.black800

getPillInfoColor :: String -> String
getPillInfoColor ticketServiceName = case ticketServiceName of
  "Entrance Fee" -> Color.grey900
  "Videography Fee" -> Color.black800
  "Aquarium Fee" ->  Color.white900
  _ -> Color.white900

bookingStatusView :: forall w. ST.TicketBookingScreenState -> (Action -> Effect Unit) -> PP.PaymentStatus -> PrestoDOM (Effect Unit) w
bookingStatusView state push paymentStatus = 
  relativeLayout
  [ width MATCH_PARENT
  , height MATCH_PARENT
  , padding $ PaddingTop 20
  , background "#E2EAFF"
  ][ linearLayout
      [ width MATCH_PARENT
      , height MATCH_PARENT
      , orientation VERTICAL
      , gravity CENTER
      ][  paymentStatusHeader state push paymentStatus
        , bookingStatusBody state push paymentStatus
      ]
  ]

copyTransactionIdView :: forall w. ST.TicketBookingScreenState -> (Action -> Effect Unit) -> Boolean -> PrestoDOM (Effect Unit) w
copyTransactionIdView state push visibility' = 
  linearLayout
  [ height WRAP_CONTENT
  , width WRAP_CONTENT
  , gravity CENTER
  , visibility if visibility' then VISIBLE else GONE
  , onClick push $ const $ Copy state.data.shortOrderId
  ][  commonTV push "TransactionID" Color.black700 (FontStyle.body3 TypoGraphy) 0 CENTER NoAction
    , textView $ 
      [ text state.data.shortOrderId
      , margin $ MarginLeft 3
      , color Color.black700
      , padding $ PaddingBottom 1
      ] <> FontStyle.h3 TypoGraphy
  , imageView
     [ width $ V 16
     , height $ V 16
     , margin $ MarginLeft 3
     , imageWithFallback $ fetchImage FF_ASSET "ny_ic_copy"
     ] 
  ]

bookingStatusBody :: forall w. ST.TicketBookingScreenState -> (Action -> Effect Unit) -> PP.PaymentStatus ->  PrestoDOM (Effect Unit) w
bookingStatusBody state push paymentStatus = 
  linearLayout
  [ width MATCH_PARENT
  , height WRAP_CONTENT
  , weight 1.0
  , orientation VERTICAL
  , margin $ Margin 16 16 16 16
  , visibility if paymentStatus == PP.Failed then GONE else VISIBLE
  ][ scrollView
      [ width MATCH_PARENT
      , height MATCH_PARENT
      ][ linearLayout
          [ width MATCH_PARENT
          , height MATCH_PARENT
          , gravity CENTER
          , orientation VERTICAL
          , padding $ Padding 10 10 10 10
          , cornerRadius 8.0
          , background Color.white900
          ][ linearLayout
              [ width MATCH_PARENT
              , height WRAP_CONTENT
              ][ imageView
                  [ width $ V 24
                  , height $ V 24
                  , imageWithFallback $ fetchImage FF_ASSET "ny_ic_ticket_black" 
                  , margin $ MarginRight 4
                  ]
                , commonTV push state.data.zooName Color.black900 (FontStyle.subHeading1 TypoGraphy) 0 LEFT NoAction
              ]
        , linearLayout
          [ height WRAP_CONTENT
          , width MATCH_PARENT
          , orientation VERTICAL
          ](DA.mapWithIndex ( \index item ->  keyValueView push state item.key item.val index) state.data.keyValArray)
          ]
      ]
  ]

bookingConfirmationActions :: forall w. ST.TicketBookingScreenState -> (Action -> Effect Unit) -> PP.PaymentStatus -> PrestoDOM (Effect Unit) w
bookingConfirmationActions state push paymentStatus = 
  let isBookingConfirmationStage = state.props.currentStage == ST.BookingConfirmationStage
  in 
  linearLayout[
    height MATCH_PARENT
  , width MATCH_PARENT
  , background Color.transparent
  , visibility $ boolToVisibility $ isBookingConfirmationStage
  , gravity BOTTOM
  ][
  linearLayout
  [ width MATCH_PARENT
  , gravity CENTER
  , orientation VERTICAL
  , height WRAP_CONTENT
  , padding $ PaddingBottom 20
  , alignParentBottom "true,-1"
  , background Color.white900
  , visibility $ boolToVisibility $ isBookingConfirmationStage
  ][ linearLayout
      [ width MATCH_PARENT
      , height $ V 1
      , background Color.grey900
      ][]
   , PrimaryButton.view (push <<< ViewTicketAC) (viewTicketButtonConfig primaryButtonText $ paymentStatus /= PP.Pending)
   , linearLayout
     [ width $ MATCH_PARENT
     , height WRAP_CONTENT
     , onClick push $ const GoHome
      , padding $ PaddingBottom 20
     , gravity CENTER
     ][commonTV push secondaryButtonText Color.black900 (FontStyle.subHeading1 TypoGraphy) 5 CENTER GoHome]
  ]]
  where primaryButtonText = case paymentStatus of
                              PP.Success -> "View Ticket"
                              PP.Failed -> "Try Again"
                              _ -> ""
        secondaryButtonText = case paymentStatus of
                              PP.Success -> "Go Home"
                              _ -> "Go Back"

paymentStatusHeader :: forall w. ST.TicketBookingScreenState -> (Action -> Effect Unit) -> PP.PaymentStatus -> PrestoDOM (Effect Unit) w
paymentStatusHeader state push paymentStatus = 
  let transactionConfig = getTransactionConfig paymentStatus
  in
    linearLayout
    [ width MATCH_PARENT
    , height WRAP_CONTENT
    , orientation VERTICAL
    , gravity CENTER
    ][ relativeLayout
      [ width $ MATCH_PARENT
      , height $ WRAP_CONTENT
      , gravity CENTER
      ][imageView
        [ width $ MATCH_PARENT
        , height $ V 100
        , visibility if paymentStatus == PP.Success then VISIBLE else GONE
        , imageWithFallback $ fetchImage FF_ASSET "ny_ic_confetti"
        ] 
      , linearLayout
        [ width $ MATCH_PARENT
        , height $ WRAP_CONTENT
        , gravity CENTER
        , margin $ MarginTop 50
        ][ imageView
          [ width $ V 65
          , height $ V 65
          , imageWithFallback transactionConfig.image
          ]
        ]
      ]
      , commonTV push transactionConfig.title Color.black900 (FontStyle.h2 TypoGraphy) 14 CENTER NoAction
      , commonTV push transactionConfig.statusTimeDesc Color.black700 (FontStyle.body3 TypoGraphy) 5 CENTER NoAction
      , copyTransactionIdView state push $ paymentStatus == PP.Failed
      , if (paymentStatus == PP.Success) then (linearLayout [][]) else (PrimaryButton.view (push <<< RefreshStatusAC) (refreshStatusButtonConfig state))

    ]

commonTV :: forall w. (Action -> Effect Unit) -> String -> String -> (forall properties. (Array (Prop properties))) -> Int -> Gravity -> Action -> PrestoDOM (Effect Unit) w
commonTV push text' color' fontStyle marginTop gravity' action =
  textView $
  [ width WRAP_CONTENT
  , height WRAP_CONTENT
  , text text'
  , color color'
  , gravity gravity'
  , onClick push $ const action
  , margin $ MarginTop marginTop
  ] <> fontStyle

keyValueView :: (Action -> Effect Unit) -> ST.TicketBookingScreenState -> String -> String -> Int -> forall w . PrestoDOM (Effect Unit) w
keyValueView push state key value index = 
  linearLayout 
  [ height WRAP_CONTENT
  , width MATCH_PARENT
  , gravity CENTER_VERTICAL
  , orientation VERTICAL
  ][ linearLayout
      [ width MATCH_PARENT
      , margin $ Margin 5 12 5 12
      , height $ V 1
      , background Color.grey700
      ][]
    , linearLayout
      [ width MATCH_PARENT
      , height WRAP_CONTENT
      , margin $ MarginHorizontal 5 5
      ][ textView $ 
        [ text key
        , margin $ MarginRight 8
        , color Color.black700
        ] <> FontStyle.body3 TypoGraphy
      , linearLayout
        [ width MATCH_PARENT
        , gravity RIGHT
        ][ if index == 1 then bookingForView state else 
           textView $ 
            [ text value
            , color Color.black800
            , onClick push $ const $ if key == "Booking ID" || key == "Transaction ID" then Copy value else NoAction -- needs refactoring
            ] <> FontStyle.body6 TypoGraphy
          ]
      ]
  ]

bookingForView :: forall w. ST.TicketBookingScreenState -> PrestoDOM (Effect Unit) w
bookingForView state = 
  linearLayout
    [ width WRAP_CONTENT
    , height WRAP_CONTENT
    ](map ( \item -> 
      textView $
      [ text item
      , padding $ Padding 6 4 6 4
      , cornerRadius 20.0
      , margin $ MarginLeft 5
      , background Color.blue600
      ] <> FontStyle.tags TypoGraphy
    ) state.data.bookedForArray)

getTransactionConfig :: PP.PaymentStatus -> {image :: String, title :: String, statusTimeDesc :: String}
getTransactionConfig status = 
  case status of
    PP.Success -> {image : fetchImage FF_COMMON_ASSET "ny_ic_green_tick", statusTimeDesc : "Your ticket has been generated below", title : "Your booking is Confirmed!"}
    PP.Pending -> {image : fetchImage FF_COMMON_ASSET "ny_ic_transaction_pending", statusTimeDesc : "Please check back in a few minutes.", title : "Your booking is Pending!"}
    PP.Failed  -> {image : fetchImage FF_COMMON_ASSET "ny_ic_payment_failed", statusTimeDesc : "Please retry booking.", title : "Booking Failed!"}
    PP.Scheduled  -> {image : fetchImage FF_COMMON_ASSET "ny_ic_pending", statusTimeDesc : "", title : ""}
