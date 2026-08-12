-- 사악령 네크로페이스
local s,id=GetID()
function s.initial_effect(c)
    local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_HAND)
	e2:SetHintTiming(TIMING_END_PHASE,TIMINGS_CHECK_MONSTER_E)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.cost)
	e2:SetTarget(s.tg)
	e2:SetOperation(s.op)
	c:RegisterEffect(e2)
end

s.listed_names = {CARD_DESTINY_BOARD, 16625614}
s.listed_series = {SET_SPIRIT_MESSAGE}
	-- "죽음의 메시지" 카드명 선언 필터
s.announce_filter={SET_SPIRIT_MESSAGE, OPCODE_ISSETCARD}
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	e:SetLabel(100)
	if chk==0 then return true end
end
function s.attfilter(c,tp)
	return c:IsFaceup() and c:IsPosition(POS_ATTACK) 
		and c:CheckUniqueOnField(tp) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
end
function s.tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    local c=e:GetHandler()
    if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_MZONE) and s.attfilter(chkc,tp) end
    
    -- 각 효과 발동 가능 여부 체크
    local b1 = Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil,REASON_EFFECT)
        and Duel.IsExistingMatchingCard(s.actfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,tp)
        
    local b2 = c:IsDiscardable() 
        and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode, CARD_DESTINY_BOARD),tp,LOCATION_ONFIELD,0,1,nil)
        and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode, 16625614),tp,LOCATION_ONFIELD,0,1,nil)
        and Duel.IsExistingTarget(s.attfilter,tp,0,LOCATION_MZONE,1,nil,tp)

    if chk==0 then
        if e:GetLabel()~=100 then return false end
        e:SetLabel(0)
        return b1 or b2 
    end

    e:SetLabel(0)
    local op=0
    if b1 and b2 then
        op=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1))+1
    elseif b1 then
        op=1
    else
        op=2
    end
    
    e:SetLabel(op)
    if op==1 then
        e:SetProperty(0)
        e:SetCategory(CATEGORY_HANDES)
        Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,tp,1)
    elseif op==2 then
        e:SetProperty(EFFECT_FLAG_CARD_TARGET)
        e:SetCategory(0)
        -- b2 효과 코스트: 이 카드를 패에서 버린다.
        Duel.SendtoGrave(c,REASON_COST+REASON_DISCARD)
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
        Duel.SelectTarget(tp,s.attfilter,tp,0,LOCATION_MZONE,1,1,nil,tp)
		local ac=Duel.AnnounceCard(tp,s.announce_filter)
		Duel.SetTargetParam(ac)
    end
end
function s.actfilter(c,tp)
	return c:IsCode(CARD_DESTINY_BOARD) and c:GetActivateEffect():IsActivatable(tp,true,true)
end
function s.monfilter(c)
	return c:IsMonster() and c:IsLevel(8) and c:IsRace(RACE_FIEND) and c:IsFaceup()
end

function s.op(e,tp,eg,ep,ev,re,r,rp,chk)
	local op=e:GetLabel()
	local c=e:GetHandler()
	if op==1 then 
		if Duel.DiscardHand(tp,nil,1,1,REASON_EFFECT|REASON_DISCARD)>0 then 
			Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,2))
			local tc=Duel.SelectMatchingCard(tp,s.actfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,tp):GetFirst()
			if tc then
				Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
				local te=tc:GetActivateEffect()
				local tep=tc:GetControler()
				local cost=te:GetCost()
				if cost then
					cost(te,tep,eg,ep,ev,re,r,rp,1)
				end
			end
		end
	else
		local tc=Duel.GetFirstTarget()
		local ac=Duel.GetChainInfo(0,CHAININFO_TARGET_PARAM)
		if Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,tc:IsMonsterCard()) then
			--Treated as a Continuous Spell
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetCode(EFFECT_CHANGE_TYPE)
			e1:SetValue(TYPE_SPELL|TYPE_CONTINUOUS)
			e1:SetReset(RESET_EVENT|(RESETS_STANDARD&~RESET_TURN_SET))
			tc:RegisterEffect(e1)
			
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
			e2:SetCode(EFFECT_CHANGE_CODE)
			e2:SetRange(LOCATION_SZONE)
			e2:SetValue(ac)
			e2:SetReset(RESET_EVENT|(RESETS_STANDARD&~RESET_TURN_SET))
			tc:RegisterEffect(e2,true)

		end
	end
end
function s.cfilter3(c)
	return c:IsFaceup() and c:IsCode(table.unpack(CARDS_SPIRIT_MESSAGE))
end
function s.winop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.cfilter3,tp,LOCATION_ONFIELD,0,nil)
	if g:GetClassCount(Card.GetCode)==4 and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode, CARD_DESTINY_BOARD),tp,LOCATION_ONFIELD,0,1,nil) then
		Duel.Win(tp,WIN_REASON_DESTINY_BOARD)
	end
end
