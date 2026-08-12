-- 궁극 시계신 Z-ONE
local s,id=GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    c:AddMustBeSpecialSummoned()
    
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetRange(LOCATION_HAND)
	e0:SetCondition(s.spcon)
	e0:SetTarget(s.sptg)
	e0:SetOperation(s.spop)
	c:RegisterEffect(e0)


	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.tgofilter)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)

    local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetCountLimit(1)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTarget(s.sptg2)
	e3:SetOperation(s.spop2)
	c:RegisterEffect(e3)
end

s.listed_names = {}
s.listed_series = {}

function s.spconfilter(c)
	return (c:IsFaceup() or c:IsLocation(LOCATION_HAND)) and c:IsSetCard(SET_TIMELORD) and c:IsMonster() and c:IsAbleToDeckAsCost()
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=e:GetHandlerPlayer()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.IsExistingMatchingCard(s.spconfilter,tp,LOCATION_HAND|LOCATION_MZONE|LOCATION_REMOVED,0,2,e:GetHandler())
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=Duel.GetMatchingGroup(s.spconfilter,tp,LOCATION_HAND|LOCATION_MZONE|LOCATION_REMOVED,0,e:GetHandler())
	local sg=aux.SelectUnselectGroup(g,e,tp,2,2,nil,1,tp,HINTMSG_TODECK,nil,nil,true)
	if #sg>0 then
		e:SetLabelObject(sg)
		return true
	end
	return false
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if g then
		local sc=g:GetFirst()
		if sc:IsLocation(LOCATION_HAND) then
			Duel.ConfirmCards(1-tp,sc)
		else
			Duel.HintSelection(sc)
		end
		Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_COST)
	end
end

function s.tgofilter(e,c)
	return c:IsSetCard(SET_TIMELORD) and c:IsFaceup()
end

function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_TIMELORD) and c:GetAttack()==0 and c:IsMonster()
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND|LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND|LOCATION_DECK)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND|LOCATION_DECK,0,1,1,nil,e,tp):GetFirst()
	if g and Duel.SpecialSummon(g,0,tp,tp,true,false,POS_FACEUP)~=0 then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
        e1:SetCondition(s.discon)
		g:RegisterEffect(e1,true)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
        e2:SetCondition(s.discon)
		e2:SetReset(RESET_EVENT|RESETS_STANDARD)
		g:RegisterEffect(e2,true)
		Duel.SpecialSummonComplete()
        local e3=Effect.CreateEffect(c)
        e3:SetType(EFFECT_TYPE_SINGLE)
        e3:SetCode(EFFECT_SET_ATTACK)
        e3:SetValue(4000)
        e3:SetReset(RESET_EVENT|(RESETS_STANDARD&~RESET_TOFIELD))
        g:RegisterEffect(e3)

	end
end

function s.discon(e)
	return Duel.IsTurnPlayer(e:GetHandlerPlayer()) and Duel.IsStandbyPhase()
end