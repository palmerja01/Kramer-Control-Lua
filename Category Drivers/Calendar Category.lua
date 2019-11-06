--Calendar category from DDE on November 5th 2019
REMOVE = ""

function initialize()
    _id = "CUSTOM"
    _reminders = {}
    _starts = {}
    _ends = {}
    _dates = {}
    _attendees = {}
    _organizers = {}
    _titles = {}
    _locations = {}
    _minutes = {}
    _statuses = {}
    _macros = {}
end

function getMacros()
   return toJSON(_macros)
end

function queryStateValue (stateId, stateKey)
    if stateId == "REMINDER" then
        return _reminders[stateKey], _reminders[stateKey]
    elseif stateId == "START_TIME" then
        return _starts[stateKey], _starts[stateKey]
    elseif stateId == "END_TIME" then
        return _ends[stateKey], _ends[stateKey]
    elseif stateId == "DATE" then
        return _dates[stateKey], _dates[stateKey]
    elseif stateId == "TITLE" then
        return _titles[stateKey], _titles[stateKey]
    elseif stateId == "ATTENDEES" then
        return _attendees[stateKey], _attendees[stateKey]
    elseif stateId == "ORGANIZER" then
        return _organizers[stateKey], _organizers[stateKey]
    elseif stateId == "LOCATION" then
        return _locations[stateKey], _locations[stateKey]
    elseif stateId == "MINUTES" then
        return _minutes[stateKey], _minutes[stateKey]
    elseif stateId == "STATUS" then
        return _statuses[stateKey], _statuses[stateKey]
    end
    return nil, nil
end

function applyStateChange (stateChange, isVirtual)
    if stateChange.category_id ~= _id then return false end
    local hasChanged = false
    local prevValue
    if stateChange.state_id == "REMINDER" then
        prevValue = _reminders[stateChange.state_key]
        _reminders[stateChange.state_key] = stateChange.state_value
        hasChanged = (prevValue ~= _reminders[stateChange.state_key])

    elseif stateChange.state_id == "START_TIME" then
        prevValue = _starts[stateChange.state_key]
         _starts[stateChange.state_key] = stateChange.state_value
        hasChanged = (prevValue ~= _starts[stateChange.state_key])

    elseif stateChange.state_id == "END_TIME" then
        prevValue = _ends[stateChange.state_key]
         _ends[stateChange.state_key] = stateChange.state_value
        hasChanged = (prevValue ~= _ends[stateChange.state_key])

    elseif stateChange.state_id == "DATE" then
        prevValue = _dates[stateChange.state_key]
         _dates[stateChange.state_key] = stateChange.state_value
        hasChanged = (prevValue ~= _dates[stateChange.state_key])

    elseif stateChange.state_id == "TITLE" then
        prevValue = _titles[stateChange.state_key]
         _titles[stateChange.state_key] = stateChange.state_value
        hasChanged = (prevValue ~= _titles[stateChange.state_key])

    elseif stateChange.state_id == "ATTENDEES" then
        prevValue = _attendees[stateChange.state_key]
         _attendees[stateChange.state_key] = stateChange.state_value
        hasChanged = (prevValue ~= _attendees[stateChange.state_key])

    elseif stateChange.state_id == "ORGANIZER" then
        prevValue = _organizers[stateChange.state_key]
         _organizers[stateChange.state_key] = stateChange.state_value
        hasChanged = (prevValue ~= _organizers[stateChange.state_key])

    elseif stateChange.state_id == "LOCATION" then
        prevValue = _locations[stateChange.state_key]
         _locations[stateChange.state_key] = stateChange.state_value
        hasChanged = (prevValue ~= _locations[stateChange.state_key])

    elseif stateChange.state_id == "MINUTES" then
        prevValue = _minutes[stateChange.state_key]
         _minutes[stateChange.state_key] = stateChange.state_value
        hasChanged = (prevValue ~= _minutes[stateChange.state_key])

    elseif stateChange.state_id == "STATUS" then
        prevValue = _statuses[stateChange.state_key]
         _statuses[stateChange.state_key] = stateChange.state_value
        hasChanged = (prevValue ~= _statuses[stateChange.state_key])
    end
    return hasChanged
