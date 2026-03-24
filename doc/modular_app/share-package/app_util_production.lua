#!/usr/bin/lua

--[[
    Linksys Now - App Utility (Production Version with SSE)

    New in Production Version:
    - Updated file paths for production deployment
    - Added SSE event triggering for UI updates
    - Supports multiple trigger mechanisms (file, MQTT, HTTP)

    Command line options:
    listapps        List all Apps (alias: list)
    listuserapps    List User Apps only
    new             Add a new User App
    update          Update an existing User App
    delete          Remove an existing User App
    rename          Rename an existing User App

    Examples:
    ./app_util.lua list
    ./app_util.lua new "My App" --dry-run
    ./app_util.lua new '{"name":"Test App","description":"A test"}' --verbose
]]

-- Use router-specific JSON library with compatibility layer
local libhdkjson = require('libhdkjsonlua')
json = {
    encode = function(obj)
        return libhdkjson.stringify(obj)
    end,
    decode = function(str)
        return libhdkjson.parse(str)
    end
}

-- Production paths
CONFIG_PATH = "/www/assets/config/linksys_apps.json"
CONFIG_BACKUP_PATH = "/www/assets/config/linksys_apps.json.backup"
base_userapp_urlpath = "192.168.1.1/"
base_userapp_subdir = "/usr_www/"
lighty_path = "/etc/init.d/lighttpd"
lighty_conf_path = "/etc/lighttpd/conf.d/"

options = {
    showRawJson = false,
    verbose = false,
    showApps = false,
    showUserOnly = false,
    dryRun = false,
    newApp = false,
    deleteApp = false,
    updateApp = false,
    renameApp = false,
    resetJson = false,
    restartLighty = false,
    baseConfNum = 90000,
    appName = "",
    newName = "",
    appDescription = "",
    appLink = "",
    appIcon = "",
    appColor = "",
    appVersion = ""
}

new_app_defaults = {
    description = "A new User App",
    configNum = -1,
    urlPath = "--",
    subDir = "--",
    link = "http://localhost",
    icon = "app-registration",
    color = "cyanAccent",
    version = "0.0.0"
}

exit_codes = {
    noOptions = 255,
    noAppName = 254,
    appNameNotUnique = 253,
    appNotFound = 252,
    noNewName = 251
}

-- SSE Event Triggering Functions
function trigger_ui_update(event_type, app_data)
    if options.dryRun then
        print("[ DRY RUN - Would trigger UI update: " .. event_type .. " ]")
        return
    end

    local event_data = {
        event = event_type,
        app = app_data,
        timestamp = os.time()
    }

    -- Method 1: File-based trigger (primary)
    trigger_file_event(event_data)

    -- Method 2: MQTT trigger (backup)
    trigger_mqtt_event(event_data)

    print("[ UI Event Triggered: " .. event_type .. " ]")
end

function trigger_file_event(event_data)
    local json_content = json.encode(event_data)

    -- 寫入內部使用的觸發檔案
    local trigger_file = "/tmp/linksys_app_update"
    local f = io.open(trigger_file, "w")
    if f then
        f:write(json_content)
        f:close()
    end

    -- 創建 /www/api/ 目錄（如果不存在）
    os.execute("mkdir -p /www/api")

    -- 1. 寫入最新事件 API
    local web_api_file = "/www/api/app-events.json"
    local f2 = io.open(web_api_file, "w")
    if f2 then
        f2:write(json_content)
        f2:close()
    end

    -- 2. 複製完整應用列表到 Web 可存取位置
    local apps_api_file = "/www/api/apps.json"
    os.execute("cp " .. CONFIG_PATH .. " " .. apps_api_file .. " 2>/dev/null || true")
end

