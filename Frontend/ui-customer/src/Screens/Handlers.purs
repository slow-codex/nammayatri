{-
 
  Copyright 2022-23, Juspay India Pvt Ltd
 
  This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License
 
  as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program
 
  is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 
  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of
 
  the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}

module Screens.Handlers (module UI) where

import Screens.AboutUsScreen.Handler (aboutUsScreen) as UI
import Screens.AccountSetUpScreen.Handler (accountSetUpScreen) as UI
import Screens.AddNewAddressScreen.Handler (addNewAddressScreen) as UI
import Screens.AppUpdatePopUp.Handler (handleAppUpdatePopUp) as UI
import Screens.ChooseLanguageScreen.Handler (chooseLanguageScreen) as UI
import Screens.ContactUsScreen.Handler (contactUsScreen) as UI
import Screens.EmergencyContactsScreen.Handler (emergencyContactsScreen) as UI
import Screens.EnterMobileNumberScreen.Handler (enterMobileNumberScreen) as UI
import Screens.HelpAndSupportScreen.Handler (helpAndSupportScreen) as UI
import Screens.SelectFaqScreen.Handler (selectFaqScreen) as UI
import Screens.FaqScreen.Handler (faqScreen) as UI
import Screens.HomeScreen.Handler (homeScreen) as UI
import Screens.InvoiceScreen.Handler (invoiceScreen) as UI
import Screens.MyProfileScreen.Handler (myProfileScreen) as UI
import Screens.MyRidesScreen.Handler (myRidesScreen) as UI
import Screens.NammaSafetyFlow.ActivateSafetyScreen.Handler (activateSafetyScreen) as UI
import Screens.NammaSafetyFlow.SafetySettingsScreen.Handler (safetySettingsScreen) as UI
import Screens.NammaSafetyFlow.SetupSafetySettingsScreen.Handler (setupSafetySettingsScreen) as UI
import Screens.NammaSafetyFlow.SosActiveScreen.Handler (sosActiveScreen) as UI
import Screens.NammaSafetyFlow.SafetyEducationScreen.Handler (safetyEducationScreen) as UI
import Screens.OnBoardingFlow.WelcomeScreen.Handler (welcomeScreen) as UI
import Screens.PermissionScreen.Handler (permissionScreen) as UI
import Screens.ReferralScreen.Handler (referralScreen) as UI
import Screens.SavedLocationScreen.Handler (savedLocationScreen) as UI
import Screens.SelectLanguageScreen.Handler (selectLanguageScreen) as UI
import Screens.SplashScreen.Handler (splashScreen) as UI
import Screens.TripDetailsScreen.Handler (tripDetailsScreen) as UI
import Screens.SuccessScreen.Handler (successScreen) as UI
import Screens.EmergencyContactsScreen.Handler (emergencyContactsScreen) as UI
import Screens.OnBoardingFlow.WelcomeScreen.Handler (welcomeScreen) as UI
import Screens.TicketBookingFlow.TicketBooking.Handler (ticketBookingScreen) as UI
import Screens.TicketBookingFlow.PlaceDetails.Handler (placeDetailsScreen) as UI
import Screens.TicketBookingFlow.TicketStatus.Handler (ticketStatusScreen) as UI
import Screens.TicketBookingFlow.TicketList.Handler (ticketListScreen) as UI
import Screens.TicketInfoScreen.Handler (ticketInfoScreen) as UI
import Screens.TicketBookingFlow.PlaceList.Handler (placeListScreen) as UI
import Screens.RentalBookingFlow.RideScheduledScreen.View (rideScheduledScreen) as UI
import Screens.RideSelectionScreen.Handler (rideSelection) as UI
import Screens.ReportIssueChatScreen.Handler (reportIssueChatScreen) as UI
import Screens.SearchLocationScreen.View (searchLocationScreen) as UI
import Screens.FollowRideScreen.Handler (followRideScreen) as UI
import Screens.TicketBookingFlow.MetroTicketDetails.Handler (metroTicketDetailsScreen) as UI
import Screens.TicketBookingFlow.MetroMyTickets.Handler (metroMyTicketsScreen) as UI
import Screens.ReportIssueChatScreen.Handler (reportIssueChatScreen) as UI
import Screens.TicketBookingFlow.MetroTicketBooking.Handler (metroTicketBookingScreen) as UI
import Screens.TicketBookingFlow.MetroTicketStatus.Handler (metroTicketStatusScreen) as UI
import Screens.RentalBookingFlow.RentalScreen.View (rentalScreen) as UI
import Screens.RideBookingFlow.PickupInstructionsScreen.Handler (pickupInstructionsScreen) as UI
import Screens.RiderDriverProfileScreen.Handler (driverProfileScreen) as UI
import Screens.NammaSafetyFlow.Handler (nammaSafetyScreen) as UI
import Screens.DataExplainWithFetch.Handler (dataFetchScreen) as UI
import Screens.RideBookingFlow.RiderRideCompletedCard.Handler (riderRideCompletedScreen) as UI
import Screens.CustomerUtils.FavouriteDriverTrips.Handler (favouriteDriverTrips) as UI
import Screens.RideSummaryScreen.Handler (rideSummaryScreen) as UI
import Screens.ParcelDeliveryFlow.ParcelDeliveryScreen.View (parcelDeliveryScreen) as UI
import Screens.SelectContactsFlow.SelectContactsScreen.Handler (selectContactsScreen) as UI
import Screens.TicketBookingFlow.BusTicketBooking.View (busTicketBookingScreen) as UI
import Screens.TicketBookingFlow.BusTrackingScreen.Handler (busTrackingScreen) as UI
import Screens.AadhaarVerificationScreen.Handler (aadhaarVerificationScreen) as UI
import Screens.SelectBusRoute.Handler (selectBusRouteScreen) as UI
