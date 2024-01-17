local defaults = {
   sessions = 0,
   unit = "meters",
}

local function OnEvent(self, event, addOnName)
   if addOnName == "DistanceCheck" then
      DistanceCheckSettings = DistanceCheckSettings or {}
      self.db = DistanceCheckSettings
      for k, v in pairs(defaults) do -- copy the defaults table and possibly any new options
         if self.db[k] == nil then -- avoids resetting any false values
            self.db[k] = v
         end
      end
      self.db.sessions = self.db.sessions + 1
      print("DistanceCheck- /distance [waypoint|unit]")
      print("DistanceCheck- Use /distance unit to switch between units.")
      print("DistanceCheck- Current unit is "..self.db.unit..".")
      
   end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", OnEvent)

utils = _G.utils
local posY1, posX1, posY2, posX2 = 0
local has_begun_a_check = false
local has_a_waypoint = false
local DistanceWithWaypoint = 0

local msgFrame = CreateFrame("FRAME", "DragFrame2", UIParent)
msgFrame:SetMovable(true)
msgFrame:EnableMouse(true)
msgFrame:RegisterForDrag("LeftButton")
msgFrame:SetScript("OnDragStart", msgFrame.StartMoving)
msgFrame:SetScript("OnDragStop", msgFrame.StopMovingOrSizing)
msgFrame:SetWidth(1)
msgFrame:SetHeight(1)
msgFrame:SetPoint("TOP"); msgFrame:SetWidth(64); msgFrame:SetHeight(32);
msgFrame:SetFrameStrata("TOOLTIP")
msgFrame.text = msgFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
msgFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE, MONOCHROME")
msgFrame.text:SetPoint("TOP")
msgFrame.text:SetText("Hello World")
msgFrame:Hide()

local function Round(num)
  return num + (2^52 + 2^51) - (2^52 + 2^51)
end

local function DistanceCheck(x1, y1, x2, y2)
   distance = ((x1 - x2) ^ 2 + (y1 - y2) ^ 2) ^ 0.5
   return distance
end

local function YardsOrMeters(x)
   if f.db.unit == "meters" then
      x = x * 0.9144
      return Round(x)
   else return Round(x) 
   end
end

local function UIValue(value)
   local unit
   if f.db.unit == "meters" then unit = "m." else unit = "yds." end
   msgFrame.text:SetText(YardsOrMeters(value)..""..unit)
end

local function UIShow(show)
   if show then
      msgFrame:Show()
   else
      msgFrame:Hide()
   end
end

local function ChatDistanceMsg(dis)
   local unit
   if f.db.unit == "meters" then unit = f.db.unit else unit = "yards" end
   SendChatMessage("just covered " ..YardsOrMeters(dis).. " "..unit.." .", "EMOTE");
   if UnitInParty("player") and not UnitInRaid("player") then
      SendChatMessage("<I covered " ..YardsOrMeters(dis).. " "..unit.."!>", "PARTY");
   elseif UnitInRaid("player") then
      SendChatMessage("<I covered " ..YardsOrMeters(dis).. " "..unit.."!>", "RAID");
   end
end

SLASH_DIS1 = "/distance"
SlashCmdList["DIS"] = function(msg)
   args = utils.split(msg)
   if args.length == 0 then
      if not has_begun_a_check then
         has_begun_a_check = true
         posY1, posX1, _, _ = UnitPosition("player")
         UIValue(0)
         UIShow(true)
      elseif has_a_waypoint then
         has_begun_a_check = false
         UIShow(false)
         ChatDistanceMsg(DistanceCheck(posX1, posY1, posX2, posY2) + DistanceWithWaypoint)
         has_a_waypoint = false
         DistanceWithWaypoint = 0
      else
         has_begun_a_check = false
         UIShow(false)
         ChatDistanceMsg(DistanceCheck(posX1, posY1, posX2, posY2))
      end
   elseif args[0] == "waypoint" then
      if has_begun_a_check then
         has_a_waypoint = true
         posY3, posX3, _, _ = UnitPosition("player")
         DistanceWithWaypoint = DistanceWithWaypoint + DistanceCheck(posX1, posY1, posX3, posY3)
         posX1 = posX3
         posY1 = posY3
         posY3, posX3 = nil
      else
         print("DistanceCheck - No active distance check!")
      end
   elseif args[0] == "unit" then
      local whatunit
      if f.db.unit == "meters" then f.db.unit = "yards"  whatunit = "Meters" else f.db.unit = "meters" whatunit = "Yards" end
      print("DistanceCheck - Toggled from "..whatunit.." to "..f.db.unit.."!")
   else
      print("Wrong usage :")
      print("/distance start")
      print("/distance stop")
   end
end

local loop_frame = CreateFrame("Frame")
loop_frame:SetScript("OnUpdate", function(self, elapsed)
   if has_begun_a_check then
      if has_a_waypoint then
         posY2, posX2, _, _ = UnitPosition("player")
         UIValue(DistanceCheck(posX1, posY1, posX2, posY2) + DistanceWithWaypoint)
      else
         posY2, posX2, _, _ = UnitPosition("player")
         UIValue(DistanceCheck(posX1, posY1, posX2, posY2))
      end
   end
end)