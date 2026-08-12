-- 여신 스쿨드의 왈큐레-아르테스트
local s,id=GetID()
function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,{id,0})
	e1:SetCost(Cost.SelfDiscard)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)


	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_LEAVE_GRAVE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_PHASE|PHASE_BATTLE_START)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)

	-- 효과를 발동한 것을 카운팅
	aux.GlobalCheck(s,function()
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_CHAIN_SOLVED)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end)
end
s.listed_names = {65687442}
s.listed_series = {SET_VALKYRIE}

function s.thfilter(c)
	return (c:IsCode(65687442) or (c:IsSetCard(SET_VALKYRIE) and c:IsMonster() and c:IsLevelBelow(9))) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	Duel.RegisterFlagEffect(rp,id,RESET_PHASE|PHASE_END,0,1)
end



function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetFlagEffect(tp,id)<1 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,0)
end
function s.atkfilter(c)
	return c:IsFaceup() and (not c:IsBaseAttack(0)) and c:IsSetCard(SET_VALKYRIE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		local breakeffect = false
		-- 공격력 상승
		local b1=Duel.IsExistingMatchingCard(s.atkfilter,0,LOCATION_MZONE,LOCATION_MZONE,1,c)
		-- 상대 카드를 묘지로
		local b2=Duel.GetFieldGroupCount(tp,0,LOCATION_ONFIELD)>1

		if b1 and Duel.SelectYesNo(tp, aux.Stringid(id, 2)) then 
			breakeffect = true
			if breakeffect then Duel.BreakEffect() end
			local g=Duel.GetMatchingGroup(s.atkfilter,tp,LOCATION_MZONE,LOCATION_MZONE,c)

			if #g>0 then 
				local atk=g:GetSum(Card.GetBaseAttack,nil)
				c:UpdateAttack(atk)
			end
		end

		if b2 and Duel.SelectYesNo(tp, aux.Stringid(id, 3)) then
			if not breakeffect then Duel.BreakEffect() end
			local g=Duel.GetFieldGroup(tp,0,LOCATION_ONFIELD)
			local ct=#g-1
			if ct>0 then
				Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_TOGRAVE)
				local sg=g:Select(1-tp,ct,ct,nil)
				Duel.SendtoGrave(sg,REASON_RULE,PLAYER_NONE,1-tp)
			end
		end
	end
end