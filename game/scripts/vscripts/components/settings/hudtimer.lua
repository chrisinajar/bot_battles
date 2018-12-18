HudTimer = HudTimer or class({})

function HudTimer:Init()
  self.isPaused = false
  self.gameTime = 0
  self.countDown = false
  Timers:CreateTimer(function()
    CustomNetTables:SetTableValue( 'timer', 'data', {
      time = self.gameTime,
      isDay = GameRules:IsDaytime(),
      isNightstalker = GameRules:IsNightstalkerNight()
    })

    if not self.isPaused then
	  if not self.countDown then
        self.gameTime = self.gameTime + 1
	  else
	    self.gameTime = self.gameTime - 1
	  end
    end

    return 1
  end)
end

function HudTimer:Pause()
  self.isPaused = true
end

function HudTimer:Resume()
  self.isPaused = false
end

function HudTimer:SetGameTime(gameTime)
  self.gameTime = gameTime
end

function HudTimer:GetGameTime()
  return self.gameTime
end

function HudTimer:SetCountDown(bCountdown)
  self.countDown = bCountdown
end

function HudTimer:GetCountDown()
  return self.countDown
end
