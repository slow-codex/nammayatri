module Components.RideSummaryCard.Controller where

import Prelude


data Action = NoAction


type Config = 
  { vehicleServiceTierImageUrl :: String
  , rideAmount :: String
  , vehicleInfo :: VehicleInfoConfig
  , scheduleInfo :: ScheduleInfoConfig
  , rideTypePill :: RideTypePillConfig
  }

type RideTypePillConfig = 
  { pillText :: String
  , pillImage :: String
  , background :: String
  }


type VehicleInfoConfig = 
  { vehicleServiceTierAirConditioned :: Boolean    
  , vehicleServiceTierSeatingCapacity :: Int
  , vehicleServiceTierName :: String
  , airConditionedText :: String
}

type ScheduleInfoConfig  = 
  { pickUpTime :: String
  , pickUpText :: String 
  , dropTime :: String
  , dropText :: String
  , showDropTime :: Boolean
  }
