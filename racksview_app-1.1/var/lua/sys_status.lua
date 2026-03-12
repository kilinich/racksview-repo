local function plain_status()
    local f = io.open("/dev/shm/status.txt", "r")
    if f then
        local content = f:read("*a")
        f:close()
        return (content:gsub("%s+$", ""))
    end
    return "Status file not ready"
end

return {
    plain_status = plain_status
}