-- Kozmo - 클라이맥스
local s,id=GetID()
function s.initial_effect(c)

	local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0)) 
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,{id,1})
	e1:SetHintTiming(0,TIMING_END_PHASE|TIMING_EQUIP)
    e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)

    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1)) 
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,{id,2})
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetCost(s.spcost)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
end

s.listed_series = {SET_KOZMO}

-- 1. 코스트 관련: Kozmo 카드를 필터링
function s.costfilter(c)
    return c:IsSetCard(SET_KOZMO) and c:IsAbleToRemoveAsCost()
        and (not c:IsLocation(LOCATION_ONFIELD) or c:IsFaceup()) -- 필드라면 앞면 표시만
end

-- 2. 코스트 조건 함수 (rescon)
-- 유저가 카드를 선택할 때마다 유효한 선택인지 검사합니다.
function s.rescon(sg, e, tp, mg)
    
    -- 최대 2장까지 선택 가능
    if #sg > 2 then return false end
    
    -- 패/덱에 파괴할 수 있는 Kozmo 몬스터가 '현재 선택한 카드 수'만큼 존재하는지 실시간 체크
    -- (1장 골랐을 때는 1장 이상, 2장 골랐을 때는 서로 다른 이름 2장 이상이 패/덱에 있어야 함)
    local dg = Duel.GetMatchingGroup(s.desfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, sg)
    return dg:GetClassCount(Card.GetCode) >= #sg
end

-- 파괴할 대상(패/덱의 Kozmo 몬스터) 필터
function s.desfilter(c)
    return c:IsSetCard(SET_KOZMO) and c:IsMonster() and c:IsDestructable()
end

-- 3. Cost 함수
function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
    -- 패 / 필드(앞면) / 묘지의 Kozmo 카드들을 긁어옵니다.
    local g = Duel.GetMatchingGroup(s.costfilter, tp, LOCATION_HAND + LOCATION_MZONE + LOCATION_GRAVE, 0, e:GetHandler())
    
    if chk == 0 then
        -- 1장부터 2장까지 선택 가능한지 체크 (minc=1, maxc=2)
        return aux.SelectUnselectGroup(g, e, tp, 1, 2, s.rescon, 0, chk)
    end
    
    -- 실제로 유저가 1~2장을 선택하도록 UI를 띄웁니다.
    local sg = aux.SelectUnselectGroup(g, e, tp, 1, 2, s.rescon, 1, chk, tp)
    
    -- 제외된 카드의 수를 Operation으로 넘겨주기 위해 Label에 저장합니다.
    e:SetLabel(#sg)
    
    -- 선택한 카드들을 제외합니다.
    Duel.Remove(sg, POS_FACEUP, REASON_COST)
end

-- 4. Target 함수
function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end -- 효과 발동 시점의 체크는 코스트 단계에서 이미 끝났으므로 true
    
    -- 제외한 수(Label)만큼 파괴 카테고리를 설정
    local count = e:GetLabel()
    Duel.SetOperationInfo(0, CATEGORY_DESTROY, nil, count, tp, LOCATION_HAND + LOCATION_DECK)
end

-- 5. 파괴 처리 조건 함수 (Operation에서 중복 없이 고르기 위한 rescon)
function s.descon(sg, e, tp, mg)
    local count = e:GetLabel()
    if #sg > count then return false end
    
    -- 같은 이름의 카드는 1장까지만 골라야 하므로, 선택된 카드들의 이름 종류 수(ClassCount)가 카드 수와 같아야 함
    if sg:GetClassCount(Card.GetCode) ~= #sg then return false end
    
    return #sg == count
end

-- 6. Operation 함수 (효과 처리)
function s.operation(e, tp, eg, ep, ev, re, r, rp)
    local count = e:GetLabel() -- 코스트로 제외했던 수
    if count == 0 then return end
    
    -- 패/덱에서 파괴 가능한 Kozmo 몬스터를 모읍니다.
    local g = Duel.GetMatchingGroup(s.desfilter, tp, LOCATION_HAND + LOCATION_DECK, 0, nil)
    
    -- 유저가 "같은 이름이 중복되지 않게" 정확히 count만큼 고르도록 aux.SelectUnselectGroup 사용
    if g:GetClassCount(Card.GetCode) >= count then
        local sg = aux.SelectUnselectGroup(g, e, tp, count, count, s.descon, 1, tp)
        if #sg > 0 then
            Duel.Destroy(sg, REASON_EFFECT)
        end
    end
end



-- 1. 대상 필터 함수
function s.spfilter(c, e, tp)
    -- 제외 상태(앞면), Kozmo(0xd2) 소속, 몬스터, 레벨을 가질 것(엑시즈/링크 배제)
    -- 그리고 특수 소환이 가능하며, 해당 레벨 x 300 만큼의 LP를 지불할 수 있는지 체크
    return c:IsFaceup() and c:IsSetCard(SET_KOZMO) and c:IsMonster() and c:IsLevelAbove(1)
        and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
        and Duel.CheckLPCost(tp, c:GetLevel() * 300)
        and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
end

-- 2. Cost 함수 (이 카드 제외 및 발동 가능 여부 체크)
function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        -- 묘지의 이 카드를 제외할 수 있는지(aux.bfg) + 대상을 지정하고 LP를 낼 수 있는 몬스터가 있는지 동시 체크
        return aux.bfgcost(e,tp,eg,ep,ev,re,r,rp,0)
            and Duel.IsExistingTarget(s.spfilter, tp, LOCATION_REMOVED, 0, 1, nil, e, tp)
    end
    -- 묘지의 이 카드를 제외 (코스트)
    Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

-- 3. Target 함수 (대상 지정 및 LP 지불)
function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then return chkc:IsLocation(LOCATION_REMOVED) and chkc:IsControler(tp) and s.spfilter(chkc, e, tp) end
    if chk == 0 then return true end -- cost 함수에서 이미 존재 여부를 체크했으므로 여기선 true 통과
    
    -- 유저에게 대상을 고르라고 창을 띄움
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local g = Duel.SelectTarget(tp, s.spfilter, tp, LOCATION_REMOVED, 0, 1, 1, nil, e, tp)
    
    local tc = g:GetFirst()
    if tc then
        -- 선택한 몬스터의 레벨 × 300 만큼 LP 지불 (발동 시점)
        Duel.PayLPCost(tp, tc:GetLevel() * 300)
    end
    
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, g, 1, 0, 0)
end

-- 4. Operation 함수 (효과 처리: 특수 소환 및 공력력 상승)
function s.spop(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    
    -- 대상이 여전히 유효한지(제외 존에 있는지 등) 체크하고 특수 소환
    if tc and tc:IsRelateToEffect(e) and Duel.SpecialSummon(tc, 0, tp, tp, false, false, POS_FACEUP) > 0 then
        -- 특수 소환에 성공했다면, 공격력 1000 상승 효과 부여
        local e1 = Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(1000)
        e1:SetReset(RESET_EVENT + RESETS_STANDARD) -- 몬스터가 앞면 표시로 존재하는 한 영구 적용
        tc:RegisterEffect(e1)
    end
end