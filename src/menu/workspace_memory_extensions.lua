-- Register workspace memory and add it near the top of the main menu.

registerWorkspaceMemoryCalculators(calculators)

local workspaceMemoryMenu = {
    title="Workspace Memory",
    subtitle="Reuse stored values in any calculator expression",
    items={
        {label="Store / View A-J",calculator="workspaceMemory"},
        {label="Evaluate Stored Expression",calculator="workspaceRecall"}
    }
}

table.insert(rootMenu.items, 2, {label="Workspace Memory",menu=workspaceMemoryMenu})