end

function getExecutionResult(availableProtocols, capabilityId, commandId, clientArgs)
    codesArray = {}
    stateChanges = {}
    if commandId == "GET_MEETINGS" then
        table.insert(codesArray, "GET MEETINGS")
    end
    local genericCommType = "HTTP"
    local codesObj = {codes=codesArray};
    local stateChangesObj = {state_changes=stateChanges}
    local linkedFeedbackId = ""
    local triggeredMacroObj = {}
    return genericCommType, toJSON(codesObj), toJSON(stateChangesObj), linkedFeedbackId,  toJSON(triggeredMacroObj)
end

function processFeedback (feedbacks, commType, previousCommand)
    stateChanges = {}
    local matches = {}
    triggeredAction = {}
    for i,v in ipairs(feedbacks) do
        matches[i] = processFeedbackCode(v, i)
    end
    local matchesObj = {matches=matches}
    local stateChangesObj = {state_changes=stateChanges}
    return toJSON(matchesObj), toJSON(stateChangesObj), toJSON(triggeredAction)    
end

function processFeedbackCode(code, index)
    loadJSONUtils()
    local lua_table = JSON:decode(code)
    local meetings = lua_table.content
    Count = 0
    for Index, Value in pairs( meetings ) do
        current_time = os.time() * 1000
        if Value.end_epoch_millis < current_time then
            Count = Count + 1
        end
    end
    for i=1,5,1 do
        processMeeting(meetings[i+Count],i)
    end
    return true 
end

function processMeeting(meeting, key)
    if meeting == nil then
        clearStates(key)
        return false
    end

    local startTime = "Broken"
    local endTime = "Broken"
    local Date = "Broken"
    local minToMeeting = 0
    local Stat = "Not Started"
    local start_epoch_sec = meeting.start_epoch_millis/1000
    local end_epoch_sec = meeting.end_epoch_millis/1000

    startMin = tonumber(os.date("%M",start_epoch_sec)) * 60000     
    startHr = tonumber(os.date("%H",start_epoch_sec)) * 3600000
    endMin = tonumber(os.date("%M",end_epoch_sec)) * 60000     
    endHr = tonumber(os.date("%H",end_epoch_sec)) * 3600000
    remindMe = (startHr + startMin) - 900000
    if remindMe < 0 then
        remindMe = remindMe + 86400000
    end
    Date = os.date("%Y-%m-%d",meeting.start_epoch_millis/1000)    --Get Date from JSON

    if os.time() < start_epoch_sec then
        minToMeeting = (start_epoch_sec - os.time())/60
        if minToMeeting < 15 then
            Stat = "About To Start"
        end
    elseif os.time() >= start_epoch_sec then
        minToMeeting = 0
        Stat = "In Progress"
    end
    
    stateChange = {category_id=_id,
                         state_id="MINUTES",
                         state_key=tostring(key),
                         state_value=tostring(math.ceil(minToMeeting))}
    table.insert(stateChanges, stateChange)

    stateChange = {category_id=_id,
                         state_id="STATUS",
                         state_key=tostring(key),
                         state_value=Stat}
    table.insert(stateChanges, stateChange)

    stateChange = {category_id=_id,
                         state_id="START_TIME",
                         state_key=tostring(key),
                         state_value="{\\\"time_type\\\":\\\"time\\\",\\\"value\\\":" .. tostring(startHr + startMin) .. "}"}
    table.insert(stateChanges, stateChange)

    stateChange = {category_id=_id,
                         state_id="END_TIME",
                         state_key=tostring(key),
                         state_value="{\\\"time_type\\\":\\\"time\\\",\\\"value\\\":" .. tostring(endHr + endMin) .. "}"}
    table.insert(stateChanges, stateChange)

    stateChange = {category_id=_id,
                         state_id="REMINDER",
                         state_key=tostring(key),
                         state_value="{\\\"time_type\\\":\\\"time\\\",\\\"value\\\":" .. tostring(remindMe) .. "}"}
    table.insert(stateChanges, stateChange)

    stateChange = {category_id=_id,
                         state_id="DATE",
                         state_key=tostring(key),
                         state_value=Date}
    table.insert(stateChanges, stateChange)

    local title = meeting.title                                    --Get value of meeting title
    stateChange = {category_id=_id,
                         state_id="TITLE",
                         state_key=tostring(key),
                         state_value=title}
    table.insert(stateChanges, stateChange)

    local attendees = getAttendees(meeting.attendees)                                    --Get list of attendees from JSON
    stateChange = {category_id=_id,
                         state_id="ATTENDEES",
                         state_key=tostring(key),
                         state_value=attendees}
    table.insert(stateChanges, stateChange)

    local organizer = getOrganizer(meeting.organizer)       --Get the organizer of the meeting from JSON
    stateChange = {category_id=_id,
                         state_id="ORGANIZER",
                         state_key=tostring(key),
                         state_value=organizer}
    table.insert(stateChanges, stateChange)

    local location = meeting.location                                  --Get the location
    stateChange = {category_id=_id,
                         state_id="LOCATION",
                         state_key=tostring(key),
                         state_value=location}
    table.insert(stateChanges, stateChange)
    return true