function trigger_mqtt_event(event_data)
    local mqtt_available = os.execute("which mosquitto_pub > /dev/null 2>&1")
    if mqtt_available == 0 then
        local payload = json.encode(event_data)
        local cmd = string.format(
            "mosquitto_pub -h 127.0.0.1 -p 1883 -t 'linksys/ui/app_update' -m '%s' 2>/dev/null &",
            payload:gsub("'", "'\\''")
        )
        os.execute(cmd)
    end
end

function generate_lighttpd_config(apps_config)
    local config_lines = {}
    table.insert(config_lines, "# Auto-generated app routes - " .. os.date())

    local userApps = apps_config.userApps or {}
    for _, app in pairs(userApps) do
        if app.urlPath and app.urlPath ~= "--" and app.urlPath ~= "" then
            local alias_line = string.format(
                'alias.url += ( "/%s/" => "/usr_www/%s/" )',
                app.urlPath, app.urlPath
            )
            table.insert(config_lines, alias_line)
        end
    end

    local config_path = "/etc/lighttpd/conf.d/99-apps.conf"
    local f = io.open(config_path, "w")
    if f then
        f:write(table.concat(config_lines, "\n") .. "\n")
        f:close()
        print("[ Updated lighttpd config: " .. config_path .. " ]")

        -- Reload lighttpd
        os.execute("/etc/init.d/lighttpd reload 2>/dev/null &")
    else
        print("[ Warning: Could not write lighttpd config ]")
    end
end

-- helper functions (keeping existing ones)
function show_app(app)
    print("App Name:    ", app.name)
    print("Description: ", app.description or "N/A")
    if app.urlPath then print("URL Path:    ", app.urlPath) end
    if app.subDir then print("Sub Dir:     ", app.subDir) end
    print("Link URL:    ", app.link or "N/A")

    if options.verbose then
        print("Icon:        ", app.icon or "N/A")
        print("Color:       ", app.color or "N/A")
        print("Version:     ", app.version or "N/A")
        if app.configNum then print("Config #:    ", app.configNum) end
    end
    print()
end

function display_apps(list)
    if #list == 0 then
        print('--no apps present--\n')
        return
    end

    for k, v in pairs(list) do
        show_app(v)
    end
end

function display_main_apps()
    print("\n[Main Apps]\n")
    display_apps(apps_list)
end

function display_user_apps(header)
    local hdr_txt = header or "Current User Apps"
    print("\n[" .. hdr_txt .. "]\n")
    display_apps(user_apps_list)
end

function check_unique_name(name, list)
    for k, v in pairs(list) do
        if v.name == name then
            return false
        end
    end
    return true
end

function find_userapp_by_name(app_name)
    for k, v in pairs(user_apps_list) do
        if v.name == app_name then
            return user_apps_list[k]
        end
    end
    return nil
end

function unique_app_name(name)
    return check_unique_name(name, apps_list) and check_unique_name(name, user_apps_list)
end

function get_app_from_options(options, fallbacks)
    return {
        name = options.newName or options.appName,
        description = options.appDescription or fallbacks.description,
        configNum = options.configNum or fallbacks.configNum,
        urlPath = options.appUrlPath or fallbacks.urlPath,
        subDir = options.appSubDir or fallbacks.subDir,
        link = options.appLink or fallbacks.link,
        icon = options.appIcon or fallbacks.icon,
        color = options.appColor or fallbacks.color,
        version = options.appVersion or fallbacks.version
    }
end

function set_app_options_from_json(json_data)
    local app_data = json.decode(json_data)

    options.appName = app_data.name
    options.configNum = app_data.configNum
    options.appUrlPath = app_data.urlPath or "--"
    options.appSubDir = app_data.subDir or "--"
    options.appDescription = app_data.description
    options.appIcon = app_data.icon
    options.appColor = app_data.color
    options.appVersion = app_data.version

    if options.appUrlPath ~= "--" and options.appSubDir ~= "--" then
        options.appLink = base_userapp_urlpath .. options.appUrlPath .. "/"
    end

    if options.updateApp then
        options.newName = app_data.new_name
    end
end

