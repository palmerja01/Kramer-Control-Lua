-- Proof of concept for phonebook category
NEW = "New"
REMOVE_ENTRY = ""
NAME_REGEX = "[%w_]+"

-- Feedback Prefix
PHONEBOOK_PREFIX = "Entry:"

function initialize()
    _id = "PHONEBOOK"
    _phonebookEntry = {}
    _macros = {}
    _macros.macros = {}
    _macros.macros[1] = {reference_id="INITIALIZATION"}
    _macros.macros[1].elements = {}
    local triggerCommand = {category_id=_id, capability_id="PHONEBOOK", command_id="QUERY_PHONEBOOK"}
    _macros.macros[1].elements[1] = {trigger_command=triggerCommand}
  
end

function getMacros ()
    return toJSON(_macros)
end

function queryAllKeys(stateId)
    local keysObj = {}
    local keysArray = {}
    if stateId == "PHONEBOOK" then
        for k,_ in pairs(_phonebookEntry) do
            table.insert(keysArray, k)
        end
    end
    keysObj.keys = keysArray
    return toJSON(keysObj)
end

function queryStateValue (stateId, stateKey)
    if stateId == "PHONEBOOK" then
        return _phonebookEntry[stateKey], _phonebookEntry[stateKey]
    end
    return nil, nil
end

function applyStateChange (stateChange, isVirtual)
    if stateChange.category_id ~= _id then return false end
    local hasChanged = false
    if stateChange.state_id == "PHONEBOOK" then
        local prevValue = _phonebookEntry[stateChange.state_key]
        if stateChange.state_value == REMOVE_ENTRY then
            _phonebookEntry[stateChange.state_key] = nil
        else
            _phonebookEntry[stateChange.state_key] = stateChange.state_value
        end

        hasChanged = (prevValue ~= _phonebookEntry[stateChange.state_key])
    end
    return hasChanged
end

function processFeedback (feedbacks, commType, linkedfeedback)
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

function processFeedbackCode (feedbackCode, commType)
    if isTCP_UDP(commType) or isSERIAL(commType) then
        local i, j, entry = string.find(feedbackCode, "^(%w+)|.*$")
        if i == nil then return false end

        if entry == PHONEBOOK_PREFIX then
            return processPhonebookFeedback(feedbackCode)
        else
            return false
        end
    else
        return false
    end
end

function processPhonebookFeedback(feedbackCode)
    if queriedEntry == nil then return false end

    local i, j, name, number = string.find(feedbackCode, "^" .. PHONEBOOK_PREFIX .. "(" .. NAME_REGEX .. "),(%w+)")
    local newEntry = NEW
    if i == nil then
        newEntry = REMOVE_ENTRY
    else
        newEntry = number
        end
    end

    local stateChange = {category_id=_id,
                         state_id="PHONEBOOK",
                         state_key=name,
                         state_value=newEntry}
    table.insert(stateChanges, stateChange)

    return true
end

function getExecutionResult (availableProtocols, capabilityId, commandId, args)
    codes = {}
    virtualStateChanges = {}
    local commType = ""
    local valid = true
    local linkedFeedbackId = ""
    triggeredAction = {}
    if checkArrayForFunctionMatch(availableProtocols, isTCP_UDP) then
        commType = TCP_UDP
    elseif checkArrayForFunctionMatch(availableProtocols, isSERIAL) then
        commType = SERIAL
    elseif checkArrayForFunctionMatch(availableProtocols, isIR) then
        commType = IR
    end
    if capabilityId == "PHONEBOOK" then
        if commandId == "DIAL_PHONEBOOK" then
            if commType == TCP_UDP or commType == SERIAL then
                valid = executeDialPhonebook(args)
            end
        elseif commandId == "QUERY_PHONEBOOK" then
            if commType == TCP_UDP or commType == SERIAL then
                valid = executeQueryPhonebook(args)
                linkedFeedbackId = "PHONEBOOK_ENTRIES"
            end
        end
    end

    local codesObj = {codes=codes}
    local stateChangesObj = {state_changes=virtualStateChanges}
    if valid then
        return commType, toJSON(codesObj), toJSON(stateChangesObj),
                linkedFeedbackId, toJSON(triggeredAction)
    else
        return "", "{ \"codes\": [] }", "{ \"state_changes\": [] }",
                "", "{}"
    end
end


function createCode(command, args)
    code = "Dialing: " .. args
    return code
end


function executeToggleStatusCommand(args)
    if args.USER == nil then return false end

    local newStatus = toggleStatus(_userStatuses[args.USER])
    if newStatus == _userStatuses[args.USER] then return false end

    codeArgs = {"Set", args.USER, fromFriendlyUserStatus(newStatus)}
    table.insert(codes, createCode(DISPLAY_STATUS_PREFIX, codeArgs))

    local stateChange = {category_id=_id,
                         state_id="USER_STATUSES",
                         state_key=args.USER,
                         state_value=newStatus}
    table.insert(virtualStateChanges, stateChange)

    return true
end

function executeQueryStatusCommand(args)
    if args.USER == nil then return false end

    codeArgs = {"Get", args.USER}
    table.insert(codes, createCode(DISPLAY_STATUS_PREFIX, codeArgs))

    return true
end