end

function getAttendees(attendees)    --Iterates the attendees' array and gets all the names or email addresses
    local returnString = ""
    for i, v in ipairs(attendees) do                  --Iterate over all attendees, add email or name to returnString
        if attendees[i].displayName == "" then
            returnString = returnString .. attendees[i].email .. ", "
        else
            returnString = returnString .. attendees[i].displayName .. ", "
        end
    end
    returnString = returnString:sub(1, -3)         -- Remove last comma and space
    return returnString
end

function getOrganizer(organizer)
    if organizer.displayName == "" then
        return organizer.email
    end
    return organizer.displayName
end

function clearStates(key)    --Removes items from the state array if there is no longer a meeting at the key.
    local stateChange = {category_id=_id,
                         state_id="START_TIME",
                         state_key=tostring(key),
                         state_value=nil}
    table.insert(stateChanges, stateChange)

    stateChange = {category_id=_id,
                         state_id="END_TIME",
                         state_key=tostring(key),
                         state_value=nil}
    table.insert(stateChanges, stateChange)

    stateChange = {category_id=_id,
                         state_id="REMINDER",
                         state_key=tostring(key),
                         state_value=nil}
    table.insert(stateChanges, stateChange)

    stateChange = {category_id=_id,
                         state_id="DATE",
                         state_key=tostring(key),
                         state_value=nil}
    table.insert(stateChanges, stateChange)

    stateChange = {category_id=_id,
                         state_id="TITLE",
                         state_key=tostring(key),
                         state_value=nil}
    table.insert(stateChanges, stateChange)

    stateChange = {category_id=_id,
                         state_id="ATTENDEES",
                         state_key=tostring(key),
                         state_value=nil}
    table.insert(stateChanges, stateChange)

    stateChange = {category_id=_id,
                         state_id="ORGANIZER",
                         state_key=tostring(key),
                         state_value=nil}
    table.insert(stateChanges, stateChange)

    stateChange = {category_id=_id,
                         state_id="LOCATION",
                         state_key=tostring(key),
                         state_value=nil}
    table.insert(stateChanges, stateChange)

    stateChange = {category_id=_id,
                         state_id="MINUTES",
                         state_key=tostring(key),
                         state_value=nil}
    table.insert(stateChanges, stateChange)

    stateChange = {category_id=_id,
                         state_id="STATUS",
                         state_key=tostring(key),
                         state_value=nil}
    table.insert(stateChanges, stateChange)
end