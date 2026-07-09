-- 크로노다이버 스플릿 S(세컨드)
local s,id=GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
	Xyz.AddProcedure(c,nil,4,2)

    local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetTarget(s.attachtg)
	e1:SetOperation(s.attachop)
	c:RegisterEffect(e1)

    local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMING_STANDBY_PHASE|TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
	e2:SetCondition(function(e) 
        local xyzg=e:GetHandler():GetOverlayGroup()
        return xyzg:FilterCount(Card.IsMonster,nil)>0 and xyzg:FilterCount(Card.IsSpell,nil)>0 and xyzg:FilterCount(Card.IsTrap,nil)>0
    end)
    e2:SetCost(Cost.SelfBanish)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end
s.listed_names = {12341}
s.listed_series = {SET_TIME_THIEF}
function s.attachtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_ONFIELD|LOCATION_GRAVE) and chkc:IsCanBeXyzMaterial(c,tp,REASON_EFFECT) end
	if chk==0 then return Duel.IsExistingTarget(Card.IsCanBeXyzMaterial,tp,0,LOCATION_ONFIELD+LOCATION_GRAVE,1,nil,c,tp,REASON_EFFECT) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local g=Duel.SelectTarget(tp,Card.IsCanBeXyzMaterial,tp,0,LOCATION_ONFIELD+LOCATION_GRAVE,1,1,nil,c,tp,REASON_EFFECT)
    if g:GetFirst():IsLocation(LOCATION_GRAVE) then
	    Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,g,#g,tp,0)
    end
end
function s.attachop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsImmuneToEffect(e) then return end
	local tg=Duel.GetTargetCards(e):Filter(Card.IsCanBeXyzMaterial,nil,c,tp,REASON_EFFECT):Remove(Card.IsImmuneToEffect,nil,e)
	if #tg>0 then
		Duel.Overlay(c,tg,true)
	end
end

function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_TIME_THIEF) and not c:IsCode(id) and c:IsXyzMonster() and Duel.GetLocationCountFromEx(tp,tp,nil,c)>1
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return 
        Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,2,nil,e,tp) 
        and Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)>=4 
    end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_EXTRA)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,2,2,nil,e,tp)
	if #g>1 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>1 and Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)>=4 then
        -- 상대 덱 위에서 4장을 넘김
        Duel.ConfirmDecktop(1-tp,4) 
        local dg=Duel.GetDecktopGroup(1-tp,4)
        -- 넘긴 카드 중 2장을 선택
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	    local sg=dg:FilterSelect(tp,aux.TRUE,2,2,nil)
        if #sg>0 then 
            -- 선택한 카드를 그 특수 소환한 몬스터 1장의 엑시즈 소재로 함
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
            local tc=g:Select(tp,1,1,nil):GetFirst()
            Duel.Overlay(tc,sg)
            g:RemoveCard(tc)
            dg:RemoveCard(sg)
            -- 남은 덱 맨위 2장을 나머지 몬스터의 엑시즈 소재로 함
            tc=g:GetFirst()
            Duel.Overlay(tc,dg)
        end
	end
end