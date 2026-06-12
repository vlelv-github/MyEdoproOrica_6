-- 시간의 기계-타임 코어
local s,id=GetID()
function s.initial_effect(c)
	--activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_HANDES)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

    --Special Summon 1 destroyed monster
	local e3a=Effect.CreateEffect(c)
	e3a:SetDescription(aux.Stringid(id,1))
	e3a:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3a:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3a:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e3a:SetCode(EVENT_CUSTOM+id)
	e3a:SetRange(LOCATION_GRAVE)
    e3a:SetCost(Cost.SelfBanish)
	e3a:SetCountLimit(1,{id,1})
	e3a:SetTarget(s.sptg)
	e3a:SetOperation(s.spop)
	c:RegisterEffect(e3a)
	local g=Group.CreateGroup()
	g:KeepAlive()
	e3a:SetLabelObject(g)
	--Register the destuction of monsters
	local e3b=Effect.CreateEffect(c)
	e3b:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3b:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e3b:SetCode(EVENT_DESTROYED)
	e3b:SetRange(LOCATION_GRAVE)
	e3b:SetLabelObject(e3a)
	e3b:SetOperation(s.regop)
	c:RegisterEffect(e3b)
end

function s.thfilter(c)
	return c:IsRace(RACE_MACHINE) and c:IsAttribute(ATTRIBUTE_DARK) and c:IsAbleToHand()
end
function s.rescon(sg,e,tp,mg)
	return aux.ChkfMMZ(2)(sg,e,tp,mg) and sg:FilterCount(s.thfilter,nil,e,tp)==2
		and sg:FilterCount(Card.IsLevelAbove,nil,5)==1 and sg:FilterCount(Card.IsLevelBelow,nil,4)==1
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
	if chk==0 then return aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,chk) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
	local sg=aux.SelectUnselectGroup(g,e,tp,2,2,s.rescon,1,tp,HINTMSG_ATOHAND)
	if #sg==2 and Duel.SendtoHand(sg,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,sg)
        Duel.BreakEffect()
        Duel.DiscardHand(tp,nil,1,1,REASON_EFFECT+REASON_DISCARD)
	end
    --Cannot Special Summon from the Extra Deck for the rest of this turn, except Machine monsters
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(function(e,c) return c:IsLocation(LOCATION_EXTRA) and not c:IsRace(RACE_MACHINE) end)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
	--Clock Lizard check
	aux.addTempLizardCheck(c,tp,function(e,c) return not c:IsOriginalRace(RACE_MACHINE) end)
end

function s.tgfilter(c,tp,e)
	return ((c:IsPreviousLocation(LOCATION_MZONE)
        and c:IsPreviousAttributeOnField(ATTRIBUTE_DARK) and c:IsPreviousRaceOnField(RACE_MACHINE)) 
		or (not c:IsPreviousLocation(LOCATION_MZONE) and c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_MACHINE)))
        and c:IsPreviousControler(tp) and c:IsFaceup()
		and c:IsLocation(LOCATION_GRAVE|LOCATION_REMOVED) 
		and c:IsReason(REASON_BATTLE|REASON_EFFECT) and c:IsCanBeEffectTarget(e)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFlagEffect(tp,id)>0 then return end
	local tg=eg:Filter(s.tgfilter,nil,tp,e)
	if #tg>0 then
		for tc in tg:Iter() do
			tc:RegisterFlagEffect(id,RESET_CHAIN,0,1)
		end
		local g=e:GetLabelObject():GetLabelObject()
		if Duel.GetCurrentChain()==0 then g:Clear() end
		g:Merge(tg)
		g:Remove(function(c) return c:GetFlagEffect(id)==0 end,nil)
		e:GetLabelObject():SetLabelObject(g)
		Duel.RaiseSingleEvent(e:GetHandler(),EVENT_CUSTOM+id,e,0,tp,tp,0)
	end
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=e:GetLabelObject():Filter(s.tgfilter,nil,tp,e)
	if chkc then return g:IsContains(chkc) and s.tgfilter(chkc,tp,e) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and #g>0 end
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE|PHASE_END,0,1)
	local tc=nil
	if #g==1 then
		tc=g:GetFirst()
		Duel.SetTargetCard(tc)
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
		tc=g:Select(tp,1,1,nil)
		Duel.SetTargetCard(tc)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,tc,1,tp,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end