function sanitize_options()
    for k, v in pairs(options) do
        if v == "" or v == "---" then
            options[k] = nil
        end
    end
end

function handle_args()
    local o = options

    for i = 1, #arg do
        local a = arg[i]

        if a == "--dry-run" then
            o.dryRun = true
        elseif a == "--verbose" then
            o.verbose = true
        elseif a == "--restart-lighty" then
            o.restartLighty = true
        elseif (o.newApp or o.updateApp or o.renameApp or o.deleteApp) and o.appName == "---" then
            if string.sub(a, 1, 1) == "{" then
                set_app_options_from_json(a)
            else
                o.appName = a
                if o.newApp then
                    o.appDescription = "---"
                elseif o.renameApp then
                    o.newName = "---"
                end
            end
        elseif o.newApp and o.appDescription == "---" then
            o.appDescription = a
            o.appLink = "---"
        elseif o.newApp and o.appLink == "---" then
            o.appLink = a
            o.appIcon = "---"
        elseif o.newApp and o.appIcon == "---" then
            o.appIcon = a
            o.appColor = "---"
        elseif o.newApp and o.appColor == "---" then
            o.appColor = a
        elseif o.renameApp and o.newName == "---" then
            o.newName = a
        elseif a == "new" then
            o.newApp, o.appName = true, "---"
        elseif a == "update" then
            o.updateApp, o.appName = true, "---"
        elseif a == "rename" then
            o.renameApp, o.appName = true, "---"
        elseif a == "delete" then
            o.deleteApp, o.appName = true, "---"
        elseif a == "listapps" or a == "list" then
            o.showApps, o.showUserOnly = true, false
        elseif a == "listuserapps" then
            o.showApps, o.showUserOnly = true, true
        elseif a == "showconfig" then
            o.showRawJson = true
        elseif a == "resetconfig" then
            o.resetJson = true
        end
    end
end

-- file utils
function path_exists(path)
    local file = io.open(path, "r")
    if (file ~= nil) then
        io.close(file)
        return true
    else
        return false
    end
end

function get_file_contents(file_name)
    local file = io.open(file_name, "r")
    if not file then
        return nil
    end
    local contents = file:read("*all")
    file:close()
    return contents
end

function backup_config_file()
    if path_exists(CONFIG_PATH) then
        os.execute("cp " .. CONFIG_PATH .. " " .. CONFIG_BACKUP_PATH)
    end
end

function update_config_file(data, file_name)
    print("\n[Updating " .. file_name .. "]\n")

    backup_config_file()

    local updated_config_enc = json.encode(data)

    -- Try to use jq for pretty formatting, fallback to direct write
    local jq_available = os.execute("which jq > /dev/null 2>&1")
    if jq_available == 0 then
        local cmd = "echo '" .. updated_config_enc .. "' | jq --indent 4 > " .. file_name
        os.execute(cmd)
    else
        local file = io.open(file_name, "w")
        if file then
            file:write(updated_config_enc)
            file:close()
        end
    end
end

function handle_updates(current_app, config_json)
    if options.newApp then
        table.insert(user_apps_list, current_app)
        trigger_ui_update("installed", current_app)
    elseif options.deleteApp then
        local new_apps_list = {}
        for k, v in pairs(user_apps_list) do
            if v.name ~= current_app.name then
                table.insert(new_apps_list, user_apps_list[k])
            end
        end

        config_json.userApps = new_apps_list
        user_apps_list = config_json.userApps
        trigger_ui_update("removed", current_app)
    elseif options.updateApp then
        trigger_ui_update("updated", current_app)
    end

    display_user_apps("Updated User Apps")

    if options.dryRun == false then
        update_config_file(config_json, CONFIG_PATH)
        generate_lighttpd_config(config_json)
    else
        print("\n[dry run - no changes made]\n")
    end
end

