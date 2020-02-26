path = "/tmp/phonenumber.txt"
debugLine = debug.getinfo(1).currentline - 114

function fileSearch ()
    local line = io.read()  -- current line
    local pos = 1           -- current position in the line
    return function ()      -- iterator function
      while line do         -- repeat while there are lines
        local s, e = string.find(line, "%w+", pos)
        if s then           -- found a word?
          pos = e + 1       -- next position is after this word
          return string.sub(line, s, e)     -- return the word
        else
          line = io.read()  -- word not found; try next line
          pos = 1           -- restart from first position
        end
      end
      return nil            -- no more lines: end of traversal
    end
  end


function openFile(path, argument)
    openedFile = io.open(path, argument)
end

function writeToFile(newEntry)
    openFile(path, "a")
    openedFile:write(newEntry, '\n')
    openedFile:flush()
    return true
end

function readFile()
    openFile(path, "a")
end

function clearFile()
    openFile(path, "w")
    openedFile:write("")
    openedFile:flush()
end

function initialize()
    _id = "PHONEBOOK"
    _phonebook = {}
    _name = {}
    _contactid = {}
    _folderid = {}
    _title = {}
    _contactmethodid = {}
    _foldername = {}
    _localfolderid = {}
    _directoryfolderid = {}
    _value = {}
    _macros = {}
end

function getMacros()
   return toJSON(_macros)
end

function queryStateValue (stateId, stateKey)
    if stateId == "PHONEBOOK" then
        return _phonebook[stateKey], _phonebook[stateKey]
    elseif stateId == "NAME" then
        return _name[stateKey], _name[stateKey]
    elseif stateId == "CONTACT_ID" then
        return _contactid[stateKey], _contactid[stateKey]
    elseif stateId == "FOLDER_ID" then
        return _folderid[stateKey], _folderid[stateKey]
    elseif stateId == "TITLE" then
        return _title[stateKey], _title[stateKey]
    elseif stateId == "CONTACT_METHOD_ID" then
        return _contactmethodid[stateKey], _contactmethodid[stateKey]
    elseif stateId == "FOLDER_NAME" then
        return _foldername[stateKey], _foldername[stateKey]
    elseif stateId == "LOCAL_FOLDER_ID" then
        return _localfolderid[stateKey], _localfolderid[stateKey]
    elseif stateId == "DIRECTORY_FOLDER_ID" then
        return _directoryfolderid[stateKey], _directoryfolderid[stateKey]
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
    elseif stateChange.state_id == "NAME" then
        prevValue = _name[stateChange.state_key]
        _name[stateChange.state_key] = stateChange.state_value
        hasChanged = (prevValue ~= _name[stateChange.state_key])
    elseif stateChange.state_id == "CONTACT_ID" then
        prevValue = _contactid[stateChange.state_key]
        _contactid[stateChange.state_key] = stateChange.state_value
        hasChanged = (prevValue ~= _contactid[stateChange.state_key])
    elseif stateChange.state_id == "FOLDER_ID" then
        prevValue = _folderid[stateChange.state_key]
        _folderid[stateChange.state_key] = stateChange.state_value
        hasChanged = (prevValue ~= _folderid[stateChange.state_key])
    elseif stateChange.state_id == "TITLE" then
        prevValue = _title[stateChange.state_key]
        _title[stateChange.state_key] = stateChange.state_value
        hasChanged = (prevValue ~= _title[stateChange.state_key])
    elseif stateChange.state_id == "CONTACT_METHOD_ID" then
        prevValue = _contactmethodid[stateChange.state_key]
        _contactmethodid[stateChange.state_key] = stateChange.state_value
        hasChanged = (prevValue ~= _contactmethodid[stateChange.state_key])
    elseif stateChange.state_id == "FOLDER_NAME" then
        prevValue = _foldername[stateChange.state_key]
        _foldername[stateChange.state_key] = stateChange.state_value
        hasChanged = (prevValue ~= _foldername[stateChange.state_key])
    elseif stateChange.state_id == "LOCAL_FOLDER_ID" then
        prevValue = _localfolderid[stateChange.state_key]
        _localfolderid[stateChange.state_key] = stateChange.state_value
        hasChanged = (prevValue ~= _localfolderid[stateChange.state_key])
    elseif stateChange.state_id == "DIRECTORY_FOLDER_ID" then
        prevValue = _directoryfolderid[stateChange.state_key]
        _directoryfolderid[stateChange.state_key] = stateChange.state_value
        hasChanged = (prevValue ~= _directoryfolderid[stateChange.state_key])
    end
    return hasChanged
end

function executePhonebookQuery(args)
    if args.DIRECTORY == nil then print("args.DIRECTORY is nil at line " .. debugLine) return false end
    local phoneDirectory = args.DIRECTORY
    local searchString = args.SEARCH_STRING
    local limit = args.RESULT_LIMIT
    clearFile()
    for i = 1,50 do clearStates(i) end
    
    table.insert(codesArray, "Command Phonebook Search " .. "PhonebookType: " .. phoneDirectory .. " SearchString: \\\"" .. searchString .. '\\\" ' .. "Limit: " .. limit)

    return true
end

function executeFolderQuery(args)
    if args.FOLDER_NAME == nil then print("args.FOLDER_NAME is nil at line " .. debugLine) return false end
    local folderName = _directoryfolderid[args.FOLDER_NAME]
    clearFile()

    table.insert(codesArray, "Command Phonebook Search " .. "PhonebookType: \\\"Corporate\\\" folderid: \\\""  .. folderName .. '\\\"')
    return true
end

function executeDialPhonebook(args)
    if args.NAME == nil then print("args.NAME is nil at line " .. debugLine) return false end
    local number = _phonebook[args.NAME]

