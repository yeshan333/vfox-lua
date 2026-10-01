local helpers = {}
function helpers.scenario(name, run)
    local ok, err = pcall(run)
    assert(ok, name .. ": " .. tostring(err))
    print("PASS: " .. name)
end
function helpers.raises(fragment, run)
    local ok, err = pcall(run)
    assert(not ok and tostring(err):find(fragment, 1, true), "expected error containing " .. fragment .. ", got " .. tostring(err))
end
return helpers
