/*

  Copyright 2022-23, Juspay India Pvt Ltd

  This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License

  as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program

  is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY

  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of

  the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
*/

const JBridge = window.JBridge;
const JOS = window.JOS;
import { callbackMapper } from "presto-ui";
export const getFromTopWindow = function (key) {
  return top[key];
}

export const getMJOS = (fileName) => {
  const mJOS = JSON.parse(JBridge.loadFileInDUI(fileName))
  checkAndUpdateOverrides(mJOS);
  return mJOS;
}

function checkAndUpdateOverrides(mJOS) {
  const overrides = mJOS.overrides;
  if (overrides != undefined && Array.isArray(overrides)) {
    overrides.forEach(function (override) {
      var shouldOverride = false;
      try {
        shouldOverride = eval(override.condition);
      } catch (e) {}
      if (shouldOverride) {
        mergeObjects(mJOS, override.result);
      }
    });
  }
}

function mergeObjects(config, result) {
  for (var key in result) {
    var newValue = result[key];
    var oldValue = config[key];
    if (typeof oldValue == typeof newValue) {
      if (newValue != null && typeof newValue == "object") {
        mergeObjects(oldValue, newValue);
      } else {
        config[key] = newValue;
      }
    }
  }
}

export const getCUGUser = function () {
  const JOSFlags = JOS.getJOSflags();
  if (JOSFlags && JOSFlags.isCUGUser) {
    return JOSFlags.isCUGUser;
  } else {
    return false;
  }
}

export const isUseLocalAssets = function () {
  if (window.__payload ) {
    return window.__payload.use_local_assets;
  } else {
    return false;
  }
}

export const renewFile = function(filePath,_location,cb) {
  JBridge.renewFile(_location,filePath,callbackMapper.map(function(result) {
    cb(result)();
  }));
}