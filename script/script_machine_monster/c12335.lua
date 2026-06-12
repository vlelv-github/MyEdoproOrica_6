-- 헤비메탈 퓨전
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Fusion.CreateSummonEff{handler=c,extraop=s.extraop,stage2=s.stage2,matfilter=s.matfil,extratg=s.extratg}
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON+CATEGORY_DESTROY)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	c:RegisterEffect(e1)

    local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1, {id, 1})
	e3:SetCondition(s.coincon1)
    e3:SetTarget(s.cointg1)
	e3:SetOperation(s.coinop1)
	c:RegisterEffect(e3)
end
function s.matfil(c,e,tp,chk)
	return c:IsLocation(LOCATION_HAND|LOCATION_MZONE) and c:IsDestructable(e) and not c:IsImmuneToEffect(e)
end
function s.extratg(e,tp,eg,ep,ev,re,r,rp,chk)
	local dg=Duel.GetFusionMaterial(tp):Filter(Card.IsLocation,nil,LOCATION_HAND|LOCATION_MZONE)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,dg,2,tp,LOCATION_HAND+LOCATION_MZONE)
end
function s.extraop(e,tc,tp,sg)
	local res=Duel.Destroy(sg,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)==#sg
	sg:Clear()
	return res
end
function s.stage2(e,tc,tp,sg,chk)
	if chk==1 then
		--Immune
		local e3=Effect.CreateEffect(e:GetHandler())
		e3:SetDescription(aux.Stringid(id,3))
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
		e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
		e3:SetRange(LOCATION_MZONE)
		e3:SetReset(RESET_EVENT|RESETS_STANDARD)
		e3:SetValue(function(e,re,rc,c) return re:IsMonsterEffect() or re:IsSpellEffect() and rp==1-e:GetHandlerPlayer() end)
		tc:RegisterEffect(e3,true)
        local e4=e3:Clone()
        e4:SetDescription(aux.Stringid(id,4))
		e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
		e4:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
		e4:SetValue(function(e,re,rp) return rp==1-e:GetHandlerPlayer() and (re:IsMonsterEffect() or re:IsSpellEffect()) end)
		tc:RegisterEffect(e4)
	end
end

function s.coincon1(e,tp,eg,ep,ev,re,r,rp)
	if eg:IsContains(e:GetHandler()) then return false end
	local ex,eg,et,cp,ct=Duel.GetOperationInfo(ev,CATEGORY_COIN)
	if ex and ct>2 then
		e:SetLabelObject(re)
		return true
	else return false end
end
function s.cointg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end
function s.coinop1(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SendtoHand(c,nil,REASON_EFFECT)~=0 then
        Duel.ConfirmCards(1-tp,c)
        Duel.BreakEffect()
        if Duel.SelectYesNo(tp,aux.Stringid(id,2)) then 
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
            e1:SetCode(EVENT_TOSS_COIN_NEGATE)
            e1:SetCondition(s.coincon2)
            e1:SetOperation(s.coinop2)
            e1:SetLabel(ev)
            e1:SetLabelObject(e:GetLabelObject())
            e1:SetReset(RESET_CHAIN)
            Duel.RegisterEffect(e1,tp)
        end
		
	end

	
end
function s.coincon2(e,tp,eg,ep,ev,re,r,rp)
	return re==e:GetLabelObject() and Duel.GetCurrentChain()==e:GetLabel()
end
function s.coinop2(e,tp,eg,ep,ev,re,r,rp)
	local res={}
	for i=1,ev do
		table.insert(res,COIN_HEADS)
	end
	Duel.SetCoinResult(table.unpack(res))
end