--!strict
-- Tween helpers used by every screen and effect.

local TweenService = game:GetService("TweenService")

local Motion = {}

function Motion.Tween(
	instance: Instance,
	seconds: number,
	goals: { [string]: any },
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?
): Tween
	local info = TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
	local tween = TweenService:Create(instance, info, goals)
	tween:Play()
	return tween
end

-- Snaps a UIScale to `peak`, then springs it back to `rest` (default 1).
function Motion.Pop(scale: UIScale, peak: number, rest: number?, seconds: number?)
	scale.Scale = peak
	Motion.Tween(scale, seconds or 0.35, { Scale = rest or 1 }, Enum.EasingStyle.Back)
end

-- Yields until the tween has finished (returns at once if it already has).
function Motion.Await(tween: Tween)
	if tween.PlaybackState == Enum.PlaybackState.Playing or tween.PlaybackState == Enum.PlaybackState.Begin then
		tween.Completed:Wait()
	end
end

return table.freeze(Motion)
