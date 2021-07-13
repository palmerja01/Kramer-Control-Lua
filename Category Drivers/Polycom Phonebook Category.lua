-- For use with Polycom Group Series codec.

debugLine = debug.getinfo(1).currentline - 114

function initialize()
    _id = "PHONEBOOK"
    _name = {}
    _number = {}
    _macros = {}
end

function getMacros()
   return toJSON(_macros)
end

function queryStateValue (stateId, stateKey)
    if stateId == "NAME" then
        return _name[stateKey], _name[stateKey]
    elseif stateId == "NUMBER" then
        return _number[stateKey], _number[stateKey]
    end
    return nil, nil
end


function applyStateChange (stateChange, isVirtual)
    if stateChange.category_id ~= _id then return false end
    local hasChanged = false
    local prevValue
    if stateChange.state_id == "NAME" then
        prevValue = _name[stateChange.state_key]
        _name[stateChange.state_key] = stateChange.state_value
        hasChanged = (prevValue ~= _name[stateChange.state_key])
    elseif stateChange.state_id == "NUMBER" then
        prevValue = _number[stateChange.state_key]
        _number[stateChange.state_key] = stateChange.state_value
        hasChanged = (prevValue ~= _number[stateChange.state_key])
    end
    return hasChanged
end

function getAddressbook() -- Does what it says it does.
    table.insert(codesArray, "addrbook all")
    return true
end

function dialEntry(args) -- Added to Name state listbox in UI. Takes Key value as argument and passes the value of said key to command.
    if args.NAME == nil then print("args.NAME is nil at line " .. debugLine) return false end
    local number = _number[args.NAME]
    table.insert(stateChanges, stateChange)
    table.insert(codesArray, "dial manaul 64 " .. number .. " h323")
    return true
end


function getExecutionResult(availableProtocols, capabilityId, commandId, args)
    codesArray = {}
    stateChanges = {}

    if commandId == "QUERY_PHONEBOOK" then
         getAddressbook()
    elseif commandId == "DIAL_ENTRY" then
         dialEntry(args)
    end

    local genericCommType = "TCP_UDP"
    local codesObj = {codes=codesArray};
    local stateChangesObj = {state_changes=stateChanges}
    local linkedFeedbackId = ""
    local triggeredMacroObj = {}
    return genericCommType, toJSON(codesObj), toJSON(stateChangesObj), linkedFeedbackId,  toJSON(triggeredMacroObj)
end

function clearPhonebook(key)    -- Removes items from the state array
    local stateChange = {
                        category_id=_id,
                        state_id="NAME",
                        state_key=tostring(key),
                        state_value=nil
                        }
    table.insert(stateChanges, stateChange)
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

function processFeedbackCode (feedbackString) -- Polycom feedback example: addrbook 0. "Last, First" h323_spd:Auto h323_num:192.168.1.10 h323_ext:
    local i, j, key, lastName, firstName, number = string.find(feedbackString, 'addrbook%s(%d+).%s"(%w+),%s(%w+)"%sh323_spd:Auto%sh323_num:(.*)%sh323_ext:')
    if i == nil then return false end
    fullName = firstName .. " " .. lastName
    local stateChange = {
        category_id=_id,
        state_id="NAME",
        state_key=tostring(fullName),
        state_value=tostring(number)
        }
    table.insert(stateChanges, stateChange)

    local stateChange = {
        category_id=_id,
        state_id="NUMBER",
        state_key=tostring(fullName),
        state_value=tostring(number)
        }
    table.insert(stateChanges, stateChange)
    return true
end
