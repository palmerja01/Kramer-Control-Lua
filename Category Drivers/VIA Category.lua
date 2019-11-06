-- status codes
INACTIVE = "0"
INACTIVE_FRIENDLY = "NotPresenting"
ACTIVE = "1"
ACTIVE_FRIENDLY = "Presenting"
WAITING = "2"
WAITING_FRIENDLY = "Waiting"
ALL = "3"
ALL_FRIENDLY = "All"
REMOVE_USER = ""

GET_STATUS_ACTIVE = "Presenting"
GET_STATUS_INACTIVE = "NotPresenting"
GET_STATUS_WAITING = "Waiting"

SET_STATUS_PRESENTING = "AlreadyPresenting"
SET_STATUS_NOT_PRESENTING = "AlreadyNotPresenting"

USER_REGEX = "[%w_]+"

DISPLAY_STATUS_PREFIX = "DisplayStatus"
PLIST_PREFIX = "PList"

function toFriendlyUserStatus(status)
    if status == INACTIVE then return INACTIVE_FRIENDLY end
    if status == ACTIVE then return ACTIVE_FRIENDLY end
    if status == WAITING then return WAITING_FRIENDLY end
    if status == ALL then return ALL_FRIENDLY end

    if status == INACTIVE_FRIENDLY or status == ACTIVE_FRIENDLY or
       status == WAITING_FRIENDLY or status == ALL_FRIENDLY then
        return status
    else
        return ALL_FRIENDLY
    end
end

function fromFriendlyUserStatus(fStatus)
    if fStatus == INACTIVE_FRIENDLY then return INACTIVE end
    if fStatus == ACTIVE_FRIENDLY then return ACTIVE end
    if fStatus == WAITING_FRIENDLY then return WAITING end
    if fStatus == ALL_FRIENDLY then return ALL end

    if fStatus == INACTIVE or fStatus == ACTIVE or
       fStatus == WAITING or fStatus == ALL then
        return fStatus
    else
        return ALL
    end
end

function initialize()
    _id = "VIDEO_PROCESSING"
    _userStatuses = {}
    _macros = {}
    _macros.macros = {}
    _macros.macros[1] = {reference_id="INITIALIZATION"}
    _macros.macros[1].elements = {}
    local triggerCommand = {category_id=_id, capability_id="CUSTOM", command_id="QUERY_PHONEBOOK"}
    _macros.macros[1].elements[1] = {trigger_command=triggerCommand}
end

function getMacros ()
    return toJSON(_macros)
end

function queryAllKeys(stateId)
    local keysObj = {}
    local keysArray = {}
    if stateId == "USER_STATUSES" then
        for k,_ in pairs(_userStatuses) do
            table.insert(keysArray, k)
        end
    end
    keysObj.keys = keysArray
    return toJSON(keysObj)
end

function queryStateValue (stateId, stateKey)
    if stateId == "USER_STATUSES" then
        return _userStatuses[stateKey], _userStatuses[stateKey]
    end
    return nil, nil
end

function applyStateChange (stateChange, isVirtual)
    if stateChange.category_id ~= _id then return false end
    local hasChanged = false
    if stateChange.state_id == "USER_STATUSES" then
        local prevValue = _userStatuses[stateChange.state_key]
        if stateChange.state_value == REMOVE_USER then
            _userStatuses[stateChange.state_key] = nil
        else
            _userStatuses[stateChange.state_key] = stateChange.state_value
        end

        hasChanged = (prevValue ~= _userStatuses[stateChange.state_key])
    end
    return hasChanged
end

function processFeedback (feedbacks, commType, linkedFeedback)
    stateChanges = {}
    local matches = {}
    triggeredAction = {}

    if linkedFeedback ~= nil and linkedFeedback.category_id == _id and
            linkedFeedback.capability_id == "CUSTOM" and
            linkedFeedback.feedback_id == "CURRENT_STATUS" then
        for i,v in ipairs(feedbacks) do
            if isTCP_UDP(commType) or isSERIAL(commType) then
                matches[i] = processDisplayStatusUserFeedback(v, linkedFeedback.USER)
            end
        end
    else
        for i,v in ipairs(feedbacks) do
            matches[i] = processFeedbackCode(v, commType)
        end
    end

    local matchesObj = {matches=matches}
    local stateChangesObj = {state_changes=stateChanges}
    return toJSON(matchesObj), toJSON(stateChangesObj), toJSON(triggeredAction)
end

function processFeedbackCode (feedbackCode, commType)
    if isTCP_UDP(commType) or isSERIAL(commType) then
        local i, j, c = string.find(feedbackCode, "^(%w+)|.*$")
        if i == nil then return false end

        if c == DISPLAY_STATUS_PREFIX then
            return processDisplayStatusFeedback(feedbackCode)
        elseif c == PLIST_PREFIX then
            return processPListFeedback(feedbackCode)
        else
            return false
        end
    else
        return false
    end
end

function processDisplayStatusUserFeedback(feedbackCode, queriedUser)
    if queriedUser == nil then return false end

    local i, j, s = string.find(feedbackCode, "^" .. DISPLAY_STATUS_PREFIX .. "|Get|(%w+)")
    local newStatus = ALL_FRIENDLY
    if i == nil then
        newStatus = REMOVE_USER
    else
        if s == GET_STATUS_ACTIVE then
            newStatus = ACTIVE_FRIENDLY
        elseif s == GET_STATUS_INACTIVE then
            newStatus = INACTIVE_FRIENDLY
        elseif s == GET_STATUS_WAITING then
            newStatus = WAITING_FRIENDLY
        elseif s == REMOVE_USER then
            newStatus = REMOVE_USER
        end
    end

    local stateChange = {category_id=_id,
                         state_id="USER_STATUSES",
                         state_key=queriedUser,
                         state_value=newStatus}
    table.insert(stateChanges, stateChange)

    return true
