local assets={
	Asset("ANIM", "anim/carrotrod.zip"),
	Asset("ANIM", "anim/swap_carrotrod.zip"),
	Asset("ATLAS", "images/inventoryimages/carrotrod.xml"),
	Asset("IMAGE", "images/inventoryimages/carrotrod.tex"),
}
-- 加载资源表，一般来说应该在开头位置
-- ANIM 动画资源，分别代表放在地上和拿在手里的动画
-- ATLAS 图片文档，用于物品栏图片。由于图片文档内含有指向具体图片的地址，所以这里不需要再额外加载图片
-- IMAGE 好像也是物品栏图片？
prefabs = {}

-- 给予物品代码，来自kahiro
-- TODO：只有骑牛才能给予物品
-- 只有素食/粗食才可以放在钓竿上
local function ItemTradeTest(inst, item)
	if item == nil or item.components.edible == nil then
		return false
	elseif item.components.edible.foodtype ~= FOODTYPE.VEGGIE and item.components.edible.foodtype ~= FOODTYPE.ROUGHAGE then
		return false 
	end
	return true
end

local function OnGetItemFromPlayer(inst, giver, item) -- 骑牛判定来自Souls heal your beefalos
    if item and (item.components.edible.foodtype == FOODTYPE.VEGGIE or item.components.edible.foodtype == FOODTYPE.ROUGHAGE) and giver then
		if giver.components.rider and giver.components.rider:IsRiding() then
            local ride = giver.components.rider:GetMount()
			if ride and ride.components.health then
                ride.components.health:DoDelta(4 * item.components.edible.healthvalue, nil, giver.prefab)
            end
			if ride and ride.components.hunger then
                ride.components.hunger:DoDelta(item.components.edible.hungervalue)
            end
			local full = ride.components.hunger:GetPercent() >= 1
    		if not full then
        		ride.components.domesticatable:DeltaObedience(TUNING.BEEFALO_DOMESTICATION_FEED_OBEDIENCE)
    		else
        		ride.components.domesticatable:DeltaObedience(TUNING.BEEFALO_DOMESTICATION_OVERFEED_OBEDIENCE)
        		ride.components.domesticatable:DeltaDomestication(TUNING.BEEFALO_DOMESTICATION_OVERFEED_DOMESTICATION)
        		ride.components.domesticatable:DeltaTendency(TENDENCY.PUDGY, TUNING.BEEFALO_PUDGY_OVERFEED)
				giver.SoundEmitter:PlaySound("dontstarve/beefalo/fart")
    		end
			giver.SoundEmitter:PlaySound("dontstarve/beefalo/chew")
		else
			giver.components.talker:Say("现在挂上去也没用哦。")
		end  
    end 
end


-- 描述函数向游戏系统描述了这个Prefab的各种情况，一般命名为fn
--[[包含内容：
	动画，要显示在地图上。
	图片，要显示在物品栏里。
	变换(Transform)，要能移动位置。
	物理引擎，要能和其它物体发生互动。
	网络，要能被其它玩家看到和互动。
--]]

local function fn()
	-- 装备回调函数
	local function OnEquip(inst, owner)
		owner.AnimState:OverrideSymbol("swap_object", "swap_carrotrod", "swap_carrotrod")
		owner.AnimState:Show("ARM_carry")
		owner.AnimState:Hide("ARM_normal")
	end
	-- 卸载回调函数
	local function OnUnequip(inst, owner)
		owner.AnimState:Hide("ARM_carry")
		owner.AnimState:Show("ARM_normal")
	end

	local inst = CreateEntity() -- 创建实体
	local trans = inst.entity:AddTransform() -- 添加变换组件
	local anim = inst.entity:AddAnimState() -- 添加动画组件
	local sound = inst.entity:AddSoundEmitter()
	MakeInventoryPhysics(inst) -- 添加物理属性

	anim:SetBank("carrotrod") -- 设置动画的Bank，也就是动画内容组合
	anim:SetBuild("carrotrod") -- 设置动画的Build，也就是外表材质
	anim:PlayAnimation("idle") -- 设置生成时应该播放的动画
	
	inst.entity:AddNetwork() -- 添加网络组件
	---------------------- 主客机分界代码 -------------------------
	-- 往上是主客机通用代码，往下则是只限于主机使用的代码
	if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()
	
	---------------------- 通用组件 -------------------------
	inst:AddComponent("inspectable") -- 可检查

	inst:AddComponent("inventoryitem") -- 可放入物品栏
	inst.components.inventoryitem.atlasname = "images/inventoryimages/carrotrod.xml"
	inst.components.inventoryitem.imagename = "carrotrod"

	inst:AddComponent("equippable") -- 可装备
	inst.components.equippable:SetOnEquip( OnEquip ) -- 设置装备时的回调函数
	inst.components.equippable:SetOnUnequip( OnUnequip ) -- 设置卸载时的回调函数
	inst.components.equippable.walkspeedmult = TUNING.CARROTROD.SPEEDMULTIPLIER

	---------------------- 核心组件 -------------------------
	inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.CARROTROD.DAMAGE)

	inst:AddComponent("trader")
    inst.components.trader:SetAbleToAcceptTest(ItemTradeTest)
    inst.components.trader.onaccept = OnGetItemFromPlayer

	---------------------- 辅助组件 -------------------------
    -- 可腐烂的组件，耐久会随时间推移而自然地降低，常用于食物
    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED) -- 设置耐久度，和carrot一样
    inst.components.perishable:StartPerishing() -- 当物体生成的时候就开始腐烂
	inst.components.perishable.onperishreplacement = "fishingrod"
    inst:AddTag("show_spoilage") -- To show spoilage as a bar instead of a percentage.
	inst:AddTag("icebox_valid")

	return inst
end

-- 这里第一项参数是物体名字，写成路径的形式是为了能够清晰地表达这个物体的分类，common也就是普通物体，inventory表明这是一个可以放在物品栏中使用的物体，最后的lotus_umbrella则是真正的Prefab名
-- 游戏在识别的时候只会识别最后这一段Prefab名，也就是lotus_umbrella。前面的部分只是为了代码可读性，对系统而言并没有什么特别意义
return  Prefab("common/inventory/carrotrod", fn, assets, prefabs)
