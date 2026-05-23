-- 레프티레스 브리트라
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Synchro Summon procedure
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_REPTILE),1,1,Synchro.NonTuner(nil),1,99)

    local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,{id,0})
	e1:SetCondition(function(e) return e:GetHandler():IsSynchroSummoned() end)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)


	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EFFECT_DESTROY_REPLACE)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.repcon)
	e3:SetTarget(s.reptg)
	e3:SetValue(s.repval)
	e3:SetOperation(s.repop)
	c:RegisterEffect(e3)

end


function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    -- 상대 필드에 토큰을 특수 소환할 공간이 있어야 함.
    -- 상대 필드에 토큰 생성이 가능해야 함
	if chk==0 then return Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0 
        and Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_REPTILIANNE,SET_REPTILIANNE,TYPES_TOKEN,0,0,1,RACE_REPTILE,ATTRIBUTE_EARTH,POS_FACEUP_DEFENSE,1-tp)
    end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end
function s.spfilter(c,e,tp)
	-- 특수 소환이 가능한 레벨 4 이하의 파충류족 몬스터 필터
	return c:IsRace(RACE_REPTILE) and c:IsMonster() and c:IsLevelBelow(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	-- 토큰 생성이 불가능 하면 불발
    if not Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_REPTILIANNE,SET_REPTILIANNE,TYPES_TOKEN,0,0,1,RACE_REPTILE,ATTRIBUTE_EARTH,POS_FACEUP_DEFENSE,1-tp) then return false end
    -- 사용 가능한 상대 몬스터 존이 없으면 불발
	if Duel.GetLocationCount(1-tp,LOCATION_MZONE)<=0 then return false end

	-- 생성할 토큰 갯수 조정
    local ct=math.min(Duel.GetLocationCount(1-tp,LOCATION_MZONE), 3)
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) and ct>=2 then 
        ct=1
    else
        ct=Duel.AnnounceNumberRange(tp,1,ct)
    end

    local cnt=0
    for i=1,ct do
		local token=Duel.CreateToken(tp,TOKEN_REPTILIANNE)
		Duel.SpecialSummonStep(token,0,tp,1-tp,false,false,POS_FACEUP_DEFENSE)
        cnt = cnt + 1
	end
    Duel.SpecialSummonComplete()
	-- 생성한 토큰 수만큼 패 / 묘지에서 파충류족 특소 가능
    if cnt>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
    and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp)
    and Duel.SelectYesNo(tp, aux.Stringid(id, 1)) then
        local ft=math.min(Duel.GetLocationCount(tp,LOCATION_MZONE),cnt)
        if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) and ft>=2 then ft=1 end
        Duel.BreakEffect()
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,ft,nil,e,tp)
        if #g>0 then
            Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
        end

    end
end


function s.cfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_REPTILE)
end
function s.repcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
end
function s.repfilter(c,tp)
	return c:IsControler(tp) and c:IsLocation(LOCATION_ONFIELD)
		and not c:IsReason(REASON_REPLACE) and c:IsReason(REASON_EFFECT)
end
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToRemove() and eg:IsExists(s.repfilter,1,nil,tp) end
	return Duel.SelectEffectYesNo(tp,c,96)
end
function s.repval(e,c)
	return s.repfilter(c,e:GetHandlerPlayer())
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_EFFECT|REASON_REPLACE)
end