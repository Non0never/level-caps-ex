
class Pokemon
  alias level_caps_level_equals level= unless method_defined?(:level_caps_level_equals)
  alias __level_caps_initialize initialize unless method_defined?(:__level_caps_initialize)
  alias __level_caps_owner_equals owner= unless method_defined?(:__level_caps_owner_equals)

  def initialize(species, level, owner = $player, withMoves = true, recheck_form = true)
    @level_cap_npc_owner = owner.is_a?(NPCTrainer)
    __level_caps_initialize(species, level, owner, withMoves, recheck_form)
  end

  def owner=(new_owner)
    npc_owner_id = @owner.id if @level_cap_npc_owner && @owner
    __level_caps_owner_equals(new_owner)
    @level_cap_npc_owner = !!(npc_owner_id && new_owner.id == npc_owner_id)
  end

  def level=(value)
    validate value => Integer
    if value < 1 || value > GameData::GrowthRate.max_level
      max_lvl = GameData::GrowthRate.max_level
      limit = (value < 1)? ["below the minimum of level 1", "1"] : ["above the maximum of level #{max_lvl}", "#{max_lvl}"]
      echoln _INTL("Level {1} for {2} is not a valid level as it goes {3}. The level has been reset to {4}",
                    value, self, limit[0], limit[1])
      value = value.clamp(1, GameData::GrowthRate.max_level)
    end

    enemy_bypass = $game_switches && $game_switches[LevelCapsEX::LEVEL_CAP_BYPASS_SWITCH] &&
                   @level_cap_npc_owner
    if LevelCapsEX.hard_cap? && !enemy_bypass && value > LevelCapsEX.level_cap
      value = LevelCapsEX.level_cap
    end

    @exp = growth_rate.minimum_exp_for_level(value)
    @level = value
  end

  def at_level_cap?
    return (LevelCapsEX.hard_cap? || LevelCapsEX.soft_cap?) && self.level >= LevelCapsEX.level_cap
  end

  alias crosses_level_cap? at_level_cap?

  def level
    @level = growth_rate.level_from_exp(@exp) if !@level
    self.level = GameData::GrowthRate.max_level if @level > GameData::GrowthRate.max_level
    return @level
  end
end

module GameData
  class GrowthRate
    def self.max_level
      return LevelCapsEX.hard_level_cap
    end
  end
end

