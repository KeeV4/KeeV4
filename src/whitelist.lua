local Whitelist = {
	Enabled = false,
}

function Whitelist:Check(context)
	-- Temporary development whitelist.
	-- Replace this function with your API check later.

	return true, nil
end

return Whitelist
