GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})  --GLOBAL相关照抄

PrefabFiles = {"carrotrod",}

STRINGS.NAMES.CARROTROD = "胡萝卜钓竿" -- 物体在游戏中显示的名字
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CARROTROD = "我希望它们喜欢这个。" -- 物体的检查描述
STRINGS.RECIPE_DESC.CARROTROD = "用食物鼓励你的坐骑！" -- 物体的制作栏描述
TUNING.CARROTROD = {
	-- SPEEDMULTIPLIER = GetModConfigData("canemultiplier")
	SPEEDMULTIPLIER = 1.25,
	DAMAGE = 17
}

AddRecipe2("carrotrod", {Ingredient("carrot", 1), Ingredient("fishingrod", 1)},TECH.SCIENCE_TWO,{
    atlas = "images/inventoryimages/carrotrod.xml",
    image = "carrotrod.tex" 
},{"TOOLS","RIDING"})
