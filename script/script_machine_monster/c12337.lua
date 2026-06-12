-- 붉은 눈의 속사포 드래곤
local s,id=GetID()
function s.initial_effect(c)
	-- 소생 제한
	c:EnableReviveLimit()
	-- 소환 조건
	Fusion.AddProcMix(c,true,true,{CARD_REDEYES_B_DRAGON, 81480460},s.ffilter)

    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SET_ATTACK_FINAL)
    e1:SetRange(LOCATION_MZONE)
    e1:SetTargetRange(0, LOCATION_MZONE) -- 상대방 몬스터 존만 대상
    e1:SetTarget(s.atktg)
    e1:SetValue(0)
    c:RegisterEffect(e1)

    local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_COIN+CATEGORY_DESTROY+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetHintTiming(0,TIMING_MAIN_END|TIMINGS_CHECK_MONSTER)
	e2:SetCondition(function() return Duel.IsMainPhase() end)
	e2:SetTarget(s.cttg)
	e2:SetOperation(s.ctop)
	c:RegisterEffect(e2)
end
s.toss_coin=true
s.material_setcode=SET_RED_EYES
s.listed_names={CARD_REDEYES_B_DRAGON,81480460}

function s.ffilter(c,fc,sumtype,tp)
	return (c:IsRace(RACE_MACHINE,fc,sumtype,tp) or c:IsRace(RACE_DRAGON,fc,sumtype,tp)) and c:IsAttribute(ATTRIBUTE_DARK,fc,sumtype,tp)
end

-- 대상 범위를 지정하는 함수
function s.atktg(e, c)
    local handler = e:GetHandler()
    local sq = c:GetSequence()
    if handler:GetSequence() < 5 then
        local seq = handler:GetSequence()
        local oppo_seq = 4 - seq
        
        if seq == 1 then 
            return (sq >= oppo_seq - 1 and sq <= oppo_seq + 1) or sq == 6
        elseif seq == 3 then 
             return (sq >= oppo_seq - 1 and sq <= oppo_seq + 1) or sq == 5
        end
        return sq >= oppo_seq - 1 and sq <= oppo_seq + 1
    else
        local seq = handler:GetSequence()
        if seq == 5 then
            return sq == 1 or sq == 0 or sq == 2
        elseif seq == 6 then
            return sq == 3 or sq == 2 or sq == 4
        end
    end
    return false
end

function s.thfilter(c)
    return c:IsAbleToHand() and (c:IsRace(RACE_MACHINE) or c:IsRace(RACE_DRAGON)) 
    and c:IsAttribute(ATTRIBUTE_DARK) and c:IsMonster()
end
function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk)
    -- 파괴할 카드가 필드에 적어도 1장 존재
    local b1=Duel.GetMatchingGroup(nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
    -- 배틀 페이즈에 진입 가능해야 함
    local b2=Duel.IsAbleToEnterBP()
    -- 회수할 카드가 존재해야 함
    local b3=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_GRAVE,0,nil)

	if chk==0 then return #b1>0 or b2 or #b3>0 end
	Duel.SetOperationInfo(0,CATEGORY_COIN,nil,0,tp,3)
    Duel.SetPossibleOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_ONFIELD)
    Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local heads=Duel.CountHeads(Duel.TossCoin(tp,3))
    local ct=heads
    -- 앞면이 없으면 아무 처리 안함
    if ct==0 then return end
    -- 앞면이 1회 이상 (파괴)
    if ct>0 then 
        local b1=Duel.GetMatchingGroup(nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
        -- 파괴할 카드가 존재하고 파괴 효과를 선택했다면
        if #b1>0 and Duel.SelectYesNo(tp,aux.Stringid(id, 0)) then 
            -- 파괴할 카드를 선택
            local dg=b1:Select(tp,1,math.min(ct, #b1),nil)
            Duel.HintSelection(dg)
            Duel.Destroy(dg,REASON_EFFECT) -- 파괴
        end
    end
    -- 앞면이 2회 이상 (연속 공격)
    if ct>1 then 
        local b2=Duel.IsAbleToEnterBP()
        -- 배틀 진입이 가능하고 효과를 선택했다면
        if b2 and Duel.SelectYesNo(tp,aux.Stringid(id, 1)) then
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
            e1:SetCode(EFFECT_EXTRA_ATTACK)
            e1:SetValue(ct-1)
            e1:SetReset(RESETS_STANDARD_PHASE_END)
            c:RegisterEffect(e1)
        end
    end
    -- 앞면이 3회 (회수)
    if ct>2 then 
        local b3=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.thfilter),tp,LOCATION_GRAVE,0,nil)
        if #b3>0 and Duel.SelectYesNo(tp,aux.Stringid(id, 2)) then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
            local th=b3:Select(tp,1,1,nil)
            Duel.SendtoHand(th,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,th)
        end
    end
end