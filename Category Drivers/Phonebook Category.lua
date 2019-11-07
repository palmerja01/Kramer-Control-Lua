REMOVE = ""
FB_PREFIX = "Entry: "

function initialize()
    _id = "PHONEBOOK"
    _phonebook = {}
    _macros = {}
end

function getMacros()
   return toJSON(_macros)
end

function queryStateValue (stateId, stateKey)
    if stateId == "PHONEBOOK" then
        return _phonebook[stateKey], _phonebook[stateKey]
    end
    return nil, nil
end

function applyStateChange (stateChange, isVirtual)
    if stateChange.category_id ~= _id then return false end
    local hasChanged = false
    local prevValue
    if stateChange.state_id == "PHONEBOOK" then
        prevValue = _phonebook[stateChange.state_key]
        _phonebook[stateChange.state_key] = stateChange.state_value
        hasChanged = (prevValue ~= _phonebook[stateChange.state_key])
    end
    return hasChanged
end


function executeDialPhonebook(args)
    if args.NAME == nil then return false end
    local number = _phonebook[args.NAME]
    table.insert(codesArray, "Dial " .. number)
    return true
end

function getExecutionResult(availableProtocols, capabilityId, commandId, args)
    codesArray = {}
    stateChanges = {}

    if commandId == "QUERY_PHONEBOOK" then
        table.insert(codesArray, "Query Phonebook Lua Command")
    elseif commandId == "DIAL_PHONEBOOK" then
        executeDialPhonebook(args)
    end

    local genericCommType = "TCP_UDP"
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
        matches[i] = processFeedbackCode(v, commType)
    end
    local matchesObj = {matches=matches}
    local stateChangesObj = {state_changes=stateChanges}
    return toJSON(matchesObj), toJSON(stateChangesObj), toJSON(triggeredAction)    
end

function processFeedbackCode (feedbackCode, commType)
    if isTCP_UDP(commType) or isSERIAL(commType) then
        local i, j, c = string.find(feedbackCode, "^(%w+): .*$")
        if i == nil then return false end

        if c == "Entry" then
            return processNewEntry(feedbackCode)
        else
            return false
        end
    else
        return false
    end
end

function processNewEntry(feedbackCode)
    local i, j, n, p = string.find(feedbackCode, "^" .. "Entry: " .. "(.*),(.*)")
    if i == nil then return false end
        name = n
        phone = p
            local stateChange = {category_id=_id,
                                 state_id="PHONEBOOK",
                                 state_key=name,
                                 state_value=phone}
            table.insert(stateChanges, stateChange)
    return true
end


function clearStates(key)    --Removes items from the state array if there is no longer a meeting at the key.
    local stateChange = {category_id=_id,
                         state_id="PHONEBOOK",
                         state_key=tostring(key),
                         state_value=nil}
    table.insert(stateChanges, stateChange)
end