class Battle
  alias __level_caps_initialize initialize unless method_defined?(:__level_caps_initialize)

  def initialize(*args)
    __level_caps_initialize(*args)

    if $game_switches && $game_switches[LevelCapsEX::LEVEL_CAP_BYPASS_SWITCH]
      return
    end

    return unless LevelCapsEX.hard_cap? || LevelCapsEX.soft_cap?

    if opponent && opponent.is_a?(Array)
      opponent.each do |trainer|
        next if !trainer || !trainer.party
        trainer.party.each do |pkmn|
          next if !pkmn
          if pkmn.level > LevelCapsEX.level_cap
            pkmn.level = LevelCapsEX.level_cap
            pkmn.calc_stats
          end
        end
      end
    end
  end

  alias __level_caps_pbGainExpOne pbGainExpOne unless method_defined?(:__level_caps_pbGainExpOne)

  def pbGainExpOne(idxParty, defeatedBattler, numPartic, expShare, expAll, showMessages = true)
    pkmn = pbParty(0)[idxParty]
    return unless pkmn
    growth_rate = pkmn.growth_rate

    if LevelCapsEX.hard_cap? && pkmn.level >= LevelCapsEX.level_cap

      if LevelCapsEX::EXP_STORAGE_ENABLED
        LevelCapsEX.store_blocked_exp(pkmn, idxParty, defeatedBattler, numPartic, expShare, expAll, trainerBattle?)
      end
      return
    end

    if LevelCapsEX::SHARED_EXP_RESPECTS_CAP &&
       (LevelCapsEX.soft_cap? || LevelCapsEX.obedience_cap?) &&
       pkmn.level >= LevelCapsEX.level_cap
      return if !defeatedBattler.participants.include?(idxParty)
    end

    soft_cap_active = LevelCapsEX.soft_cap? && pkmn.level >= LevelCapsEX.level_cap
    hard_cap_clamp_needed = LevelCapsEX.hard_cap?
    unless soft_cap_active || hard_cap_clamp_needed
      return __level_caps_pbGainExpOne(idxParty, defeatedBattler, numPartic, expShare, expAll, showMessages)
    end

    if pkmn.exp >= growth_rate.maximum_exp
      pkmn.calc_stats
      return
    end
    isPartic    = defeatedBattler.participants.include?(idxParty)
    hasExpShare = expShare.include?(idxParty)
    level = defeatedBattler.level

    exp = 0
    a = level * defeatedBattler.pokemon.base_exp
    if expShare.length > 0 && (isPartic || hasExpShare)
      if numPartic == 0
        exp = a / (Settings::SPLIT_EXP_BETWEEN_GAINERS ? expShare.length : 1)
      elsif Settings::SPLIT_EXP_BETWEEN_GAINERS
        exp = a / (2 * numPartic) if isPartic
        exp += a / (2 * expShare.length) if hasExpShare
      else
        exp = (isPartic) ? a : a / 2
      end
    elsif isPartic
      exp = a / (Settings::SPLIT_EXP_BETWEEN_GAINERS ? numPartic : 1)
    elsif expAll

      exp = a / 2
    end
    return if exp <= 0

    exp = (exp * 1.5).floor if Settings::MORE_EXP_FROM_TRAINER_POKEMON && trainerBattle?

    if Settings::SCALED_EXP_FORMULA
      exp /= 5
      levelAdjust = ((2 * level) + 10.0) / (pkmn.level + level + 10.0)
      levelAdjust **= 5
      levelAdjust = Math.sqrt(levelAdjust)
      exp *= levelAdjust
      exp = exp.floor
      exp += 1 if isPartic || hasExpShare
    else
      exp /= 7
    end

    isOutsider = (pkmn.owner.id != pbPlayer.id ||
                 (pkmn.owner.language != 0 && pkmn.owner.language != pbPlayer.language))
    if isOutsider
      if pkmn.owner.language != 0 && pkmn.owner.language != pbPlayer.language
        exp = (exp * 1.7).floor
      else
        exp = (exp * 1.5).floor
      end
    end

    exp = exp * 3 / 2 if $bag.has?(:EXPCHARM)

    i = Battle::ItemEffects.triggerExpGainModifier(pkmn.item, pkmn, exp)
    if i < 0
      i = Battle::ItemEffects.triggerExpGainModifier(@initialItems[0][idxParty], pkmn, exp)
    end
    exp = i if i >= 0

    if Settings::AFFECTION_EFFECTS && @internalBattle && pkmn.affection_level >= 4 && !pkmn.mega?
      exp = exp * 6 / 5
      isOutsider = true
    end

    over_level_cap = false
    if LevelCapsEX.soft_cap? && pkmn.level >= LevelCapsEX.level_cap
      over_level_cap = true
      levels_over = pkmn.level - LevelCapsEX.level_cap
      if LevelCapsEX::SOFT_CAP_SCALED

        reduction = [0.5 ** (levels_over + 1), 0.01].max
        exp = (exp * reduction).to_i
      else

        exp = (exp / 10).to_i
      end
      exp = 1 if exp < 1
    end

    expFinal = growth_rate.add_exp(pkmn.exp, exp)

    if LevelCapsEX.hard_cap?
      max_exp_allowed = growth_rate.minimum_exp_for_level(LevelCapsEX.level_cap)
      expFinal = [expFinal, max_exp_allowed].min
    end

    expGained = expFinal - pkmn.exp
    return if expGained <= 0

    if showMessages
      message = _INTL("{1} got {2} Exp. Points!", pkmn.name, expGained)
      message = _INTL("{1} got a boosted {2} Exp. Points!", pkmn.name, expGained) if isOutsider
      message = _INTL("{1} got a reduced {2} Exp. Points!", pkmn.name, expGained) if over_level_cap
      pbDisplayPaused(message)
    end
    curLevel = pkmn.level
    newLevel = growth_rate.level_from_exp(expFinal)
    if newLevel < curLevel
      debugInfo = "Levels: #{curLevel}->#{newLevel} | Exp: #{pkmn.exp}->#{expFinal} | gain: #{expGained}"
      raise _INTL("{1}'s new level is less than its current level, which shouldn't happen.", pkmn.name) + "\n[#{debugInfo}]"
    end

    if pkmn.shadowPokemon?
      if pkmn.heartStage <= 3
        pkmn.exp += expGained
        $stats.total_exp_gained += expGained
      end
      return
    end
    $stats.total_exp_gained += expGained
    tempExp1 = pkmn.exp

    if LevelCapsEX.hard_cap? && newLevel > LevelCapsEX.level_cap
      newLevel = LevelCapsEX.level_cap
    end
    battler = pbFindBattler(idxParty)
    loop do

      levelMinExp = growth_rate.minimum_exp_for_level(curLevel)
      levelMaxExp = growth_rate.minimum_exp_for_level(curLevel + 1)
      tempExp2 = (levelMaxExp < expFinal) ? levelMaxExp : expFinal
      pkmn.exp = tempExp2
      @scene.pbEXPBar(battler, levelMinExp, levelMaxExp, tempExp1, tempExp2)
      tempExp1 = tempExp2
      curLevel += 1
      if curLevel > newLevel

        pkmn.calc_stats
        battler&.pbUpdate(false)
        @scene.pbRefreshOne(battler.index) if battler
        break
      end

      pbCommonAnimation("LevelUp", battler) if battler
      oldTotalHP = pkmn.totalhp
      oldAttack  = pkmn.attack
      oldDefense = pkmn.defense
      oldSpAtk   = pkmn.spatk
      oldSpDef   = pkmn.spdef
      oldSpeed   = pkmn.speed
      battler.pokemon.changeHappiness("levelup") if battler&.pokemon
      pkmn.calc_stats
      battler&.pbUpdate(false)
      @scene.pbRefreshOne(battler.index) if battler
      pbDisplayPaused(_INTL("{1} grew to Lv. {2}!", pkmn.name, curLevel)) { pbSEPlay("Pkmn level up") }
      @scene.pbLevelUp(pkmn, battler, oldTotalHP, oldAttack, oldDefense,
                       oldSpAtk, oldSpDef, oldSpeed)

      moveList = pkmn.getMoveList
      moveList.each { |m| pbLearnMove(idxParty, m[1]) if m[0] == curLevel }
    end
  end
