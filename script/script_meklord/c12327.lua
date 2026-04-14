-- 기황지배
local s,id=GetID()
function s.initial_effect(c)
    local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e0:SetCode(EVENT_CHAIN_SOLVING)
	e0:SetRange(LOCATION_SZONE)
	e0:SetCondition(s.discon)
	e0:SetOperation(s.disop)
	c:RegisterEffect(e0)

    local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)

    local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOGRAVE)
    e3:SetCountLimit(1,{id,1})
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetTarget(s.tgtg)
	e3:SetOperation(s.tgop)
	c:RegisterEffect(e3)
end
s.listed_series = {SET_MEKLORD}
function s.mekfilter(c)
    return c:IsSetCard(SET_MEKLORD) and c:IsMonster() and c:IsFaceup()
end
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.mekfilter,tp,LOCATION_MZONE,0,1,nil) and rp==1-tp and re:IsMonsterEffect() 
        and re:GetHandler():IsType(TYPE_TUNER|TYPE_SYNCHRO) and re:GetHandler():GetOwner()~=e:GetHandler():GetControler()
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateEffect(ev)
end

function s.spfilter(c,code,e,tp)
	return c:IsSetCard(SET_MEKLORD) and not c:IsCode(code) and c:IsMonster() and (c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP) or c:IsAbleToHand())
end
function s.desfilter(c,e,tp)
    return c:IsFaceup() and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,c:GetCode(),e,tp)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then return chkc:IsOnField() and chkc:IsControler(tp) and s.desfilter(chkc,e,tp) and chkc~=c end
	if chk==0 then return Duel.IsExistingTarget(s.desfilter,tp,LOCATION_ONFIELD,0,1,c,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,s.desfilter,tp,LOCATION_ONFIELD,0,1,1,c,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK|LOCATION_GRAVE)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK|LOCATION_GRAVE)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and Duel.Destroy(tc,REASON_EFFECT)~=0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,tc:GetCode(),e,tp):GetFirst()
		if g then
            local sp_chk=Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			aux.ToHandOrElse(g,tp,
                function() return sp_chk and g:IsCanBeSpecialSummoned(e,0,tp,false,false) end,
                function() Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP) end,
                aux.Stringid(id,5)
            )
		end
	end
end

function s.synfilter(c)
    return c:IsType(TYPE_SYNCHRO) and c:IsMonster() and c:IsAbleToGrave()
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
    local g1=Duel.GetFieldGroup(tp,LOCATION_EXTRA,0) -- 내 엑덱
	local g2=Duel.GetFieldGroup(tp,0,LOCATION_EXTRA) -- 상대 엑덱
	if chk==0 then return #g1>0 or #g2>0 end --둘 중 한 쪽이라도 있으면 발동 가능
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_EXTRA)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
    local g1=Duel.GetFieldGroup(tp,LOCATION_EXTRA,0) -- 내 엑덱
	local g2=Duel.GetFieldGroup(tp,0,LOCATION_EXTRA) -- 상대 엑덱
    if (#g1<1 and #g2<1) then return false end -- 효과 처리시에 둘 다 엑덱이 없으면 불발

    -- 누구의 엑덱을 볼지 결정
    local op=Duel.SelectEffect(tp,
		{#g1>0,aux.Stringid(id,2)},
		{#g2>0,aux.Stringid(id,3)})
    
    local g=(op==1) and g1 or g2 -- 엑덱 타겟 설정
    Duel.ConfirmCards(tp,g) -- 엑덱을 확인
    Duel.BreakEffect()
    
    -- 싱크로 몬스터가 껴있으면 그 중 1장을 묘지로 보낼 것인지를 선택
    if g:IsExists(s.synfilter,1,nil) and Duel.SelectYesNo(tp,aux.Stringid(id,4)) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
        -- 싱크로 몬스터를 선택
        local tg=g:FilterSelect(tp,s.synfilter,1,1,nil)
        if #tg>0 then
            Duel.SendtoGrave(tg,REASON_EFFECT) -- 덤핑
            if op==2 then Duel.ShuffleExtra(1-tp) end -- 상대 엑덱을 본거면 처리 후 엑덱 셔플
        end
    end


   
end