parameters = {}
state_references = {}
loadJSONUtils()

function matchFeedback (message)
    return true
end

function processFeedback (message)
   local ajaHeloFeedback = JSON:decode(message)
   if ajaHeloFeedback.name == "eParamID_CurrentMediaAvailable" then
        state_references.STATE_4 = ajaHeloFeedback.value
   elseif ajaHeloFeedback.name == "eParamID_RecordingDuration" then
        state_references.STATE_5 = ajaHeloFeedback.value
   elseif ajaHeloFeedback.name == "eParamID_ReplicatorRecordState" then
        state_references.STATE_1 = ajaHeloFeedback.value
  end
end