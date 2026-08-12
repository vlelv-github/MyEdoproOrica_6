-- Sin 패러미터
local s,id=GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
	c:AddMustBeSpecialSummoned()
	aux.AddMaleficSummonProcedure(c,{74509280,48829461},LOCATION_HAND|LOCATION_GRAVE)
	c:SetSPSummonOnce(id)
	--spson
	local e9=Effect.CreateEffect(c)
	e9:SetType(EFFECT_TYPE_SINGLE)
	e9:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e9:SetCode(EFFECT_SPSUMMON_CONDITION)
	e9:SetValue(aux.FALSE)
	c:RegisterEffect(e9)
    local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_REMOVE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(1,1)
	e1:SetTarget(s.rmlimit)
	c:RegisterEffect(e1)
end

s.listed_names = {27564031,74509280,48829461}
s.listed_series = {SET_MALEFIC}
function s.rmlimit(e,c,tp,r)
	return c:IsCode(27564031) and c:IsLocation(LOCATION_ONFIELD) and c:IsFaceup()
		and c:IsControler(e:GetHandlerPlayer()) and not c:IsImmuneToEffect(e) and r&REASON_EFFECT>0
end
function s.filter(c,e,tp,ft)
	return c:IsLevelBelow(10) and c:IsMonster() and c:IsSetCard(SET_MALEFIC) and (c:IsAbleToHand() or (ft>0 and c:IsCanBeSpecialSummoned(e,0,tp,true,false)))
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp,ft) end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,nil,1,tp,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK|LOCATION_GRAVE|LOCATION_REMOVED)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK|LOCATION_GRAVE|LOCATION_REMOVED)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,2))
	-- Sin 월드가 존재하면 덱에서도 선택 가능
	local loc=Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,27564031),tp,LOCATION_FZONE,LOCATION_FZONE,1,nil) and LOCATION_DECK+LOCATION_REMOVED+LOCATION_GRAVE or LOCATION_REMOVED+LOCATION_GRAVE
	local hc=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.filter),tp,loc,0,1,1,nil,e,tp,ft):GetFirst()
	if not hc then return end
	aux.ToHandOrElse(hc,tp,
		function()
			return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and hc:IsCanBeSpecialSummoned(e,0,tp,true,false)
		end,
		function()
			Duel.SpecialSummon(hc,0,tp,tp,true,false,POS_FACEUP)
		end,
		aux.Stringid(id,3)
	)
end