end

class Battle::Battler

  alias __level_cap__pbObedienceCheck? pbObedienceCheck? unless method_defined?(:__level_cap__pbObedienceCheck?)
  def pbObedienceCheck?(*args)
    ret = __level_cap__pbObedienceCheck?(*args)
    db = @disobeyed
    @disobeyed = false

    return ret if db

    return ret unless ret

    return true unless LevelCapsEX.obedience_cap?
    lv_diff = @level - LevelCapsEX.level_cap
    return true if lv_diff <= 0
    lv_diff = 5 if lv_diff > 5

    range = 5 - lv_diff
    disobedient = range <= 0 || rand(range) == 0
    return pbDisobey(args[0], (lv_diff * 2)) if disobedient
    return true
  end

  alias __level_cap__pbDisobey pbDisobey unless method_defined?(:__level_cap__pbDisobey)
  def pbDisobey(*args)
    ret = __level_cap__pbDisobey(*args)
    @disobeyed = true
    return ret
  end
end

class Battle::AI
  alias __level_caps_pbDefaultChooseNewEnemy pbDefaultChooseNewEnemy unless method_defined?(:__level_caps_pbDefaultChooseNewEnemy)

  def pbDefaultChooseNewEnemy(idxBattler)
    ret = __level_caps_pbDefaultChooseNewEnemy(idxBattler)
    return ret if !ret || ret < 0
    return ret if @battle.pbCanSwitchIn?(idxBattler, ret)

    new_choice = -1
    @battle.eachInTeamFromBattlerIndex(idxBattler) do |_pkmn, i|
      next if !@battle.pbCanSwitchIn?(idxBattler, i)
      new_choice = i
      break
    end
    return new_choice
  end
end

module GameData
  class GrowthRate

    @original_max_level = Settings::MAXIMUM_LEVEL

    class << self
      alias_method :original_max_level, :max_level unless method_defined?(:original_max_level)

      def max_level

        if defined?(FileLineData) || caller.any? { |c| c.include?("compile") }
          return @original_max_level || Settings::MAXIMUM_LEVEL
        end

        return LevelCapsEX.hard_level_cap
      end
    end
  end
end

class Trainer
  alias __level_caps_initialize initialize unless method_defined?(:__level_caps_initialize)

  def initialize(*args)
    __level_caps_initialize(*args)
    enforce_level_cap
  end

  def enforce_level_cap

    return if !$game_switches
    return if $game_switches[LevelCapsEX::LEVEL_CAP_BYPASS_SWITCH] && is_a?(NPCTrainer)
    return unless LevelCapsEX.hard_cap? || LevelCapsEX.soft_cap?

    return if @_level_cap_enforced
    @_level_cap_enforced = true

    cap = LevelCapsEX.level_cap
    @party&.each do |pkmn|
      next if !pkmn
      if pkmn.level > cap
        pkmn.level = cap
        pkmn.calc_stats
      end
    end
  end
end