end

function processDisplayStatusFeedback(feedbackCode)
    local i, j, u, s = string.find(feedbackCode, "^" .. DISPLAY_STATUS_PREFIX .. "|UP|(" .. USER_REGEX .. ")|([0123])")
    if i == nil then return false end

    if u ~= "cnt" then
        local stateChange = {category_id=_id,
                             state_id="USER_STATUSES",
                             state_key=u,
                             state_value=toFriendlyUserStatus(s)}
        table.insert(stateChanges, stateChange)
    end

    return true
end

function processPListFeedback(feedbackCode)
    local i, j, c, s, u = string.find(feedbackCode, "^" .. PLIST_PREFIX .. "|(%w+)|([0123])|(.*)")
    if i == nil then return processPListUPFeedback(feedbackCode) end

    if c == "cnt" then
        -- handle cnt feedback?
        return true
    elseif c == "all" then
        users = splitUsers(u)
        for i,user in ipairs(users) do
            local stateChange = {category_id=_id,
                                 state_id="USER_STATUSES",
                                 state_key=user,
                                 state_value=toFriendlyUserStatus(s)}
            table.insert(stateChanges, stateChange)
        end
    end

    return true
end

function processPListUPFeedback(feedbackCode)
    local i, j, u, s = string.find(feedbackCode, "^" .. PLIST_PREFIX .. "|UP|(" .. USER_REGEX .. ")|([01])")
    if i == nil then return false end

    if u ~= "cnt" then
        local newStatus = ""
        if s == "1" and _userStatuses[u] ~= INACTIVE_FRIENDLY then
            newStatus = INACTIVE_FRIENDLY
        elseif s == "0" and _userStatuses[u] ~= nil then
            newStatus = REMOVE_USER
        else
            return false
        end

        local stateChange = {category_id=_id,
                             state_id="USER_STATUSES",
                             state_key=u,
                             state_value=newStatus}
        table.insert(stateChanges, stateChange)

        return true
    else
        return false
    end
end

function splitUsers(users)
    local t = {}
    local i = 0
    while true do
       i = string.find(users, "#", i+1)
       if i == nil then break end
       table.insert(t, i)
    end

    usersArray = {}
    searchIndex = 1
    for k,v in pairs(t) do
        table.insert(usersArray, string.sub(users, searchIndex, v - 1))
        searchIndex = v + 1
    end

    return usersArray
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
    if capabilityId == "CUSTOM" then
        if commandId == "SET_STATUS" then
            if commType == TCP_UDP or commType == SERIAL then
                valid = executeSetStatusCommand(args)
            end
        elseif commandId == "QUERY_STATUS" then
            if commType == TCP_UDP or commType == SERIAL then
                valid = executeQueryStatusCommand(args)
                linkedFeedbackId = "CURRENT_STATUS"
            end
        elseif commandId == "QUERY_ALL_USERS" then
            args = {USER_STATUS=INACTIVE_FRIENDLY}
            valid = executeGetAllCommand(args)
            args = {USER_STATUS=ACTIVE_FRIENDLY}
            valid = valid and executeGetAllCommand(args)
            args = {USER_STATUS=WAITING_FRIENDLY}
            valid = valid and executeGetAllCommand(args)
        elseif commandId == "TOGGLE_STATUS" then
            if commType == TCP_UDP or commType == SERIAL then
                valid = executeToggleStatusCommand(args)
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

function toggleStatus(oldStatus)
    if oldStatus == INACTIVE then
        return ACTIVE
    elseif oldStatus == ACTIVE then
        return INACTIVE
    elseif oldStatus == INACTIVE_FRIENDLY then
        return ACTIVE_FRIENDLY
    elseif oldStatus == ACTIVE_FRIENDLY then
        return INACTIVE_FRIENDLY
    else
        return oldStatus
    end
end

function createCode(command, args)
    for i=1,10 do if args[i] == nil then args[i] = "" end end
    code = "<Cmd>" .. command .. "</Cmd>" ..
           "<P1>" .. args[1] .. "</P1><P2>" .. args[2] .. "</P2><P3>" .. args[3] .. "</P3>" ..
           "<P4>" .. args[4] .. "</P4><P5>" .. args[5] .. "</P5><P6>" .. args[6] .. "</P6>" ..
           "<P7>" .. args[7] .. "</P7><P8>" .. args[8] .. "</P8><P9>" .. args[9] .. "</P9>" ..
           "<P10>" .. args[10] .. "</P10>"
    return code
end

function executeGetAllCommand(args)
    if args.USER_STATUS == nil then args.USER_STATUS = ALL_FRIENDLY end

    codeArgs = {"all", fromFriendlyUserStatus(args.USER_STATUS)}
    table.insert(codes, createCode(PLIST_PREFIX, codeArgs))

    return true
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

function executeSetStatusCommand(args)
    if args.USER == nil or args.NEW_STATUS == nil then return false end

    codeArgs = {"Set", args.USER, fromFriendlyUserStatus(args.NEW_STATUS)}
    table.insert(codes, createCode(DISPLAY_STATUS_PREFIX, codeArgs))

    local stateChange = {category_id=_id,
                         state_id="USER_STATUSES",
                         state_key=args.USER,
                         state_value=args.NEW_STATUS}
    table.insert(virtualStateChanges, stateChange)

    return true
end

function executeQueryStatusCommand(args)
    if args.USER == nil then return false end

    codeArgs = {"Get", args.USER}
    table.insert(codes, createCode(DISPLAY_STATUS_PREFIX, codeArgs))

    return true
end