-- main script
function create_default_config()
    local main_config = {
        api = {
            creator = "Linksys",
            version = "0.0.1"
        },
        apps = {
            {
                name = "Router Admin",
                description = "Router Administration Panel",
                link = "http://192.168.1.1/admin",
                icon = "settings",
                color = "blueAccent",
                version = "1.0.0"
            }
        },
        userApps = {}
    }

    if not path_exists(CONFIG_PATH) then
        print("Creating default configuration: " .. CONFIG_PATH)
        update_config_file(main_config, CONFIG_PATH)
    end
end

-- initialize
handle_args()
create_default_config()

-- read configuration
local config_contents = get_file_contents(CONFIG_PATH)
if not config_contents then
    print("Error: Could not read configuration file: " .. CONFIG_PATH)
    os.exit(1)
end

local config_json = json.decode(config_contents)
apps_list = config_json.apps or {}
user_apps_list = config_json.userApps or {}

-- execute commands
if options.resetJson then
    print("\n[Resetting " .. CONFIG_PATH .. " to base]\n")
    config_json.userApps = {}
    update_config_file(config_json, CONFIG_PATH)

elseif options.showRawJson then
    local config_enc = json.encode(config_json)
    print(config_enc)

elseif options.showApps then
    if options.showUserOnly == false then
        display_main_apps()
    end
    display_user_apps()

elseif options.deleteApp then
    sanitize_options()
    local app_name = options.appName

    if not app_name or unique_app_name(app_name) then
        print("\n[User App not found: " .. (app_name or "nil") .. "]\n")
        os.exit(exit_codes.appNotFound)
    end

    print("\n[Deleting: " .. app_name .. "]\n")
    local current_app = find_userapp_by_name(app_name)
    handle_updates(current_app, config_json)

elseif options.updateApp then
    sanitize_options()

    if not options.appName then
        print("\n[update requires an App name as an argument]\n")
        os.exit(exit_codes.noAppName)
    end

    local current_app = find_userapp_by_name(options.appName)
    if not current_app then
        print("\n[User App not found: " .. options.appName .. "]\n")
        os.exit(exit_codes.appNotFound)
    end

    local updated_app = get_app_from_options(options, current_app)
    for k in pairs(updated_app) do
        current_app[k] = updated_app[k]
    end

    handle_updates(current_app, config_json)

elseif options.renameApp then
    sanitize_options()

    if not options.appName then
        print("\n[rename requires App name as the 1st argument]\n")
        os.exit(exit_codes.noAppName)
    elseif not options.newName then
        print("\n[rename requires a new App name as the 2nd argument]\n")
        os.exit(exit_codes.noNewName)
    end

    local current_app = find_userapp_by_name(options.appName)
    if not current_app then
        print("\n[User App not found: " .. options.appName .. "]\n")
        os.exit(exit_codes.appNotFound)
    end

    if not check_unique_name(options.newName, user_apps_list) then
        print("\n[User App name already in use: " .. options.newName .. "]\n")
        os.exit(exit_codes.appNameNotUnique)
    end

    current_app.name = options.newName
    handle_updates(current_app, config_json)

elseif options.newApp then
    sanitize_options()

    if not options.appName then
        print("\n[new requires an App name as an argument]\n")
        os.exit(exit_codes.noAppName)
    end

    if not unique_app_name(options.appName) then
        print("\n[User App name already in use: " .. options.appName .. "]\n")
        os.exit(exit_codes.appNameNotUnique)
    end

    local new_app = get_app_from_options(options, new_app_defaults)
    handle_updates(new_app, config_json)

else
    print("\n[Usage: app_util.lua {list|listuserapps|new|update|delete|rename} [options]]\n")
    print("Examples:")
    print("  ./app_util.lua list")
    print("  ./app_util.lua new \"My App\" --dry-run")
    print("  ./app_util.lua delete \"My App\"")
    print("  ./app_util.lua new '{\"name\":\"Demo\",\"urlPath\":\"demo\"}' --verbose")
    print("")
end