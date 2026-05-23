-- 레프티레스 페트리피케이션
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.cfilter(c)
	return c:IsRace(RACE_REPTILE) and c:IsMonster() and not c:IsPublic()
end
function s.repfilter(c)
	return c:IsSetCard(SET_REPTILIANNE) and c:IsMonster()
end
function s.notzerofilter(c)
    return c:GetAttack()>0 and c:IsFaceup()
end
function s.zerofilter(c)
    return c:GetAttack()==0 and c:IsFaceup()
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    local g0=Duel.GetMatchingGroup(s.notzerofilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND,0,1,nil) and #g0>0 end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_HAND,0,1,#g0,nil)
	Duel.ConfirmCards(1-tp,g)
	Duel.ShuffleHand(tp)
	e:SetLabel(#g)
    if g:IsExists(s.repfilter,1,nil) then 
        Duel.SetChainLimit(function(e,ep,tp) return tp==ep end) 
    end
end
function s.thfilter(c)
    return c:IsSetCard(SET_REPTILIANNE) and c:IsMonster() and c:IsAbleToHand()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.notzerofilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
    Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
	local ct=e:GetLabel()
    local g=Duel.GetMatchingGroup(s.notzerofilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
    if #g>=ct then 
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATKDEF)
        g=g:Select(tp,ct,ct,nil)
        Duel.HintSelection(g)

        local tc = g:GetFirst()
        local cnt = 0
        while tc do 
            if tc:GetAttack() > 0 then
                local e1=Effect.CreateEffect(c)
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_SET_ATTACK_FINAL)
                e1:SetReset(RESETS_STANDARD_PHASE_END)
                e1:SetValue(0)
                tc:RegisterEffect(e1)

                cnt = cnt + 1
            end

            tc=g:GetNext()
        end

        if cnt > 0 and Duel.IsExistingMatchingCard(s.zerofilter,tp,LOCATION_MZONE,LOCATION_MZONE,2,nil) and Duel.SelectYesNo(tp, aux.Stringid(id, 0)) then 
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
            local g1=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK|LOCATION_GRAVE,0,1,1,nil)
            if #g1>0 then
                Duel.BreakEffect()
                Duel.SendtoHand(g1,nil,REASON_EFFECT)
                Duel.ConfirmCards(1-tp,g1)
            end
        end

    end
end