table.insert(stateChanges, stateChange)
    table.insert(codesArray, "Command Dial Number: \\\"" .. number .. '\\\"')
    return true
end

function executeEraseFile()
    clearFile()
print("File Erased!!")
    return true
end

function executeGeneratePhonebook()
    print("Generating Phonebook Values")
    for i = 1,50 do clearPhonebook(i) end
    for line in io.lines(path) do
        local i, j, n, t, v = string.find(line, "(%d+) (.*): (.*)")
        
        local stateID = t
        stateValue = v
        key = n

        local stateChange = {
            category_id=_id,
            state_id=tostring(stateID),
            state_key=tostring(key),
            state_value=tostring(v)
            }
table.insert(stateChanges, stateChange)

    end
print("Phonebook completed!")
end


function getExecutionResult(availableProtocols, capabilityId, commandId, args)
    codesArray = {}
    stateChanges = {}

    if commandId == "GET_DIRECTORY" then
        executePhonebookQuery(args)
    elseif commandId == "QUERY_DIRECTORY_FOLDER" then
        executeFolderQuery(args)
    elseif commandId == "DIAL_PHONEBOOK" then
        executeDialPhonebook(args)
    elseif commandId == "ERASE_FILE" then
        executeEraseFile()
    elseif commandId == "GENERATE" then
        executeGeneratePhonebook()
    end

    local genericCommType = "SERIAL"
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

        local stateChange = {
                        category_id=_id,
                        state_id="PHONEBOOK",
                        state_key=tostring(key),
                        state_value=nil
                        }
    table.insert(stateChanges, stateChange)

function clearStates(key)    -- Removes items from the state array
    local stateChange = {
                        category_id=_id,
                        state_id="PHONEBOOK",
                        state_key=tostring(key),
                        state_value=nil
                        }
    table.insert(stateChanges, stateChange)

        local stateChange = {
                        category_id=_id,
                        state_id="NAME",
                        state_key=tostring(key),
                        state_value=nil
                        }
    table.insert(stateChanges, stateChange)
        local stateChange = {
                        category_id=_id,
                        state_id="CONTACT_ID",
                        state_key=tostring(key),
                        state_value=nil
                        }
    table.insert(stateChanges, stateChange)
        local stateChange = {
                        category_id=_id,
                        state_id="FOLDER_ID",
                        state_key=tostring(key),
                        state_value=nil
                        }
    table.insert(stateChanges, stateChange)
    local stateChange = {
                        category_id=_id,
                        state_id="TITLE",
                        state_key=tostring(key),
                        state_value=nil
                        }
    table.insert(stateChanges, stateChange)
    local stateChange = {
                        category_id=_id,
                        state_id="CONTACT_METHOD_ID",
                        state_key=tostring(key),
                        state_value=nil
                        }
    table.insert(stateChanges, stateChange)
    local stateChange = {
                        category_id=_id,
                        state_id="FOLDER_NAME",
                        state_key=tostring(key),
                        state_value=nil
                        }
    table.insert(stateChanges, stateChange)
    local stateChange = {
                        category_id=_id,
                        state_id="LOCAL_FOLDER_ID",
                        state_key=tostring(key),
                        state_value=nil
                        }
    table.insert(stateChanges, stateChange)
        local stateChange = {
                        category_id=_id,
                        state_id="DIRECTORY_FOLDER_ID",
                        state_key=tostring(key),
                        state_value=nil
                        }
    table.insert(stateChanges, stateChange)
    
end


function feedbackEndSearch(feedbackString, stateType, number)
    local i, j, fbTarget = string.find(feedbackString, "\"(.*)\"")
    if fbTarget == "" then fbTarget = "nil" end
    return writeToFile(number .. " " .. stateType .. " " .. fbTarget)
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

function processFeedbackCode (feedbackString)
        local i, j, p, c, f = string.find(feedbackString, "r%s(%w+)%s(%w+)%s(.*)")
        if i == nil then return false end
        if p == "PhonebookSearchResult" then
            if c == "Contact" then
                return processContact(f)
            elseif c == "Folder" then
                return processFolder(f)
            else
            return false
            end
        end
        return false
end

function processFolder(folderFeedback)
    local i, j, number, location, endResult = string.find(folderFeedback, "(%d+)%s(%g*)%s(.*)")
    if i == nil then return false end
    if location == "Name:" then
        feedbackEndSearch(endResult, "FOLDER_NAME:", number)
    elseif location == "LocalId:" then
        feedbackEndSearch(endResult, "LOCAL_FOLDER_ID:", number)
    elseif location == "FolderId:" then
        feedbackEndSearch(endResult, "DIRECTORY_FOLDER_ID:", number)
     end
     return true
end

function processContact(contactFeedback)
    local i, j, number, v, e = string.find(contactFeedback, "(%d+)%s(%g*)%s(.*)")
    if i == nil then return false end
    if v == "Name:" then
        feedbackEndSearch(e, "NAME:", number)
    elseif v == "ContactId:" then
        feedbackEndSearch(e, "CONTACT_ID:", number)
    elseif v == "FolderId:" then
        feedbackEndSearch(e, "FOLDER_ID:", number)
    elseif v == "Title:" then
        feedbackEndSearch(e, "TITLE:", number)
    else
      cmString = v .. " " .. e
      local i, j, x, y= string.find(cmString, "ContactMethod %d+ (.*) (.*)")
        if x == "ContactMethodId:" then
         feedbackEndSearch(y, "CONTACT_METHOD_ID:", number)
        elseif x == "Number:" then
         feedbackEndSearch(y, "PHONEBOOK:", number)
        end
    end
    return true
end
end