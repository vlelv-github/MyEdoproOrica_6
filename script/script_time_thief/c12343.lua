-- 크로노다이버 무브먼트
local s,id=GetID()
function s.initial_effect(c)
    --Activate
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	local e1a=Effect.CreateEffect(c)
	e1a:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1a:SetCode(EVENT_REMOVE)
	e1a:SetCountLimit(1,{id,1})
	e1a:SetProperty(EFFECT_FLAG_DELAY)
	e1a:SetRange(LOCATION_SZONE)
	e1a:SetCondition(s.regcon)
	e1a:SetOperation(s.regop)
	c:RegisterEffect(e1a)

	local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,2))
    e2:SetCategory(CATEGORY_DRAW)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_REMOVE)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetRange(LOCATION_SZONE)
    e2:SetCountLimit(1,{id,2})
    e2:SetCondition(s.condition2)
    e2:SetTarget(s.target2)
    e2:SetOperation(s.operation2)
    c:RegisterEffect(e2)
end
s.listed_series = {SET_TIME_THIEF}

function s.thfilter(c)
	return c:IsSetCard(SET_TIME_THIEF) and c:IsMonster() and c:IsAbleToHand()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.chlimit(re,rp,tp)
    return rp==tp or not (re:GetActivateLocation()==LOCATION_HAND)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

function s.regconfilter(c,tp)
	return c:IsPreviousControler(tp) -- 자신
		and c:IsPreviousLocation(LOCATION_ONFIELD) -- 필드의
		and c:IsSetCard(SET_TIME_THIEF) -- "크로노다이버"
		and c:IsType(TYPE_XYZ) -- 엑시즈
		and c:IsMonster() -- 몬스터가
	   	and c:IsFaceup() -- 앞면으로 제외된 경우
end
function s.regcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.regconfilter,1,nil,tp)
end

function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_CHANGE_BATTLE_DAMAGE)
	e1:SetTargetRange(1,0)
	e1:SetValue(HALF_DAMAGE)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
end


function s.xyzfilter(c)
    return c:IsFaceup() and c:IsRace(RACE_PSYCHIC) and c:IsType(TYPE_XYZ)
end

function s.condition2(e,tp,eg,ep,ev,re,r,rp)
    return eg and #eg>0
end

function s.target2(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetMatchingGroupCount(Card.IsFacedown,tp,0,LOCATION_HAND,nil)>0 -- 확인 가능한 상대 패가 1장 이상
            and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil) -- 자신 필드에 사이킥족 엑시즈 존재
            and Duel.IsPlayerCanDraw(tp,1) and Duel.IsPlayerCanDraw(1-tp,1) -- 양쪽 플레이어 드로우 가능
    end
    
    Duel.SetChainLimit(s.chlimit)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,PLAYER_ALL,1)
end



function s.operation2(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end

	local g0=Duel.GetMatchingGroup(Card.IsFacedown,tp,0,LOCATION_HAND,nil)
	if #g0==0 then return end --확인할 패가 없으면 효과 불발
    local g=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
    if #g==0 then return end
    Duel.ConfirmCards(tp,g)
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
    local sg=g:Select(tp,1,1,nil)
    local tc=sg:GetFirst()
	Duel.HintSelection(tc)
    

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
    local xyzg=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_MZONE,0,1,1,nil)
    local xyz=xyzg:GetFirst()
	Duel.HintSelection(xyz)
    
    if tc and xyz and not xyz:IsImmuneToEffect(e) then
        -- 패를 보여준 상태를 해제하고 엑시즈 소재로 겹침
        Duel.ShuffleHand(1-tp)
        Duel.Overlay(xyz,tc)
        
        -- 그 후, 양쪽 플레이어는 1장 드로우
        Duel.BreakEffect()
        Duel.Draw(tp,1,REASON_EFFECT)
        Duel.Draw(1-tp,1,REASON_EFFECT)
    else
        Duel.ShuffleHand(1-tp)
    end
end