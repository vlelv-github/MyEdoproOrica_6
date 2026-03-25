-- 우주괴수 그로온
local s,id=GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_REPTILE),1,1,Synchro.NonTuner(nil),1,99)

    local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)

	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_RELEASE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0,TIMING_MAIN_END|TIMING_SUMMON|TIMING_SPSUMMON)
	e1:SetCountLimit(1,{id,2})
	e1:SetCondition(function() return Duel.IsMainPhase() end)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end
-- "에일리언"의 테마명이 쓰여짐
s.listed_series={SET_ALIEN}
-- "A 카운터"가 쓰여짐
s.counter_list={COUNTER_A}
function s.thfilter(c)
	return c:ListsCounter(COUNTER_A) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
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

function s.AcounterFilter(c)
	return c:GetCounter(COUNTER_A)>0 and c:IsReleasableByEffect() and c:IsFaceup()
end
function s.alien_filter(c,e,tp)
	return c:IsSetCard(SET_ALIEN) and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(s.AcounterFilter,tp,LOCATION_MZONE,LOCATION_MZONE,c)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_RELEASE,g,#g,0,0)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(s.AcounterFilter,tp,LOCATION_MZONE,LOCATION_MZONE,c)
	local r=Duel.Release(g,REASON_EFFECT)

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_ADD_SETCODE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(SET_ALIEN)
	e1:SetReset(RESETS_STANDARD_PHASE_END)
	c:RegisterEffect(e1)

	if r==0 then return end
	local mz=Duel.GetMZoneCount(tp)
	if Duel.IsExistingMatchingCard(s.alien_filter,tp,LOCATION_GRAVE,0,1,nil,e,tp) and mz>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		local sp=Duel.SelectMatchingCard(tp,s.alien_filter,tp,LOCATION_GRAVE,0,1,math.min(mz,r),nil,e,tp)
		if #sp>0 then 
			Duel.SpecialSummon(sp,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end