-- 틴당글 스피리컬 트리아도스
local s,id=GetID()
function s.initial_effect(c)
    -- 소환 조건
	Link.AddProcedure(c,nil,3,3,s.lcheck)
	c:EnableReviveLimit()

    local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.mvcon)
	e1:SetTarget(s.mvtg)
	e1:SetOperation(s.mvop)
	c:RegisterEffect(e1)

    local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_POSITION)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetHintTiming(TIMING_END_PHASE,TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
	e3:SetCountLimit(1)
    e3:SetCondition(s.tncon)
	e3:SetTarget(s.tntg)
	e3:SetOperation(s.tnop)
	c:RegisterEffect(e3)

    local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_TOHAND+CATEGORY_TOGRAVE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1)
	e4:SetCondition(function(e,tp)
		return Duel.IsTurnPlayer(1-tp)
	end)
	e4:SetTarget(s.thtg)
	e4:SetOperation(s.thop)
	e4:SetHintTiming(0,TIMING_STANDBY_PHASE|TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
	c:RegisterEffect(e4)

    aux.GlobalCheck(s,function()
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_CHANGE_POS)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end)
end

s.listed_series = {SET_TINDANGLE}
	-- 소환 조건
function s.lcheck(g,lc,sumtype,tp)
	return g:IsExists(Card.IsSetCard,1,nil,SET_TINDANGLE,lc,sumtype,tp)
end

function s.mvcon(e)
	local c=e:GetHandler()
    local g=Duel.GetMatchingGroup(s.cfilter,e:GetHandler():GetControler(),LOCATION_GRAVE,0,nil)
	return c:IsLinkSummoned() and c:IsInExtraMZone() and g:GetClassCount(Card.GetCode)>=3
end
function s.mvtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE,tp,LOCATION_REASON_CONTROL)>0
        and Duel.IsExistingMatchingCard(Card.IsAbleToGrave,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end
function s.mvop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsControler(tp) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then 
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOZONE)
	    Duel.MoveSequence(c,math.log(Duel.SelectDisableField(tp,1,LOCATION_MZONE,0,0),2))
        if not c:IsInExtraMZone() then 
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
            local g=Duel.SelectMatchingCard(tp,Card.IsAbleToGrave,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil)
            if #g>0 then
                Duel.SendtoGrave(g,REASON_EFFECT)
            end
        end
    end

end

function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE|PHASE_END,0,1)
end
function s.tncon(e,tp,eg,ep,ev,re,r,rp,chk)
	return Duel.GetFlagEffect(tp,id)>0 or Duel.GetFlagEffect(1-tp,id)>0 
end
function s.tntg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsCanTurnSet,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_POSITION,nil,1,PLAYER_EITHER,POS_FACEDOWN_DEFENSE)
end
function s.tnop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_POSCHANGE)
    local g=Duel.SelectMatchingCard(tp,Card.IsCanTurnSet,tp,LOCATION_MZONE,LOCATION_MZONE,1,3,nil)
    if #g==0 then return end
    Duel.HintSelection(g,true)
    Duel.BreakEffect()
    Duel.ChangePosition(g,POS_FACEDOWN_DEFENSE)
end

function s.thfilter(c)
	return c:IsType(TYPE_FLIP) and c:IsMonster() and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_HAND)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then	
		Duel.ConfirmCards(1-tp,g)
        Duel.DiscardHand(tp,nil,1,1,REASON_EFFECT,nil)
	end
end
