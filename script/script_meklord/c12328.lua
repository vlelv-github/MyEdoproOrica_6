-- 궁극기황신 트리니티 프라임
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
    --Must first be Special Summoned (from your hand) by banishing 3 "Meklord" monsters with different names from your GY
	local e0=Effect.CreateEffect(c)
	e0:SetDescription(aux.Stringid(id,0))
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetRange(LOCATION_HAND)
	e0:SetCondition(s.spcon)
	e0:SetTarget(s.sptg)
	e0:SetOperation(s.spop)
	c:RegisterEffect(e0)

    local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RECOVER)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetTarget(s.sptg1)
	e1:SetOperation(s.spop1)
	c:RegisterEffect(e1)

    local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_TOEXTRA+CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCost(s.retcost)
	e3:SetOperation(s.retop)
	c:RegisterEffect(e3)

end
s.listed_series={SET_MEKLORD_EMPEROR,SET_MEKLORD_ASTRO}
function s.spcostfilter(c)
	return c:IsSetCard(SET_MEKLORD_ASTRO) and c:IsMonster() and c:IsAbleToRemoveAsCost() --and aux.SpElimFilter(c,true)
    and ((not c:IsLocation(LOCATION_MZONE)) or (c:IsLocation(LOCATION_MZONE) and c:IsFaceup()))
end
function s.rescon(sg,e,tp,mg)
	return Duel.GetMZoneCount(tp,sg)>0 and sg:GetClassCount(Card.GetCode)==#sg,sg:GetClassCount(Card.GetCode)~=#sg
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local rg=Duel.GetMatchingGroup(s.spcostfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_MZONE+LOCATION_GRAVE,0,c)
	return #rg>=2 and aux.SelectUnselectGroup(rg,e,tp,3,3,s.rescon,0)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local rg=Duel.GetMatchingGroup(s.spcostfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_MZONE+LOCATION_GRAVE,0,c)
	local g=aux.SelectUnselectGroup(rg,e,tp,3,3,s.rescon,1,tp,HINTMSG_REMOVE,nil,nil,true)
	if #g>0 then
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.Remove(g,POS_FACEUP,REASON_COST)
	g:DeleteGroup()
end

function s.spfilter1(c,e,tp)
	return c:IsType(TYPE_SYNCHRO) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) and Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
end
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
    Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,0)
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter1,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	if #g>0 and Duel.SpecialSummon(g,0,tp,1-tp,false,false,POS_FACEUP)>0 then
        local atk=Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsType,TYPE_SYNCHRO),tp,LOCATION_MZONE,LOCATION_MZONE,nil):GetSum(Card.GetAttack)
		if atk>0 then
            Duel.BreakEffect()
		    Duel.Recover(tp,atk,REASON_EFFECT)
        end
	end
end
function s.costfilter(c)
	return c:IsSetCard(SET_MEKLORD_EMPEROR) and c:IsAbleToGraveAsCost()
end
function s.retcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_DECK,0,1,1,nil)
	Duel.SendtoGrave(g,REASON_COST)
    e:SetLabel(g:GetFirst():GetOriginalCodeRule())
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
    local code=e:GetLabel()
	if code and c:IsRelateToEffect(e) and c:IsFaceup() then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESETS_STANDARD_PHASE_END,2)
		e1:SetCode(EFFECT_CHANGE_CODE)
		e1:SetValue(code)
		c:RegisterEffect(e1)
		c:CopyEffect(code, RESETS_STANDARD_PHASE_END, 2)
	end
end