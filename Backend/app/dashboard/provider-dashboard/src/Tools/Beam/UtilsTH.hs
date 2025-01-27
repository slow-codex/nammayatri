{-
 Copyright 2022-23, Juspay India Pvt Ltd

 This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License

 as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program

 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY

 or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of

 the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}

module Tools.Beam.UtilsTH (module Reexport, module Tools.Beam.UtilsTH) where

import Kernel.Beam.Lib.UtilsTH as Reexport hiding (mkTableInstances, mkTableInstancesWithTModifier)
import qualified Kernel.Beam.Lib.UtilsTH as TH
import Kernel.Prelude
import Kernel.Types.Version as Reexport
import Kernel.Utils.Version as Reexport
import Language.Haskell.TH

currentSchemaName :: String
currentSchemaName = "atlas_bpp_dashboard"

mkTableInstances :: Name -> String -> Q [Dec]
mkTableInstances name table = TH.mkTableInstances name table currentSchemaName

mkTableInstancesWithTModifier :: Name -> String -> [(String, String)] -> Q [Dec]
mkTableInstancesWithTModifier name table = TH.mkTableInstancesWithTModifier name table currentSchemaName
